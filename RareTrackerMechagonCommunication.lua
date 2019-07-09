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

-- The assigned leader of the shard.
RTM.leader = nil

-- Which channel are we registered to?
RTM.channel_id = nil

-- Get the minimal value in the list.
function RTM:findMinArrivalTime()
	local min_player, min_time = nil, nil

	for key, value in ipairs(RTM.registered_players_arrival_time) do 
		if min_time == nil or value < min_time then
			min_player, min_time = key, value
		end
	end
	
	return min_player, min_time
end

-- Find the ID of the RTM channel.
function RTM:findChannelID()
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
	
	RTM.channel_id = self:findChannelID()
end

-- Inform other clients of your arrival.
function RTM:registerArrival(shard_id)
	-- Generate a time stamp for the client's arrival.
	local player, time_stamp = select(1, UnitName("player")), time()
	registered_players[player] = time_stamp
	registered_players_arrival_time[player] = time_stamp
	
	-- Announce to the others that you have arrived.
	C_ChatInfo.SendAddonMessage("RTM", "Test", "CHANNEL", RTM.channel_id)
end

-- Inform the others that you are still present.
function RTM:registerPresence(shard_id)
	
end

-- Inform other clients of your departure.
function RTM:registerDeparture(shard_id)
	
end

function RTM:registerLeadership(shard_id)
	
end

function RTM:acknowledgeArrival(player, time_stamp)
	RTM.registered_players[player] = time_stamp
	RTM.registered_players_arrival_time[player] = time_stamp
end

function RTM:acknowledgePresence(player, time_stamp)
	RTM.registered_players[player] = time_stamp
end

function RTM:acknowledgeDeparture(player)
	RTM.registered_players[player] = nil
	RTM.registered_players_arrival_time[player] = nil
	
	if player == leader then
		-- find a new leader.
		local player, _ = RTM:findMinArrivalTime()
	end
end

function RTM:acknowledgeLeadership(player)
	RTM.leader = player
end