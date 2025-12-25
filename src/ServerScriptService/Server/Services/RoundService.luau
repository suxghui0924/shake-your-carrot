local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Shared.Network)
-- Attempt to get GrowthService; assuming it's a module in the same directory or accessible via _G if lazy loaded.
-- For now, we'll try to require it if we can find it, or use a dependency injection pattern if that's what the loader does.
-- Based on file structure: src/ServerScriptService/Server/Services/GrowthService.luau
local GrowthService = require(script.Parent.GrowthService)

local RoundService = {
    CurrentState = "Intermission",
    TimeLeft = 0,
    IntermissionDuration = 10,
    RoundDuration = 60,
    Running = false,
}

function RoundService:Init()
    -- Initialize listeners if any
    self:Start()
end

function RoundService:Start()
    if self.Running then return end
    self.Running = true
    
    task.spawn(function()
        while self.Running do
            self:GameLoop()
            task.wait()
        end
    end)
    
    print("RoundService Started")
end

function RoundService:GameLoop()
    -- Intermission
    self:SetState("Intermission", self.IntermissionDuration)
    while self.TimeLeft > 0 do
        self.TimeLeft -= 1
        self:BroadcastStatus()
        task.wait(1)
    end
    
    -- Round Start
    self:StartRound()
    
    -- Round In-Progress
    self:SetState("Round", self.RoundDuration)
    while self.TimeLeft > 0 do
        self.TimeLeft -= 1
        self:BroadcastStatus()
        task.wait(1)
    end
    
    -- Round End
    self:EndRound()
end

function RoundService:SetState(state, duration)
    self.CurrentState = state
    self.TimeLeft = duration
    self:BroadcastStatus()
end

function RoundService:BroadcastStatus(message)
    -- Send to all players
    Network.packets.roundStatusUpdate.sendToAll({
        status = self.CurrentState,
        timeLeft = self.TimeLeft,
        message = message
    })
end

function RoundService:StartRound()
    print("Round Starting!")
    self:BroadcastStatus("GO!")
    
    -- Reset all players' growth
    for _, player in ipairs(Players:GetPlayers()) do
        GrowthService:ResetGrowth(player)
        
        -- Optional: Respawn players at spawn points if needed
        -- player:LoadCharacter() 
        -- For now, we just reset their growth as per requirements. 
        -- If they are dead, they will respawn naturally.
    end
end

function RoundService:EndRound()
    print("Round Ended!")
    self:BroadcastStatus("Time's Up!")
    task.wait(3) -- Short delay before intermission
end

return RoundService
