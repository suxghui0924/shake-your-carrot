local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Monetizations = require(ReplicatedStorage.Shared.Monetizations)

local MonetizationService = {}

function MonetizationService:ProcessReceipt(receiptInfo)
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId

	if Monetizations.Products[productId] then
		print("[MonetizationService] Product purchased:", productId, "by player:", player.Name)
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService:Init()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:ProcessReceipt(receiptInfo)
	end
end

return MonetizationService
