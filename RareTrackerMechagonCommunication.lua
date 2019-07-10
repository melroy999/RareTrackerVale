local _, data = ...

local RTM = data.RTM;

-- ####################################################################
-- ##                         Communication                          ##
-- ####################################################################

-- The players that have been registered in the communication pool. 
-- The key is the player name and the value is the time of last presence declaration.
RTM.registered_players = {}

-- The time stamp of the last presence declaration.
RTM.registered_players_arrival_time = {}

-- The name and realm of the player.
local player_name = UnitName("player").."-"..GetRealmName()

function RTM:PrintRegisteredPlayers()
	local count = 0
	for key, value in pairs(self.registered_players) do 
		print(key, value)
		count = count + 1
	end
	print("We have", count, "registered players.")
end

function RTM:PrintRegisteredPlayersArrivalTimes()
	for key, value in pairs(self.registered_players_arrival_time) do 
		print(key, value)
	end
end

-- Get the minimal value in the list.
function RTM:FindMinArrivalTime()
	print(#self.registered_players_arrival_time)
	local min_player, min_time = nil, nil

	for key, value in ipairs(self.registered_players_arrival_time) do 
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

-- ####################################################################
-- ##            Shard Group Management Register Functions           ##
-- ####################################################################

RTM.last_message_sent = 0
-- A function that acts as a rate limiter for channel messages.
function RTM:SendRateLimitedAddonMessage(message, target, target_id)
	-- We only allow one message to be sent every ~4 seconds.
	if RTM.last_message_sent + 2 < time() then
		C_ChatInfo.SendAddonMessage("RTM", message, target, target_id)
		RTM.last_message_sent = time()
	end
end

-- ####################################################################
-- ##            Shard Group Management Register Functions           ##
-- ####################################################################

-- Inform other clients of your arrival.
function RTM:RegisterArrival(shard_id)
	-- Reset your communication lists.
	RTM.registered_players = {}
	RTM.registered_players_arrival_time = {}

	-- Announce to the others that you have arrived.
	C_ChatInfo.SendAddonMessage("RTM", "A-"..shard_id..":"..time(), "CHANNEL", select(1, GetChannelName("RTM")))
end

-- Inform the others that you are still present.
function RTM:RegisterPresence(shard_id)
	-- Announce to the others that you are still present on the shard.
	C_ChatInfo.SendAddonMessage("RTM", "P-"..shard_id..":"..time(), "CHANNEL", select(1, GetChannelName("RTM")))
end

-- Inform the others that you are still present.
function RTM:RegisterPresenceWhisper(shard_id, target)
	-- Announce to the others that you are still present on the shard.
	local last_update, arrival = self.registered_players[player_name], self.registered_players_arrival_time[player_name]
	C_ChatInfo.SendAddonMessage("RTM", "PW-"..shard_id..":"..last_update.."-"..arrival, "WHISPER", target)
end

-- Inform other clients of your departure.
function RTM:RegisterDeparture(shard_id)
	-- Announce to the others that you have departed the shard.
	C_ChatInfo.SendAddonMessage("RTM", "D-"..shard_id, "CHANNEL", select(1, GetChannelName("RTM")))
	
	-- Reset your communication lists.
	RTM.registered_players = {}
	RTM.registered_players_arrival_time = {}
end

-- Inform the others that you are still present.
function RTM:RegisterEntityDeath(shard_id, npc_id)
	-- Announce to the others that you are still present on the shard.
	C_ChatInfo.SendAddonMessage("RTM", "ED-"..shard_id..":"..npc_id, "CHANNEL", select(1, GetChannelName("RTM")))
end

-- Inform the others that you are still present.
function RTM:RegisterEntityHealth(shard_id, npc_id, percentage)
	-- Announce to the others that you are still present on the shard.
	self:SendRateLimitedAddonMessage("EH-"..shard_id..":"..npc_id.."-"..percentage, "CHANNEL", select(1, GetChannelName("RTM")))
end

-- ####################################################################
-- ##          Shard Group Management Acknowledge Functions          ##
-- ####################################################################

function RTM:AcknowledgeArrival(player, time_stamp)
	self.registered_players[player] = time_stamp
	self.registered_players_arrival_time[player] = time_stamp
	
	-- Notify the newly arrived user of your presence through a whisper.
	if player_name ~= player then
		self:RegisterPresenceWhisper(self.current_shard_id, player)
	end	
	
	self:PrintRegisteredPlayers()
end

function RTM:AcknowledgePresence(player, time_stamp)
	self.registered_players[player] = time_stamp
	
	self:PrintRegisteredPlayers()
end

function RTM:AcknowledgePresenceWhisper(player, last_update, arrival)
	self.registered_players[player] = last_update
	self.registered_players_arrival_time[player] = arrival
	
	self:PrintRegisteredPlayers()
end

function RTM:AcknowledgeDeparture(player)
	self.registered_players[player] = nil
	self.registered_players_arrival_time[player] = nil
	
	self:PrintRegisteredPlayers()
end

function RTM:AcknowledgeEntityDeath(player, npc_id)
	self.is_alive[npc_id] = false
	self.current_health[npc_id] = nil
	self.last_recorded_death[npc_id] = time()
end

function RTM:AcknowledgeEntityHealth(player, npc_id, percentage)
	self.is_alive[npc_id] = true
	self.current_health[npc_id] = percentage
	self.last_recorded_death[npc_id] = nil
end





function RTM:OnChatMessageReceived(player, prefix, shard_id, payload)
	--print(player, prefix, shard_id, payload)
	
	if self.current_shard_id == shard_id then
		if prefix == "A" then
			time_stamp = tonumber(payload)
			self:AcknowledgeArrival(player, time_stamp)
		elseif prefix == "P" then
			time_stamp = tonumber(payload)
			self:AcknowledgePresence(player, time_stamp)
		elseif prefix == "PW" then
			local last_update_str, arrival_str = strsplit("-", payload)
			local last_update, arrival = tonumber(last_update_str), tonumber(arrival_str)
			self:AcknowledgePresence(player, last_update, arrival)
		elseif prefix == "D" then
			self:AcknowledgeDeparture(player)
		elseif prefix == "ED" then
			self:AcknowledgeEntityDeath(player, payload)
		elseif prefix == "EH" then
			local npc_id_str, percentage_str = strsplit("-", payload)
			local npc_id, percentage = tonumber(npc_id_str), tonumber(percentage_str)
			self:AcknowledgeEntityHealth(player, npc_id, percentage)
		end
	end
end