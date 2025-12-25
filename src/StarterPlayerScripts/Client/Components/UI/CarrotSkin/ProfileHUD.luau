local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)

local Children = Fusion.Children
local New = Fusion.New
local Computed = Fusion.Computed

local ProfileHUD = {}

local THEME = {
	BG_SEC = Color3.fromRGB(30, 30, 36),
	TEXT_MAIN = Color3.fromRGB(255, 255, 255),
	ACCENT_GOLD = Color3.fromRGB(255, 200, 50),
	ACCENT_ORANGE = Color3.fromRGB(255, 120, 40),
}

function ProfileHUD.new(scope, props)
    local player = props.player
    local Coins = props.Coins
    local CarrotScale = props.CarrotScale

	return scope:New "Frame" {
		Name = "ProfileHUD",
		Size = UDim2.fromOffset(320, 100), 
		Position = UDim2.new(0, 30, 1, -30),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		
		[Children] = {
			-- Glass Background
			scope:New "Frame" {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(10, 10, 12),
				BackgroundTransparency = 0.3,
				[Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 20) }, 
					scope:New "UIStroke" { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Thickness = 1 },
					
					-- Avatar Circle
					scope:New "ImageLabel" {
						Size = UDim2.fromOffset(80, 80),
						Position = UDim2.new(0, 12, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = THEME.BG_SEC,
						Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150),
						[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(1, 0) } }
					},
					
					-- Info Stack
					scope:New "Frame" {
						Position = UDim2.fromOffset(90, 15),
						Size = UDim2.new(1, -100, 1, -30),
						BackgroundTransparency = 1,
						[Children] = {
							scope:New "UIListLayout" { Padding = UDim.new(0, 4) },
							
							-- Name
							scope:New "TextLabel" {
								Text = player.DisplayName,
								Font = Enum.Font.FredokaOne,
								TextSize = 18,
								TextColor3 = THEME.TEXT_MAIN,
								Size = UDim2.new(1,0,0,20),
								BackgroundTransparency = 1,
								TextXAlignment = Enum.TextXAlignment.Left,
							},
							
							-- Coins
							scope:New "TextLabel" {
								Text = scope:Computed(function(use) return "💰 " .. string.format("%d", use(Coins)) end),
								Font = Enum.Font.FredokaOne,
								TextSize = 16,
								TextColor3 = THEME.ACCENT_GOLD,
								Size = UDim2.new(1,0,0,20),
								BackgroundTransparency = 1,
								TextXAlignment = Enum.TextXAlignment.Left,
							},
							
							-- Scale Bar
							scope:New "Frame" {
								Size = UDim2.new(1, 0, 0, 12),
								BackgroundTransparency = 1,
								[Children] = {
									scope:New "UIListLayout" { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,6), VerticalAlignment = Enum.VerticalAlignment.Center },
									
									scope:New "TextLabel" {
										Text = scope:Computed(function(use) return string.format("x%.1f", use(CarrotScale)) end),
										Font = Enum.Font.Code,
										TextSize = 14,
										TextColor3 = THEME.ACCENT_ORANGE,
										Size = UDim2.new(0,35,1,0),
										BackgroundTransparency = 1,
									},
									
									-- Bar
									scope:New "Frame" {
										Size = UDim2.new(1, -45, 0, 10), 
										BackgroundColor3 = Color3.fromRGB(0,0,0),
										BackgroundTransparency = 0.5,
										[Children] = {
											scope:New "UICorner" { CornerRadius = UDim.new(1,0) },
											scope:New "Frame" {
												BackgroundColor3 = THEME.ACCENT_ORANGE,
												Size = scope:Computed(function(use)
													local s = use(CarrotScale)
													-- Max scale is 3.0, Base is 1.0. Range is 2.0.
													local progress = math.clamp((s - 1) / 2, 0, 1)
													return UDim2.fromScale(progress, 1)
												end),
												[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(1,0) } }
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

return ProfileHUD
