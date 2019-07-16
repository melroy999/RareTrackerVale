local _, data = ...

local RTM = data.RTM

-- ####################################################################
-- ##                         Communication                          ##
-- ####################################################################

-- The time at which you broad-casted the joined the shard group.
RTM.arrival_register_time = nil

-- The name and realm of the player.
local player_name = UnitName("player").."-"..GetRealmName()

-- A flag that ensures that the version warning is only given once per session.
local reported_version_mismatch = false

-- The name of the current channel.
local channel_name = nil

-- The last time the health of an entity has been reported.
-- Used for limiting the number of messages sent to the channel.
RTM.last_health_report = {}

-- ####################################################################
-- ##                        Helper Functions                        ##
-- ####################################################################

-- A time stamp at which the last message was sent in the rate limited message sender.
RTM.last_message_sent = 0

-- A function that acts as a rate limiter for channel messages.
function RTM:SendRateLimitedAddonMessage(message, target, target_id)
	-- We only allow one message to be sent every ~4 seconds.
	if GetServerTime() - RTM.last_message_sent > 4 then
		C_ChatInfo.SendAddonMessage("RTM", message, target, target_id)
		RTM.last_message_sent = GetServerTime()
	end
end

-- Compress all the kill data the user has to Base64.
function RTM:GetCompressedSpawnData(time_stamp)
	local data = ""
	
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		local kill_time = RTM.last_recorded_death[npc_id]
		
		if kill_time ~= nil then
			data = data..RTM:toBase64(time_stamp - kill_time)..","
		else
			data = data..RTM:toBase64(0)..","
		end
	end
	
	return data:sub(1, #data - 1)
end

-- Decompress all the Base64 data sent by a peer to decimal and update the timers.
function RTM:DecompressSpawnData(spawn_data, time_stamp)
	local spawn_data_entries = {strsplit(",", spawn_data, #RTM.rare_ids)}

	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		local kill_time = RTM:toBase10(spawn_data_entries[i])
		
		if kill_time ~= 0 then
			if RTM.last_recorded_death[npc_id] then
				-- If we already have an entry, take the minimal.
				if time_stamp - kill_time < RTM.last_recorded_death[npc_id] then
					RTM.last_recorded_death[npc_id] = time_stamp - kill_time
				end
			else
				RTM.last_recorded_death[npc_id] = time_stamp - kill_time
			end
		end
	end
end

-- A function that enables the delayed execution of a function.
function RTM:DelayedExecution(delay, _function)
	local frame = CreateFrame("Frame", "RTM.message_delay_frame", self)
	frame.start_time = GetServerTime()
	frame:SetScript("OnUpdate", 
		function(self)
			if GetServerTime() - self.start_time > delay then
				_function()
				self:SetScript("OnUpdate", nil)
				self:Hide()
			end
		end
	)
	frame:Show()
end

-- ####################################################################
-- ##            Shard Group Management Register Functions           ##
-- ####################################################################

-- Inform other clients of your arrival.
function RTM:RegisterArrival(shard_id)
	-- Attempt to load previous data from our cache.
	if RTMDB.previous_records[shard_id] then
		if GetServerTime() - RTMDB.previous_records[shard_id].time_stamp < 300 then
			print("<RTM> Restoring data from previous session in shard "..(shard_id + 42)..".")
			RTM.last_recorded_death = RTMDB.previous_records[shard_id].time_table
		else
			RTMDB.previous_records[shard_id] = nil
		end
	end

	RTM.channel_name = "RTM"..shard_id
	
	local is_in_channel = false
	if select(1, GetChannelName(RTM.channel_name)) ~= 0 then
		is_in_channel = true
	end

	-- Announce to the others that you have arrived.
	RTM.arrival_register_time = GetServerTime()
	RTM.rare_table_updated = false
		
	if not is_in_channel then
		-- Join the appropriate channel.
		JoinTemporaryChannel(RTM.channel_name)		
		
		-- We want to avoid overwriting existing channel numbers. So delay the channel join.
		RTM:DelayedExecution(1, function()
				print("<RTM> Requesting rare kill data for shard "..(shard_id + 42)..".")
				C_ChatInfo.SendAddonMessage("RTM", "A-"..shard_id.."-"..RTM.version..":"..RTM.arrival_register_time, "CHANNEL", select(1, GetChannelName(RTM.channel_name)))
			end
		)
	else
		C_ChatInfo.SendAddonMessage("RTM", "A-"..shard_id.."-"..RTM.version..":"..RTM.arrival_register_time, "CHANNEL", select(1, GetChannelName(RTM.channel_name)))
	end	
end

-- Inform the others that you are still present.
function RTM:RegisterPresenceWhisper(shard_id, target, time_stamp)
	-- Announce to the others that you are still present on the shard.
	C_ChatInfo.SendAddonMessage("RTM", "PW-"..shard_id.."-"..RTM.version..":"..RTM:GetCompressedSpawnData(time_stamp), "WHISPER", target)
end

--Leave the channel.
function RTM:RegisterDeparture(shard_id)
	local n_channels = GetNumDisplayChannels()
	local channels_to_leave = {}
	
	-- Leave all channels with an RTM prefix.
	for i = 1, n_channels do
		local _, channel_name = GetChannelName(i)
		if channel_name and channel_name:find("RTM") then
			channels_to_leave[channel_name] = true
		end
	end
	
	for channel_name, _ in pairs(channels_to_leave) do
		LeaveChannelByName(channel_name)
	end
	
	-- Store any timer data we previously had in the saved variables.
	if shard_id then
		RTMDB.previous_records[shard_id] = {}
		RTMDB.previous_records[shard_id].time_stamp = GetServerTime()
		RTMDB.previous_records[shard_id].time_table = RTM.last_recorded_death
	end
end

-- ####################################################################
-- ##          Shard Group Management Acknowledge Functions          ##
-- ####################################################################

-- Acknowledge that the player has arrived and whisper your data table.
function RTM:AcknowledgeArrival(player, time_stamp)
	-- Notify the newly arrived user of your presence through a whisper.
	if player_name ~= player then
		RTM:RegisterPresenceWhisper(RTM.current_shard_id, player, time_stamp)
	end	
end

-- Acknowledge the welcome message of other players and parse and import their tables.
function RTM:AcknowledgePresenceWhisper(player, spawn_data)
	RTM:DecompressSpawnData(spawn_data, RTM.arrival_register_time)
end

-- ####################################################################
-- ##               Entity Information Share Functions               ##
-- ####################################################################

-- Inform the others that a specific entity has died.
function RTM:RegisterEntityDeath(shard_id, npc_id, spawn_uid)
	if not RTM.recorded_entity_death_ids[spawn_uid] then
		-- Mark the entity as dead.
		RTM.last_recorded_death[npc_id] = GetServerTime()
		RTM.is_alive[npc_id] = nil
		RTM.current_health[npc_id] = nil
		RTM.current_coordinates[npc_id] = nil
		RTM.recorded_entity_death_ids[spawn_uid] = true
		
		-- We want to avoid overwriting existing channel numbers. So delay the channel join.
		RTM:DelayedExecution(1, function() RTM:UpdateDailyKillMark(npc_id) end)
		
		-- Send the death message.
		C_ChatInfo.SendAddonMessage("RTM", "ED-"..shard_id.."-"..RTM.version..":"..npc_id.."-"..spawn_uid, "CHANNEL", select(1, GetChannelName(RTM.channel_name)))
	end
end

-- Inform the others that you have spotted an alive entity.
function RTM:RegisterEntityAlive(shard_id, npc_id, spawn_uid, x, y)
	if RTM.recorded_entity_death_ids[spawn_uid] == nil then
		-- Mark the entity as alive.
		RTM.is_alive[npc_id] = GetServerTime()
	
		-- Send the alive message.
		if x and y then 
			RTM.current_coordinates[npc_id] = {}
			RTM.current_coordinates[npc_id].x = x
			RTM.current_coordinates[npc_id].y = y
			C_ChatInfo.SendAddonMessage("RTM", "EA-"..shard_id.."-"..RTM.version..":"..npc_id.."-"..spawn_uid.."-"..x.."-"..y, "CHANNEL", select(1, GetChannelName(RTM.channel_name)))
		else
			C_ChatInfo.SendAddonMessage("RTM", "EA-"..shard_id.."-"..RTM.version..":"..npc_id.."-"..spawn_uid.."--", "CHANNEL", select(1, GetChannelName(RTM.channel_name)))
		end
	end
end

-- Inform the others that you have spotted an alive entity.
function RTM:RegisterEntityTarget(shard_id, npc_id, spawn_uid, percentage, x, y)
	if RTM.recorded_entity_death_ids[spawn_uid] == nil then
		-- Mark the entity as targeted and alive.
		RTM.is_alive[npc_id] = GetServerTime()
		RTM.current_health[npc_id] = percentage
		RTM.current_coordinates[npc_id] = {}
		RTM.current_coordinates[npc_id].x = x
		RTM.current_coordinates[npc_id].y = y
		RTM:UpdateStatus(npc_id)
	
		-- Send the target message.
		C_ChatInfo.SendAddonMessage("RTM", "ET-"..shard_id.."-"..RTM.version..":"..npc_id.."-"..spawn_uid.."-"..percentage.."-"..x.."-"..y, "CHANNEL", select(1, GetChannelName(RTM.channel_name)))
	end
end

-- Inform the others the health of a specific entity.
function RTM:RegisterEntityHealth(shard_id, npc_id, spawn_uid, percentage)
	if not RTM.last_health_report[npc_id] or GetServerTime() - RTM.last_health_report[npc_id] > 2 then
		-- Mark the entity as targeted and alive.
		RTM.is_alive[npc_id] = GetServerTime()
		RTM.current_health[npc_id] = percentage
		RTM:UpdateStatus(npc_id)
	
		-- Send the health message, using a rate limited function.
		RTM:SendRateLimitedAddonMessage("EH-"..shard_id.."-"..RTM.version..":"..npc_id.."-"..spawn_uid.."-"..percentage, "CHANNEL", select(1, GetChannelName(RTM.channel_name)))
	end
end

-- Acknowledge that the entity has died and set the according flags.
function RTM:AcknowledgeEntityDeath(npc_id, spawn_uid)	
	if not RTM.recorded_entity_death_ids[spawn_uid] then
		-- Mark the entity as dead.
		RTM.last_recorded_death[npc_id] = GetServerTime()
		RTM.is_alive[npc_id] = nil
		RTM.current_health[npc_id] = nil
		RTM.current_coordinates[npc_id] = nil
		RTM:UpdateDailyKillMark(npc_id)
		RTM.recorded_entity_death_ids[spawn_uid] = true
		RTM:UpdateStatus(npc_id)
	end

	if RTM.waypoints[npc_id] and TomTom then
		TomTom:RemoveWaypoint(RTM.waypoints[npc_id])
		RTM.waypoints[npc_id] = nil
	end
end

-- Acknowledge that the entity is alive and set the according flags.
function RTM:AcknowledgeEntityAlive(npc_id, spawn_uid, x, y)
	if not RTM.recorded_entity_death_ids[spawn_uid] then
		RTM.is_alive[npc_id] = GetServerTime()
		RTM:UpdateStatus(npc_id)
		
		if x and y then
			RTM.current_coordinates[npc_id] = {}
			RTM.current_coordinates[npc_id].x = x
			RTM.current_coordinates[npc_id].y = y
		end
		
		if RTMDB.favorite_rares[npc_id] and not RTM.reported_spawn_uids[spawn_uid] then
			-- Play a sound file.
			PlaySoundFile(RTMDB.selected_sound_number)
			RTM.reported_spawn_uids[spawn_uid] = true
		end
	end
end

-- Acknowledge that the entity is alive and set the according flags.
function RTM:AcknowledgeEntityTarget(npc_id, spawn_uid, percentage, x, y)
	if not RTM.recorded_entity_death_ids[spawn_uid] then
		RTM.last_recorded_death[npc_id] = nil
		RTM.is_alive[npc_id] = GetServerTime()
		RTM.current_health[npc_id] = percentage
		RTM.current_coordinates[npc_id] = {}
		RTM.current_coordinates[npc_id].x = x
		RTM.current_coordinates[npc_id].y = y
		RTM:UpdateStatus(npc_id)
		
		if RTMDB.favorite_rares[npc_id] and not RTM.reported_spawn_uids[spawn_uid] then
			-- Play a sound file.
			PlaySoundFile(RTMDB.selected_sound_number)
			RTM.reported_spawn_uids[spawn_uid] = true
		end
	end
end

-- Acknowledge the health change of the entity and set the according flags.
function RTM:AcknowledgeEntityHealth(npc_id, spawn_uid, percentage)
	if not RTM.recorded_entity_death_ids[spawn_uid] then
		RTM.last_recorded_death[npc_id] = nil
		RTM.is_alive[npc_id] = GetServerTime()
		RTM.current_health[npc_id] = percentage
		RTM.last_health_report[npc_id] = GetServerTime()
		RTM:UpdateStatus(npc_id)
		
		if RTMDB.favorite_rares[npc_id] and not RTM.reported_spawn_uids[spawn_uid] then
			-- Play a sound file.
			PlaySoundFile(RTMDB.selected_sound_number)
			RTM.reported_spawn_uids[spawn_uid] = true
		end
	end
end

-- ####################################################################
-- ##                      Core Chat Management                      ##
-- ####################################################################

-- Determine what to do with the received chat message.
function RTM:OnChatMessageReceived(player, prefix, shard_id, addon_version, payload)
	-- The format of messages might change over time and as such, versioning is needed.
	-- To ensure optimal performance, all users should use the latest version.
	if not reported_version_mismatch and RTM.version < addon_version and addon_version ~= 9001 then
		print("<RTM> Your version or RareTrackerMechagon is outdated. Please update to the most recent version at the earliest convenience.")
		reported_version_mismatch = true
	end
	
	-- Only allow communication if the users are on the same shards and if their addon version is equal.
	if RTM.current_shard_id == shard_id and RTM.version == addon_version then
		if prefix == "A" then
			time_stamp = tonumber(payload)
			RTM:AcknowledgeArrival(player, time_stamp)
		elseif prefix == "PW" then
			RTM:AcknowledgePresenceWhisper(player, payload)
		elseif prefix == "ED" then
			local npcs_id_str, spawn_uid = strsplit("-", payload)
			local npc_id = tonumber(npcs_id_str)
			RTM:AcknowledgeEntityDeath(npc_id, spawn_uid)
		elseif prefix == "EA" then
			local npcs_id_str, spawn_uid, x_str, y_str = strsplit("-", payload)
			local npc_id, x, y = tonumber(npcs_id_str), tonumber(x_str), tonumber(y_str)
			RTM:AcknowledgeEntityAlive(npc_id, spawn_uid, x, y)
		elseif prefix == "ET" then
			local npc_id_str, spawn_uid, percentage_str, x_str, y_str = strsplit("-", payload)
			local npc_id, percentage, x, y = tonumber(npc_id_str), tonumber(percentage_str), tonumber(x_str), tonumber(y_str)
			RTM:AcknowledgeEntityTarget(npc_id, spawn_uid, percentage, x, y)
		elseif prefix == "EH" then
			local npc_id_str, spawn_uid, percentage_str = strsplit("-", payload)
			local npc_id, percentage = tonumber(npc_id_str), tonumber(percentage_str)
			RTM:AcknowledgeEntityHealth(npc_id, spawn_uid, percentage)
		end
	end
end