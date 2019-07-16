local _, data = ...

local RTM = data.RTM

-- ####################################################################
-- ##                         Event Handlers                         ##
-- ####################################################################

-- Listen to a given set of events and handle them accordingly.
function RTM:OnEvent(event, ...)
	if event == "PLAYER_TARGET_CHANGED" then
		RTM:OnTargetChanged(...)
	elseif event == "UNIT_HEALTH" and RTM.chat_frame_loaded then
		RTM:OnUnitHealth(...)
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" and RTM.chat_frame_loaded then
		RTM:OnCombatLogEvent(...)
	elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" then
		RTM:OnZoneTransition()
	elseif event == "CHAT_MSG_ADDON" then
		RTM:OnChatMsgAddon(...)
	elseif event == "VIGNETTE_MINIMAP_UPDATED" and RTM.chat_frame_loaded then
		RTM:OnVignetteMinimapUpdated(...)
	elseif event == "ADDON_LOADED" then
		RTM:OnAddonLoaded()
	elseif event == "PLAYER_LOGOUT" then
		RTM:OnPlayerLogout()	
	end
end

-- Change from the original shard to the other.
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

-- Check whether the user has changed shards and proceed accordingly.
function RTM:CheckForShardChange(zone_uid)
	local has_changed = false

	if RTM.current_shard_id ~= zone_uid and zone_uid ~= nil then
		print("<RTM> Moving to shard", (zone_uid + 42)..".")
		RTM:UpdateShardNumber(zone_uid)
		has_changed = true
		
		if RTM.current_shard_id == nil then
			-- Register yourRTM for the given shard.
			RTM:RegisterArrival(zone_uid)
		else
			-- Move from one shard to another.
			RTM:ChangeShard(RTM.current_shard_id, zone_uid)
		end
		
		RTM.current_shard_id = zone_uid
	end
	
	return has_changed
end

-- Called when a target changed event is fired.
function RTM:OnTargetChanged(...)
	if UnitGUID("target") ~= nil then
		-- Get information about the target.
		local guid, name = UnitGUID("target"), UnitName("target")
		local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", guid);
		npc_id = tonumber(npc_id)
		
		if RTM:CheckForShardChange(zone_uid) then
			--print("[Target]", guid)
		end
		
		if RTM.rare_ids_set[npc_id] then
			-- Find the health of the entity.
			local health = UnitHealth("target")
			
			if health > 0 then
				-- Get the current position of the player and the health of the entity.
				local pos = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")
				local x, y = math.floor(pos.x * 10000 + 0.5) / 100, math.floor(pos.y * 10000 + 0.5) / 100
				local percentage = RTM:GetTargetHealthPercentage()
				
				-- Mark the entity as alive and report to your peers.
				RTM:RegisterEntityTarget(RTM.current_shard_id, npc_id, spawn_uid, percentage, x, y)
			else 
				-- Mark the entity has dead and report to your peers.
				RTM:RegisterEntityDeath(RTM.current_shard_id, npc_id, spawn_uid)
			end
		end
	end
end

-- Called when a unit health update event is fired.
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
		
		if RTM:CheckForShardChange(zone_uid) then
			--print("[OnUnitHealth]", guid)
		end
		
		if RTM.rare_ids_set[npc_id] then
			-- Update the current health of the entity.
			local percentage = RTM:GetTargetHealthPercentage()
			
			-- Does the entity have any health left?
			if percentage > 0 then
				-- Report the health of the entity to your peers.
				RTM:RegisterEntityHealth(RTM.current_shard_id, npc_id, spawn_uid, percentage)
			else
				-- Mark the entity has dead and report to your peers.
				RTM:RegisterEntityDeath(RTM.current_shard_id, npc_id, spawn_uid)
			end
		end
	end
end

-- Called when a unit health update event is fired.
function RTM:OnCombatLogEvent(...)
	-- The event does not have a payload (8.0 change). Use CombatLogGetCurrentEventInfo() instead.
	local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
	local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", destGUID);
	npc_id = tonumber(npc_id)
	
	-- We can always check for a shard change.
	-- We only take fights between creatures, since they seem to be the only reliable option.
	if unittype == "Creature" and not RTM.banned_NPC_ids[npc_id] then
		if RTM:CheckForShardChange(zone_uid) then
			--print("[OnCombatLogEvent]", sourceGUID, destGUID)
		end
	end	
		
	if subevent == "UNIT_DIED" then
		if RTM.rare_ids_set[npc_id] then
			-- Mark the entity has dead and report to your peers.
			RTM:RegisterEntityDeath(RTM.current_shard_id, npc_id, spawn_uid)
		end
	end
end	

-- Called when a vignette on the minimap is updated.
function RTM:OnVignetteMinimapUpdated(...)
	vignetteGUID, onMinimap = ...
	vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
	vignetteLocation = C_VignetteInfo.GetVignettePosition(vignetteGUID, C_Map.GetBestMapForUnit("player"))
	
	if not vignetteInfo and RTM.current_shard_id ~= nil then
		-- An entity we saw earlier might have died.
		if RTM.reported_vignettes[vignetteGUID] then
			-- Fetch the npc_id and spawn_uid from our cached data.
			npc_id, spawn_uid = RTM.reported_vignettes[vignetteGUID][1], RTM.reported_vignettes[vignetteGUID][2]
		
			-- Mark the entity has dead and report to your peers.
			RTM:RegisterEntityDeath(RTM.current_shard_id, npc_id, spawn_uid)
		end
	elseif vignetteInfo then
		-- Report the entity.
		local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", vignetteInfo.objectGUID);
		local npc_id = tonumber(npc_id)
		
		if unittype == "Creature" then
			if RTM:CheckForShardChange(zone_uid) then
				--print("[OnVignette]", vignetteInfo.objectGUID)
			end
			
			if RTM.rare_ids_set[npc_id] and not RTM.reported_vignettes[vignetteGUID] then
				RTM.reported_vignettes[vignetteGUID] = {npc_id, spawn_uid}
				
				local x, y = 100 * vignetteLocation.x, 100 * vignetteLocation.y
				RTM:RegisterEntityAlive(RTM.current_shard_id, npc_id, spawn_uid, x, y)
			end
		end
	end
