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
    -- print("RoundService Started")
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
	-- print("Round Starting!")
	self:BroadcastStatus("GO!")

	-- Clean/Setup Map Folder
	local mapFolder = workspace:FindFirstChild("Map")
	if not mapFolder then
		mapFolder = Instance.new("Folder")
		mapFolder.Name = "Map"
		mapFolder.Parent = workspace
	else
		mapFolder:ClearAllChildren()
	end

	-- Clone Map
	local mapsFolder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Maps")
	local maps = mapsFolder and mapsFolder:GetChildren() or {}
	local chosenMapCFrame = CFrame.new(0, 50, 0) -- Default fallback

	if #maps > 0 then
		local randomMap = maps[math.random(1, #maps)]
		local clonedMap = randomMap:Clone()
		clonedMap.Parent = mapFolder
		
		-- Default to Map Center if possible
		if clonedMap:IsA("Model") then
			local cframe, size = clonedMap:GetBoundingBox()
			chosenMapCFrame = cframe + Vector3.new(0, size.Y/2 + 5, 0)
		elseif clonedMap:IsA("BasePart") then
			chosenMapCFrame = clonedMap.CFrame + Vector3.new(0, 5, 0)
		end
		
		-- Find Spawn (Priority)
		local spawnLocation = clonedMap:FindFirstChild("Spawn") or clonedMap:FindFirstChild("SpawnLocation")
		if spawnLocation and spawnLocation:IsA("BasePart") then
			chosenMapCFrame = spawnLocation.CFrame + Vector3.new(0, 3, 0)
		end
	end
	
	-- Allow map to replicate/load
	task.wait(2)

	-- Setup Alive Folder
	local aliveFolder = workspace:FindFirstChild("Alive")
	if not aliveFolder then
		aliveFolder = Instance.new("Folder")
		aliveFolder.Name = "Alive"
		aliveFolder.Parent = workspace
	end

	-- Teleport Players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			GrowthService:ResetGrowth(player)
			player:LoadCharacter()
			
			local character = player.Character or player.CharacterAdded:Wait()
			if character then
				character.Parent = aliveFolder
				-- Wait a brief moment to ensure physics exist
				task.wait()
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					-- Pre-load area if streaming enabled (best effort)
					if player then
						pcall(function() player:RequestStreamAroundAsync(chosenMapCFrame.Position) end)
					end
					
					hrp.CFrame = chosenMapCFrame
					
					-- Anchor momentarily to prevent falling through floor
					hrp.Anchored = true
					task.wait(2)
					if hrp then hrp.Anchored = false end
				end
			end
		end)
	end
end

function RoundService:EndRound()
	-- print("Round Ended!")
	self:BroadcastStatus("Time's Up!")
	
	-- Cleanup Map
	local mapFolder = workspace:FindFirstChild("Map")
	if mapFolder then
		mapFolder:ClearAllChildren()
	end

	-- Cleanup Alive Folder Players (Respawn to Lobby)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			player:LoadCharacter()
		end)
	end

	task.wait(3) -- Short delay before intermission
end

return RoundService
