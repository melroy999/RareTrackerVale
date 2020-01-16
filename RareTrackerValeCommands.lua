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
		if RTV.last_zone_id and RTV.target_zones[RTV.last_zone_id] then
			RTV:Show()
			RTVDB.show_window = true
		end
	elseif cmd == "hide" then
		RTV:Hide()
		RTVDB.show_window = false
	else
		InterfaceOptionsFrame_Show()
		InterfaceOptionsFrame_OpenToCategory(RTV.options_panel)
	end
end

-- Register the slashes that can be used to issue commands.
SLASH_RTV1 = "/rtv"
SlashCmdList["RTV"] = CommandHandler