end

-- Called whenever an event occurs that could indicate a zone change.
function RTM:OnZoneTransition()
	-- The zone the player is in.
	local zone_id = C_Map.GetBestMapForUnit("player")
		
	if RTM.target_zones[zone_id] and not RTM.target_zones[RTM.last_zone_id] then
		RTM:StartInterface()	
	elseif not RTM.target_zones[zone_id] then
		RTM:RegisterDeparture(RTM.current_shard_id)
		RTM:CloseInterface()
	end
	
	RTM.last_zone_id = zone_id
end	

-- Called on every addon message received by the addon.
function RTM:OnChatMsgAddon(...)
	local addon_prefix, message, channel, sender = ...

	if addon_prefix == "RTM" then
		local header, payload = strsplit(":", message)
		local prefix, shard_id, addon_version_str = strsplit("-", header)
		local addon_version = tonumber(addon_version_str)

		RTM:OnChatMessageReceived(sender, prefix, shard_id, addon_version, payload)
	end
end	

-- A counter that tracks the time stamp on which the displayed data was updated last. 
RTM.last_display_update = 0

-- Called on every addon message received by the addon.
function RTM:OnUpdate()
	if (RTM.last_display_update + 0.25 < GetServerTime()) then
		for i=1, #RTM.rare_ids do
			local npc_id = RTM.rare_ids[i]
			
			-- It might occur that the rare is marked as alive, but no health is known.
			-- If 20 seconds pass without a health value, the alive tag will be reset.
			if RTM.is_alive[npc_id] and not RTM.current_health[npc_id] and GetServerTime() - RTM.is_alive[npc_id] > 120 then
				RTM.is_alive[npc_id] = nil
			end
			
			-- It might occur that we have both a hp and health, but no changes.
			-- If 2 minutes pass without a health value, the alive and health tags will be reset.
			if RTM.is_alive[npc_id] and RTM.current_health[npc_id] and GetServerTime() - RTM.is_alive[npc_id] > 120 then
				RTM.is_alive[npc_id] = nil
				RTM.current_health[npc_id] = nil
			end
			
			RTM:UpdateStatus(npc_id)
		end
		
		RTM.last_display_update = GetServerTime();
	end
end	

-- Called when the addon loaded event is fired.
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
			if GetServerTime() - RTMDB.previous_records[key].time_stamp > 300 then
				print("<RTM> Removing cached data for shard", (key + 42)..".")
				RTMDB.previous_records[key] = nil
			end
		end
	end
end	

-- Called when the player logs out, such that we can save the current time table for later use.
function RTM:OnPlayerLogout()
	if RTM.current_shard_id then
		-- Save the records, such that we can use them after a reload.
		RTMDB.previous_records[RTM.current_shard_id] = {}
		RTMDB.previous_records[RTM.current_shard_id].time_stamp = GetServerTime()
		RTMDB.previous_records[RTM.current_shard_id].time_table = RTM.last_recorded_death
	end
end

-- Register to the events required for the addon to function properly.
function RTM:RegisterEvents()
	RTM:RegisterEvent("PLAYER_TARGET_CHANGED")
	RTM:RegisterEvent("UNIT_HEALTH")
	RTM:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	RTM:RegisterEvent("CHAT_MSG_ADDON")
	RTM:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
end

-- Unregister from the events, to disable the tracking functionality.
function RTM:UnregisterEvents()
	RTM:UnregisterEvent("PLAYER_TARGET_CHANGED")
	RTM:UnregisterEvent("UNIT_HEALTH")
	RTM:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	RTM:UnregisterEvent("CHAT_MSG_ADDON")
	RTM:UnregisterEvent("VIGNETTE_MINIMAP_UPDATED")
end

-- Create a frame that handles the frame updates of the addon.
RTM.updateHandler = CreateFrame("Frame", "RTM.updateHandler", RTM)
RTM.updateHandler:SetScript("OnUpdate", RTM.OnUpdate)

-- Register the event handling of the frame.
RTM:SetScript("OnEvent", RTM.OnEvent)
RTM:RegisterEvent("ZONE_CHANGED_NEW_AREA")
RTM:RegisterEvent("ZONE_CHANGED")
RTM:RegisterEvent("PLAYER_ENTERING_WORLD")
RTM:RegisterEvent("ADDON_LOADED")
RTM:RegisterEvent("PLAYER_LOGOUT")

-- ####################################################################
-- ##                       Channel Wait Frame                       ##
-- ####################################################################

-- One of the issues encountered is that the chat might be joined before the default channels.
-- In such a situation, the order of the channels changes, which is undesirable.
-- Thus, we block certain events until these chats have been loaded.
RTM.chat_frame_loaded = false

RTM.message_delay_frame = CreateFrame("Frame", "RTM.message_delay_frame", self)
RTM.message_delay_frame.start_time = GetServerTime()
RTM.message_delay_frame:SetScript("OnUpdate", 
	function(self)
		if GetServerTime() - self.start_time > 0 then
			if #{GetChannelList()} == 0 then
				self.start_time = GetServerTime()
			else
				RTM.chat_frame_loaded = true
				self:SetScript("OnUpdate", nil)
				self:Hide()
			end
		end
	end
)
RTM.message_delay_frame:Show()