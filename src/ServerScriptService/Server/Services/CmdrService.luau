local ServerStorage = game:GetService("ServerStorage")
local Cmdr = require(ServerStorage.ServerPackages.Cmdr)

local Commands = ServerStorage.Cmdr.Commands
local Hooks = ServerStorage.Cmdr.Hooks
local Types = ServerStorage.Cmdr.Types

local CmdrController = {}

function CmdrController:Init()
	Cmdr:RegisterDefaultCommands()
	Cmdr:RegisterCommandsIn(Commands)
	Cmdr:RegisterHooksIn(Hooks)
	Cmdr:RegisterTypesIn(Types)
end

return CmdrController
