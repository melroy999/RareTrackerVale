-- ####################################################################
-- ##                        Command Handlers                        ##
-- ####################################################################

-- Process the given command.
-- msg, editbox
function CommandHandler(msg, _)
	-- pattern matching that skips leading whitespace and whitespace between cmd and args
	-- any whitespace at end of args is retained
  -- _, _, cmd, args
	local _, _, cmd, _ = string.find(msg, "%s?(%w+)%s?(.*)")
   
	if cmd == "show" then
		if RTM.last_zone_id and RTM.target_zones[RTM.last_zone_id] then
			RTM:Show()
			RTMDB.show_window = true
		end
	elseif cmd == "hide" then
		RTM:Hide()
		RTMDB.show_window = false
	else
		InterfaceOptionsFrame_Show()
		InterfaceOptionsFrame_OpenToCategory(RTM.options_panel)
	end
end

-- Register the slashes that can be used to issue commands.
SLASH_RTM1 = "/rtm"
SlashCmdList["RTM"] = CommandHandler