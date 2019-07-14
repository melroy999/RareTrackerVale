local _, data = ...

local RTM = data.RTM

-- ####################################################################
-- ##                        Command Handlers                        ##
-- ####################################################################

function CommandHandler(msg, editbox)
	-- pattern matching that skips leading whitespace and whitespace between cmd and args
	-- any whitespace at end of args is retained
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
   
	if cmd == "show" then
		if RTM.last_zone_id and RTM.target_zones[RTM.last_zone_id] then
			RTM:Show()
			RTMDB.show_window = true
		end
	elseif cmd == "hide" then
		RTM:Hide()  
		RTMDB.show_window = false
	end
end

SLASH_RTM1 = "/rtm"
SlashCmdList["RTM"] = CommandHandler