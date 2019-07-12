local _, data = ...

local RTM = data.RTM;

local entity_name_width = 170
local entity_status_width = 50 
local frame_padding = 4
local favorite_rares_width = 10

local shard_id_frame_height = 16

background_opacity = 0.2
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
	f.status_text:SetPoint("TOPLEFT", 10 + 2 * favorite_rares_width + 2 * frame_padding, -2)
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
		
		-- Add an action listener.
		f.checkboxes[npc_id]:SetScript("OnClick", 
			function()
				local pos = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")
				local x, y = math.floor(pos.x * 10000 + 0.5) / 100, math.floor(pos.y * 10000 + 0.5) / 100
				
				local name = RTM.rare_names_localized["enUS"][npc_id]
				local health = RTM.current_health[npc_id]
				local last_death = RTM.last_recorded_death[npc_id]
			
				if RTM.current_health[npc_id] then
					SendChatMessage(string.format("<RTM> %s (%s%%) seen at ~(%.2f, %.2f)", name, health, x, y), "CHANNEL", nil, 1)
				elseif RTM.last_recorded_death[npc_id] ~= nil then
					SendChatMessage(string.format("<RTM> %s was last seen ~%s minutes ago", name, math.floor((time() - last_death) / 60)), "CHANNEL", nil, 1)
				elseif RTM.is_alive[npc_id] then
					SendChatMessage(string.format("<RTM> %s seen alive (location unknown)", name), "CHANNEL", nil, 1)
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
		alive_status_frame.texture:SetColorTexture(0, 0, 0, front_opacity)
	elseif RTM.is_alive[npc_id] then
		status_text_frame:SetText("NA")
		alive_status_frame.texture:SetColorTexture(0, 1, 0, 1)
	else
		status_text_frame:SetText("--")
		alive_status_frame.texture:SetColorTexture(0, 0, 0, front_opacity)
	end
end

function RTM:UpdateShardNumber(shard_number)
	RTM.shard_id_frame.status_text:SetText("Shard ID: "..shard_number)
end

function RTM:CorrectFavoriteMarks()
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		
		if RTMDB.favorite_rares[npc_id] then
			self.favorite_rares_frame.checkboxes[npc_id].texture:SetColorTexture(0, 1, 0, 1)
		end
	end
end

function RTM:InitializeInterface()
	self:SetSize(entity_name_width + entity_status_width + 2 * favorite_rares_width + 5 * frame_padding, shard_id_frame_height + 3 * frame_padding + #RTM.rare_ids * 12 + 8)
	local texture = self:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, 0.1)
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
	self.favorite_icon = CreateFrame("Frame", "RTM.favorite_icon", self)
	self.favorite_icon:SetSize(10, 10)
	self.favorite_icon:SetPoint("TOPLEFT", self, frame_padding + 1, -(frame_padding + 3))

	self.favorite_icon.texture = self.favorite_icon:CreateTexture(nil, "OVERLAY")
	self.favorite_icon.texture:SetTexture("Interface\\AddOns\\RareTrackerMechagon\\Icons\\Favorite.tga")
	self.favorite_icon.texture:SetSize(10, 10)
	self.favorite_icon.texture:SetBlendMode("ADD")
	self.favorite_icon.texture:SetPoint("CENTER", self.favorite_icon)
	
	self.broadcast_icon = CreateFrame("Frame", "RTM.broadcast_icon", self)
	self.broadcast_icon:SetSize(10, 10)
	self.broadcast_icon:SetPoint("TOPLEFT", self, 2 * frame_padding + favorite_rares_width + 1, -(frame_padding + 3))

	self.broadcast_icon.texture = self.broadcast_icon:CreateTexture(nil, "OVERLAY")
	self.broadcast_icon.texture:SetTexture("Interface\\AddOns\\RareTrackerMechagon\\Icons\\Broadcast.tga")
	self.broadcast_icon.texture:SetSize(10, 10)
	self.broadcast_icon.texture:SetBlendMode("ADD")
	self.broadcast_icon.texture:SetPoint("CENTER", self.broadcast_icon)
	
	
	self:Hide()
end

RTM:InitializeInterface()