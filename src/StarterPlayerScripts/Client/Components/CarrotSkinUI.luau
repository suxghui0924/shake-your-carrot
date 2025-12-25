local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)
local Trove = require(Packages.Trove)
local ProfileTemplateModule = require(ReplicatedStorage.Shared.Data.ProfileTemplate)
local CarrotSkins = ProfileTemplateModule.Skins
local Network = require(ReplicatedStorage.Shared.Network)

local Children = Fusion.Children
local peek = Fusion.peek

local CarrotSkinUI = {}
CarrotSkinUI.__index = CarrotSkinUI

-- [[ MODERN THEME ]]
local THEME = {
	BG_MAIN = Color3.fromRGB(20, 20, 24),
	BG_SEC = Color3.fromRGB(30, 30, 36),
	BG_PANEL = Color3.fromRGB(40, 40, 48),
	
	ACCENT_ORANGE = Color3.fromRGB(255, 120, 40),
	ACCENT_GREEN = Color3.fromRGB(80, 220, 100),
	ACCENT_GOLD = Color3.fromRGB(255, 200, 50),
	ACCENT_RED = Color3.fromRGB(255, 80, 80),
	
	TEXT_MAIN = Color3.fromRGB(255, 255, 255),
	TEXT_DIM = Color3.fromRGB(180, 180, 190),
	
	CORNER = UDim.new(0, 12),
	PADDING = UDim.new(0, 16),
}

-- Rarity Colors
local RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Rare = Color3.fromRGB(50, 150, 255),
	Epic = Color3.fromRGB(180, 60, 255),
	Heroic = Color3.fromRGB(255, 50, 50),
	Legendary = Color3.fromRGB(255, 200, 0),
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
	
	-- [[ STATE ]]
	self.IsOpen = self.Scope:Value(false) -- Default: Closed
	self.Tab = self.Scope:Value("Skins") -- "Skins" | "Shop"
	
	self.SelectedSkin = self.Scope:Value("Default")
	
	-- Player Attributes (Synced)
	-- Player Attributes (Synced)
	self.EquippedSkin = self.Scope:Value(player:GetAttribute("EquippedSkin") or "Default")
	
	-- Decode JSON for unlocked skins
	local function getUnlockedSkins()
		local attr = player:GetAttribute("UnlockedSkins")
		if type(attr) == "string" then
			local success, result = pcall(function() return HttpService:JSONDecode(attr) end)
			if success and type(result) == "table" then return result end
		end
		return {"Default"}
	end
	
	self.UnlockedSkins = self.Scope:Value(getUnlockedSkins())
	self.Coins = self.Scope:Value(player:GetAttribute("Money") or 0)
	self.CarrotScale = self.Scope:Value(player:GetAttribute("CarrotScale") or 1.0)
	
	-- Listeners
	self._trove:Connect(player.AttributeChanged, function(attr)
		if attr == "EquippedSkin" then self.EquippedSkin:set(player:GetAttribute(attr))
		elseif attr == "UnlockedSkins" then 
			self.UnlockedSkins:set(getUnlockedSkins())
		elseif attr == "Money" then self.Coins:set(player:GetAttribute(attr))
		elseif attr == "CarrotScale" then self.CarrotScale:set(player:GetAttribute(attr))
		end
	end)
	
	self.PreviewRotation = self.Scope:Value(0)
	self._trove:Connect(RunService.RenderStepped, function(dt)
		if peek(self.IsOpen) then
			self.PreviewRotation:set(peek(self.PreviewRotation) + dt * 45) -- Faster spin
		end
	end)

	-- [[ RESPONSIVE STATE ]]
	local camera = workspace.CurrentCamera
	self.ViewportSize = self.Scope:Value(camera.ViewportSize)
	self.UIScale = self.Scope:Computed(function(use)
		local size = use(self.ViewportSize)
		-- Reference height: 1080p. 
		-- Scale factor: minimal 0.6 (mobile), max 1.2 (large screens)
		-- Logic: Scale based on height to keep elements readable
		local scale = math.clamp(size.Y / 1080, 0.6, 1.1)
		
		-- On very small width (portrait mobile), scale down further if needed to fit width
		if size.X < 800 then
			scale = math.min(scale, size.X / 1000)
		end
		return scale
	end)
	
	self._trove:Connect(camera:GetPropertyChangedSignal("ViewportSize"), function()
		self.ViewportSize:set(camera.ViewportSize)
	end)

	-- [[ GUI CONSTRUCTION ]]
	self.ScreenGui = self.Scope:New "ScreenGui" {
		Name = "CarrotUI_V2",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		Parent = player:WaitForChild("PlayerGui"),
		
		[Children] = {
			self.Scope:New "UIScale" { Scale = self.UIScale },
			self:CreateProfileHUD(player),
			self:CreateSideButtons(),
			self:CreateMainWindow(),
		}
	}

	-- [[ SHOP PROMPT INTERACTION ]]
	task.spawn(function()
		local prompts = workspace:WaitForChild("Prompts", 10)
		if not prompts then return end
		
		local carrots = prompts:WaitForChild("Carrots", 10)
		if not carrots then return end
		
		-- Wait for the prompt
		local prompt = carrots:WaitForChild("ProximityPrompt", 10) 
		if prompt and prompt:IsA("ProximityPrompt") then
			self._trove:Connect(prompt.Triggered, function(triggerPlayer)
				if triggerPlayer == player then
					self.Tab:set("Shop")
					self.IsOpen:set(true)
				end
			end)
		end
	end)
