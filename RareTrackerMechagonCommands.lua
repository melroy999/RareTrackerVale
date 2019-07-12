local _, data = ...

local RTM = data.RTM;

-- ####################################################################
-- ##                        Command Handlers                        ##
-- ####################################################################

function CommandHandler(msg, editbox)
	-- pattern matching that skips leading whitespace and whitespace between cmd and args
	-- any whitespace at end of args is retained
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
   
	if cmd == "show" then
		print("showing interface")
		RTM:Show()
		-- Handle adding of the contents of rest... to something.
	elseif cmd == "hide" then
		print("hiding interface")
		RTM:Hide()
		-- Handle removing of the contents of rest... to something.   
	end
end

SLASH_RT1 = "/rt"
SLASH_RT2 = "/raretracker"
SlashCmdList["RT"] = CommandHandler