local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

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

function RoundController:Init()
    -- Mount the UI
    AnnouncerUI.new({
        scope = scope,
        Parent = PlayerGui,
        status = status,
        timeLeft = timeLeft,
        message = message
    })
    
    -- Listen for updates
    Network.packets.roundStatusUpdate.listen(function(data)
        status:set(data.status)
        timeLeft:set(data.timeLeft)
        if data.message then
            message:set(data.message)
            -- Clear message after a short time if it's a specific alert (optional, depending on UX)
            -- For now, the server sends a message, and if the next update doesn't have it, it might clear?
            -- Actually, the server sends `message` as optional. If we receive nil, `message:set(nil)` won't clear the value if we don't handle it.
            -- Let's assume if data.message is nil, we should probably clear it if we want it to be transient, 
            -- OR we only update if it's present.
            -- Better approach: Server sends explicit empty string or nil. 
            -- If server sends nil, we might want to keep the old message? No, usually updates are snapshots.
            -- If data.message is nil, we should probably set it to empty string or nil to clear old messages.
        else
            message:set("")
        end
    end)
    
    -- print("RoundController Initialized")
end

return RoundController
