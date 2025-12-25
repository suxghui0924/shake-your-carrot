local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Fusion = require(Packages.Fusion)
local Trove = require(Packages.Trove)

local CarrotSkins = require(ReplicatedStorage.Shared.Data.CarrotSkins)
local Network = require(ReplicatedStorage.Shared.Network)
local Monetizations = require(ReplicatedStorage.Shared.Monetizations)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local CarrotSkinUI = {}
CarrotSkinUI.__index = CarrotSkinUI

-- [ THEME: Juicy Dark & Comic ] --
local THEME = {
	BG_DARK = Color3.fromRGB(15, 15, 20),
	BG_PANEL = Color3.fromRGB(25, 25, 30),
	
	TEXT_MAIN = Color3.fromRGB(255, 255, 255),
	TEXT_DIM = Color3.fromRGB(180, 180, 200),
	
	ACCENT_ORANGE = Color3.fromRGB(255, 120, 40),
	ACCENT_GREEN = Color3.fromRGB(80, 220, 100),
	ACCENT_GOLD = Color3.fromRGB(255, 215, 0),
	
	RARITY = {
		Common = Color3.fromRGB(180, 180, 180),
		Rare = Color3.fromRGB(50, 200, 255), -- Blue-ish
		Epic = Color3.fromRGB(180, 60, 255),  -- Purple
		Heroic = Color3.fromRGB(255, 50, 100), -- Red
		Legendary = Color3.fromRGB(255, 220, 0), -- Gold
	}
}

function CarrotSkinUI.new()
	local self = setmetatable({}, CarrotSkinUI)
	self._trove = Trove.new()
	self:Init()
	return self
end

function CarrotSkinUI:Init()
	local player = Players.LocalPlayer
	self.Scope = Fusion.scoped(Fusion)
	
	-- [ STATE ] --
	self.ActiveWindow = self.Scope:Value(nil) 
	self.SelectedSkin = self.Scope:Value("Default")
	
	-- Data
	self.EquippedSkin = self.Scope:Value(player:GetAttribute("EquippedSkin") or "Default")
	self.UnlockedSkins = self.Scope:Value(player:GetAttribute("UnlockedSkins") or {"Default"})
	self.Coins = self.Scope:Value(player:GetAttribute("Money") or 0)
	self.Health = self.Scope:Value(player.Character and player.Character:GetAttribute("Health") or 100)
	self.MaxHealth = self.Scope:Value(player.Character and player.Character:GetAttribute("MaxHealth") or 100)
	
	-- Animations
	self.PreviewRotation = self.Scope:Value(0)
	self.HoverScale = self.Scope:Value(1)
	
	self._trove:Connect(RunService.RenderStepped, function(dt)
		if peek(self.ActiveWindow) == "Skins" then
			self.PreviewRotation:set(peek(self.PreviewRotation) + dt * 45)
		end
	end)
	
	-- Attribute Listeners
	self._trove:Connect(player.AttributeChanged, function(attr)
		if attr == "EquippedSkin" then self.EquippedSkin:set(player:GetAttribute("EquippedSkin"))
		elseif attr == "Money" then self.Coins:set(player:GetAttribute("Money"))
		elseif attr == "UnlockedSkins" then self.UnlockedSkins:set(player:GetAttribute("UnlockedSkins"))
		end
	end)
	
	-- Health Listener
	local function bindChar(char)
		if not char then return end
		local humanoid = char:WaitForChild("Humanoid", 10)
		if humanoid then
			self.Health:set(humanoid.Health)
			self.MaxHealth:set(humanoid.MaxHealth)
			self._trove:Connect(humanoid.HealthChanged, function(h)
				self.Health:set(h)
				self.MaxHealth:set(humanoid.MaxHealth)
			end)
		end
	end
	self._trove:Connect(player.CharacterAdded, bindChar)
	bindChar(player.Character)
	
	-- [ GUI ] --
	self.ScreenGui = self.Scope:New "ScreenGui" {
		Name = "CarrotUI_Juicy",
		Parent = player:WaitForChild("PlayerGui"),
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 10,
		
		[Children] = {
			self:CreateProfileHUD(player),
			self:CreateSideButtons(),
			self:CreateMainWindow(),
		}
	}
