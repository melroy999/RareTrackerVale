-- Redefine often used functions locally.
local CreateFrame = CreateFrame
local InterfaceOptionsFrame_Show = InterfaceOptionsFrame_Show
local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
local LibStub = LibStub
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax

-- Redefine global variables locally.
local UIParent = UIParent
local C_ChatInfo = C_ChatInfo

-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTrackerUldum", true)

-- ####################################################################
-- ##                              Core                              ##
-- ####################################################################

local RTU = CreateFrame("Frame", "RTU", UIParent);

-- The current data we have of the rares.
RTU.is_alive = {}
RTU.current_health = {}
RTU.last_recorded_death = {}
RTU.current_coordinates = {}

-- The zone_uid can be used to distinguish different shards of the zone.
RTU.current_shard_id = nil

-- A table containing all UID deaths reported by the player.
RTU.recorded_entity_death_ids = {}

-- A table containing all vignette UIDs reported by the player.
RTU.reported_vignettes = {}

-- A table containing all spawn UIDs that have been reported through a sound warning.
RTU.reported_spawn_uids = {}

-- The version of the addon.
RTU.version = 6
-- Version 2: changed the order of the rares.
-- Version 3: death messages now send the spawn id.
-- Version 4: changed the interface of the alive message to include coordinates.
-- Version 5: added a future version of Mechtarantula.
-- Version 6: the time stamp that was used to generate the compressed table is now included in group messages.

-- The last zone the user was in.
RTU.last_zone_id = nil

-- Check whether the addon has loaded.
RTU.is_loaded = false

-- ####################################################################
-- ##                         Saved Variables                        ##
-- ####################################################################

-- Setting saved in the saved variables.
RTUDB = {}

-- The rares marked as RTUDB.favorite_rares by the player.
RTUDB.favorite_rares = {}

-- Remember whether the user wants to see the window or not.
RTUDB.show_window = nil

-- Keep a cache of previous data, that we can restore if appropriate.
RTUDB.previous_records = {}

-- ####################################################################
-- ##                        Helper functions                        ##
-- ####################################################################

-- Get the current health of the entity, rounded down to an integer.
function RTU.GetTargetHealthPercentage()
	-- Find the current and maximum health of the current target.
	local max_hp = UnitHealthMax("target")
	
	-- Check for division by zero.
	if max_hp == 0 then
		return -1
	end
	
	return math.floor((100 * UnitHealth("target")) / UnitHealthMax("target"))
end

-- A print function used for debug purposes.
function RTU.Debug(...)
	if RTUDB.debug_enabled then
		print(...)
	end
end

-- Open and start the RTU interface and subscribe to all the required events.
function RTU:StartInterface()
	-- Reset the data, since we cannot guarantee its correctness.
	self.is_alive = {}
	self.current_health = {}
	self.last_recorded_death = {}
	self.current_coordinates = {}
	self.reported_spawn_uids = {}
	self.reported_vignettes = {}
	self.waypoints = {}
	self.current_shard_id = nil
	self:UpdateShardNumber(nil)
	self:UpdateAllDailyKillMarks()
	
	self:RegisterEvents()
	
	if RTUDB.minimap_icon_enabled then
		self.icon:Show("RTU_icon")
	else
		self.icon:Hide("RTU_icon")
	end
	
	if C_ChatInfo.RegisterAddonMessagePrefix("RTU") ~= true then
		print(L["<RTU> Failed to register AddonPrefix 'RTU'. RTU will not function properly."])
	end
	
	if RTUDB.show_window then
		self:Show()
	end
end

-- Open and start the RTU interface and unsubscribe to all the required events.
function RTU:CloseInterface()
	-- Reset the data.
	self.is_alive = {}
	self.current_health = {}
	self.last_recorded_death = {}
	self.current_coordinates = {}
	self.reported_spawn_uids = {}
	self.reported_vignettes = {}
	self.current_shard_id = nil
	self:UpdateShardNumber(nil)
	
	-- Register the user's departure and disable event listeners.
	self:RegisterDeparture(self.current_shard_id)
	self:UnregisterEvents()
	self.icon:Hide("RTU_icon")
	
	-- Hide the interface.
	self:Hide()
end

-- ####################################################################
-- ##                          Minimap Icon                          ##
-- ####################################################################

local RTU_LDB = LibStub("LibDataBroker-1.1"):NewDataObject("RTU_icon_object", {
	type = "data source",
	text = "RTU",
	icon = "Interface\\AddOns\\RareTrackerUldum\\Icons\\RareTrackerIcon",
	OnClick = function(_, button)
		if button == "LeftButton" then
			if RTU.last_zone_id and RTU.target_zones[RTU.last_zone_id] then
				if RTU:IsShown() then
					RTU:Hide()
					RTUDB.show_window = false
				else
					RTU:Show()
					RTUDB.show_window = true
				end
			end
		else
			InterfaceOptionsFrame_Show()
			InterfaceOptionsFrame_OpenToCategory(RTU.options_panel)
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:SetText("RTU")
		tooltip:AddLine(L["Left-click: hide/show RTU"], 1, 1, 1)
		tooltip:AddLine(L["Right-click: show options"], 1, 1, 1)
		tooltip:Show()
	end
})

RTU.icon = LibStub("LibDBIcon-1.0")
RTU.icon:Hide("RTU_icon")

function RTU:RegisterMapIcon()
	self.ace_db = LibStub("AceDB-3.0"):New("RTU_ace_db", {
		profile = {
			minimap = {
				hide = false,
			},
		},
	})
	RTU.icon:Register("RTU_icon", RTU_LDB, self.ace_db.profile.minimap)
end


