local _, data = ...

local RTM = data.RTM;

-- ####################################################################
-- ##                         Communication                          ##
-- ####################################################################

-- The players that have been registered in the communication pool. 
-- The key is the player name and the value is the time of joining the channel.
RTM.registered_players = {}

-- The time at which you broad-casted the joined the shard group.
RTM.arrival_register_time = nil

-- The name and realm of the player.
local player_name = UnitName("player").."-"..GetRealmName()

-- ####################################################################
-- ##                        Helper Functions                        ##
-- ####################################################################

function RTM:PrintRegisteredPlayers()
	local count = 0
	for key, value in pairs(RTM.registered_players) do 
		print(key, value)
		count = count + 1
	end
	print("We have", count, "registered players.")
end

-- Get the minimal value in the list.
function RTM:FindMinArrivalTime()
	print(#RTM.registered_players)
	local min_player, min_time = nil, nil

	for key, value in ipairs(RTM.registered_players) do 
		if min_time == nil or value < min_time then
			min_player, min_time = key, value
		end
	end
	
	return min_player, min_time
end

-- Find the ID of the RTM channel.
function RTM:FindChannelID()
	local n_channels = GetNumDisplayChannels()
	
	for i=1, n_channels do
		SetSelectedDisplayChannel(i)
		local name = select(1, GetChannelDisplayInfo(i))
		if name == "RTM" then
			return i
		end
	end
	
	return -1
end

-- Register to the channel.
function RTM:RegisterToRTMChannel()
	JoinTemporaryChannel("RTM")
	
	if C_ChatInfo.RegisterAddonMessagePrefix("RTM") ~= true then
		print("RTM: Couldn't register AddonPrefix")
	end
end

RTM.last_message_sent = 0
-- A function that acts as a rate limiter for channel messages.
function RTM:SendRateLimitedAddonMessage(message, target, target_id)
	-- We only allow one message to be sent every ~4 seconds.
	if RTM.last_message_sent + 2 < time() then
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
	-- Reset your communication lists.
	RTM.registered_players = {}

	-- Announce to the others that you have arrived.
	RTM.arrival_register_time = time()
	C_ChatInfo.SendAddonMessage("RTM", "A-"..shard_id..":"..RTM.arrival_register_time, "CHANNEL", select(1, GetChannelName("RTM")))
end

-- Inform the others that you are still present.
function RTM:RegisterPresenceWhisper(shard_id, target, time_stamp)
	-- Announce to the others that you are still present on the shard.
	local arrival = RTM.registered_players[player_name]
	C_ChatInfo.SendAddonMessage("RTM", "PW-"..shard_id..":"..arrival.."-"..RTM:GetCompressedSpawnData(time_stamp), "WHISPER", target)
end

-- Inform other clients of your departure.
function RTM:RegisterDeparture(shard_id)
	-- Announce to the others that you have departed the shard.
	C_ChatInfo.SendAddonMessage("RTM", "D-"..shard_id, "CHANNEL", select(1, GetChannelName("RTM")))
	
	-- Reset your communication lists.
	RTM.registered_players = {}
	RTM.arrival_register_time = nil
end

-- ####################################################################
-- ##          Shard Group Management Acknowledge Functions          ##
-- ####################################################################

function RTM:AcknowledgeArrival(player, time_stamp)
	RTM.registered_players[player] = time_stamp
	
	-- Notify the newly arrived user of your presence through a whisper.
	if player_name ~= player then
		RTM:RegisterPresenceWhisper(RTM.current_shard_id, player, time_stamp)
	end	
	
	RTM:PrintRegisteredPlayers()
end

function RTM:AcknowledgePresenceWhisper(player, arrival, spawn_data)
	RTM.registered_players[player] = arrival
	
	RTM:DecompressSpawnData(spawn_data, RTM.arrival_register_time)
	
	RTM:PrintRegisteredPlayers()
end

function RTM:AcknowledgeDeparture(player)
	RTM.registered_players[player] = nil
	
	RTM:PrintRegisteredPlayers()
end



-- ####################################################################
-- ##               Entity Information Share Functions               ##
-- ####################################################################

-- Inform the others that a specific entity has died.
function RTM:RegisterEntityDeath(shard_id, npc_id)
	C_ChatInfo.SendAddonMessage("RTM", "ED-"..shard_id..":"..npc_id, "CHANNEL", select(1, GetChannelName("RTM")))
end

-- Inform the others that you have spotted an alive entity.
function RTM:RegisterEntityAlive(shard_id, npc_id, spawn_id)
	C_ChatInfo.SendAddonMessage("RTM", "EA-"..shard_id..":"..npc_id.."-"..spawn_id, "CHANNEL", select(1, GetChannelName("RTM")))
end

-- Inform the others the health of a specific entity.
function RTM:RegisterEntityHealth(shard_id, npc_id, spawn_id, percentage)
	RTM:SendRateLimitedAddonMessage("EH-"..shard_id..":"..npc_id.."-"..spawn_id.."-"..percentage, "CHANNEL", select(1, GetChannelName("RTM")))
end


function RTM:AcknowledgeEntityDeath(npc_id)
	RTM.last_recorded_death[npc_id] = time()
	RTM.is_alive[npc_id] = false
	RTM.current_health[npc_id] = nil
end

function RTM:AcknowledgeEntityAlive(npc_id, spawn_id)
	RTM.is_alive[npc_id] = true
	
	if RTMDB.favorite_rares[npc_id] and not RTM.reported_spawn_uids[spawn_id] then
		-- Play a sound file.
		PlaySoundFile(543587)
		print("Playing sound file")
		RTM.reported_spawn_uids[spawn_id] = true
	end
end

function RTM:AcknowledgeEntityHealth(npc_id, spawn_id, percentage)
	RTM.last_recorded_death[npc_id] = nil
	RTM.is_alive[npc_id] = true
	RTM.current_health[npc_id] = percentage
	
	if RTMDB.favorite_rares[npc_id] and not RTM.reported_spawn_uids[spawn_id] then
		-- Play a sound file.
		PlaySoundFile(543587)
		print("Playing sound file")
		RTM.reported_spawn_uids[spawn_id] = true
	end
end



function RTM:OnChatMessageReceived(player, prefix, shard_id, payload)
	print(player, prefix, shard_id, payload)
	
	if RTM.current_shard_id == shard_id then
		if prefix == "A" then
			time_stamp = tonumber(payload)
			RTM:AcknowledgeArrival(player, time_stamp)
		elseif prefix == "PW" then
			local arrival_str, spawn_data = strsplit("-", payload)
			local arrival = tonumber(arrival_str)
			RTM:AcknowledgePresenceWhisper(player, arrival, spawn_data)
		elseif prefix == "D" then
			RTM:AcknowledgeDeparture(player)
		elseif prefix == "ED" then
			local npc_id = tonumber(payload)
			RTM:AcknowledgeEntityDeath(npc_id)
		elseif prefix == "EA" then
			local npcs_id_str, spawn_id = strsplit("-", payload)
			local npc_id = tonumber(npcs_id_str)
			RTM:AcknowledgeEntityAlive(npc_id, spawn_id)
		elseif prefix == "EH" then
			local npc_id_str, spawn_id, percentage_str = strsplit("-", payload)
			local npc_id, percentage = tonumber(npc_id_str), tonumber(percentage_str)
			RTM:AcknowledgeEntityHealth(npc_id, spawn_id, percentage)
		end
	end
end