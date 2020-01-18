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
local L = LibStub("AceLocale-3.0"):GetLocale("RareTrackerVale", true)

-- ####################################################################
-- ##                              Core                              ##
-- ####################################################################

local RTV = CreateFrame("Frame", "RTV", UIParent);

-- The current data we have of the rares.
RTV.is_alive = {}
RTV.current_health = {}
RTV.last_recorded_death = {}
RTV.current_coordinates = {}

-- The zone_uid can be used to distinguish different shards of the zone.
RTV.current_shard_id = nil

-- A table containing all UID deaths reported by the player.
RTV.recorded_entity_death_ids = {}

-- A table containing all vignette UIDs reported by the player.
RTV.reported_vignettes = {}

-- A table containing all spawn UIDs that have been reported through a sound warning.
RTV.reported_spawn_uids = {}

-- The version of the addon.
RTV.version = 7
-- Version 2: changed the order of the rares.
-- Version 3: death messages now send the spawn id.
-- Version 4: changed the interface of the alive message to include coordinates.
-- Version 5: added a future version of Mechtarantula.
-- Version 6: the time stamp that was used to generate the compressed table is now included in group messages.
-- Version 7: added additional rares to the list.

-- The last zone the user was in.
RTV.last_zone_id = nil

-- Check whether the addon has loaded.
RTV.is_loaded = false

-- Check which assault is currently active.
RTV.assault_id = 0


-- ####################################################################
-- ##                         Saved Variables                        ##
-- ####################################################################

-- Setting saved in the saved variables.
RTVDB = {}

-- The rares marked as RTVDB.favorite_rares by the player.
RTVDB.favorite_rares = {}

-- Remember whether the user wants to see the window or not.
RTVDB.show_window = nil

-- Keep a cache of previous data, that we can restore if appropriate.
RTVDB.previous_records = {}

-- ####################################################################
-- ##                        Helper functions                        ##
-- ####################################################################

-- Get the current health of the entity, rounded down to an integer.
function RTV.GetTargetHealthPercentage()
	-- Find the current and maximum health of the current target.
	local max_hp = UnitHealthMax("target")
	
	-- Check for division by zero.
	if max_hp == 0 then
		return -1
	end
	
	return math.floor((100 * UnitHealth("target")) / UnitHealthMax("target"))
end

-- A print function used for debug purposes.
function RTV.Debug(...)
	if RTVDB.debug_enabled then
		print(...)
	end
end

-- Open and start the RTV interface and subscribe to all the required events.
function RTV:StartInterface()
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
	
	if RTVDB.minimap_icon_enabled then
		self.icon:Show("RTV_icon")
	else
		self.icon:Hide("RTV_icon")
	end
	
	if C_ChatInfo.RegisterAddonMessagePrefix("RTV") ~= true then
		print(L["<RTV> Failed to register AddonPrefix 'RTV'. RTV will not function properly."])
	end
	
	if RTVDB.show_window then
		self:Show()
	end
end

-- Open and start the RTV interface and unsubscribe to all the required events.
function RTV:CloseInterface()
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
	self.icon:Hide("RTV_icon")
	
	-- Hide the interface.
	self:Hide()
end

-- ####################################################################
-- ##                          Minimap Icon                          ##
-- ####################################################################

local RTV_LDB = LibStub("LibDataBroker-1.1"):NewDataObject("RTV_icon_object", {
	type = "data source",
	text = "RTV",
	icon = "Interface\\AddOns\\RareTrackerVale\\Icons\\RareTrackerIcon",
	OnClick = function(_, button)
		if button == "LeftButton" then
			if RTV.last_zone_id and RTV.target_zones[RTV.last_zone_id] then
				if RTV:IsShown() then
					RTV:Hide()
					RTVDB.show_window = false
				else
					RTV:Show()
					RTVDB.show_window = true
				end
			end
		else
			InterfaceOptionsFrame_Show()
			InterfaceOptionsFrame_OpenToCategory(RTV.options_panel)
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:SetText("RTV")
		tooltip:AddLine(L["Left-click: hide/show RTV"], 1, 1, 1)
		tooltip:AddLine(L["Right-click: show options"], 1, 1, 1)
		tooltip:Show()
	end
})

RTV.icon = LibStub("LibDBIcon-1.0")
RTV.icon:Hide("RTV_icon")

function RTV:RegisterMapIcon()
	self.ace_db = LibStub("AceDB-3.0"):New("RTV_ace_db", {
		profile = {
			minimap = {
				hide = false,
			},
		},
	})
	RTV.icon:Register("RTV_icon", RTV_LDB, self.ace_db.profile.minimap)
end