end

-- [[ COMPONENT: Profile HUD (Bottom Left) ]]
function CarrotSkinUI:CreateProfileHUD(player)
	return self.Scope:New "Frame" {
		Name = "ProfileHUD",
		Size = UDim2.fromOffset(320, 100), -- Slightly Increased Size
		Position = UDim2.new(0, 30, 1, -30), -- Adjusted margin for scale
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		
		[Children] = {
			-- Glass Background
			self.Scope:New "Frame" {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(10, 10, 12),
				BackgroundTransparency = 0.3,
				[Children] = {
					self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 20) }, -- Larger Corner
					self.Scope:New "UIStroke" { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Thickness = 1 },
					
					-- Avatar Circle (Overhanging left)
					self.Scope:New "ImageLabel" {
						Size = UDim2.fromOffset(80, 80), -- Increased Avatar
						Position = UDim2.new(0, 12, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = THEME.BG_SEC,
						Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150),
						[Children] = { self.Scope:New "UICorner" { CornerRadius = UDim.new(1, 0) } }
					},
					
					-- Info Stack
					self.Scope:New "Frame" {
						Position = UDim2.fromOffset(90, 15),
						Size = UDim2.new(1, -100, 1, -30),
						BackgroundTransparency = 1,
						[Children] = {
							self.Scope:New "UIListLayout" { Padding = UDim.new(0, 4) },
							
							-- Name
							self.Scope:New "TextLabel" {
								Text = player.DisplayName,
								Font = Enum.Font.FredokaOne,
								TextSize = 18,
								TextColor3 = THEME.TEXT_MAIN,
								Size = UDim2.new(1,0,0,20),
								BackgroundTransparency = 1,
								TextXAlignment = Enum.TextXAlignment.Left,
							},
							
							-- Coins
							self.Scope:New "TextLabel" {
								Text = self.Scope:Computed(function(use) return "💰 " .. string.format("%d", use(self.Coins)) end),
								Font = Enum.Font.FredokaOne,
								TextSize = 16,
								TextColor3 = THEME.ACCENT_GOLD,
								Size = UDim2.new(1,0,0,20),
								BackgroundTransparency = 1,
								TextXAlignment = Enum.TextXAlignment.Left,
							},
							
							-- Scale Bar (From user request)
							self.Scope:New "Frame" {
								Size = UDim2.new(1, 0, 0, 12),
								BackgroundTransparency = 1,
								[Children] = {
									self.Scope:New "UIListLayout" { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,6), VerticalAlignment = Enum.VerticalAlignment.Center },
									
									self.Scope:New "TextLabel" {
										Text = self.Scope:Computed(function(use) return string.format("x%.1f", use(self.CarrotScale)) end),
										Font = Enum.Font.Code,
										TextSize = 14,
										TextColor3 = THEME.ACCENT_ORANGE,
										Size = UDim2.new(0,35,1,0),
										BackgroundTransparency = 1,
									},
									
									-- Bar
									self.Scope:New "Frame" {
										Size = UDim2.new(1, -45, 0, 10), -- Thicker bar
										BackgroundColor3 = Color3.fromRGB(0,0,0),
										BackgroundTransparency = 0.5,
										[Children] = {
											self.Scope:New "UICorner" { CornerRadius = UDim.new(1,0) },
											self.Scope:New "Frame" {
												BackgroundColor3 = THEME.ACCENT_ORANGE,
												Size = self.Scope:Computed(function(use)
													local s = use(self.CarrotScale)
													-- Max scale is 3.0, Base is 1.0. Range is 2.0.
													local progress = math.clamp((s - 1) / 2, 0, 1)
													return UDim2.fromScale(progress, 1)
												end),
												[Children] = { self.Scope:New "UICorner" { CornerRadius = UDim.new(1,0) } }
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
end

local function Spring(scope, goal, speed, damping)
    return scope:Spring(goal, speed or 20, damping or 0.8)
end

-- [[ COMPONENT: Side Buttons (Skins / Shop) ]]
function CarrotSkinUI:CreateSideButtons()
	return self.Scope:New "Frame" {
		Size = UDim2.fromOffset(80, 200),
		Position = UDim2.new(1, -20, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Visible = self.Scope:Computed(function(use) return not use(self.IsOpen) end),
		[Children] = {
			self.Scope:New "UIListLayout" { Padding = UDim.new(0, 12) },
			
			self:CreateCircleButton("🥕", "SKINS", function()
				self.Tab:set("Skins")
				self.IsOpen:set(true)
			end),
			
			self:CreateCircleButton("💎", "SHOP", function()
				self.Tab:set("Shop")
				self.IsOpen:set(true)
			end),
			
			self:CreateCircleButton("📜", "QUESTS", function()
				local events = ReplicatedStorage:FindFirstChild("Events")
				local ev = events and events:FindFirstChild("ClientQuestToggle")
				if ev then ev:Fire() end
			end)
		}
	}
end

function CarrotSkinUI:CreateCircleButton(icon, label, onClick)
    local isHovering = self.Scope:Value(false)
    local springScale = Spring(self.Scope, self.Scope:Computed(function(use) return use(isHovering) and 1.1 or 1.0 end))
    
	return self.Scope:New "TextButton" {
		Size = UDim2.fromOffset(80, 80),
		BackgroundColor3 = THEME.BG_SEC,
		Text = "",
		[Fusion.OnEvent "Activated"] = onClick,
        [Fusion.OnEvent "MouseEnter"] = function() isHovering:set(true) end,
        [Fusion.OnEvent "MouseLeave"] = function() isHovering:set(false) end,
		[Children] = {
            self.Scope:New "UIScale" { Scale = springScale },
			self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 20) }, -- Squircle
			self.Scope:New "UIStroke" { 
                Color = Color3.fromRGB(255,255,255), 
                Thickness = 2, 
                Transparency = 0,
                [Children] = {
                    self.Scope:New "UIGradient" { Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, THEME.ACCENT_ORANGE),
                        ColorSequenceKeypoint.new(1, THEME.ACCENT_GOLD)
                    }), Rotation = 45 }
                }
            },
			
			self.Scope:New "TextLabel" {
				Text = icon,
				TextSize = 32,
				Position = UDim2.fromScale(0.5, 0.4),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
			},
			self.Scope:New "TextLabel" {
				Text = label,
				Font = Enum.Font.FredokaOne,
				TextSize = 14,
				TextColor3 = THEME.TEXT_MAIN,
				Position = UDim2.fromScale(0.5, 0.75),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
			}
		}
	}
end

-- [[ COMPONENT: Main Window ]]
function CarrotSkinUI:CreateMainWindow()
	return self.Scope:New "Frame" {
		Name = "MainWindow",
		Size = UDim2.fromScale(0.85, 0.8), -- Adaptive Size
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = self.IsOpen,
		BackgroundTransparency = 1,
		
		[Children] = {
			-- Constraints to prevent it looking weird on ultra-wide or tiny screens
			self.Scope:New "UISizeConstraint" { MaxSize = Vector2.new(1100, 750), MinSize = Vector2.new(600, 400) },
			self.Scope:New "UIAspectRatioConstraint" { AspectRatio = 1.5, DominantAxis = Enum.DominantAxis.Height, AspectType = Enum.AspectType.FitWithinMaxSize },
			
			-- Main Card
			self.Scope:New "Frame" {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = THEME.BG_MAIN,
				[Children] = {
					self.Scope:New "UICorner" { CornerRadius = THEME.CORNER },
					self.Scope:New "UIStroke" { Color = THEME.BG_PANEL, Thickness = 1 },
					
					-- Header
					self:CreateHeader(),
					
					-- Content Split (Grid Left, Inspector Right)
					self.Scope:New "Frame" {
						Size = UDim2.new(1, 0, 1, -60),
						Position = UDim2.fromOffset(0, 60),
						BackgroundTransparency = 1,
						[Children] = {
							self.Scope:New "UIPadding" { PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,10), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10) },
							
							-- GRID AREA (65%)
							self.Scope:New "Frame" {
								Name = "GridArea",
								Size = UDim2.new(0.65, -10, 1, 0),
								BackgroundColor3 = THEME.BG_SEC,
								[Children] = {
									self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
									self.Scope:New "ScrollingFrame" {
										Size = UDim2.fromScale(1,1),
										BackgroundTransparency = 1,
										CanvasSize = UDim2.fromScale(0,0),
										AutomaticCanvasSize = Enum.AutomaticSize.Y,
										ScrollBarThickness = 6,
										ScrollBarImageColor3 = THEME.TEXT_DIM,
										[Children] = {
											self.Scope:New "UIPadding" { PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,10), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10) },
											self.Scope:New "UIGridLayout" {
												CellSize = UDim2.fromOffset(130, 160),
												CellPadding = UDim2.fromOffset(10, 10),
											},
											-- Dynamic Items
											self:CreateGridItems()
										}
									}
								}
							},
							
							-- INSPECTOR AREA (35%)
							self.Scope:New "Frame" {
								Name = "InspectorArea",
								Size = UDim2.new(0.35, 0, 1, 0),
								Position = UDim2.fromScale(1, 0),
								AnchorPoint = Vector2.new(1, 0),
								BackgroundColor3 = THEME.BG_SEC,
								[Children] = {
									self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
									self:CreateInspectorContent()
								}
							}
						}
					}
				}
			}
		}
	}
