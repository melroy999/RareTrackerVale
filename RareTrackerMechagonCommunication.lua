local _, data = ...

local RTM = data.RTM;

-- ####################################################################
-- ##                         Communication                          ##
-- ####################################################################

function RTM:findChannelID()
	local n_channels = GetNumDisplayChannels()
	
	for i=1, n_channels do
		SetSelectedDisplayChannel(i)
		name = select(1, GetChannelDisplayInfo(i))
		if name == "RTM" then
			return i
		end
	end
	
	return -1
end