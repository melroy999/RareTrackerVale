-- ####################################################################
-- ##                              Core                              ##
-- ####################################################################

local RareCouncil = CreateFrame("Frame", "RareCouncil", UIParent);
--local RareCouncil = CreateFrame("Frame", "RareCouncil", UIParent, "BasicFrameTemplateWithInset");

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
	
	return math.floor((100 * current_hp) / max_hp) 
end

-- ####################################################################
-- ##                          Static Data                           ##
-- ####################################################################

-- The ids of the rares the addon monitors.
local rare_ids = {
	153293,
	153294,
	153269
}

local rare_ids_set = Set(rare_ids)

local rare_names_localized = {}
rare_names_localized["enUS"] = {}
rare_names_localized["enUS"][153293] = "Rustwing Scavenger"
rare_names_localized["enUS"][153294] = "Dead Mechagnome"
rare_names_localized["enUS"][153269] = "Rustwing Raven"

-- ####################################################################
-- ##                              GUI                               ##
-- ####################################################################

local function InitializeInterfaceEntityNameFrame(parent)
	local f = CreateFrame("Frame", "RareCouncil.entity_name_frame", parent)
	f:SetSize(200, parent:GetHeight() - 10)
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, 0.3)
	texture:SetAllPoints(f)
	f.texture = texture
	
	f.strings = {}
	for i=1, #rare_ids do
		local npc_id = rare_ids[i]
		f.strings[npc_id] = f:CreateFontString(nil, nil,"GameFontNormal")
		f.strings[npc_id]:SetPoint("TOPLEFT", 10, -i * 12)
		f.strings[npc_id]:SetText(rare_names_localized["enUS"][npc_id])
	end
	
	f:SetPoint("TOPLEFT", parent, 5, -5)
	return f
end

local function InitializeInterfaceEntityStatusFrame(parent)
	local f = CreateFrame("Frame", "RareCouncil.entity_status_frame", parent)
	f:SetSize(85, parent:GetHeight() - 10)
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, 0.3)
	texture:SetAllPoints(f)
	f.texture = texture
	
	f.strings = {}
	for i=1, #rare_ids do
		local npc_id = rare_ids[i]
		f.strings[npc_id] = f:CreateFontString(nil, nil,"GameFontNormal")
		f.strings[npc_id]:SetPoint("TOPLEFT", 10, -i * 12)
		f.strings[npc_id]:SetText("--")
	end
	
	f:SetPoint("TOPRIGHT", parent, -5, -5)
	return f
end

local function InitializeInterface(f)
	f:SetSize(300, 200)
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, 0.4)
	texture:SetAllPoints(f)
	f.texture = texture
	f:SetPoint("CENTER")
	
	-- Create a sub-frame for the entity names.
	f.entity_name_frame = InitializeInterfaceEntityNameFrame(f)
	f.entity_status_frame = InitializeInterfaceEntityStatusFrame(f)

	f:Show()
end

InitializeInterface(RareCouncil)

function RareCouncil:UpdateStatus(npc_id)
	if is_alive[npc_id] then
		RareCouncil.entity_status_frame.strings[npc_id]:SetText(current_health[npc_id].."%")
	elseif last_recorded_death[npc_id] ~= nil then
		RareCouncil.entity_status_frame.strings[npc_id]:SetText("dead")
	end
end

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
		
		if rare_ids_set[npc_id] then
			-- Find the health of the entity.
			local health = UnitHealth("target")
			
			if health > 0 then
				is_alive[npc_id] = true
				current_health[npc_id] = self:GetTargetHealthPercentage()
				last_recorded_death[npc_id] = nil
				self:UpdateStatus(npc_id)
			else 
				is_alive[npc_id] = false
				current_health[npc_id] = nil
				
				if last_recorded_death[npc_id] == nil then
					last_recorded_death[npc_id] = time()
				end
				
				self:UpdateStatus(npc_id)
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
		
		if rare_ids_set[npc_id] then
			-- Update the current health of the entity.
			current_health[npc_id] = self:GetTargetHealthPercentage()
			self:UpdateStatus(npc_id)
		end
	end
end

function RareCouncil:OnCombatLogEvent(...)
	-- The event itself does not have a payload (8.0 change). Use CombatLogGetCurrentEventInfo() instead.
	local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
	local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", destGUID);
	npc_id = tonumber(npc_id)
		
	if subevent == "UNIT_DIED" then
		if rare_ids_set[npc_id] then
			last_recorded_death[npc_id] = timestamp
			is_alive[npc_id] = false
			current_health[npc_id] = nil
			self:UpdateStatus(npc_id)
			
			print(is_alive[npc_id], current_health[npc_id], last_recorded_death[npc_id])
		end
	end
end	

-- Register the event handling of the frame.
RareCouncil:SetScript("OnEvent", RareCouncil.OnEvent)
RareCouncil:RegisterEvent("PLAYER_TARGET_CHANGED")
RareCouncil:RegisterEvent("UNIT_HEALTH")
RareCouncil:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")