end

function CarrotSkinUI:CreateHeader()
	return self.Scope:New "Frame" {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = THEME.BG_SEC,
		[Children] = {
			self.Scope:New "UICorner" { CornerRadius = THEME.CORNER },
			-- Flatten bottom corners
			self.Scope:New "Frame" {
				Size = UDim2.new(1, 0, 0, 20),
				Position = UDim2.new(0, 0, 1, -20),
				BackgroundColor3 = THEME.BG_SEC,
				BorderSizePixel = 0,
			},
			
			-- Title
			self.Scope:New "TextLabel" {
				Text = self.Scope:Computed(function(use) return use(self.Tab) == "Skins" and "INVENTORY" or "SHOP" end),
				Font = Enum.Font.FredokaOne,
				TextSize = 24,
				TextColor3 = THEME.TEXT_MAIN,
				Position = UDim2.fromOffset(20, 0),
				Size = UDim2.new(0, 100, 1, 0),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
			
			-- Close Button
			self.Scope:New "TextButton" {
				Size = UDim2.fromOffset(40, 40),
				Position = UDim2.new(1, -10, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = THEME.ACCENT_RED,
				Text = "✕",
				Font = Enum.Font.FredokaOne,
				TextColor3 = Color3.new(1,1,1),
				TextSize = 18,
				[Fusion.OnEvent "Activated"] = function() self.IsOpen:set(false) end,
				[Children] = { self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 8) } }
			}
		}
	}
