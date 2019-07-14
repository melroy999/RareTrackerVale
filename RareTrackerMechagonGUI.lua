local _, data = ...

local RTM = data.RTM

local entity_name_width = 180
local entity_status_width = 50 
local frame_padding = 4
local favorite_rares_width = 10

local shard_id_frame_height = 16

background_opacity = 0.4
front_opacity = 0.6

-- ####################################################################
-- ##                              GUI                               ##
-- ####################################################################

function RTM:InitializeShardNumberFrame()
	local f = CreateFrame("Frame", "RTM.shard_id_frame", self)
	f:SetSize(entity_name_width + entity_status_width + 3 * frame_padding + 2 * favorite_rares_width, shard_id_frame_height)
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f)
	f.texture = texture
	
	f.status_text = f:CreateFontString(nil, nil, "GameFontNormal")
	f.status_text:SetPoint("TOPLEFT", 10 + 2 * favorite_rares_width + 2 * frame_padding, -3)
	f.status_text:SetText("Shard ID: Unknown")
	f:SetPoint("TOPLEFT", self, frame_padding, -frame_padding)
	
	return f
end

function RTM:InitializeFavoriteMarkerFrame()
	local f = CreateFrame("Frame", "RTM.RTMDB.favorite_rares_frame", self)
	f:SetSize(favorite_rares_width, self:GetHeight() - 2 * frame_padding - frame_padding - shard_id_frame_height)
	
	f.checkboxes = {}
	local height_offset = -(2 * frame_padding + shard_id_frame_height)
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		f.checkboxes[npc_id] = CreateFrame("CheckButton", "RTM.shard_id_frame.checkbox["..i.."]", f)
		f.checkboxes[npc_id]:SetSize(10, 10)
		local texture = f.checkboxes[npc_id]:CreateTexture(nil, "BACKGROUND")
		texture:SetColorTexture(0, 0, 0, front_opacity)
		texture:SetAllPoints(f.checkboxes[npc_id])
		f.checkboxes[npc_id].texture = texture
		f.checkboxes[npc_id]:SetPoint("TOPLEFT", 1, -(i - 1) * 12 - 5)
		
		-- Add an action listener.
		f.checkboxes[npc_id]:SetScript("OnClick", 
			function()
				if RTMDB.favorite_rares[npc_id] then
					RTMDB.favorite_rares[npc_id] = nil
					f.checkboxes[npc_id].texture:SetColorTexture(0, 0, 0, front_opacity)
				else
					RTMDB.favorite_rares[npc_id] = true
					f.checkboxes[npc_id].texture:SetColorTexture(0, 1, 0, 1)
				end
			end
		);
	end
	
	f:SetPoint("TOPLEFT", self, frame_padding, height_offset)
	return f
end

