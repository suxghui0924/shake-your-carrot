local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Network = require(ReplicatedStorage.Shared.Network)
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Fusion = require(Packages.Fusion)

local AnnouncerUI = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("UI"):WaitForChild("AnnouncerUI"))

local RoundController = {}
local scope = Fusion.scoped(Fusion)
local status = scope:Value("Intermission")
local timeLeft = scope:Value(0)
local message = scope:Value("")
local stats = scope:Value(nil)

function RoundController:Init()
    -- Mount the UI
    AnnouncerUI.new({
        scope = scope,
        Parent = PlayerGui,
        status = status,
        timeLeft = timeLeft,
        message = message,
		stats = stats
    })
    
    -- Listen for updates
    Network.packets.roundStatusUpdate.listen(function(data)
        status:set(data.status)
        timeLeft:set(data.timeLeft)
        
		if data.message then
            message:set(data.message)
        else
            message:set("")
        end
		
		if data.stats then
			local success, decoded = pcall(function() return HttpService:JSONDecode(data.stats) end)
			if success then
				stats:set(decoded)
			else
				stats:set(nil)
			end
		else
			stats:set(nil)
		end
    end)
    
    -- print("RoundController Initialized")
end

return RoundController
