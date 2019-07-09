local _, data = ...

local RTM = data.RTM;

-- ####################################################################
-- ##                        Command Handlers                        ##
-- ####################################################################

function CommandHandler(msg, editbox)
	-- pattern matching that skips leading whitespace and whitespace between cmd and args
	-- any whitespace at end of args is retained
	print(msg)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
   
	if cmd == "show" then
		print("showing interface")
		RTM:Show()
		-- Handle adding of the contents of rest... to something.
	elseif cmd == "hide" then
		print("hiding interface")
		RTM:Hide()
		-- Handle removing of the contents of rest... to something.   
	elseif cmd == "channel" then
		
		-- print(RTM.channel_id)
		-- 
		-- SetSelectedDisplayChannel(RTM.channel_id)
		-- count = select(5, GetChannelDisplayInfo(RTM.channel_id))
		-- print(RTM.channel_id, count)
		-- print(GetChannelName("RTM"))
		-- 
		-- id, name = GetChannelName("RTM")
		-- print(id, name)
		
		C_ChatInfo.SendAddonMessage("RTM", "Test", "CHANNEL", select(1, GetChannelName("RTM")))
	end
end

SLASH_RT1 = "/rt"
SLASH_RT2 = "/raretracker"
SlashCmdList["RT"] = CommandHandler