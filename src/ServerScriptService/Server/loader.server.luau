local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Loader = require(ReplicatedStorage.Packages:WaitForChild("Loader"))

local ServerFolder = script.Parent

local Services = ServerFolder:FindFirstChild("Services")
local Components = ServerFolder:FindFirstChild("Components")

if Services then
	Loader.SpawnAll(Loader.LoadDescendants(Services), "Init")
end

if Components then
	Loader.LoadDescendants(Components)
end