end

-- [ HELPERS ] --
function CarrotSkinUI:CreateGlossyGradient(color)
	return self.Scope:New "UIGradient" {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
			ColorSequenceKeypoint.new(1, color)
		}),
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(1, 0)
		})
	}
end

-- [ COMPONENTS ] --

function CarrotSkinUI:CreateProfileHUD(player)
	return self.Scope:New "Frame" {
		Name = "ProfileHUD",
		Size = UDim2.fromOffset(300, 100),
		Position = UDim2.new(0, 20, 1, -20),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		[Children] = {
			-- Main Pill
			self.Scope:New "Frame" {
				Size = UDim2.new(1, -50, 0, 70),
				Position = UDim2.fromOffset(50, 15),
				BackgroundColor3 = Color3.fromRGB(30, 30, 35),
				[Children] = {
					self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 35) },
					self.Scope:New "UIStroke" { Color = Color3.fromRGB(60, 60, 70), Thickness = 2 },
					
					-- Info
					self.Scope:New "Frame" {
						Size = UDim2.new(1, -60, 1, 0),
						Position = UDim2.fromOffset(50, 0),
						BackgroundTransparency = 1,
						[Children] = {
							self.Scope:New "UIListLayout" { Padding = UDim.new(0, 5), VerticalAlignment = Enum.VerticalAlignment.Center },
							
							self.Scope:New "TextLabel" {
								Text = player.DisplayName,
								Font = Enum.Font.FredokaOne,
								TextSize = 20,
								TextColor3 = THEME.TEXT_MAIN,
								Size = UDim2.new(1, 0, 0, 20),
								BackgroundTransparency = 1,
								TextXAlignment = Enum.TextXAlignment.Left,
							},
							
							self.Scope:New "Frame" { -- Coins
								Size = UDim2.new(1, 0, 0, 24),
								BackgroundTransparency = 1,
								[Children] = {
									self.Scope:New "UIListLayout" { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), VerticalAlignment = Enum.VerticalAlignment.Center },
									self.Scope:New "TextLabel" { Text = "💰", TextSize = 20, BackgroundTransparency = 1, Size = UDim2.fromOffset(24,24) },
									self.Scope:New "TextLabel" {
										Text = self.Scope:Computed(function(use) return string.format("%d", use(self.Coins)) end), -- Format number
										Font = Enum.Font.FredokaOne,
										TextSize = 22,
										TextColor3 = THEME.ACCENT_GOLD,
										Size = UDim2.fromOffset(0, 24),
										AutomaticSize = Enum.AutomaticSize.X,
										BackgroundTransparency = 1,
									}
								}
							}
						}
					}
				}
			},
			
			-- Health Bar
			self.Scope:New "Frame" {
				Size = UDim2.new(0.7, 0, 0, 8),
				Position = UDim2.new(0.3, 0, 1, -5),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = Color3.fromRGB(50, 10, 10),
				[Children] = {
					self.Scope:New "UICorner" { CornerRadius = UDim.new(1, 0) },
					self.Scope:New "Frame" {
						Size = self.Scope:Computed(function(use)
							return UDim2.fromScale(math.clamp(use(self.Health)/use(self.MaxHealth), 0, 1), 1)
						end),
						BackgroundColor3 = Color3.fromRGB(255, 60, 60),
						[Children] = { self.Scope:New "UICorner" { CornerRadius = UDim.new(1, 0) } }
					}
				}
			},
			
			-- Avatar
			self.Scope:New "ImageLabel" {
				Size = UDim2.fromOffset(90, 90),
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = THEME.BG_PANEL,
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150",
				ZIndex = 5,
				[Children] = {
					self.Scope:New "UICorner" { CornerRadius = UDim.new(1, 0) },
					self.Scope:New "UIStroke" { Color = THEME.ACCENT_ORANGE, Thickness = 3 },
				}
			}
		}
	}
