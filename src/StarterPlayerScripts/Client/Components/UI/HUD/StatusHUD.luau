local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)

local Children = Fusion.Children
local New = Fusion.New
local Computed = Fusion.Computed

local StatusHUD = {}

function StatusHUD.new(scope, props)
    local status = props.status
    local timeLeft = props.timeLeft
    local message = props.message
    local stats = props.stats 

    return scope:New "Frame" {
        Name = "Container",
        Size = UDim2.new(1, 0, 0.15, 0),
        Position = UDim2.fromScale(0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        
        [Children] = {
            scope:New "UIPadding" { PaddingTop = UDim.new(0, 5) }, 
            scope:New "UIListLayout" {
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top, 
                Padding = UDim.new(0, 0)
            },

            -- Main Message
            scope:New "TextLabel" {
                Name = "MainText",
                LayoutOrder = 1,
                Size = UDim2.new(1, 0, 0, 30),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text = scope:Computed(function(use)
                    local s = use(status)
                    local m = use(message)
                    
                    if m == "GO!" then return "" end 
                    
                    if m and m ~= "" then
                        return m
                    elseif s == "Intermission" then
                        return "NEXT ROUND IN"
                    elseif s == "Round" then
                        return "TIME LEFT"
                    elseif s == "Ended" then
                        return "ROUND OVER"
                    end
                    return ""
                end),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.GothamBlack,
                TextSize = 24,
                TextStrokeTransparency = 0.5,
                Visible = scope:Computed(function(use)
                    return use(stats) == nil
                end),
            },
            
            -- Timer
            scope:New "TextLabel" {
                Name = "TimerText",
                LayoutOrder = 2,
                Size = UDim2.new(1, 0, 0, 50),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text = scope:Computed(function(use)
                    local m = use(message)
                    local t = use(timeLeft)
                        if m and m ~= "" then
                        return "" 
                    end
                    return tostring(t)
                end),
                TextColor3 = scope:Computed(function(use)
                    local t = use(timeLeft)
                    if t <= 5 then
                        return Color3.fromRGB(255, 80, 80) 
                    end
                    return Color3.fromRGB(255, 255, 255) 
                end),
                Font = Enum.Font.FredokaOne,
                TextSize = 48,
                TextStrokeTransparency = 0,
                Visible = scope:Computed(function(use)
                    return use(stats) == nil
                end),
                
                [Children] = {
                    scope:New "UIStroke" {
                        Thickness = 3,
                        Color = Color3.fromRGB(0, 0, 0)
                    }
                }
            }
        }
    }
end

return StatusHUD