end

function CarrotSkinUI:CreateGridItems()
	return self.Scope:Computed(function(use)
		local items = {}
		local unlocked = use(self.UnlockedSkins)
		local tab = use(self.Tab) -- "Skins" or "Shop"
		
		-- Get all potential keys first
		local keys = {}
		for id, data in pairs(CarrotSkins) do
			local isUnlocked = table.find(unlocked, id) or id == "Default"
			
			if tab == "Skins" then
				-- Inventory: Only Show Unlocked
				if isUnlocked then
					table.insert(keys, id)
				end
			elseif tab == "Shop" then
				-- Shop: Only Show Locked (that have a price)
				if not isUnlocked and data.CoinPrice then
					table.insert(keys, id)
				end
			end
		end

		-- Sort
		table.sort(keys, function(a, b)
			if a == "Default" then return true end
			if b == "Default" then return false end
			return CarrotSkins[a].Name < CarrotSkins[b].Name
		end)

		-- Create Cards
		for i, id in ipairs(keys) do
			local card = self:CreateSkinCard(id, CarrotSkins[id])
			card.LayoutOrder = i
			table.insert(items, card)
		end
		
		-- If Shop is empty, maybe show a "All Collected!" message? (Optional, kept simple for now)
		
		return items
	end)
end

function CarrotSkinUI:CreateSkinCard(id, skin)
	local isSelected = self.Scope:Computed(function(use) return use(self.SelectedSkin) == id end)
	local isUnlocked = self.Scope:Computed(function(use) return table.find(use(self.UnlockedSkins), id) or id == "Default" end)
	local isEquipped = self.Scope:Computed(function(use) return use(self.EquippedSkin) == id end)
	
	local rarityColor = RARITY_COLORS[skin.Rarity] or Color3.new(1,1,1)

    -- Hover Animation
    local isHovering = self.Scope:Value(false)
    local springScale = Spring(self.Scope, self.Scope:Computed(function(use) return use(isHovering) and 1.05 or 1.0 end))
	
	return self.Scope:New "TextButton" {
		Text = "",
		BackgroundColor3 = self.Scope:Computed(function(use) return use(isSelected) and THEME.BG_PANEL or THEME.BG_MAIN end),
		[Fusion.OnEvent "Activated"] = function()
			self.SelectedSkin:set(id)
		end,
        [Fusion.OnEvent "MouseEnter"] = function() isHovering:set(true) end,
        [Fusion.OnEvent "MouseLeave"] = function() isHovering:set(false) end,
		[Children] = {
            self.Scope:New "UIScale" { Scale = springScale },
			self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			self.Scope:New "UIStroke" {
				Color = self.Scope:Computed(function(use) return use(isEquipped) and THEME.ACCENT_GREEN or rarityColor end),
				Thickness = self.Scope:Computed(function(use) return use(isSelected) and 3 or 1 end),
				Transparency = self.Scope:Computed(function(use) return use(isUnlocked) and 0 or 0.5 end)
			},
			
			-- Icon/Preview Image (3D Viewport)
            self:CreateMiniViewport(id),
			
			-- Lock Overlay (Draws over viewport)
			self.Scope:New "Frame" {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 0.2, -- Dark overlay
				Visible = self.Scope:Computed(function(use) return not use(isUnlocked) end),
				[Children] = {
					self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
					self.Scope:New "TextLabel" {
						Text = "🔒",
						TextSize = 24,
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
					}
				}
			},

			-- Labels (Draws on top of overlay)
			self.Scope:New "TextLabel" {
				Text = skin.Name,
				Font = Enum.Font.FredokaOne,
				TextSize = 18,
				TextColor3 = THEME.TEXT_MAIN,
				Position = UDim2.fromScale(0.5, 0.75),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Size = UDim2.fromScale(0.9, 0.2),
                [Children] = {
                    self.Scope:New "UIStroke" { Color = Color3.new(0,0,0), Thickness = 2, Transparency = 0.5 }
                }
			}
		}
	}