end

function CarrotSkinUI:CreateSideButtons()
	local function SideButton(text, iconId, actionName)
		local hover = self.Scope:Value(false)
		
		return self.Scope:New "TextButton" {
			Name = actionName .. "Btn",
			Size = UDim2.fromOffset(80, 80),
			BackgroundColor3 = THEME.ACCENT_ORANGE,
			Text = "",
			[Children] = {
				self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 16) },
				self.Scope:New "UIStroke" { Color = THEME.TEXT_MAIN, Thickness = 3 },
				self.Scope:New "UIGradient" { Color = ColorSequence.new(Color3.new(1,1,1), Color3.fromRGB(255, 150, 50)), Rotation = 45 },
				
				-- Icon
				self.Scope:New "ImageLabel" {
					Image = iconId,
					Size = UDim2.fromOffset(40, 40),
					Position = UDim2.new(0.5, 0, 0.4, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					ScaleType = Enum.ScaleType.Fit,
				},
				
				-- Label
				self.Scope:New "TextLabel" {
					Text = text,
					Size = UDim2.new(1, 0, 0.3, 0),
					Position = UDim2.new(0, 0, 1, -5),
					AnchorPoint = Vector2.new(0, 1),
					BackgroundTransparency = 1,
					Font = Enum.Font.FredokaOne,
					TextColor3 = Color3.new(1,1,1),
					TextStrokeTransparency = 0.5,
					TextSize = 14,
				}
			},
			-- Simple Bounce
			[OnEvent "MouseEnter"] = function() hover:set(true) end,
			[OnEvent "MouseLeave"] = function() hover:set(false) end,
			[OnEvent "Activated"] = function()
				if peek(self.ActiveWindow) == actionName then
					self.ActiveWindow:set(nil)
				else
					self.ActiveWindow:set(actionName)
				end
			end
		}
	end

	return self.Scope:New "Frame" {
		Name = "SideButtons",
		Position = UDim2.new(1, -20, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.fromOffset(90, 200),
		BackgroundTransparency = 1,
		[Children] = {
			self.Scope:New "UIListLayout" { Padding = UDim.new(0, 20), HorizontalAlignment = Enum.HorizontalAlignment.Center },
			
			SideButton("SKINS", "rbxassetid://13926315848", "Skins"),
			SideButton("SHOP", "rbxassetid://13926317282", "Shop"),
		}
	}
end

function CarrotSkinUI:CreateMainWindow()
	local isVisible = self.Scope:Computed(function(use) return use(self.ActiveWindow) ~= nil end)
	
	return self.Scope:New "Frame" {
		Name = "MainWindow",
		Size = UDim2.fromOffset(1024, 640),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = THEME.BG_DARK,
		BackgroundTransparency = 0.05,
		Visible = self.Scope:Computed(function(use) return use(isVisible) end),
		
		[Children] = {
			self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
			self.Scope:New "UIStroke" { Color = THEME.TEXT_MAIN, Thickness = 2 },
			
			-- Close
			self.Scope:New "TextButton" {
				Text = "✕",
				Size = UDim2.fromOffset(40, 40),
				Position = UDim2.new(1, -10, 0, 10),
				AnchorPoint = Vector2.new(1,0),
				BackgroundColor3 = Color3.fromRGB(255, 80, 80),
				TextColor3 = Color3.new(1,1,1),
				Font = Enum.Font.FredokaOne,
				TextSize = 20,
				[Children] = { self.Scope:New "UICorner" { CornerRadius = UDim.new(1,0) } },
				[OnEvent "Activated"] = function() self.ActiveWindow:set(nil) end
			},
			
			-- Content
			self.Scope:New "Frame" {
				Size = UDim2.new(1, -40, 1, -40),
				Position = UDim2.fromOffset(20, 20),
				BackgroundTransparency = 1,
				[Children] = {
					-- Skins Content
					self.Scope:New "Frame" {
						Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
						Visible = self.Scope:Computed(function(use) return use(self.ActiveWindow) == "Skins" end),
						[Children] = { self:CreateSkinsInterface() }
					},
					
					-- Shop Content
					self.Scope:New "Frame" {
						Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
						Visible = self.Scope:Computed(function(use) return use(self.ActiveWindow) == "Shop" end),
						[Children] = { self:CreateShopInterface() }
					}
				}
			}
		}
	}
end

function CarrotSkinUI:CreateSkinsInterface()
	return {
		-- Left Panel (Preview & Info)
		self.Scope:New "Frame" {
			Size = UDim2.new(0.35, -10, 1, 0),
			BackgroundColor3 = THEME.BG_PANEL,
			[Children] = {
				self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
				
				-- 3D Viewport Area
				self.Scope:New "Frame" {
					Size = UDim2.new(1, 0, 0.6, 0),
					BackgroundTransparency = 1,
					[Children] = {
						self.Scope:New "UIGradient" { Color = ColorSequence.new(Color3.fromRGB(40,40,50), Color3.fromRGB(20,20,25)), Rotation = 90 },
						self:CreatePreviewViewport(),
						
						-- Rarity Tag
						self.Scope:New "TextLabel" {
							Size = UDim2.fromOffset(120, 30),
							Position = UDim2.new(0.5, 0, 0.9, 0),
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = self.Scope:Computed(function(use)
								return THEME.RARITY[CarrotSkins[use(self.SelectedSkin)].Rarity] or THEME.RARITY.Common
							end),
							Text = self.Scope:Computed(function(use) return string.upper(CarrotSkins[use(self.SelectedSkin)].Rarity) end),
							Font = Enum.Font.FredokaOne,
							TextColor3 = Color3.new(1,1,1),
							TextSize = 16,
							[Children] = { self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 8) } }
						}
					}
				},
				
				-- Info Area
				self.Scope:New "Frame" {
					Size = UDim2.new(1, -20, 0.4, -20),
					Position = UDim2.new(0, 10, 0.6, 10),
					BackgroundTransparency = 1,
					[Children] = {
						self.Scope:New "UIListLayout" { Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center },
						
						self.Scope:New "TextLabel" {
							Text = self.Scope:Computed(function(use) return CarrotSkins[use(self.SelectedSkin)].Name end),
							Font = Enum.Font.FredokaOne,
							TextSize = 32,
							TextColor3 = THEME.TEXT_MAIN,
							Size = UDim2.new(1, 0, 0, 40),
							BackgroundTransparency = 1,
						},
						
						self.Scope:New "TextLabel" {
							Text = self.Scope:Computed(function(use) return CarrotSkins[use(self.SelectedSkin)].Description end),
							Font = Enum.Font.GothamMedium,
							TextSize = 14,
							TextColor3 = THEME.TEXT_DIM,
							Size = UDim2.new(1, 0, 0, 60),
							BackgroundTransparency = 1,
							TextWrapped = true,
						},
						
						self.Scope:New "Frame" { Size = UDim2.new(0,0,0,10), BackgroundTransparency = 1 },
						
						-- Buy/Equip Button
						self.Scope:New "TextButton" {
							Size = UDim2.new(0.9, 0, 0, 50),
							BackgroundColor3 = self.Scope:Computed(function(use)
								local id = use(self.SelectedSkin)
								local unlocked = table.find(use(self.UnlockedSkins), id) or id == "Default"
								return unlocked and theme.ACCENT_GREEN or theme.ACCENT_ORANGE
							end),
							Text = self.Scope:Computed(function(use)
								local id = use(self.SelectedSkin)
								local unlocked = table.find(use(self.UnlockedSkins), id) or id == "Default"
								if unlocked then
									return use(self.EquippedSkin) == id and "EQUIPPED" or "EQUIP"
								else
									return "BUY: " .. CarrotSkins[id].CoinPrice .. " 💰"
								end
							end),
							Font = Enum.Font.FredokaOne,
							TextSize = 24,
							TextColor3 = Color3.new(1,1,1),
							[Children] = { self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 12) } },
							[OnEvent "Activated"] = function()
								local id = peek(self.SelectedSkin)
								local unlocked = table.find(peek(self.UnlockedSkins), id) or id == "Default"
								if unlocked then
									if peek(self.EquippedSkin) ~= id then Network.packets.equipSkin.send({ skinId = id }) end
								else
									Network.packets.buySkin.send({ skinId = id })
								end
							end
						}
					}
				}
			}
		},
		
		-- Right Panel (Grid)
		self.Scope:New "ScrollingFrame" {
			Size = UDim2.new(0.65, -10, 1, 0),
			Position = UDim2.new(0.35, 10, 0, 0),
			BackgroundTransparency = 1,
			ScrollBarThickness = 6,
			ScrollBarImageColor3 = THEME.ACCENT_ORANGE,
			CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
			[Children] = {
				-- 4 Columns Layout
				self.Scope:New "UIGridLayout" {
					CellSize = UDim2.fromOffset(135, 150),
					CellPadding = UDim2.fromOffset(15, 15),
				},
				self.Scope:New "UIPadding" { PaddingLeft = UDim.new(0, 10) },
				self:CreateGridItems()
			}
		}
	}
