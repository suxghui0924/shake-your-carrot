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
                    -- Main Message (e.g., "Round Starts in...")
                    scope:New "TextLabel" {
                        Name = "MainText",
                        Size = UDim2.new(1, 0, 0.4, 0),
                        Position = UDim2.fromScale(0.5, 0.35),
                        AnchorPoint = Vector2.new(0.5, 0.5),
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
                        TextSize = 32, -- Increased from 24
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
                        Size = UDim2.new(1, 0, 0.5, 0),
                        Position = UDim2.fromScale(0.5, 0.65),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Text = scope:Computed(function(use)
                            local m = use(message)
                            -- If there's a specific message (like "GO!"), hiding the timer might be cleaner?
                            -- For now showing timer always if message is nil or empty, or if we want to show both.
                            -- Actually, let's just show time numbers.
                            local t = use(timeLeft)
                             if m and m ~= "" then
                                return "" -- Message takes precedence visually in the main text slot? 
                                          -- Wait, main text slot logic above puts message there. 
                                          -- If message is "GO!", we probably don't need the timer below it immediately.
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
                        TextSize = 32, -- Decreased from 48
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