end

function CarrotSkinUI:CreateInspectorContent()
    -- Action Button Hover State
    local isHoveringAction = self.Scope:Value(false)
    local actionScale = Spring(self.Scope, self.Scope:Computed(function(use) return use(isHoveringAction) and 1.05 or 1.0 end))

	return {
		self.Scope:New "UIPadding" { PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,10), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10) },
		self.Scope:New "UIListLayout" { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center },
		
		-- 3D PREVIEW BOX
		self.Scope:New "Frame" {
			Size = UDim2.fromOffset(280, 240),
			BackgroundColor3 = Color3.new(0,0,0),
			BackgroundTransparency = 0.5,
			[Children] = {
				self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
				self:CreateViewport()
			}
		},
		
		-- INFO
		self.Scope:New "TextLabel" {
			Text = self.Scope:Computed(function(use) 
				local s = CarrotSkins[use(self.SelectedSkin)]
				return s and s.Name or "Unknown"
			end),
			Font = Enum.Font.FredokaOne,
			TextSize = 24,
			TextColor3 = THEME.TEXT_MAIN,
			Size = UDim2.new(1,0,0,30),
			BackgroundTransparency = 1,
		},
		
		self.Scope:New "TextLabel" {
			Text = self.Scope:Computed(function(use) 
				local s = CarrotSkins[use(self.SelectedSkin)]
				return s and s.Rarity or ""
			end),
			Font = Enum.Font.Code,
			TextSize = 16,
			TextColor3 = self.Scope:Computed(function(use)
				local s = CarrotSkins[use(self.SelectedSkin)]
				return s and RARITY_COLORS[s.Rarity] or THEME.TEXT_DIM
			end),
			Size = UDim2.new(1,0,0,20),
			BackgroundTransparency = 1,
		},
		
		self.Scope:New "TextLabel" {
			Text = self.Scope:Computed(function(use) 
				local s = CarrotSkins[use(self.SelectedSkin)]
				return s and s.Description or ""
			end),
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextColor3 = THEME.TEXT_DIM,
			Size = UDim2.new(1,0,0,60),
			BackgroundTransparency = 1,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
		},
		
		-- ACTION BUTTON
		self.Scope:New "TextButton" {
			Size = UDim2.new(1, 0, 0, 50),
			BackgroundColor3 = self.Scope:Computed(function(use)
				local id = use(self.SelectedSkin)
				local unlocked = table.find(use(self.UnlockedSkins), id) or id == "Default"
				return unlocked and THEME.ACCENT_GREEN or THEME.ACCENT_ORANGE
			end),
			Text = self.Scope:Computed(function(use)
				local id = use(self.SelectedSkin)
				local unlocked = table.find(use(self.UnlockedSkins), id) or id == "Default"
				if unlocked then
					return use(self.EquippedSkin) == id and "EQUIPPED" or "EQUIP"
				else
					local p = CarrotSkins[id] and CarrotSkins[id].CoinPrice or 0
					return "BUY " .. p .. " 💰"
				end
			end),
			Font = Enum.Font.FredokaOne,
			TextSize = 20,
			TextColor3 = Color3.new(1,1,1),
            [Fusion.OnEvent "MouseEnter"] = function() isHoveringAction:set(true) end,
            [Fusion.OnEvent "MouseLeave"] = function() isHoveringAction:set(false) end,
            [Fusion.OnEvent "Activated"] = function()
				local id = peek(self.SelectedSkin)
				local unlocked = table.find(peek(self.UnlockedSkins), id) or id == "Default"
				if unlocked then
					Network.packets.equipSkin.send({ skinId = id })
				else
					Network.packets.buySkin.send({ skinId = id })
				end
			end,
			[Children] = {
                self.Scope:New "UIScale" { Scale = actionScale },
				self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
                self.Scope:New "UIStroke" { Color = Color3.new(1,1,1), Thickness = 2, Transparency = 0.5 },
			},
		}
	}