function RTM:InitializeAliveMarkerFrame()
	local f = CreateFrame("Frame", "RTM.alive_marker_frame", self)
	f:SetSize(favorite_rares_width, self:GetHeight() - 2 * frame_padding - frame_padding - shard_id_frame_height)
	
	f.checkboxes = {}
	local height_offset = -(2 * frame_padding + shard_id_frame_height)
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		f.checkboxes[npc_id] = CreateFrame("Button", "RTM.shard_id_frame.checkbox["..i.."]", f)
		
		f.checkboxes[npc_id]:SetSize(10, 10)
		local texture = f.checkboxes[npc_id]:CreateTexture(nil, "BACKGROUND")
		texture:SetColorTexture(0, 0, 0, front_opacity)
		texture:SetAllPoints(f.checkboxes[npc_id])
		f.checkboxes[npc_id].texture = texture
		f.checkboxes[npc_id]:SetPoint("TOPLEFT", 1, -(i - 1) * 12 - 5)
		f.checkboxes[npc_id]:RegisterForClicks("LeftButtonDown", "RightButtonDown")
		
		-- Add an action listener.
		f.checkboxes[npc_id]:SetScript("OnClick", 
			function(self, button, down)
				local name = RTM.rare_names_localized["enUS"][npc_id]
				local health = RTM.current_health[npc_id]
				local last_death = RTM.last_recorded_death[npc_id]
				local loc = RTM.current_coordinates[npc_id]
				
				if button == "LeftButton" then
					if RTM.current_health[npc_id] and loc then
						-- SendChatMessage
						SendChatMessage(string.format("<RTM> %s (%s%%) seen at ~(%.2f, %.2f)", name, health, loc.x, loc.y), "CHANNEL", nil, 1)
					elseif RTM.current_health[npc_id] then
						SendChatMessage(string.format("<RTM> %s (%s%%) seen at ~(location unknown)", name, health), "CHANNEL", nil, 1)
					elseif RTM.last_recorded_death[npc_id] ~= nil then
						if time() - last_death < 60 then
							SendChatMessage(string.format("<RTM> %s died %s seconds ago", name, time() - last_death), "CHANNEL", nil, 1)
						else
							SendChatMessage(string.format("<RTM> %s was last seen ~%s minutes ago", name, math.floor((time() - last_death) / 60)), "CHANNEL", nil, 1)
						end
					elseif RTM.is_alive[npc_id] then
						SendChatMessage(string.format("<RTM> %s seen alive (location unknown)", name), "CHANNEL", nil, 1)
					end
				else
					-- does the user have tom tom? if so, add a waypoint if it exists.
					if TomTom ~= nil and loc then
						RTM.waypoints[npc_id] = TomTom:AddWaypointToCurrentZone(loc.x, loc.y, name)
					end
				end
			end
		);
	end
	
	f:SetPoint("TOPLEFT", self, 2 * frame_padding + favorite_rares_width, height_offset)
	return f
end

function RTM:InitializeInterfaceEntityNameFrame()
	local f = CreateFrame("Frame", "RTM.entity_name_frame", self)
	f:SetSize(entity_name_width, self:GetHeight() - 2 * frame_padding - frame_padding - shard_id_frame_height)
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f)
	f.texture = texture
	
	f.strings = {}
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		f.strings[npc_id] = f:CreateFontString(nil, nil, "GameFontNormal")
		f.strings[npc_id]:SetJustifyH("LEFT")
		f.strings[npc_id]:SetJustifyV("TOP")
		f.strings[npc_id]:SetPoint("TOPLEFT", 10, -(i - 1) * 12 - 4)
		f.strings[npc_id]:SetText(RTM.rare_names_localized["enUS"][npc_id])
	end
	
	f:SetPoint("TOPLEFT", self, 3 * frame_padding + 2 * favorite_rares_width, -(2 * frame_padding + shard_id_frame_height))
	return f
end

function RTM:InitializeInterfaceEntityStatusFrame()
	local f = CreateFrame("Frame", "RTM.entity_status_frame", self)
	f:SetSize(entity_status_width, self:GetHeight() - 2 * frame_padding - frame_padding - shard_id_frame_height)
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f)
	f.texture = texture
	
	f.strings = {}
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		f.strings[npc_id] = f:CreateFontString(nil, nil,"GameFontNormal")
		f.strings[npc_id]:SetPoint("TOP", 0, -(i - 1) * 12 - 4)
		f.strings[npc_id]:SetText("--")
		f.strings[npc_id]:SetJustifyH("LEFT")
		f.strings[npc_id]:SetJustifyV("TOP")
	end
	
	f:SetPoint("TOPRIGHT", self, -frame_padding, -(2 * frame_padding + shard_id_frame_height))
	return f
end

function RTM:UpdateStatus(npc_id)
	local status_text_frame = RTM.entity_status_frame.strings[npc_id]
	local alive_status_frame = RTM.alive_marker_frame.checkboxes[npc_id]

	if RTM.current_health[npc_id] then
		status_text_frame:SetText(RTM.current_health[npc_id].."%")
		alive_status_frame.texture:SetColorTexture(0, 1, 0, 1)
	elseif RTM.last_recorded_death[npc_id] ~= nil then
		local last_death = RTM.last_recorded_death[npc_id]
		status_text_frame:SetText(math.floor((time() - last_death) / 60).."m")
		alive_status_frame.texture:SetColorTexture(0, 0, 1, front_opacity)
	elseif RTM.is_alive[npc_id] then
		status_text_frame:SetText("NA")
		alive_status_frame.texture:SetColorTexture(0, 1, 0, 1)
	else
		status_text_frame:SetText("--")
		alive_status_frame.texture:SetColorTexture(0, 0, 0, front_opacity)
	end
