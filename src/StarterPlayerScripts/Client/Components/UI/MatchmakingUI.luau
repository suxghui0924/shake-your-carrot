-- src/StarterPlayerScripts/Client/Components/UI/MatchmakingUI.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

local MatchmakingUI = {}

function MatchmakingUI.new(props)
    local scope = props.scope
    local controller = props.Controller
    local parent = props.Parent
    
    local isQueued = controller.isQueued
    local statusText = controller.statusText
    local elapsedTime = controller.elapsedTime
    
    return scope:New "ScreenGui" {
        Name = "MatchmakingUI",
        Parent = parent,
        ResetOnSpawn = false,
        DisplayOrder = 10,
        
        [Children] = {
            scope:New "Frame" {
                Name = "Container",
                Size = UDim2.fromOffset(250, 100),
                Position = UDim2.new(0.5, 0, 1, -120),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                BackgroundTransparency = 0.3,
                
                [Children] = {
                    scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
                    scope:New "UIStroke" { Color = Color3.fromRGB(100, 100, 100), Thickness = 1 },
                    
                    scope:New "TextButton" {
                        Name = "JoinButton",
                        Size = UDim2.new(0.9, 0, 0.4, 0),
                        Position = UDim2.fromScale(0.5, 0.3),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = scope:Computed(function(use)
                            return use(isQueued) and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(50, 150, 50)
                        end),
                        Text = scope:Computed(function(use)
                            return use(isQueued) and "Cancel Matchmaking" or "Join Matchmaking"
                        end),
                        TextColor3 = Color3.new(1, 1, 1),
                        Font = Enum.Font.GothamBold,
                        TextSize = 14,
                        
                        [OnEvent "MouseButton1Click"] = function()
                            controller:ToggleQueue()
                        end,
                        
                        [Children] = {
                            scope:New "UICorner" { CornerRadius = UDim.new(0, 6) }
                        }
                    },
                    
                    scope:New "TextLabel" {
                        Name = "StatusLabel",
                        Size = UDim2.new(0.9, 0, 0.3, 0),
                        Position = UDim2.fromScale(0.5, 0.75),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Text = scope:Computed(function(use)
                            if use(isQueued) then
                                return string.format("Searching... (%ds)", use(elapsedTime))
                            else
                                return use(statusText)
                            end
                        end),
                        TextColor3 = Color3.fromRGB(200, 200, 200),
                        Font = Enum.Font.Gotham,
                        TextSize = 12,
                    }
                }
            }
        }
    }
end

return MatchmakingUI