end

function CarrotSkinUI:CreateMiniViewport(id)
	local skin = CarrotSkins[id]
	if not skin then return nil end

	local world = Instance.new("WorldModel")
	local cam = Instance.new("Camera")
	cam.FieldOfView = 50
	
	local vp = self.Scope:New "ViewportFrame" {
		Size = UDim2.fromScale(0.75, 0.75), -- Reduced from 0.9
		Position = UDim2.fromScale(0.5, 0.4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		CurrentCamera = cam,
		Ambient = Color3.fromRGB(200, 200, 200),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-1, 1, 1),
		[Children] = { world }
	}
	
	-- Async load/setup
	task.defer(function()
		local function getAssetFromPath(path)
			local segments = string.split(path, ".")
			local current = game
			for _, segment in ipairs(segments) do
				current = current:FindFirstChild(segment)
				if not current then return nil end
			end
			return current
		end

		local asset = getAssetFromPath(skin.AssetPath)
		if not asset then
			local folder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Carrots")
			if folder then asset = folder:FindFirstChild(skin.Name) end
		end
		
		if asset then
			asset = asset:Clone()
			asset.Parent = world
			
			local min = Vector3.new(math.huge, math.huge, math.huge)
			local max = Vector3.new(-math.huge, -math.huge, -math.huge)
			
			for _, d in ipairs(asset:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					local size = d.Size
					local cf = d.CFrame
					local corners = {
						cf * Vector3.new(size.X/2, size.Y/2, size.Z/2),
						cf * Vector3.new(size.X/2, size.Y/2, -size.Z/2),
						cf * Vector3.new(size.X/2, -size.Y/2, size.Z/2),
						cf * Vector3.new(size.X/2, -size.Y/2, -size.Z/2),
						cf * Vector3.new(-size.X/2, size.Y/2, size.Z/2),
						cf * Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
						cf * Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
						cf * Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
					}
					for _, c in ipairs(corners) do
						min = Vector3.new(math.min(min.X, c.X), math.min(min.Y, c.Y), math.min(min.Z, c.Z))
						max = Vector3.new(math.max(max.X, c.X), math.max(max.Y, c.Y), math.max(max.Z, c.Z))
					end
				end
			end
			
			local center = (min + max) / 2
			local size = max - min
			local dist = math.max(size.Magnitude, 3) * 1.4 -- Zoom Out (1.0 -> 1.4)

			local rot = CFrame.Angles(0, math.rad(30), 0)
			local tilt = CFrame.Angles(math.rad(-15), 0, 0)
			
			for _, d in ipairs(asset:GetDescendants()) do
				if d:IsA("BasePart") then d.CFrame = d.CFrame - center end
			end
			
			cam.CFrame = CFrame.new(0, 0, 0) * rot * tilt * CFrame.new(0, 0, dist)
		end
	end)
	
	return vp
end

function CarrotSkinUI:CreateViewport()
	local world = Instance.new("WorldModel")
	local cam = Instance.new("Camera")
	cam.FieldOfView = 50
	
	local currentDist = 5
	
	local function updateCamera()
		local angle = peek(self.PreviewRotation)
		-- Rotate camera around center
		local rot = CFrame.Angles(0, math.rad(angle), 0)
		local tilt = CFrame.Angles(math.rad(-15), 0, 0)
		cam.CFrame = CFrame.new(0, 0, 0) * rot * tilt * CFrame.new(0, 0, currentDist)
	end

	local function update()
		world:ClearAllChildren()
		local id = peek(self.SelectedSkin)
		local skin = CarrotSkins[id]
		if not skin then return end
		
		-- Asset Loader Helper
		local function getAssetFromPath(path)
			local segments = string.split(path, ".")
			local current = game
			for _, segment in ipairs(segments) do
				current = current:FindFirstChild(segment)
				if not current then return nil end
			end
			return current
		end

		local asset = getAssetFromPath(skin.AssetPath)
		if not asset then
			local folder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Carrots")
			if folder then
				asset = folder:FindFirstChild(skin.Name)
			end
		end
		
		if asset then
			asset = asset:Clone()
			asset.Parent = world
			
			-- Manual Bounding Box & Centering
			local min = Vector3.new(math.huge, math.huge, math.huge)
			local max = Vector3.new(-math.huge, -math.huge, -math.huge)
			local parts = {}
			
			for _, d in ipairs(asset:GetDescendants()) do
				if d:IsA("BasePart") then
					table.insert(parts, d)
					-- Ensure anchored for viewport
					d.Anchored = true
					
					local size = d.Size
					local cf = d.CFrame
					local corners = {
						cf * Vector3.new(size.X/2, size.Y/2, size.Z/2),
						cf * Vector3.new(size.X/2, size.Y/2, -size.Z/2),
						cf * Vector3.new(size.X/2, -size.Y/2, size.Z/2),
						cf * Vector3.new(size.X/2, -size.Y/2, -size.Z/2),
						cf * Vector3.new(-size.X/2, size.Y/2, size.Z/2),
						cf * Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
						cf * Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
						cf * Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
					}
					for _, c in ipairs(corners) do
						min = Vector3.new(math.min(min.X, c.X), math.min(min.Y, c.Y), math.min(min.Z, c.Z))
						max = Vector3.new(math.max(max.X, c.X), math.max(max.Y, c.Y), math.max(max.Z, c.Z))
					end
				end
			end
			
			if #parts > 0 then
				local center = (min + max) / 2
				local size = max - min
				local offset = -center
				
				-- Shift all parts to origin
				for _, p in ipairs(parts) do
					p.CFrame = p.CFrame + offset
				end
				
				currentDist = math.max(size.Magnitude, 3) * 1.2
			else
				-- No parts found?
				currentDist = 5
			end
		else
			-- Red Part Fail
			local box = Instance.new("Part")
			box.Color = Color3.fromRGB(255, 50, 50)
			box.Size = Vector3.new(1.5, 1.5, 1.5)
			box.Material = Enum.Material.Neon
			box.Parent = world
			currentDist = 5
		end
		updateCamera()
	end
	
	self._trove:Add(self.Scope:Observer(self.SelectedSkin):onChange(update))
	task.defer(update)
	
	-- Rotate Camera
	self._trove:Add(self.Scope:Observer(self.PreviewRotation):onChange(updateCamera))
	
	return self.Scope:New "ViewportFrame" {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		CurrentCamera = cam,
		Ambient = Color3.fromRGB(150, 150, 150),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(1, 1, 1),
		[Children] = { world }
	}
end

-- Instantiate singleton
CarrotSkinUI.new()

return CarrotSkinUI
