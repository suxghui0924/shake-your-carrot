local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Loader = require(ReplicatedStorage.Packages:WaitForChild("Loader"))

local ClientFolder = script.Parent

local Controllers = ClientFolder:WaitForChild("Controllers")
local Components = ClientFolder:WaitForChild("Components")

Loader.SpawnAll(Loader.LoadDescendants(Controllers), "Init")
Loader.LoadDescendants(Components)