end

function CarrotSkinUI:CreateGridItems()
	local items = {}
	local keys = {}
	for k in pairs(CarrotSkins) do table.insert(keys, k) end
	table.sort(keys)

	for _, id in ipairs(keys) do
		local data = CarrotSkins[id]
		local isSelected = self.Scope:Computed(function(use) return use(self.SelectedSkin) == id end)
		local isUnlocked = self.Scope:Computed(function(use) return table.find(use(self.UnlockedSkins), id) or id == "Default" end)
		local rarityColor = THEME.RARITY[data.Rarity] or THEME.RARITY.Common
		
		table.insert(items, self.Scope:New "TextButton" {
			BackgroundColor3 = THEME.BG_PANEL,
			Text = "",
			[Children] = {
				self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
				self.Scope:New "UIStroke" {
					Color = self.Scope:Computed(function(use) return use(isSelected) and Color3.new(1,1,1) or rarityColor end),
					Thickness = self.Scope:Computed(function(use) return use(isSelected) and 3 or 2 end),
					Transparency = self.Scope:Computed(function(use) return (use(isSelected) or not use(isUnlocked)) and 0 or 0.3 end)
				},
				
				-- Icon
				self.Scope:New "Frame" {
					Size = UDim2.fromScale(0.7, 0.7),
					Position = UDim2.fromScale(0.5, 0.45),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = data.Color,
					[Children] = {
						self.Scope:New "UICorner" { CornerRadius = UDim.new(1, 0) },
						self.Scope:New "TextLabel" { Text="🔒", Visible=self.Scope:Computed(function(use) return not use(isUnlocked) end), Size=UDim2.fromScale(1,1), BackgroundTransparency=1, TextSize=24 }
					}
				},
				
				-- Name
				self.Scope:New "TextLabel" {
					Text = data.Name,
					Position = UDim2.new(0, 0, 1, -25),
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextColor3 = THEME.TEXT_MAIN
				}
			},
			[OnEvent "Activated"] = function() self.SelectedSkin:set(id) end
		})
	end
	return items
