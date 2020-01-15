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
		if RTU.last_zone_id and RTU.target_zones[RTU.last_zone_id] then
			RTU:Show()
			RTUDB.show_window = true
		end
	elseif cmd == "hide" then
		RTU:Hide()
		RTUDB.show_window = false
	else
		InterfaceOptionsFrame_Show()
		InterfaceOptionsFrame_OpenToCategory(RTU.options_panel)
	end
end

-- Register the slashes that can be used to issue commands.
SLASH_RTU1 = "/rtu"
SlashCmdList["RTU"] = CommandHandler
