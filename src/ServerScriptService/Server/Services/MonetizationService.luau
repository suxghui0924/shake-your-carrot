local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Monetizations = require(Shared.Monetizations)

-- We need PlayerDataService to grant items/coins
local PlayerDataService

local MonetizationService = {}

function MonetizationService:ProcessReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId
	local productData = Monetizations.Products[productId]

	if not productData then
		warn("[MonetizationService] Unknown product ID:", productId)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if not PlayerDataService then
		local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
		PlayerDataService = require(Server:WaitForChild("Services"):WaitForChild("PlayerDataService"))
	end

	local profileData = PlayerDataService:GetData(player)
	if not profileData then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Grant reward based on type
	if productData.Type == "Coins" then
		local amount = productData.Amount or 0
		profileData.Money += amount
		player:SetAttribute("Money", profileData.Money)
		print("[MonetizationService] Granted", amount, "coins to", player.Name)
	elseif productData.Type == "Skin" then
		local skinId = productData.SkinId
		if not table.find(profileData.UnlockedSkins, skinId) then
			table.insert(profileData.UnlockedSkins, skinId)
			print("[MonetizationService] Unlocked skin", skinId, "for", player.Name)
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService:Init()
	 MarketplaceService.ProcessReceipt = function(receiptInfo)
		local status, result = pcall(function()
			return self:ProcessReceipt(receiptInfo)
		end)
		if not status then
			warn("[MonetizationService] Error processing receipt:", result)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		return result
	end
end

return MonetizationService
