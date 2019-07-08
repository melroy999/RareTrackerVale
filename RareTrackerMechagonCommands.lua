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
		channel_id = RTM:findChannelID()
		if channel_id == -1 then return end
		
		SetSelectedDisplayChannel(channel_id)
		count = select(5, GetChannelDisplayInfo(channel_id))
		print(channel_id, count)

		for i=1, count do
			print(channel_id, i)
			name, owner, moderator, guid = C_ChatInfo.GetChannelRosterInfo(channel_id, i)
			print(name, owner, moderator, guid)
		end
	end
end

SLASH_RT1 = "/rt"
SLASH_RT2 = "/raretracker"
SlashCmdList["RT"] = CommandHandler