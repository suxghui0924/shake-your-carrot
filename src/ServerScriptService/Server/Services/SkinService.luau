local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Network = require(ReplicatedStorage.Shared.Network)
local CarrotSkins = require(ReplicatedStorage.Shared.Data.CarrotSkins)

local PlayerDataService = nil -- Will be required in Init

local SkinService = {}

function SkinService:Init()
	PlayerDataService = require(script.Parent.PlayerDataService)
	
	-- Listen for skin equip requests
	Network.packets.equipSkin.listen(function(data, player)
		self:EquipSkin(player, data.skinId)
	end)

	-- Listen for skin purchase requests (Coins)
	Network.packets.buySkin.listen(function(data, player)
		self:BuySkin(player, data.skinId)
	end)
	
	-- Apply skin when player joins
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			-- Wait for data to be ready
			local profileData = PlayerDataService:GetData(player)
			while not profileData do
				task.wait(0.1)
				profileData = PlayerDataService:GetData(player)
			end
			
			-- Set initial attributes for UI
			player:SetAttribute("EquippedSkin", profileData.EquippedSkin)
			player:SetAttribute("Money", profileData.Money)
			
			-- Apply to character tools if player already has them
			if player.Character then
				self:ApplySkinToPlayerTools(player)
			end
		end)

		player.CharacterAdded:Connect(function(character)
			task.wait(0.5) -- Wait for tools to load
			self:ApplySkinToPlayerTools(player)
		end)
	end)
	
	-- Apply skin when carrot tool is added
	CollectionService:GetInstanceAddedSignal("Carrot"):Connect(function(instance)
		if instance:IsA("Tool") then
			task.wait()
			local player = self:GetToolOwner(instance)
			if player then
				local profileData = PlayerDataService:GetData(player)
				if profileData then
					self:ApplySkinToTool(instance, profileData.EquippedSkin)
				end
			end
		end
	end)
end

function SkinService:EquipSkin(player, skinId)
	-- Validate skin exists
	if not CarrotSkins[skinId] then
		warn("Invalid skin ID:", skinId)
		return
	end
	
	-- Get player data
	local profileData = PlayerDataService:GetData(player)
	if not profileData then
		warn("No profile data for player:", player.Name)
		return
	end
	
	-- Check if skin is unlocked
	local isUnlocked = table.find(profileData.UnlockedSkins, skinId)
	if not isUnlocked then
		warn("Skin not unlocked:", skinId, "for player:", player.Name)
		return
	end
	
	-- Update equipped skin
	profileData.EquippedSkin = skinId
	player:SetAttribute("EquippedSkin", skinId)
	
	-- Apply to all current tools
	self:ApplySkinToPlayerTools(player)
	
	print("Equipped skin:", skinId, "for player:", player.Name)
end

function SkinService:BuySkin(player, skinId)
	-- Validate skin exists
	local skinData = CarrotSkins[skinId]
	if not skinData then
		warn("Invalid skin ID:", skinId)
		return
	end

	-- Get player data
	local profileData = PlayerDataService:GetData(player)
	if not profileData then return end

	-- Check if already unlocked
	if table.find(profileData.UnlockedSkins, skinId) then
		warn("Skin already unlocked:", skinId)
		return
	end

	-- Check price
	local price = skinData.CoinPrice or 0
	if profileData.Money < price then
		warn("Not enough coins for skin:", skinId)
		return
	end

	-- Purchase
	profileData.Money -= price
	table.insert(profileData.UnlockedSkins, skinId)
	
	-- Update attributes
	player:SetAttribute("Money", profileData.Money)
	
	print("Player", player.Name, "bought skin", skinId, "for", price, "coins")
end

function SkinService:ApplySkinToPlayerTools(player)
	local profileData = PlayerDataService:GetData(player)
	if not profileData then return end
	
	local skinId = profileData.EquippedSkin
	
	-- We need to REPLACE the tool, not just color it
	-- Remove old tools and give new one
	
	local character = player.Character
	if character then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") and CollectionService:HasTag(tool, "Carrot") then
				tool:Destroy()
			end
		end
	end
	
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and CollectionService:HasTag(tool, "Carrot") then
				tool:Destroy()
			end
		end
	end
	
	-- Give new tool
	self:GiveSkinTool(player, skinId)
end

function SkinService:GiveSkinTool(player, skinId)
	local skinData = CarrotSkins[skinId]
	if not skinData then return end
	
	-- Find asset
	local target = game
	for _, part in ipairs(string.split(skinData.AssetPath, ".")) do
		target = target:FindFirstChild(part)
		if not target then break end
	end
	
	if target and target:IsA("Tool") then
		local newTool = target:Clone()
		CollectionService:AddTag(newTool, "Carrot") -- Ensure tag is present
		
		-- Give to backpack or character? Default to Backpack unless handled otherwise
		-- If player has no tool currently held, maybe auto-equip? For now, Backpack.
		newTool.Parent = player:FindFirstChild("Backpack")
	else
		warn("Could not find tool asset for skin:", skinId, "Path:", skinData.AssetPath)
	end
end

function SkinService:ApplySkinToTool(tool, skinId)
	-- Deprecated in favor of replacement, but kept for compatibility if needed.
	-- Actually, let's redirect to replacement if it's a fresh spawn case?
	-- For simplicity, we just won't call this anymore from EquipSkin.
end

function SkinService:GetToolOwner(tool)
	local parent = tool.Parent
	if parent:IsA("Model") and Players:GetPlayerFromCharacter(parent) then
		return Players:GetPlayerFromCharacter(parent)
	elseif parent:IsA("Backpack") and parent.Parent:IsA("Player") then
		return parent.Parent
	end
	return nil
end

function SkinService:Start()
	print("SkinService Started")
end

return SkinService
