-- ####################################################################
-- ##                              Core                              ##
-- ####################################################################

local RareCouncil = CreateFrame("Frame");

-- ####################################################################
-- ##                        Helper functions                        ##
-- ####################################################################

-- Simulate a set data structure for efficient existence lookups.
function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

function RareCouncil:GetTargetHealthPercentage()
	-- Find the current and maximum health of the current target.
	local current_hp = UnitHealth("target")
	local max_hp = UnitHealthMax("target")
	
	-- Check for division by zero.
	if max_hp == 0 then
		return -1
	end
	
	return math.floor(current_hp/max_hp * 100) 
end

-- ####################################################################
-- ##                          Static Data                           ##
-- ####################################################################

-- The ids of the rares the addon monitors.
local rare_ids = Set {
	153293,
	153294,
	153269
}

-- ####################################################################
-- ##                         Tracking Data                          ##
-- ####################################################################

is_alive = {}
current_health = {}
last_recorded_death = {}

-- ####################################################################
-- ##                        Event Listeners                         ##
-- ####################################################################

-- Listen to a given set of events and handle them accordingly.
function RareCouncil:OnEvent(event, ...)
	if event == "PLAYER_TARGET_CHANGED" then
		self:OnTargetChanged(...)
	elseif event == "UNIT_HEALTH" then
		self:OnUnitHealth(...)
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		self:OnCombatLogEvent(...)
	end
end

function RareCouncil:OnTargetChanged(...)
	if UnitGUID("target") ~= nil then
		-- Get information about the target.
		local guid, name = UnitGUID("target"), UnitName("target")
		local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", guid);
		npc_id = tonumber(npc_id)
		
		if rare_ids[npc_id] then
			-- Find the health of the entity.
			local health = UnitHealth("target")
			
			if health > 0 then
				is_alive[npc_id] = true
				current_health[npc_id] = self:GetTargetHealthPercentage()
				--print(guid, name, "alive", current_health[npc_id].."%")
			else 
				is_alive[npc_id] = false
				current_health[npc_id] = nil
				--print(guid, name, "dead", current_health[npc_id])
			end
		end
	end
end

function RareCouncil:OnUnitHealth(unit)
	-- If the unit is not the target, skip.
	if unit ~= "target" then 
		return 
	end
	
	if UnitGUID("target") ~= nil then
		-- Get information about the target.
		local guid, name = UnitGUID("target"), UnitName("target")
		local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", guid);
		npc_id = tonumber(npc_id)
		
		if rare_ids[npc_id] then
			-- Update the current health of the entity.
			current_health[npc_id] = self:GetTargetHealthPercentage()
			--print(current_health[npc_id])
		end
	end
end

function RareCouncil:OnCombatLogEvent(...)
	-- The event itself does not have a payload (8.0 change). Use CombatLogGetCurrentEventInfo() instead.
	local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
	local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", destGUID);
	npc_id = tonumber(npc_id)
		
	if subevent == "UNIT_DIED" then
		if rare_ids[npc_id] then
			last_recorded_death[npc_id] = timestamp
			is_alive[npc_id] = false
			current_health[npc_id] = nil
			
			print(is_alive[npc_id], current_health[npc_id], last_recorded_death[npc_id])
		end
	end
end	

-- Register the event handling of the frame.
RareCouncil:SetScript("OnEvent", RareCouncil.OnEvent)
RareCouncil:RegisterEvent("PLAYER_TARGET_CHANGED")
RareCouncil:RegisterEvent("UNIT_HEALTH")
RareCouncil:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")