local _, data = ...

local RTM = data.RTM;

-- ####################################################################
-- ##                              GUI                               ##
-- ####################################################################

function RTM:InitializeInterfaceEntityNameFrame()
	local f = CreateFrame("Frame", "RTM.entity_name_frame", self)
	f:SetSize(200, self:GetHeight() - 10)
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
	
	f:SetPoint("TOPLEFT", self, 5, -5)
	return f
end

function RTM:InitializeInterfaceEntityStatusFrame()
	local f = CreateFrame("Frame", "RTM.entity_status_frame", self)
	f:SetSize(85, self:GetHeight() - 10)
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
	
	f:SetPoint("TOPRIGHT", self, -5, -5)
	return f
end

function RTM:UpdateStatus(npc_id)
	if RTM.is_alive[npc_id] then
		RTM.entity_status_frame.strings[npc_id]:SetText(RTM.current_health[npc_id].."%")
	elseif RTM.last_recorded_death[npc_id] ~= nil then
		RTM.entity_status_frame.strings[npc_id]:SetText(math.floor((time() - RTM.last_recorded_death[npc_id]) / 60).."m")
	else
		RTM.entity_status_frame.strings[npc_id]:SetText("--")
	end
end

function RTM:InitializeInterface()
	self:SetSize(300, #RTM.rare_ids * 12 + 10 + 8)
	local texture = self:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, 0.4)
	texture:SetAllPoints(self)
	self.texture = texture
	self:SetPoint("CENTER")
	
	-- Create a sub-frame for the entity names.
	self.entity_name_frame = self:InitializeInterfaceEntityNameFrame()
	self.entity_status_frame = self:InitializeInterfaceEntityStatusFrame()

	self:Hide()
end

RTM:InitializeInterface()