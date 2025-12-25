local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = workspace

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Fusion = require(Packages.Fusion)
local scope = Fusion.scoped(Fusion)

local FusionFolder = LocalPlayer.PlayerScripts:WaitForChild("Fusion")
local Components = FusionFolder:WaitForChild("Components")
local SoftShutdownComponent = require(Components:WaitForChild("SoftShutdownComponent"))

Workspace:GetAttributeChangedSignal("ShuttingDown"):Connect(function()
	local isShutdown = Workspace:GetAttribute("ShuttingDown")
	if isShutdown then
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		end)

		SoftShutdownComponent.new({
            scope = scope,
			Parent = PlayerGui
		})
	end
end)
