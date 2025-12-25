--[[
    ServerScriptService/Server/Services/PlayerCollisionService.luau
]]

local Players = game:GetService("Players")

local PlayerCollisionService = {}

function PlayerCollisionService:SetCharacterCollisionGroup(character: Model)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Players"
		end
	end
end

function PlayerCollisionService:OnPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		self:SetCharacterCollisionGroup(character)
	end)
end

function PlayerCollisionService:Init()
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
	end)
end

return PlayerCollisionService