end

function RTM:UpdateShardNumber(shard_number)
	if shard_number then
		RTM.shard_id_frame.status_text:SetText("Shard ID: "..(shard_number + 42))
	else
		RTM.shard_id_frame.status_text:SetText("Shard ID: Unknown")
	end
end

function RTM:CorrectFavoriteMarks()
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		
		if RTMDB.favorite_rares[npc_id] then
			self.favorite_rares_frame.checkboxes[npc_id].texture:SetColorTexture(0, 1, 0, 1)
		end
	end
end

function RTM:UpdateDailyKillMark(npc_id)
	if IsQuestFlaggedCompleted(RTM.completion_quest_ids[npc_id]) then
		self.entity_name_frame.strings[npc_id]:SetText("(x) "..RTM.rare_names_localized["enUS"][npc_id])
	else
		self.entity_name_frame.strings[npc_id]:SetText(RTM.rare_names_localized["enUS"][npc_id])
	end
end

function RTM:UpdateAllDailyKillMarks()
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		self:UpdateDailyKillMark(npc_id)
	end
end

function RTM:InitializeFavoriteIconFrame(f)
	f.favorite_icon = CreateFrame("Frame", "RTM.favorite_icon", f)
	f.favorite_icon:SetSize(10, 10)
	f.favorite_icon:SetPoint("TOPLEFT", f, frame_padding + 1, -(frame_padding + 3))

	f.favorite_icon.texture = f.favorite_icon:CreateTexture(nil, "OVERLAY")
	f.favorite_icon.texture:SetTexture("Interface\\AddOns\\RareTrackerMechagon\\Icons\\Favorite.tga")
	f.favorite_icon.texture:SetSize(10, 10)
	f.favorite_icon.texture:SetPoint("CENTER", f.favorite_icon)
	
	f.favorite_icon.tooltip = CreateFrame("Frame", nil, UIParent)
	f.favorite_icon.tooltip:SetSize(300, 18)
	
	local texture = f.favorite_icon.tooltip:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f.favorite_icon.tooltip)
	f.favorite_icon.tooltip.texture = texture
	f.favorite_icon.tooltip:SetPoint("TOPLEFT", f, 0, 19)
	f.favorite_icon.tooltip:Hide()
	
	f.favorite_icon.tooltip.text = f.favorite_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.favorite_icon.tooltip.text:SetJustifyH("LEFT")
	f.favorite_icon.tooltip.text:SetJustifyV("TOP")
	f.favorite_icon.tooltip.text:SetPoint("TOPLEFT", f.favorite_icon.tooltip, 5, -3)
	f.favorite_icon.tooltip.text:SetText("Click on the squares to add rares to your favorites.")
	
	f.favorite_icon:SetScript("OnEnter", 
		function(self)
			self.tooltip:Show()
		end
	);
	
	f.favorite_icon:SetScript("OnLeave", 
		function(self)
			self.tooltip:Hide()
		end
	);
end

