local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)
local Value = Fusion.Value

local Network = require(ReplicatedStorage.Shared.Network)
local QuestUI = require(script.Parent.Parent.Components.UI.QuestUI)

local QuestController = {
	scope = Fusion.scoped({}),
	quests = Value({}),
	isVisible = Value(false),
}

function QuestController:Init()
	-- Mount UI
	QuestUI.new({
		scope = self.scope,
		Parent = Players.LocalPlayer.PlayerGui,
		quests = self.quests,
		isVisible = self.isVisible,
		onClaim = function(questId)
			Network.packets.claimQuestReward.send({
				questId = questId
			})
		end,
		onToggle = function()
			self.isVisible:set(not self.isVisible:get())
		end
	})
	
	-- Listen for Updates
	Network.packets.questUpdate.listen(function(data)
		local success, decoded = pcall(function()
			return HttpService:JSONDecode(data.quests)
		end)
		
		if success and decoded then
			self.quests:set(decoded)
		end
	end)
end

function QuestController:OnStart()
	self:Init()
end

return QuestController
