local _, data = ...

local RTM = data.RTM

-- ####################################################################
-- ##                         Event Handlers                         ##
-- ####################################################################

-- Listen to a given set of events and handle them accordingly.
function RTM:OnEvent(event, ...)
	if event == "PLAYER_TARGET_CHANGED" then
		RTM:OnTargetChanged(...)
	elseif event == "UNIT_HEALTH" then
		RTM:OnUnitHealth(...)
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		RTM:OnCombatLogEvent(...)
	elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" then
		RTM:OnZoneTransition()
	elseif event == "CHAT_MSG_CHANNEL" then
		RTM:OnChatMsgChannel(...)
	elseif event == "CHAT_MSG_ADDON" then
		RTM:OnChatMsgAddon(...)
	elseif event == "VIGNETTE_MINIMAP_UPDATED" then
		RTM:OnVignetteMinimapUpdated(...)
	elseif event == "ADDON_LOADED" then
		RTM:OnAddonLoaded()
	elseif event == "PLAYER_LOGOUT" then
		RTM:OnPlayerLogout()	
	end
end

function RTM:ChangeShard(old_zone_uid, new_zone_uid)
	-- Notify the users in your old shard that you have moved on to another shard.
	RTM:RegisterDeparture(old_zone_uid)
	
	-- Reset all the data we have, since it has all become useless.
	RTM.is_alive = {}
	RTM.current_health = {}
	RTM.last_recorded_death = {}
	RTM.recorded_entity_death_ids = {}
	RTM.current_coordinates = {}
	RTM.reported_spawn_uids = {}
	RTM.reported_vignettes = {}
	
	-- Announce your arrival in the new shard.
	RTM:RegisterArrival(new_zone_uid)
end

function RTM:CheckForShardChange(zone_uid)
	if RTM.current_shard_id ~= zone_uid and zone_uid ~= nil then
		print("<RTM> Moving to shard", (zone_uid + 42)..".")
		RTM:UpdateShardNumber(zone_uid)
		
		if RTM.current_shard_id == nil then
			-- Register yourRTM for the given shard.
			RTM:RegisterArrival(zone_uid)
		else
			-- Move from one shard to another.
			RTM:ChangeShard(RTM.current_shard_id, zone_uid)
		end
		
		RTM.current_shard_id = zone_uid
	end
end

function RTM:OnTargetChanged(...)
	if UnitGUID("target") ~= nil then
		-- Get information about the target.
		local guid, name = UnitGUID("target"), UnitName("target")
		local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", guid);
		npc_id = tonumber(npc_id)
		
		RTM:CheckForShardChange(zone_uid)
		
		if RTM.rare_ids_set[npc_id] then
			-- Find the health of the entity.
			local health = UnitHealth("target")
			
			if health > 0 then
				local percentage = RTM:GetTargetHealthPercentage()
				
				RTM.is_alive[npc_id] = time()
				RTM.current_health[npc_id] = percentage
				RTM:UpdateStatus(npc_id)
				
				-- Get the current position of the player.
				local pos = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")
				local x, y = math.floor(pos.x * 10000 + 0.5) / 100, math.floor(pos.y * 10000 + 0.5) / 100
				
				RTM:RegisterEntityTarget(RTM.current_shard_id, npc_id, spawn_uid, percentage, x, y)
			else 
				if RTM.recorded_entity_death_ids[spawn_uid] == nil then
					RTM.recorded_entity_death_ids[spawn_uid] = true
					RTM:RegisterEntityDeath(RTM.current_shard_id, npc_id)
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
		
		RTM:CheckForShardChange(zone_uid)
		
		if RTM.rare_ids_set[npc_id] then
			-- Update the current health of the entity.
			local percentage = RTM:GetTargetHealthPercentage()
			
			RTM.is_alive[npc_id] = time()
			RTM.current_health[npc_id] = percentage
			RTM:UpdateStatus(npc_id)
			
			RTM:RegisterEntityHealth(RTM.current_shard_id, npc_id, spawn_uid, percentage)
		end
	end
end

function RTM:OnCombatLogEvent(...)
	-- The event does not have a payload (8.0 change). Use CombatLogGetCurrentEventInfo() instead.
	local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
	local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", destGUID);
	npc_id = tonumber(npc_id)
	
	-- We can always check for a shard change.
	-- We only take fights between creatures, since they seem to be the only reliable option.
	if unittype == "Creature" and not RTM.banned_NPC_ids[npc_id] then
		RTM:CheckForShardChange(zone_uid)
	end	
		
	if subevent == "UNIT_DIED" then
		if RTM.rare_ids_set[npc_id] then
			if RTM.recorded_entity_death_ids[spawn_uid] == nil then
				RTM.recorded_entity_death_ids[spawn_uid] = true
				RTM:RegisterEntityDeath(RTM.current_shard_id, npc_id)
			end
		end
	end
end	

function RTM:OnZoneTransition()
	-- The zone the player is in.
	local zone_id = C_Map.GetBestMapForUnit("player")
		
	if RTM.target_zones[zone_id] and not RTM.target_zones[RTM.last_zone_id] then
		-- Enable the Mechagon rares.
		RTM:StartInterface()
		
	elseif not RTM.target_zones[zone_id] then
		-- Disable the addon.
		
		-- If we do not have a shard ID, we are not subscribed to one of the channels.
		RTM:RegisterDeparture(RTM.current_shard_id)
		
		RTM:CloseInterface()
	end
	
	RTM.last_zone_id = zone_id
