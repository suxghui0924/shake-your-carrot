local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)

local Network = require(ReplicatedStorage.Shared.Network)
local QuestUI = require(script.Parent.Parent.Components.UI.QuestUI)

local QuestController = {
	scope = nil,
	quests = nil,
	isVisible = nil,
}

function QuestController:Init()
	self.scope = Fusion.scoped({})
	self.quests = self.scope:Value({})
	self.isVisible = self.scope:Value(false)

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
