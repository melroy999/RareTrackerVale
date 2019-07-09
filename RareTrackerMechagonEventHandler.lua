local _, data = ...

local RTM = data.RTM;

-- ####################################################################
-- ##                         Event Handlers                         ##
-- ####################################################################

-- Listen to a given set of events and handle them accordingly.
function RTM:OnEvent(event, ...)
	if event == "PLAYER_TARGET_CHANGED" then
		self:OnTargetChanged(...)
	elseif event == "UNIT_HEALTH" then
		self:OnUnitHealth(...)
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		self:OnCombatLogEvent(...)
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		self:OnZoneTransition()
	elseif event == "PLAYER_ENTERING_WORLD" then
		self:OnZoneTransition()
	elseif event == "CHAT_MSG_CHANNEL" then
		self:OnChatMsgChannel(...)
	elseif event == "CHAT_MSG_ADDON" then
		self:OnChatMsgAddon(...)
	end
end

function RTM:OnTargetChanged(...)
	if UnitGUID("target") ~= nil then
		-- Get information about the target.
		local guid, name = UnitGUID("target"), UnitName("target")
		local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", guid);
		npc_id = tonumber(npc_id)
		
		if RTM.current_shard_id ~= zone_uid and zone_uid ~= nil then
			print("Changing from shard", RTM.current_shard_id, "to", zone_uid..".")
			RTM.current_shard_id = zone_uid
		end
		
		if RTM.rare_ids_set[npc_id] then
			-- Find the health of the entity.
			local health = UnitHealth("target")
			
			if health > 0 then
				RTM.is_alive[npc_id] = true
				RTM.current_health[npc_id] = self:GetTargetHealthPercentage()
				RTM.last_recorded_death[npc_id] = nil
			else 
				RTM.is_alive[npc_id] = false
				RTM.current_health[npc_id] = nil
				
				if RTM.last_recorded_death[npc_id] == nil then
					RTM.last_recorded_death[npc_id] = time()
				end
			end
		end
	end
end

function RTM:OnUnitHealth(unit)
	-- If the unit is not the target, skip.
	if unit ~= "target" then 
		return 
	end
	
	if UnitGUID("target") ~= nil then
		-- Get information about the target.
		local guid, name = UnitGUID("target"), UnitName("target")
		local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", guid);
		npc_id = tonumber(npc_id)
		
		if RTM.rare_ids_set[npc_id] then
			-- Update the current health of the entity.
			RTM.current_health[npc_id] = self:GetTargetHealthPercentage()
		end
	end
end

function RTM:OnCombatLogEvent(...)
	-- The event itself does not have a payload (8.0 change). Use CombatLogGetCurrentEventInfo() instead.
	local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
	local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", destGUID);
	npc_id = tonumber(npc_id)
		
	if subevent == "UNIT_DIED" then
		if RTM.rare_ids_set[npc_id] then
			RTM.last_recorded_death[npc_id] = timestamp
			RTM.is_alive[npc_id] = false
			RTM.current_health[npc_id] = nil
		end
	end
end	

function RTM:OnZoneTransition()
	-- The zone the player is in.
	local zone_id = C_Map.GetBestMapForUnit("player")
	
	if zone_id == 1462 or zone_id == 37 then
		-- Enable the Mechagon rares.
		self:StartInterface()
	else 
		-- Disable the addon.
		print(zone_id)
		self:CloseInterface()
	end
end	

function RTM:OnChatMsgChannel(...)
	text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons = ...
	
	print(text)
end	

function RTM:OnChatMsgAddon(...)
	prefix, message, channel, sender = ...
	
	if prefix == "RTM" then
		print(message)
	end
end	

RTM.LastDisplayUpdate = 0

function RTM:OnUpdate()
	if (RTM.LastDisplayUpdate + 0.5 < time()) then
		for i=1, #RTM.rare_ids do
			local npc_id = RTM.rare_ids[i]
			RTM:UpdateStatus(npc_id)
		end
		
		RTM.LastDisplayUpdate = time();
	end
end	

function RTM:RegisterEvents()
	print("Registering events")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("CHAT_MSG_CHANNEL")
	self:RegisterEvent("CHAT_MSG_ADDON")
end

function RTM:UnregisterEvents()
	print("Unregistering events")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("UNIT_HEALTH")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("CHAT_MSG_CHANNEL")
	self:UnregisterEvent("CHAT_MSG_ADDON")
end

RTM.updateHandler = CreateFrame("Frame", "RTM.updateHandler", RTM)
RTM.updateHandler:SetScript("OnUpdate", RTM.OnUpdate)

-- Register the event handling of the frame.
RTM:SetScript("OnEvent", RTM.OnEvent)
RTM:RegisterEvent("ZONE_CHANGED_NEW_AREA")
RTM:RegisterEvent("PLAYER_ENTERING_WORLD")