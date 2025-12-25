local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local PlayerDataService = require(script.Parent.PlayerDataService)
local Network = require(ReplicatedStorage.Shared.Network)

local QuestService = {
	QuestDefinitions = {
		{ Id = "Shake100", Title = "Shake Carrot 100 Times", Target = 100, Reward = 500, Type = "Shake" },
		{ Id = "Kill10", Title = "Kill 10 Players", Target = 10, Reward = 1000, Type = "Kill" },
		{ Id = "Die5", Title = "Die 5 Times", Target = 5, Reward = 300, Type = "Death" },
	}
}

function QuestService:Init()
	-- Listen for Claim Requests
	Network.packets.claimQuestReward.listen(function(data, player)
		self:ClaimReward(player, data.questId)
	end)
	
	-- Hook into PlayerDataService (or listen to player added here if PDS doesn't expose hook)
	-- We'll just use PlayerAdded and wait for data load
	Players.PlayerAdded:Connect(function(player)
		local attempts = 0
		while not player:GetAttribute("DataLoaded") and attempts < 10 do
			task.wait(1)
			attempts += 1
		end
		
		if player:GetAttribute("DataLoaded") then
			self:AssignDailyQuests(player)
		end
	end)
end

function QuestService:AssignDailyQuests(player)
	local profileData = PlayerDataService:GetData(player)
	if not profileData then return end
	
	local lastLogin = profileData.DailyQuests.LastLogin
	local currentDay = math.floor(os.time() / 86400) -- Simple day check
	
	local quests = profileData.DailyQuests.Quests
	
	-- Reset if new day
	if lastLogin ~= currentDay then
		-- print("New Day! Resetting quests for " .. player.Name)
		profileData.DailyQuests.LastLogin = currentDay
		profileData.DailyQuests.Quests = {} -- Reset
		
		-- Assign all defined quests for now (or pick random)
		for _, def in ipairs(self.QuestDefinitions) do
			profileData.DailyQuests.Quests[def.Id] = {
				Progress = 0,
				Completed = false,
				Claimed = false
			}
		end
	else
		-- Ensure missing quests are added (if we added new ones)
		for _, def in ipairs(self.QuestDefinitions) do
			if not profileData.DailyQuests.Quests[def.Id] then
				profileData.DailyQuests.Quests[def.Id] = {
					Progress = 0,
					Completed = false,
					Claimed = false
				}
			end
		end
	end
	
	self:SendUpdate(player)
end

function QuestService:UpdateProgress(player, type, amount)
	local profileData = PlayerDataService:GetData(player)
	if not profileData then return end
	
	local updated = false
	for _, def in ipairs(self.QuestDefinitions) do
		if def.Type == type then
			local questData = profileData.DailyQuests.Quests[def.Id]
			if questData and not questData.Completed then
				questData.Progress += (amount or 1)
				if questData.Progress >= def.Target then
					questData.Progress = def.Target
					questData.Completed = true
					-- Notify completion?
				end
				updated = true
			end
		end
	end
	
	if updated then
		self:SendUpdate(player)
	end
end

function QuestService:ClaimReward(player, questId)
	local profileData = PlayerDataService:GetData(player)
	if not profileData then return end
	
	local questData = profileData.DailyQuests.Quests[questId]
	if not questData or not questData.Completed or questData.Claimed then
		return
	end
	
	-- Find Definition
	local rewardAmount = 0
	for _, def in ipairs(self.QuestDefinitions) do
		if def.Id == questId then
			rewardAmount = def.Reward
			break
		end
	end
	
	if rewardAmount > 0 then
		questData.Claimed = true
		PlayerDataService:UpdateData(player, "Money", profileData.Money + rewardAmount)
		PlayerDataService:UpdateLeaderstats(player, "Money", profileData.Money) -- Sync leaderstats
		self:SendUpdate(player)
	end
end

function QuestService:SendUpdate(player)
	local profileData = PlayerDataService:GetData(player)
	if not profileData then return end
	
	-- Structure for Client
	local clientQuests = {}
	for _, def in ipairs(self.QuestDefinitions) do
		local data = profileData.DailyQuests.Quests[def.Id]
		table.insert(clientQuests, {
			Id = def.Id,
			Title = def.Title,
			Target = def.Target,
			Reward = def.Reward,
			Progress = data.Progress,
			Completed = data.Completed,
			Claimed = data.Claimed
		})
	end
	
	Network.packets.questUpdate.sendTo(player, {
		quests = HttpService:JSONEncode(clientQuests)
	})
end

return QuestService