end

function CarrotSkinUI:CreatePreviewViewport()
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	local world = Instance.new("WorldModel")
	
	local function update()
		world:ClearAllChildren()
		local data = CarrotSkins[peek(self.SelectedSkin)]
		if not data then return end
		
		-- Try find asset
		local target = game
		for _, p in ipairs(string.split(data.AssetPath, ".")) do
			target = target:FindFirstChild(p)
			if not target then break end
		end
		
		if target then
			local c = target:Clone()
			if c:IsA("Tool") then
				local m = Instance.new("Model")
				for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then d.Parent = m end end
				c = m
			end
			c.Parent = world
			local cf, size = c:GetBoundingBox()
			c:PivotTo(CFrame.new(-cf.Position))
			cam.CFrame = CFrame.new(Vector3.new(0, 2, size.Magnitude*2.5), Vector3.new(0,0,0)) * CFrame.Angles(math.rad(-15), 0, 0)
		end
		
		-- Floor Pedestal
		local pedestal = Instance.new("Part")
		pedestal.Size = Vector3.new(5, 0.5, 5)
		pedestal.Position = Vector3.new(0, -1.5, 0)
		pedestal.Shape = Enum.PartType.Cylinder
		pedestal.Orientation = Vector3.new(0,0,90)
		pedestal.Color = THEME.ACCENT_ORANGE
		pedestal.Material = Enum.Material.Neon
		pedestal.Anchored = true
		pedestal.Parent = world
	end
	
	self._trove:Add(self.Scope:Observer(self.SelectedSkin):onChange(update))
	task.defer(update)
	
	self._trove:Add(self.Scope:Observer(self.PreviewRotation):onChange(function()
		local r = peek(self.PreviewRotation)
		for _, c in ipairs(world:GetChildren()) do
			-- Rotate model only (not pedestal if we wanted)
			if c:IsA("Model") then
				c:PivotTo(c:GetPivot() * CFrame.Angles(0, math.rad(1), 0))
			end
		end
	end))

	return self.Scope:New "ViewportFrame" {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		CurrentCamera = cam,
		[Children] = { cam, world }
	}
