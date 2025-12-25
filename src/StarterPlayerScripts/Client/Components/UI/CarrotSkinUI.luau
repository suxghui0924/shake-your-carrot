local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)
local Trove = require(Packages.Trove)

local Children = Fusion.Children
local peek = Fusion.peek

-- Sub-Components
local UI = script.Parent.CarrotSkin
local ProfileHUD = require(UI.ProfileHUD)
local Navigation = require(UI.Navigation)
local MainWindow = require(UI.MainWindow)

local CarrotSkinUI = {}
CarrotSkinUI.__index = CarrotSkinUI

function CarrotSkinUI.new()
	local self = setmetatable({}, CarrotSkinUI)
	self._trove = Trove.new()
	self:Init()
	return self
end

function CarrotSkinUI:Init()
	local player = Players.LocalPlayer
	-- Wait for player to be ready? Usually fine in StarterPlayerScripts.
	
	self.Scope = Fusion.scoped(Fusion)
	
	-- [[ STATE ]]
	self.IsOpen = self.Scope:Value(false)
	self.Tab = self.Scope:Value("Skins") -- "Skins" | "Shop"
	self.SelectedSkin = self.Scope:Value("Default")
	
	-- Player Attributes
	self.EquippedSkin = self.Scope:Value(player:GetAttribute("EquippedSkin") or "Default")
	self.Coins = self.Scope:Value(player:GetAttribute("Money") or 0)
	self.CarrotScale = self.Scope:Value(player:GetAttribute("CarrotScale") or 1.0)
	
	-- Helper
	local function getUnlockedSkins()
		local attr = player:GetAttribute("UnlockedSkins")
		if type(attr) == "string" then
			local success, result = pcall(function() return HttpService:JSONDecode(attr) end)
			if success and type(result) == "table" then return result end
		end
		return {"Default"}
	end
	
	self.UnlockedSkins = self.Scope:Value(getUnlockedSkins())
	
	-- Listeners
	self._trove:Connect(player.AttributeChanged, function(attr)
		if attr == "EquippedSkin" then self.EquippedSkin:set(player:GetAttribute(attr))
		elseif attr == "UnlockedSkins" then self.UnlockedSkins:set(getUnlockedSkins())
		elseif attr == "Money" then self.Coins:set(player:GetAttribute(attr))
		elseif attr == "CarrotScale" then self.CarrotScale:set(player:GetAttribute(attr))
		end
	end)
	
	-- Rotation Loop for 3D Previews
	self.PreviewRotation = self.Scope:Value(0)
	self._trove:Connect(RunService.RenderStepped, function(dt)
		if peek(self.IsOpen) then
			-- Rotate 45 degrees per second
			self.PreviewRotation:set(peek(self.PreviewRotation) + dt * 45) 
		end
	end)

    -- Props Table
    local props = {
        player = player,
        IsOpen = self.IsOpen,
        Tab = self.Tab,
        SelectedSkin = self.SelectedSkin,
        EquippedSkin = self.EquippedSkin,
        Coins = self.Coins,
        CarrotScale = self.CarrotScale,
        UnlockedSkins = self.UnlockedSkins,
        PreviewRotation = self.PreviewRotation,
    }

	-- [[ RENDER ]]
	local gui = self.Scope:New "ScreenGui" {
		Name = "CarrotSkinUI",
		Parent = player:WaitForChild("PlayerGui"),
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 10,
		
		[Children] = {
			ProfileHUD.new(self.Scope, props),
			Navigation.new(self.Scope, props),
			MainWindow.new(self.Scope, props)
		}
	}
	
	self._trove:Add(gui)
end

-- Singleton Init
CarrotSkinUI.new()

return CarrotSkinUI
