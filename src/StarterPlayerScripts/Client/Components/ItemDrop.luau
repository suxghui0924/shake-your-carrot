local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Component = require(Packages:WaitForChild("Component"))
local Trove = require(Packages:WaitForChild("Trove"))
local Fusion = require(Packages:WaitForChild("Fusion"))
local Network = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"))

local peek = Fusion.peek
local Children = Fusion.Children

local ItemDrop = Component.new({
	Tag = "ItemDrop",
	Ancestors = {workspace},
})

function ItemDrop:Construct()
	self._trove = Trove.new()
	self.Scope = Fusion.scoped(Fusion)
	
	-- Fusion State
	self.NextAvailableTime = self.Scope:Value(self.Instance:GetAttribute("NextAvailableTime") or 0)
	
	self.TimeLeft = self.Scope:Computed(function(use)
		local nextAvailable = use(self.NextAvailableTime) or 0
		local success, serverTime = pcall(function() return workspace:GetServerTime() end)
		if not success then
			serverTime = os.time()
		end
		return math.max(0, nextAvailable - serverTime)
	end)
	
	self.IsReady = self.Scope:Computed(function(use)
		local t = use(self.TimeLeft)
		return t ~= nil and t <= 0
	end)
	
	-- Run UI setup in a separate task to avoid blocking and handle slow loading
	task.spawn(function()
		local proxy = self.Instance:WaitForChild("proxy", 10)
		if proxy then
			self:SetupProximityPrompt(proxy)
		else
			warn("ItemDrop: No 'proxy' part found for " .. self.Instance.Name .. " after 10s")
		end
		
		local guiPart = self.Instance:FindFirstChild("gui") or proxy or self.Instance
		if guiPart then
			self:CreateBillboardUI(guiPart)
		end
	end)
end

function ItemDrop:Start()
	-- Sync Item State on Attribute change
	self._trove:Connect(self.Instance:GetAttributeChangedSignal("NextAvailableTime"), function()
		self.NextAvailableTime:set(self.Instance:GetAttribute("NextAvailableTime") or 0)
	end)
end

function ItemDrop:SetupProximityPrompt(proxy)
	local prompt = self.Scope:New "ProximityPrompt" {
		Parent = proxy,
		ActionText = "획득",
		ObjectText = self.Instance:GetAttribute("Type") or self.Instance.Name,
		HoldDuration = 0.5,
		KeyboardKeyCode = Enum.KeyCode.E,
		Enabled = self.IsReady,
		
		[Fusion.OnEvent "Triggered"] = function()
			if peek(self.IsReady) then
				Network.packets.itemPickup.send({
					itemInstance = self.Instance
				})
			end
		end
	}
	
	self._trove:Add(prompt)
end

function ItemDrop:CreateBillboardUI(guiPart)
	local billboard = self.Scope:New "BillboardGui" {
		Parent = guiPart,
		Name = "ItemInfo",
		Adornee = guiPart,
		Size = UDim2.fromOffset(250, 100),
		StudsOffset = Vector3.new(0, 3, 0),
		AlwaysOnTop = true,
		
		[Children] = {
			self.Scope:New "Frame" {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				
				[Children] = {
					self.Scope:New "UIListLayout" {
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 5)
					},
					
					-- Item Name Label
					self.Scope:New "TextLabel" {
						LayoutOrder = 1,
						Size = UDim2.fromScale(1, 0.3),
						BackgroundTransparency = 1,
						Text = self.Instance:GetAttribute("Type") or self.Instance.Name,
						TextColor3 = Color3.fromRGB(255, 255, 0), -- Gold/Yellow for name
						Font = Enum.Font.FredokaOne,
						TextSize = 22,
						TextStrokeTransparency = 0.5
					},

					-- Status / Timer Label
					self.Scope:New "TextLabel" {
						LayoutOrder = 2,
						Size = UDim2.fromScale(1, 0.4),
						BackgroundTransparency = 1,
						Text = self.Scope:Computed(function(use)
							local ready = use(self.IsReady)
							if ready then
								return "READY"
							else
								local t = use(self.TimeLeft) or 0
								local minutes = math.floor(t / 60)
								local seconds = math.floor(t % 60)
								return string.format("%02d:%02d", minutes, seconds)
							end
						end),
						TextColor3 = self.Scope:Computed(function(use)
							return use(self.IsReady) and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
						end),
						Font = Enum.Font.FredokaOne,
						TextSize = 32,
						TextStrokeTransparency = 0.5
					},
					
					-- Description Label
					self.Scope:New "TextLabel" {
						LayoutOrder = 3,
						Size = UDim2.fromScale(1, 0.3),
						BackgroundTransparency = 1,
						Text = self.Scope:Computed(function(use)
							local itemType = self.Instance:GetAttribute("Type") or self.Instance.Name
							local desc = self.Instance:GetAttribute("Description")
							if desc then return desc end
							
							if itemType == "Water" or itemType == "Lettuce" then
								return "양상추 당근 성장 2.0x 지급"
							elseif itemType == "Broccoli" then
								return "브로콜리 체력 50 회복"
							end
							return "아이템 상호작용"
						end),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						Font = Enum.Font.FredokaOne,
						TextSize = 18,
						TextStrokeTransparency = 0.5
					}
				}
			}
		}
	}
	
	self._trove:Add(billboard)
end

function ItemDrop:Stop()
	self._trove:Clean()
	self.Scope:doCleanup()
end

return ItemDrop