end

function CarrotSkinUI:CreateShopInterface()
	local items = {}
	for id, data in pairs(Monetizations.Products) do
		if data.Type == "Coins" then
			table.insert(items, self.Scope:New "Frame" {
				BackgroundColor3 = THEME.BG_PANEL,
				[Children] = {
					self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
					self.Scope:New "UIStroke" { Color = THEME.ACCENT_GOLD, Thickness = 2 },
					self.Scope:New "UIListLayout" { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center },
					
					self.Scope:New "TextLabel" { Text = "💰", TextSize = 40, BackgroundTransparency = 1, Size=UDim2.fromOffset(50,50) },
					self.Scope:New "TextLabel" { Text = data.Name, TextColor3 = THEME.TEXT_MAIN, Font = Enum.Font.FredokaOne, TextSize = 18, BackgroundTransparency = 1, Size=UDim2.new(1,0,0,20) },
					
					self.Scope:New "TextButton" {
						Size = UDim2.fromOffset(120, 35),
						BackgroundColor3 = THEME.ACCENT_GREEN,
						Text = "BUY",
						Font = Enum.Font.FredokaOne,
						TextColor3 = Color3.new(1,1,1),
						[Children] = { self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 8) } },
						[OnEvent "Activated"] = function() MarketplaceService:PromptProductPurchase(Players.LocalPlayer, id) end
					}
				}
			})
		end
	end

	return self.Scope:New "ScrollingFrame" {
		Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
		[Children] = {
			self.Scope:New "UIGridLayout" { CellSize = UDim2.fromOffset(180, 200), CellPadding = UDim2.fromOffset(20, 20) },
			items
		}
	}
end

function CarrotSkinUI:Destroy()
	if self.Scope then self.Scope:doCleanup() end
	self._trove:Clean()
end

local instance = CarrotSkinUI.new()
return instance
