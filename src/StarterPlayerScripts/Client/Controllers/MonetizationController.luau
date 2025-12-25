local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Monetizations = require(ReplicatedStorage.Shared.Monetizations)

local SoundController = require(script.Parent.SoundController)
local NotificationController = require(script.Parent.NotificationController)

local MonetizationController = {}

function MonetizationController:GamePass(gamePassId)
	local ownsGamePass
	local success, err = pcall(function()
		ownsGamePass = MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, gamePassId)
	end)

	if not success then
		warn("An error occurred when checking if player owns GamePass: " .. tostring(err))
		NotificationController:SendNotification("구매 중 오류가 발생했습니다: " .. tostring(err), 3)
		return
	end

	if ownsGamePass then
		NotificationController:SendNotification("이미 소유 중입니다.", 3)
		return
	end

	local purchaseSuccess, purchaseErr = pcall(function()
		MarketplaceService:PromptGamePassPurchase(LocalPlayer, gamePassId)
	end)

	if not purchaseSuccess then
		warn("An error occurred when prompting a game pass purchase: " .. tostring(purchaseErr))
		NotificationController:SendNotification("구매를 시작하지 못했습니다: " .. tostring(purchaseErr), 3)
	else
		self:_initPurchaseProcess()
	end
end

function MonetizationController:DeveloperProduct(productId)
	local success, err = pcall(function()
		MarketplaceService:PromptProductPurchase(LocalPlayer, productId)
	end)

	if not success then
		warn("An error occurred when prompting a product purchase: " .. tostring(err))
		local productName = Monetizations.Products[productId] and Monetizations.Products[productId].Name or "상품"
		NotificationController:SendNotification(
			productName .. " 구매 중 오류가 발생했습니다: " .. tostring(err),
			3
		)
	else
		self:_initPurchaseProcess()
	end
end

function MonetizationController:_initPurchaseProcess()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local monetizationProcessUI = playerGui:FindFirstChild("MonetizationProcessUI")
		or playerGui:FindFirstChild("MonetizationProcessUI", true)

	if monetizationProcessUI then
		monetizationProcessUI.Enabled = true
	end

	SoundController:PlaySound("purchase_process")
end

function MonetizationController:_endPurchaseProcess()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")

	local monetizationProcessUI = playerGui:FindFirstChild("MonetizationProcessUI")
		or playerGui:FindFirstChild("MonetizationProcessUI", true)

	if monetizationProcessUI then
		monetizationProcessUI.Enabled = false
	end
end

function MonetizationController:_purchaseCompleted(_, productId, isPurchased)
	self:_endPurchaseProcess()

	local productName
	if Monetizations.GamePasses[productId] then
		productName = Monetizations.GamePasses[productId].Name
	elseif Monetizations.Products[productId] then
		productName = Monetizations.Products[productId].Name
	else
		productName = "알 수 없음"
	end

	if isPurchased then
		NotificationController:SendNotification(productName .. "(이/가) 지급 되었습니다!", 3)
		if SoundController then
			SoundController:PlaySound("purchase_completed")
		end
	else
		NotificationController:SendNotification("구매 실패했습니다.", 3)
	end
end

function MonetizationController:Init()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(...)
		self:_purchaseCompleted(...)
	end)

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(...)
		self:_purchaseCompleted(...)
	end)
end

return MonetizationController
