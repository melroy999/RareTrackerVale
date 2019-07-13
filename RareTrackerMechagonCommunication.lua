local _, data = ...

local RTM = data.RTM;

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

-- A flag that ensures that the rare table is only updated once upon query.
local rare_table_updated = false

-- ####################################################################
-- ##                        Helper Functions                        ##
-- ####################################################################

RTM.last_message_sent = 0
-- A function that acts as a rate limiter for channel messages.
function RTM:SendRateLimitedAddonMessage(message, target, target_id)
	-- We only allow one message to be sent every ~4 seconds.
	if RTM.last_message_sent + 4 < time() then
		C_ChatInfo.SendAddonMessage("RTM", message, target, target_id)
		RTM.last_message_sent = time()
	end
end

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

function RTM:DecompressSpawnData(spawn_data, time_stamp)

	local spawn_data_entries = {strsplit(",", spawn_data, #RTM.rare_ids)}

	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		local kill_time = RTM:toBase10(spawn_data_entries[i])
		
		if kill_time ~= 0 then
			RTM.last_recorded_death[npc_id] = time_stamp - kill_time
		end
	end
end

-- ####################################################################
-- ##            Shard Group Management Register Functions           ##
-- ####################################################################

-- Inform other clients of your arrival.
function RTM:RegisterArrival(shard_id)
	RTM.channel_name = "RTM"..shard_id

	-- Join the appropriate channel.
	JoinTemporaryChannel(RTM.channel_name)

	-- Announce to the others that you have arrived.
	RTM.arrival_register_time = time()
	RTM.rare_table_updated = false
	
	C_ChatInfo.SendAddonMessage("RTM", "A-"..shard_id.."-"..RTM.version..":"..RTM.arrival_register_time, "CHANNEL", select(1, GetChannelName(RTM.channel_name)))
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
end

-- ####################################################################
-- ##          Shard Group Management Acknowledge Functions          ##
-- ####################################################################

function RTM:AcknowledgeArrival(player, time_stamp)
	-- Notify the newly arrived user of your presence through a whisper.
	if player_name ~= player then
		RTM:RegisterPresenceWhisper(RTM.current_shard_id, player, time_stamp)
	end	
end

function RTM:AcknowledgePresenceWhisper(player, spawn_data)
	if not RTM.rare_table_updated then
		RTM:DecompressSpawnData(spawn_data, RTM.arrival_register_time)
		RTM.rare_table_updated = true
	end
end

-- ####################################################################
-- ##               Entity Information Share Functions               ##
-- ####################################################################

-- Inform the others that a specific entity has died.
function RTM:RegisterEntityDeath(shard_id, npc_id)
	C_ChatInfo.SendAddonMessage("RTM", "ED-"..shard_id.."-"..RTM.version..":"..npc_id, "CHANNEL", select(1, GetChannelName(RTM.channel_name)))
end

-- Inform the others that you have spotted an alive entity.
function RTM:RegisterEntityAlive(shard_id, npc_id, spawn_id)
	C_ChatInfo.SendAddonMessage("RTM", "EA-"..shard_id.."-"..RTM.version..":"..npc_id.."-"..spawn_id, "CHANNEL", select(1, GetChannelName(RTM.channel_name)))
end

-- Inform the others that you have spotted an alive entity.
function RTM:RegisterEntityTarget(shard_id, npc_id, spawn_id, percentage, x, y)
	C_ChatInfo.SendAddonMessage("RTM", "ET-"..shard_id.."-"..RTM.version..":"..npc_id.."-"..spawn_id.."-"..percentage.."-"..x.."-"..y, "CHANNEL", select(1, GetChannelName(RTM.channel_name)))
end

-- Inform the others the health of a specific entity.
function RTM:RegisterEntityHealth(shard_id, npc_id, spawn_id, percentage)
	RTM:SendRateLimitedAddonMessage("EH-"..shard_id.."-"..RTM.version..":"..npc_id.."-"..spawn_id.."-"..percentage, "CHANNEL", select(1, GetChannelName(RTM.channel_name)))
end


function RTM:AcknowledgeEntityDeath(npc_id)
	RTM.last_recorded_death[npc_id] = time()
	RTM.is_alive[npc_id] = nil
	RTM.current_health[npc_id] = nil
	RTM.current_coordinates[npc_id] = nil
	RTM:UpdateDailyKillMark(npc_id)
	
	if RTM.waypoints[npc_id] and TomTom then
		TomTom:RemoveWaypoint(RTM.waypoints[npc_id])
		RTM.waypoints[npc_id] = nil
	end
end

function RTM:AcknowledgeEntityAlive(npc_id, spawn_id)
	RTM.is_alive[npc_id] = time()
	
	if RTMDB.favorite_rares[npc_id] and not RTM.reported_spawn_uids[spawn_id] then
		-- Play a sound file.
		PlaySoundFile(543587)
		RTM.reported_spawn_uids[spawn_id] = true
	end
end

function RTM:AcknowledgeEntityTarget(npc_id, spawn_id, percentage, x, y)
	RTM.last_recorded_death[npc_id] = nil
	RTM.is_alive[npc_id] = time()
	RTM.current_health[npc_id] = percentage
	RTM.current_coordinates[npc_id] = {}
	RTM.current_coordinates[npc_id].x = x
	RTM.current_coordinates[npc_id].y = y
	
	if RTMDB.favorite_rares[npc_id] and not RTM.reported_spawn_uids[spawn_id] then
		-- Play a sound file.
		PlaySoundFile(543587)
		RTM.reported_spawn_uids[spawn_id] = true
	end
end

function RTM:AcknowledgeEntityHealth(npc_id, spawn_id, percentage)
	RTM.last_recorded_death[npc_id] = nil
	RTM.is_alive[npc_id] = time()
	RTM.current_health[npc_id] = percentage
	
	if RTMDB.favorite_rares[npc_id] and not RTM.reported_spawn_uids[spawn_id] then
		-- Play a sound file.
		PlaySoundFile(543587)
		RTM.reported_spawn_uids[spawn_id] = true
	end
end

function RTM:OnChatMessageReceived(player, prefix, shard_id, addon_version, payload)

	if not reported_version_mismatch and RTM.version < addon_version and addon_version ~= 9001 then
		print("[RTM] Your version or RareTrackerMechagon is outdated. Please update to the most recent version at the earliest convenience.")
		reported_version_mismatch = true
	end
	
	if RTM.current_shard_id == shard_id and RTM.version == addon_version then
		if prefix == "A" then
			time_stamp = tonumber(payload)
			RTM:AcknowledgeArrival(player, time_stamp)
		elseif prefix == "PW" then
			RTM:AcknowledgePresenceWhisper(player, payload)
		elseif prefix == "ED" then
			local npc_id = tonumber(payload)
			RTM:AcknowledgeEntityDeath(npc_id)
		elseif prefix == "EA" then
			local npcs_id_str, spawn_id = strsplit("-", payload)
			local npc_id = tonumber(npcs_id_str)
			RTM:AcknowledgeEntityAlive(npc_id, spawn_id)
		elseif prefix == "ET" then
			local npc_id_str, spawn_id, percentage_str, x_str, y_str = strsplit("-", payload)
			local npc_id, percentage, x, y = tonumber(npc_id_str), tonumber(percentage_str), tonumber(x_str), tonumber(y_str)
			RTM:AcknowledgeEntityTarget(npc_id, spawn_id, percentage, x, y)
		elseif prefix == "EH" then
			local npc_id_str, spawn_id, percentage_str = strsplit("-", payload)
			local npc_id, percentage = tonumber(npc_id_str), tonumber(percentage_str)
			RTM:AcknowledgeEntityHealth(npc_id, spawn_id, percentage)
		end
	end
end