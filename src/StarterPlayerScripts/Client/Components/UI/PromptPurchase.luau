local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)
local Trove = require(Packages.Trove)

local Monetizations = require(ReplicatedStorage.Shared.Monetizations)

local LocalPlayer = Players.LocalPlayer
local MonetizationController = require(LocalPlayer.PlayerScripts.Client.Controllers.MonetizationController)

local PromptPurchase = Component.new({
	Tag = "PromptPurchase",
	Ancestors = { LocalPlayer:WaitForChild("PlayerGui") },
})

function PromptPurchase:Construct()
	self._trove = Trove.new()
	self.Debounce = false
	self.GotActualId = false
end

function PromptPurchase:Start()
	local instance = self.Instance

	self.ProductType = instance:GetAttribute("ProductType")
	self.Id = instance:GetAttribute("Id")
	self.SetTextToPrice = instance:GetAttribute("SetTextToPrice")

	assert(
		instance:IsA("GuiButton"),
		string.format("[PromptPurchase]: %s must be a GuiButton; got %s", instance:GetFullName(), instance.ClassName)
	)

	assert(
		typeof(self.ProductType) == "string",
		string.format(
			"[PromptPurchase]: %s attribute, ProductType must be a string; got %s",
			instance:GetFullName(),
			typeof(self.ProductType)
		)
	)

	assert(
		typeof(self.Id) == "number" or typeof(self.Id) == "string",
		string.format(
			"[PromptPurchase]: %s attribute, Id must be a number or string; got %s",
			instance:GetFullName(),
			typeof(self.Id)
		)
	)

	assert(
		typeof(self.SetTextToPrice) == "boolean" or typeof(self.SetTextToPrice) == "nil",
		string.format(
			"[PromptPurchase]: %s attribute, SetTextToPrice must be a boolean or nil; got %s",
			instance:GetFullName(),
			typeof(self.SetTextToPrice)
		)
	)

	if typeof(self.Id) == "number" then
		if self.ProductType == "GamePass" and Monetizations.GamePasses[self.Id] then
			self.ActualId = self.Id
			self.GotActualId = true
		elseif self.ProductType == "DeveloperProduct" and Monetizations.Products[self.Id] then
			self.ActualId = self.Id
			self.GotActualId = true
		else
			self.ActualId = self.Id
			self.GotActualId = true
		end
	elseif typeof(self.Id) == "string" then
		warn("[PromptPurchase]: String Id not supported with current Monetizations config: " .. tostring(self.Id))
	end

	task.spawn(function()
		repeat
			task.wait()
		until self.GotActualId

		local alreadyOwned
		if self.ProductType == "GamePass" then
			pcall(function()
				alreadyOwned = MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, self.ActualId)
			end)
			if alreadyOwned then
				local textLabel = instance:FindFirstChild("TextLabel")
				if textLabel then
					textLabel.Text = "Owned"
				else
					instance.Text = "Owned"
				end
			end
		end

		if not alreadyOwned then
			if self.SetTextToPrice == true then
				local infoTypes = {
					Asset = Enum.InfoType.Asset,
					Bundle = Enum.InfoType.Bundle,
					GamePass = Enum.InfoType.GamePass,
					DeveloperProduct = Enum.InfoType.Product,
					Subscription = Enum.InfoType.Subscription,
				}
				for typeName, infoType in pairs(infoTypes) do
					if self.ProductType == typeName then
						local productInfo
						local ok, err = pcall(function()
							productInfo = MarketplaceService:GetProductInfo(self.ActualId, infoType)
						end)
						if productInfo and productInfo.PriceInRobux then
							local textLabel = instance:FindFirstChild("TextLabel")
							if textLabel then
								textLabel.Text = string.format("%s", productInfo.PriceInRobux)
							else
								instance.Text = string.format("%s", productInfo.PriceInRobux)
							end
						elseif not ok then
							warn("An error occurred when getting ProductInfo: " .. err)
						end
					end
				end
			end

			self._trove:Connect(instance.MouseButton1Click, function()
				if MonetizationController[self.ProductType] and not self.Debounce then
					self.Debounce = true
					local ok, err = pcall(function()
						MonetizationController[self.ProductType](MonetizationController, self.ActualId)
					end)
					if not ok then
						warn("An error occurred when prompting " .. self.ProductType .. " Purchase: " .. err)
					end
					task.wait(1)
					self.Debounce = false
				end
			end)
		end
	end)
end

function PromptPurchase:Stop()
	self._trove:Destroy()
end

return PromptPurchase
