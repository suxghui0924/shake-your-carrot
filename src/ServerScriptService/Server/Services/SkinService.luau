local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Network = require(ReplicatedStorage.Shared.Network)
local ProfileTemplateModule = require(ReplicatedStorage.Shared.Data.ProfileTemplate)
local CarrotSkins = ProfileTemplateModule.Skins

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
		self:OnPlayerAdded(player)
	end)
	
	-- Handle existing players (Fix for Studio race condition)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:OnPlayerAdded(player)
		end)
	end
	
	-- Apply skin when carrot tool is added (to overwrite or skin it if needed)
	-- NOTE: This might conflict with GiveSkinTool if we are not careful, but let's keep it safe.
	CollectionService:GetInstanceAddedSignal("Carrot"):Connect(function(instance)
		if instance:IsA("Tool") then
			-- Ensure we don't skin-loop
			-- task.wait() 
			-- Check if it needs skinning? 
			-- Actually currently GiveSkinTool sets the skin already. 
			-- This listener might be redundant or for tools spawned by other means.
		end
	end)
end

function SkinService:OnPlayerAdded(player)
	task.spawn(function()
		-- print("[SkinService] Player added processing:", player.Name)
		
		-- Wait for data to be ready
		local profileData = PlayerDataService:GetData(player)
		local retries = 0
		while not profileData and retries < 50 do
			task.wait(0.2)
			profileData = PlayerDataService:GetData(player)
			retries += 1
		end
		
		if not profileData then
			warn("[SkinService] Failed to load data for:", player.Name)
			return
		end
		
		local HttpService = game:GetService("HttpService")

		-- Set initial attributes for UI
		-- Set initial attributes for UI
		self:UpdateAttributes(player, profileData)
		
		-- print("[SkinService] Data loaded for:", player.Name, "Skin:", profileData.EquippedSkin)

		-- Apply to character tools if player already has them
		if player.Character then
			self:ApplySkinToPlayerTools(player)
		end
		
		player.CharacterAdded:Connect(function(character)
			-- print("[SkinService] Character spawned:", player.Name)
			task.wait(1) -- Wait a bit longer for default Roblox tools to load if any
			self:ApplySkinToPlayerTools(player)
		end)
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
	-- Update equipped skin
	profileData.EquippedSkin = skinId
	self:UpdateAttributes(player, profileData)
	
	-- Apply to all current tools
	self:ApplySkinToPlayerTools(player)
	
	-- print("Equipped skin:", skinId, "for player:", player.Name)
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
	self:UpdateAttributes(player, profileData)
	
	-- print("Player", player.Name, "bought skin", skinId, "for", price, "coins")
end

function SkinService:UpdateAttributes(player, profileData)
	player:SetAttribute("Money", profileData.Money)
	player:SetAttribute("EquippedSkin", profileData.EquippedSkin)
	
	local HttpService = game:GetService("HttpService")
	local func, err = pcall(function()
		local json = HttpService:JSONEncode(profileData.UnlockedSkins)
		player:SetAttribute("UnlockedSkins", json)
	end)
	if not func then warn("Failed to encode UnlockedSkins:", err) end
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
	if not skinData then 
		warn("[SkinService] ID not found in data:", skinId)
		return 
	end
	
	-- Robust Asset Finding
	local function getAssetFromPath(path)
		local segments = string.split(path, ".")
		local current = game
		for _, segment in ipairs(segments) do
			current = current:FindFirstChild(segment)
			if not current then return nil end
		end
		return current
	end
	
	local target = getAssetFromPath(skinData.AssetPath)
	
	if not target then
		-- Fallback: Try searching by Name in Carrots folder
		local folder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Carrots")
		if folder then
			target = folder:FindFirstChild(skinData.Name)
		end
	end
	
	-- Fallback 2: Recursively search ReplicatedStorage for any Tool with the matching Name
	if not target then
		local function findToolRecursive(parent, name)
			for _, child in ipairs(parent:GetChildren()) do
				if child:IsA("Tool") and child.Name == name then
					return child
				end
				local found = findToolRecursive(child, name)
				if found then return found end
			end
			return nil
		end
		
		target = findToolRecursive(ReplicatedStorage, skinData.Name)
	end
	
	-- Fallback 3: Check if asset path was relative to ReplicatedStorage but misspelled (Old logic kept as backup)
	if not target then
		local cleanPath = string.gsub(skinData.AssetPath, "^ReplicatedStorage%.", "")
		target = ReplicatedStorage:FindFirstChild(cleanPath, true) 
	end

	if target and target:IsA("Tool") then
		local newTool = target:Clone()
		CollectionService:AddTag(newTool, "Carrot") 
		newTool.Name = "Carrot" -- Normalize name for scripts that look for "Carrot"
		
		-- Equip Logic
		local character = player.Character
		if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
			newTool.Parent = player.Backpack
			character.Humanoid:EquipTool(newTool) -- Force equip
		else
			newTool.Parent = player:FindFirstChild("Backpack")
		end
		
		-- print("[SkinService] Successfully found and gave skin:", skinId, "found at:", target:GetFullName())
	else
		warn("[SkinService] CRITICAL: Tool asset missing for:", skinId, "Path:", skinData.AssetPath)
		
		-- EMERGENCY FALLBACK: Create a dummy tool so game doesn't break
		local dummy = Instance.new("Tool")
		dummy.Name = "Carrot"
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(1, 2, 1)
		handle.BrickColor = BrickColor.new("Bright orange")
		handle.Parent = dummy
		CollectionService:AddTag(dummy, "Carrot")
		dummy.Parent = player:FindFirstChild("Backpack")
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
	-- print("SkinService Started")
end

return SkinService
