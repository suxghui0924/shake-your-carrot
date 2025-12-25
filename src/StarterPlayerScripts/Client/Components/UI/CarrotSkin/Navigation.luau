local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)

local Children = Fusion.Children
local New = Fusion.New
local Computed = Fusion.Computed
local Value = Fusion.Value
local Spring = Fusion.Spring

local Navigation = {}

local THEME = {
	BG_SEC = Color3.fromRGB(30, 30, 36),
	TEXT_MAIN = Color3.fromRGB(255, 255, 255),
    ACCENT_ORANGE = Color3.fromRGB(255, 120, 40),
	ACCENT_GOLD = Color3.fromRGB(255, 200, 50),
}

local function CreateCircleButton(scope, icon, label, onClick)
    local isHovering = scope:Value(false)
    local springScale = scope:Spring(scope:Computed(function(use) return use(isHovering) and 1.1 or 1.0 end), 20, 0.8)
    
	return scope:New "TextButton" {
		Size = UDim2.fromOffset(80, 80),
		BackgroundColor3 = THEME.BG_SEC,
		Text = "",
		[Fusion.OnEvent "Activated"] = onClick,
        [Fusion.OnEvent "MouseEnter"] = function() isHovering:set(true) end,
        [Fusion.OnEvent "MouseLeave"] = function() isHovering:set(false) end,
		[Children] = {
            scope:New "UIScale" { Scale = springScale },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 20) }, 
			scope:New "UIStroke" { 
                Color = Color3.fromRGB(255,255,255), 
                Thickness = 2, 
                Transparency = 0,
                [Children] = {
                    scope:New "UIGradient" { Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, THEME.ACCENT_ORANGE),
                        ColorSequenceKeypoint.new(1, THEME.ACCENT_GOLD)
                    }), Rotation = 45 }
                }
            },
			
			scope:New "TextLabel" {
				Text = icon,
				TextSize = 32,
				Position = UDim2.fromScale(0.5, 0.4),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
			},
			scope:New "TextLabel" {
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

function Navigation.new(scope, props)
    local IsOpen = props.IsOpen
    local Tab = props.Tab
    
	return scope:New "Frame" {
		Size = UDim2.fromOffset(80, 200),
		Position = UDim2.new(1, -20, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Visible = scope:Computed(function(use) return not use(IsOpen) end),
		[Children] = {
			scope:New "UIListLayout" { Padding = UDim.new(0, 12) },
			
			CreateCircleButton(scope, "🥕", "SKINS", function()
				Tab:set("Skins")
				IsOpen:set(true)
			end),
			
			CreateCircleButton(scope, "💎", "SHOP", function()
				Tab:set("Shop")
				IsOpen:set(true)
			end),

            CreateCircleButton(scope, "📜", "QUESTS", function()
				local events = ReplicatedStorage:FindFirstChild("Events")
				local ev = events and events:FindFirstChild("ClientQuestToggle")
				if ev then ev:Fire() end
			end)
		}
	}
end

return Navigation
