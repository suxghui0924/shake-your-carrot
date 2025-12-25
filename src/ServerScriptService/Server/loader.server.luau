local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Loader = require(ReplicatedStorage.Packages:WaitForChild("Loader"))

local ServerFolder = script.Parent

local Services = ServerFolder:FindFirstChild("Services")
local Components = ServerFolder:FindFirstChild("Components")

Loader.SpawnAll(Loader.LoadDescendants(Services), "Init")
Loader.LoadDescendants(Components)
