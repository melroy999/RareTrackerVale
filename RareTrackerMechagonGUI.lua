local _, data = ...

local RTM = data.RTM;

local entity_name_width = 170
local entity_status_width = 50 
local frame_padding = 5

local shard_id_frame_height = 16

-- ####################################################################
-- ##                              GUI                               ##
-- ####################################################################

function RTM:InitializeShardNumberFrame()
	local f = CreateFrame("Frame", "RTM.shard_id_frame", self)
	f:SetSize(entity_name_width + entity_status_width + frame_padding, shard_id_frame_height)
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, 0.3)
	texture:SetAllPoints(f)
	f.texture = texture
	
	f.status_text = f:CreateFontString(nil, nil, "GameFontNormal")
	f.status_text:SetPoint("TOPLEFT", 10, -2)
	f.status_text:SetText("Shard ID: Unknown")
	f:SetPoint("TOPLEFT", self, frame_padding, -frame_padding)
	
	return f
end

function RTM:InitializeInterfaceEntityNameFrame()
	local f = CreateFrame("Frame", "RTM.entity_name_frame", self)
	f:SetSize(entity_name_width, self:GetHeight() - 10 - frame_padding - shard_id_frame_height)
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, 0.3)
	texture:SetAllPoints(f)
	f.texture = texture
	
	f.strings = {}
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		f.strings[npc_id] = f:CreateFontString(nil, nil, "GameFontNormal")
		f.strings[npc_id]:SetPoint("TOPLEFT", 10, -(i - 1) * 12 - 4)
		f.strings[npc_id]:SetText(RTM.rare_names_localized["enUS"][npc_id])
	end
	
	f:SetPoint("TOPLEFT", self, frame_padding, -(2 * frame_padding + shard_id_frame_height))
	return f
end

function RTM:InitializeInterfaceEntityStatusFrame()
	local f = CreateFrame("Frame", "RTM.entity_status_frame", self)
	f:SetSize(entity_status_width, self:GetHeight() - 10 - frame_padding - shard_id_frame_height)
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, 0.3)
	texture:SetAllPoints(f)
	f.texture = texture
	
	f.strings = {}
	for i=1, #RTM.rare_ids do
		local npc_id = RTM.rare_ids[i]
		f.strings[npc_id] = f:CreateFontString(nil, nil,"GameFontNormal")
		f.strings[npc_id]:SetPoint("TOPLEFT", 10, -(i - 1) * 12 - 4)
		f.strings[npc_id]:SetText("--")
	end
	
	f:SetPoint("TOPRIGHT", self, -frame_padding, -(2 * frame_padding + shard_id_frame_height))
	return f
end

function RTM:UpdateStatus(npc_id)
	local frame_target = RTM.entity_status_frame.strings[npc_id]

	if RTM.is_alive[npc_id] then
		frame_target:SetText(RTM.current_health[npc_id].."%")
	elseif RTM.last_recorded_death[npc_id] ~= nil then
		local last_death = RTM.last_recorded_death[npc_id]
	
		frame_target:SetText(math.floor((time() - last_death) / 60).."m")
	else
		frame_target:SetText("--")
	end
end

function RTM:UpdateShardNumber(shard_number)
	RTM.shard_id_frame.status_text:SetText("Shard ID: "..shard_number)
end

function RTM:InitializeInterface()
	self:SetSize(entity_name_width + entity_status_width + 3 * frame_padding, shard_id_frame_height + frame_padding + #RTM.rare_ids * 12 + 10 + 8)
	local texture = self:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, 0.4)
	texture:SetAllPoints(self)
	self.texture = texture
	self:SetPoint("CENTER")
	
	-- Create a sub-frame for the entity names.
	self.shard_id_frame = self:InitializeShardNumberFrame()
	self.entity_name_frame = self:InitializeInterfaceEntityNameFrame()
	self.entity_status_frame = self:InitializeInterfaceEntityStatusFrame()

	self:SetMovable(true)
	self:EnableMouse(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)
	
	self:Hide()
end

RTM:InitializeInterface()