function RTM:InitializeAnnounceIconFrame(f)
	f.broadcast_icon = CreateFrame("Frame", "RTM.broadcast_icon", f)
	f.broadcast_icon:SetSize(10, 10)
	f.broadcast_icon:SetPoint("TOPLEFT", f, 2 * frame_padding + favorite_rares_width + 1, -(frame_padding + 3))

	f.broadcast_icon.texture = f.broadcast_icon:CreateTexture(nil, "OVERLAY")
	f.broadcast_icon.texture:SetTexture("Interface\\AddOns\\RareTrackerMechagon\\Icons\\Broadcast.tga")
	f.broadcast_icon.texture:SetSize(10, 10)
	f.broadcast_icon.texture:SetPoint("CENTER", f.broadcast_icon)
	
	f.broadcast_icon.tooltip = CreateFrame("Frame", nil, UIParent)
	f.broadcast_icon.tooltip:SetSize(273, 44)
	
	local texture = f.broadcast_icon.tooltip:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f.broadcast_icon.tooltip)
	f.broadcast_icon.tooltip.texture = texture
	f.broadcast_icon.tooltip:SetPoint("TOPLEFT", f, 0, 45)
	f.broadcast_icon.tooltip:Hide()
	
	f.broadcast_icon.tooltip.text1 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text1:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text1:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text1:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -3)
	f.broadcast_icon.tooltip.text1:SetText("Click on the squares to announce rare timers.")
	
	f.broadcast_icon.tooltip.text2 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text2:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text2:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text2:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -15)
	f.broadcast_icon.tooltip.text2:SetText("Left click: report to general chat")
	  
	f.broadcast_icon.tooltip.text3 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text3:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text3:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text3:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -27)
	f.broadcast_icon.tooltip.text3:SetText("Right click: set waypoint if available")
	
	f.broadcast_icon:SetScript("OnEnter", 
		function(self)
			self.tooltip:Show()
		end
	);
	
	f.broadcast_icon:SetScript("OnLeave", 
		function(self)
			self.tooltip:Hide()
		end
	);
end


function RTM:InitializeInterface()
	self:SetSize(entity_name_width + entity_status_width + 2 * favorite_rares_width + 5 * frame_padding, shard_id_frame_height + 3 * frame_padding + #RTM.rare_ids * 12 + 8)
	local texture = self:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, background_opacity)
	texture:SetAllPoints(self)
	self.texture = texture
	self:SetPoint("CENTER")
	
	-- Create a sub-frame for the entity names.
	self.shard_id_frame = self:InitializeShardNumberFrame()
	self.favorite_rares_frame = self:InitializeFavoriteMarkerFrame()
	self.alive_marker_frame = self:InitializeAliveMarkerFrame()
	self.entity_name_frame = self:InitializeInterfaceEntityNameFrame()
	self.entity_status_frame = self:InitializeInterfaceEntityStatusFrame()

	self:SetMovable(true)
	self:EnableMouse(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)
	
	-- Add icons for the favorite and broadcast columns.
	RTM:InitializeFavoriteIconFrame(self)
	RTM:InitializeAnnounceIconFrame(self)
	
	-- Create a reset button.
	self.reload_button = CreateFrame("Button", "RTM.reload_button", self)
	self.reload_button:SetSize(10, 10)
	self.reload_button:SetPoint("TOPRIGHT", self, -2 * frame_padding, -(frame_padding + 3))

	self.reload_button.texture = self.reload_button:CreateTexture(nil, "OVERLAY")
	self.reload_button.texture:SetTexture("Interface\\AddOns\\RareTrackerMechagon\\Icons\\Reload.tga")
	self.reload_button.texture:SetSize(10, 10)
	self.reload_button.texture:SetPoint("CENTER", self.reload_button)
	
	self.reload_button:SetScript("OnClick", 
		function()
			if RTM.current_shard_id then
				print("<RTM> Resetting current rare timers and requesting up-to-date data.")
				RTM.is_alive = {}
				RTM.current_health = {}
				RTM.last_recorded_death = {}
				RTM.recorded_entity_death_ids = {}
				RTM.current_coordinates = {}
				RTM.reported_spawn_uids = {}
				RTM.reported_vignettes = {}
				
				-- Reset the cache.
				RTMDB.previous_records[RTM.current_shard_id] = nil
				
				-- Re-register your arrival in the shard.
				RTM:RegisterArrival(RTM.current_shard_id)
			else
				print("<RTM> Please target a non-player entity prior to reloading, such that the addon can determine the current shard id.")
			end
		end
	);
	
	self:Hide()
end

RTM:InitializeInterface()