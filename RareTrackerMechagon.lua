local _, data = ...

-- ####################################################################
-- ##                              Core                              ##
-- ####################################################################

data.RTM = CreateFrame("Frame", "RTM", UIParent);
local RTM = data.RTM;

RTM.is_alive = {}
RTM.current_health = {}
RTM.last_recorded_death = {}

-- The zone_uid can be used to distinguish different shards of the zone.
RTM.current_shard_id = nil

-- An override to hide the interface initially (development).
RTM.hide_override = true

-- ####################################################################
-- ##                        Helper functions                        ##
-- ####################################################################

function RTM:GetTargetHealthPercentage()
	-- Find the current and maximum health of the current target.
	local current_hp = UnitHealth("target")
	local max_hp = UnitHealthMax("target")
	
	-- Check for division by zero.
	if max_hp == 0 then
		return -1
	end
	
	return math.floor((100 * current_hp) / max_hp) 
end

function RTM:StartInterface()
	-- reset the data, since we cannot guarantee its correctness.
	RTM.is_alive = {}
	RTM.current_health = {}
	RTM.last_recorded_death = {}
	RTM.current_shard_id = nil
	
	print("enabling RTM")
	
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	JoinChannelByName("RTM")
	
	if C_ChatInfo.RegisterAddonMessagePrefix("RTM") ~= true then
		print("RTM: Couldn't register AddonPrefix")
	end
	
	self:Show()
	
	if RTM.hide_override then self:Hide() end
end

function RTM:CloseInterface()
	print("disabling RTM")
	
	LeaveChannelByName("RTM")
	
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("UNIT_HEALTH")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	self:Hide()
end