end	

function RTM:OnChatMsgChannel(...)
	local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons = ...

end	

function RTM:OnChatMsgAddon(...)
	local addon_prefix, message, channel, sender = ...
	
	if addon_prefix == "RTM" then
		local header, payload = strsplit(":", message)
		local prefix, shard_id, addon_version_str = strsplit("-", header)
		local addon_version = tonumber(addon_version_str)

		RTM:OnChatMessageReceived(sender, prefix, shard_id, addon_version, payload)
	end
end	



function RTM:OnVignetteMinimapUpdated(...)
	vignetteGUID, onMinimap = ...
	vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
	
	if vignetteInfo == nil and RTM.current_shard_id ~= nil then
		-- An entity we saw earlier might have died.
		if RTM.reported_vignettes[vignetteGUID] then
			RTM:RegisterEntityDeath(RTM.current_shard_id, RTM.reported_vignettes[vignetteGUID])
		end
	else
		if vignetteInfo == nil then
			return
		end
	
		-- Report the entity.
		local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", vignetteInfo.objectGUID);
		local npc_id = tonumber(npc_id)
		
		if unittype == "Creature" then
			RTM:CheckForShardChange(zone_uid)
			
			if RTM.rare_ids_set[npc_id] and not RTM.reported_vignettes[vignetteGUID] then
				RTM.is_alive[npc_id] = time()
				RTM.reported_vignettes[vignetteGUID] = npc_id
				RTM:RegisterEntityAlive(RTM.current_shard_id, npc_id, spawn_uid)
			end
		end
	end
end

RTM.last_display_update = 0

function RTM:OnUpdate()
	if (RTM.last_display_update + 0.25 < time()) then
		for i=1, #RTM.rare_ids do
			local npc_id = RTM.rare_ids[i]
			
			-- It might occur that the rare is marked as alive, but no health is known.
			-- If 20 seconds pass without a health value, the alive tag will be reset.
			if RTM.is_alive[npc_id] and not RTM.current_health[npc_id] and time() - RTM.is_alive[npc_id] > 20 then
				RTM.is_alive[npc_id] = nil
			end
			
			-- It might occur that we have both a hp and health, but no changes.
			-- If 2 minutes pass without a health value, the alive and health tags will be reset.
			if RTM.is_alive[npc_id] and RTM.current_health[npc_id] and time() - RTM.is_alive[npc_id] > 120 then
				RTM.is_alive[npc_id] = nil
				RTM.current_health[npc_id] = nil
			end
			
			RTM:UpdateStatus(npc_id)
		end
		
		RTM.last_display_update = time();
	end
end	

function RTM:OnAddonLoaded()
	-- OnAddonLoaded might be called multiple times. We only want it to do so once.
	if not RTM.is_loaded then
		self:CorrectFavoriteMarks()
		self:RegisterMapIcon()
		RTM.is_loaded = true
		
		if RTMDB.show_window == nil then
			RTMDB.show_window = true
		end
		
		if not RTMDB.favorite_rares then
			RTMDB.favorite_rares = {}
		end
		
		if not RTMDB.previous_records then
			RTMDB.previous_records = {}
		end
		
		-- Remove any data in the previous records that has expired.
		for key, _ in pairs(RTMDB.previous_records) do
			if time() - RTMDB.previous_records[key].time_stamp > 300 then
				print("<RTM> Removing cached data for shard", (key + 42)..".")
				RTMDB.previous_records[key] = nil
			end
		end
	end
end	

function RTM:OnPlayerLogout()
	if RTM.current_shard_id then
		RTMDB.previous_records[RTM.current_shard_id] = {}
		RTMDB.previous_records[RTM.current_shard_id].time_stamp = time()
		RTMDB.previous_records[RTM.current_shard_id].time_table = RTM.last_recorded_death
	end
end

function RTM:RegisterEvents()
	RTM:RegisterEvent("PLAYER_TARGET_CHANGED")
	RTM:RegisterEvent("UNIT_HEALTH")
	RTM:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	RTM:RegisterEvent("CHAT_MSG_CHANNEL")
	RTM:RegisterEvent("CHAT_MSG_ADDON")
	RTM:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
end

function RTM:UnregisterEvents()
	RTM:UnregisterEvent("PLAYER_TARGET_CHANGED")
	RTM:UnregisterEvent("UNIT_HEALTH")
	RTM:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	RTM:UnregisterEvent("CHAT_MSG_CHANNEL")
	RTM:UnregisterEvent("CHAT_MSG_ADDON")
	RTM:UnregisterEvent("VIGNETTE_MINIMAP_UPDATED")
end

RTM.updateHandler = CreateFrame("Frame", "RTM.updateHandler", RTM)
RTM.updateHandler:SetScript("OnUpdate", RTM.OnUpdate)

-- Register the event handling of the frame.
RTM:SetScript("OnEvent", RTM.OnEvent)
RTM:RegisterEvent("ZONE_CHANGED_NEW_AREA")
RTM:RegisterEvent("ZONE_CHANGED")
RTM:RegisterEvent("PLAYER_ENTERING_WORLD")
RTM:RegisterEvent("ADDON_LOADED")
RTM:RegisterEvent("PLAYER_LOGOUT")

