local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)

local Children = Fusion.Children

local SoftShutdownComponent = {}

function SoftShutdownComponent.new(props)
    local scope = props.scope
    local parent = props.Parent
    
    local transparency = scope:Value(1)
    
    -- Fade in animation
    task.spawn(function()
        task.wait(0.1)
        transparency:set(0)
    end)
    
    local animatedTransparency = scope:Spring(transparency, 15, 0.8)

    local screenGui = scope:New "ScreenGui" {
        Name = "SoftShutdownUI",
        Parent = parent,
        DisplayOrder = 100,
        IgnoreGuiInset = true,
        
        [Children] = {
            scope:New "Frame" {
                Name = "Overlay",
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.fromRGB(15, 15, 15),
                BackgroundTransparency = animatedTransparency,
                
                [Children] = {
                    scope:New "Frame" {
                        Name = "CenterGroup",
                        Size = UDim2.fromScale(0.4, 0.2),
                        Position = UDim2.fromScale(0.5, 0.5),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        
                        [Children] = {
                            scope:New "TextLabel" {
                                Name = "Title",
                                Size = UDim2.new(1, 0, 0.5, 0),
                                BackgroundTransparency = 1,
                                Text = "SERVER RESTARTING",
                                TextColor3 = Color3.fromRGB(240, 240, 240),
                                Font = Enum.Font.GothamBold,
                                TextSize = 32,
                                TextTransparency = animatedTransparency,
                            },
                            scope:New "TextLabel" {
                                Name = "Subtitle",
                                Size = UDim2.new(1, 0, 0.3, 0),
                                Position = UDim2.fromScale(0, 0.6),
                                BackgroundTransparency = 1,
                                Text = "The server is being updated. Please wait a moment...",
                                TextColor3 = Color3.fromRGB(180, 180, 180),
                                Font = Enum.Font.Gotham,
                                TextSize = 16,
                                TextTransparency = animatedTransparency,
                            },
                            scope:New "Frame" {
                                Name = "LoadingBar",
                                Size = UDim2.new(0.6, 0, 0, 2),
                                Position = UDim2.fromScale(0.5, 1),
                                AnchorPoint = Vector2.new(0.5, 0),
                                BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                                BorderSizePixel = 0,
                                
                                [Children] = {
                                    scope:New "Frame" {
                                        Name = "Progress",
                                        Size = UDim2.fromScale(0.3, 1), -- Simple static progress for now
                                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                        BorderSizePixel = 0,
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    return screenGui
end

return SoftShutdownComponent
