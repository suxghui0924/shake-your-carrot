local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Network = require(ReplicatedStorage.Shared.Network)
-- Attempt to get GrowthService; assuming it's a module in the same directory or accessible via _G if lazy loaded.
-- For now, we'll try to require it if we can find it, or use a dependency injection pattern if that's what the loader does.
-- Based on file structure: src/ServerScriptService/Server/Services/GrowthService.luau
-- Based on file structure: src/ServerScriptService/Server/Services/GrowthService.luau
local GrowthService = require(script.Parent.GrowthService)
local QuestService = require(script.Parent.QuestService)

local RoundService = {
    CurrentState = "Intermission",
    TimeLeft = 0,
    IntermissionDuration = 5,
    RoundDuration = 10,
    Running = false,
	RoundStats = {}, -- [UserId] = { Name = "", Kills = 0, Deaths = 0 }
}



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

function RoundService:BroadcastStatus(message, stats)
    -- Send to all players
    Network.packets.roundStatusUpdate.sendToAll({
        status = self.CurrentState,
        timeLeft = self.TimeLeft,
        message = message,
		stats = stats
    })
end

function RoundService:StartRound()
	-- print("Round Starting!")
	self.RoundStats = {}
    for _, player in ipairs(Players:GetPlayers()) do
        self.RoundStats[player.UserId] = { Name = player.Name, Kills = 0, Deaths = 0 }
    end
	
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
		
		-- Find Spawn (Priority: Spawns Folder > Spawn Part)
		local spawnsFolder = clonedMap:FindFirstChild("Spawns")
		local singleSpawn = clonedMap:FindFirstChild("Spawn") or clonedMap:FindFirstChild("SpawnLocation")
		
		if spawnsFolder and spawnsFolder:IsA("Folder") then
			local spawns = spawnsFolder:GetChildren()
			if #spawns > 0 then
				local randomSpawn = spawns[math.random(1, #spawns)]
				if randomSpawn:IsA("BasePart") then
					chosenMapCFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0)
				end
			end
		elseif singleSpawn and singleSpawn:IsA("BasePart") then
			chosenMapCFrame = singleSpawn.CFrame + Vector3.new(0, 3, 0)
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
	
	self.CurrentMapSpawnCFrame = chosenMapCFrame

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

function RoundService:OnPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		-- Connect Death Listener for Kill Tracking
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			humanoid.Died:Connect(function()
				if self.CurrentState == "Round" then
					-- Record Death
					if not self.RoundStats[player.UserId] then
						self.RoundStats[player.UserId] = { Name = player.Name, Kills = 0, Deaths = 0 }
					end
					self.RoundStats[player.UserId].Deaths += 1
					
					-- Check for Killer
					local creator = humanoid:FindFirstChild("creator")
					if creator and creator.Value and creator.Value:IsA("Player") then
						local killer = creator.Value
						if not self.RoundStats[killer.UserId] then
							self.RoundStats[killer.UserId] = { Name = killer.Name, Kills = 0, Deaths = 0 }
						end
						self.RoundStats[killer.UserId].Kills += 1
						
						-- Quest Progress (Kill)
						QuestService:UpdateProgress(killer, "Kill", 1)
					end
					
					-- Quest Progress (Death)
					QuestService:UpdateProgress(player, "Death", 1)
				end
			end)
		end
		
		if self.CurrentState == "Round" and self.CurrentMapSpawnCFrame then
			-- Handle Respawn Logic during Round
			task.spawn(function()
				task.wait() -- Wait for character initialization
				
				local aliveFolder = workspace:FindFirstChild("Alive")
				if aliveFolder then
					character.Parent = aliveFolder
				end
				
				local hrp = character:WaitForChild("HumanoidRootPart", 5)
				if hrp then
					task.wait(0.1) -- extra safety
					hrp.CFrame = self.CurrentMapSpawnCFrame
					
					-- Anchor momentarily
					hrp.Anchored = true
					task.wait(2)
					if hrp then hrp.Anchored = false end
				end
			end)
		end
	end)
end

function RoundService:Init()
	-- Initialize listeners if any
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
	end)
	
	for _, player in ipairs(Players:GetPlayers()) do
		self:OnPlayerAdded(player)
	end
	
	self:Start()
end

function RoundService:EndRound()
	-- print("Round Ended!")
	
	-- Compile Stats
	local statsList = {}
	for _, data in pairs(self.RoundStats) do
		table.insert(statsList, data)
	end
	table.sort(statsList, function(a,b) return a.Kills > b.Kills end)
	
	local jsonStats = HttpService:JSONEncode(statsList)
	
	self:BroadcastStatus("GAME OVER", jsonStats)
	
	-- Immediately move all players out of Alive folder to disable PVP
	local aliveFolder = workspace:FindFirstChild("Alive")
	if aliveFolder then
		for _, char in ipairs(aliveFolder:GetChildren()) do
			char.Parent = workspace
		end
	end
	
	-- Wait for Game Over screen
	task.wait(5)
	
	-- Teleport Players to Lobby (Don't Kill)
	local lobbyCFrame = CFrame.new(0, 50, 0)
	-- Try to find actual lobby spawn
	local spawn = workspace:FindFirstChild("SpawnLocation")
	if spawn then
		lobbyCFrame = spawn.CFrame + Vector3.new(0,5,0)
	end
	
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local human = char and char:FindFirstChild("Humanoid")
			
			if char and hrp and human and human.Health > 0 then
				hrp.CFrame = lobbyCFrame
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
				-- Heal them? Optional.
				human.Health = human.MaxHealth
			else
				player:LoadCharacter()
			end
		end)
	end
    
    task.wait(1) -- Safety wait to ensure players are out
	
	-- Cleanup Map
	local mapFolder = workspace:FindFirstChild("Map")
	if mapFolder then
		mapFolder:ClearAllChildren()
	end
	
	-- Reset Stats
	self.RoundStats = {}

	task.wait(3) -- Short delay before intermission
end

return RoundService
