local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)

local Children = Fusion.Children
local New = Fusion.New
local Computed = Fusion.Computed
local Value = Fusion.Value
local Tween = Fusion.Tween
local Spring = Fusion.Spring

local AnnouncerUI = {}

function AnnouncerUI.new(props)
    local scope = props.scope
    local status = props.status
    local timeLeft = props.timeLeft
    local message = props.message
    
    local parent = props.Parent
    
    local gui = scope:New "ScreenGui" {
        Name = "AnnouncerUI",
        Parent = parent,
        ResetOnSpawn = false,
        DisplayOrder = 100, -- High priority to be on top
        
        [Children] = {
            scope:New "Frame" {
                Name = "Container",
                Size = UDim2.new(1, 0, 0.2, 0),
                Position = UDim2.fromScale(0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                
                [Children] = {
                    scope:New "UIListLayout" {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 5) -- Fixed 5px gap
                    },

                    -- Main Message (e.g., "Round Starts in...")
                    scope:New "TextLabel" {
                        Name = "MainText",
                        LayoutOrder = 1,
                        Size = UDim2.new(1, 0, 0, 40),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Text = scope:Computed(function(use)
                            local s = use(status)
                            local t = use(timeLeft)
                            local m = use(message)
                            
                            if m and m ~= "" then
                                return m
                            elseif s == "Intermission" then
                                return "Next Round in..."
                            elseif s == "Round" then
                                return "Time Remaining"
                            elseif s == "Ended" then
                                return "Round Ended"
                            end
                            return ""
                        end),
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        Font = Enum.Font.FredokaOne,
                        TextSize = 32,
                        TextStrokeTransparency = 0.5,
                        
                        [Children] = {
                            scope:New "UIStroke" {
                                Thickness = 2,
                                Color = Color3.fromRGB(0, 0, 0)
                            }
                        }
                    },
                    
                    -- Timer / Emphasis Text
                    scope:New "TextLabel" {
                        Name = "TimerText",
                        LayoutOrder = 2,
                        Size = UDim2.new(1, 0, 0, 40),
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
                                return Color3.fromRGB(255, 50, 50) -- Red alert
                            end
                            return Color3.fromRGB(255, 200, 50) -- Normal Gold-ish
                        end),
                        Font = Enum.Font.FredokaOne,
                        TextSize = 32,
                        TextStrokeTransparency = 0,
                        
                        [Children] = {
                            scope:New "UIStroke" {
                                Thickness = 3,
                                Color = Color3.fromRGB(0, 0, 0)
                            }
                        }
                    }
                }
            }
        }
    }
    
    return gui
end

return AnnouncerUI
