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

-- A table containing all UID deaths reported by the player.
RTM.recorded_entity_death_ids = {}

-- A table containing all vignette UIDs reported by the player.
RTM.reported_vignettes = {}

-- A table containing all spawn UIDs that have been reported through a sound warning.
RTM.reported_spawn_uids = {}

-- Sound file options.
local sound_options = {}
sound_options['none'] = -1
sound_options['Algalon: Beware!'] = 543587



-- Setting saved in the saved variables.
RTMDB = {}

-- The rares marked as RTMDB.favorite_rares by the player.
RTMDB.favorite_rares = {}


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
	
	RTM:RegisterEvents()
	RTM:RegisterToRTMChannel()
	
	RTM:Show()
	
	if RTM.hide_override then RTM:Hide() end
end

function RTM:CloseInterface()
	LeaveChannelByName("RTM")
	
	RTM:UnregisterEvents()
	
	RTM:Hide()
end





