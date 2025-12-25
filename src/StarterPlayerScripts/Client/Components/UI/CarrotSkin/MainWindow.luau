local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)

local Children = Fusion.Children
local New = Fusion.New
local Computed = Fusion.Computed

local SkinGrid = require(script.Parent.SkinGrid)
local SkinDetails = require(script.Parent.SkinDetails)

local MainWindow = {}

function MainWindow.new(scope, props)
    local IsOpen = props.IsOpen
    local Tab = props.Tab
    
    local UnlockedSkins = props.UnlockedSkins
    local SelectedSkin = props.SelectedSkin
    local EquippedSkin = props.EquippedSkin
    local PreviewRotation = props.PreviewRotation

	return scope:New "Frame" {
		Name = "MainWindow",
		Size = UDim2.fromOffset(800, 500),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(20, 20, 24),
		BackgroundTransparency = 0.1,
		Visible = IsOpen,
		
		[Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 16) },
			scope:New "UIStroke" { Color = Color3.fromRGB(60, 60, 70), Thickness = 2 },
			
			-- Header
			scope:New "TextLabel" {
				Text = scope:Computed(function(use) return use(Tab):upper() end),
				Font = Enum.Font.FredokaOne,
				TextSize = 32,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.new(1, -40, 0, 60),
				Position = UDim2.new(0, 20, 0, 0),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
			},

            -- Close Button
			scope:New "TextButton" {
				Text = "X",
				Font = Enum.Font.FredokaOne,
				TextSize = 24,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				Size = UDim2.fromOffset(40, 40),
				Position = UDim2.new(1, -10, 0, 10),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				[Fusion.OnEvent "Activated"] = function() IsOpen:set(false) end,
			},
			
			-- Content Container (Split View)
			scope:New "Frame" {
				Size = UDim2.new(1, -40, 1, -80),
				Position = UDim2.new(0, 20, 0, 70),
				BackgroundTransparency = 1,
				
				[Children] = {
					scope:New "UIListLayout" { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 20) },
					
					-- Left: Grid (Skins/Shop)
					scope:New "ScrollingFrame" {
						Size = UDim2.new(0.6, 0, 1, 0),
						BackgroundTransparency = 1,
						ScrollBarThickness = 6,
						ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80),
						CanvasSize = UDim2.new(0,0,0,0),
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						
						[Children] = {
							scope:New "UIGradient" { 
								Transparency = NumberSequence.new({
									NumberSequenceKeypoint.new(0,0),
									NumberSequenceKeypoint.new(0.9,0),
									NumberSequenceKeypoint.new(1,1) -- Fade out bottom
								}),
								Rotation = 90
							},
							scope:New "UIGridLayout" {
								CellSize = UDim2.fromOffset(130, 160),
								CellPadding = UDim2.fromOffset(10, 10),
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
							},
							scope:New "UIPadding" { PaddingBottom = UDim.new(0, 20) },
							
							-- Grid Items
							SkinGrid.new(scope, props)
						}
					},
					
					-- Right: Inspector
					scope:New "Frame" {
						Size = UDim2.new(0.4, -20, 1, 0),
						BackgroundColor3 = Color3.fromRGB(30, 30, 36),
						[Children] = {
							scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
							SkinDetails.new(scope, props)
						}
					}
				}
			}
		}
	}
end

return MainWindow
