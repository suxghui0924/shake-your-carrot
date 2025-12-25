local GetServerType = {}

function GetServerType.getServerType()
	if game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0 then
		return "VIPServer"
	elseif game.PrivateServerId ~= "" then
		return "ReservedServer"
	else
		return "StandardServer"
	end
end

return GetServerType
