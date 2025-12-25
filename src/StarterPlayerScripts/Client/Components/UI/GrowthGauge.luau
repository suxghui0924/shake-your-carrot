local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Fusion = require(Packages.Fusion)

local New = Fusion.New
local Value = Fusion.Value
local Computed = Fusion.Computed

local GrowthGauge = {}

function GrowthGauge:Create(scope)
    local player = Players.LocalPlayer
    local carrotScale = Value(player:GetAttribute("CarrotScale") or 1.0)
    
    player.AttributeChanged:Connect(function(attr)
        if attr == "CarrotScale" then
            carrotScale:set(player:GetAttribute("CarrotScale") or 1.0)
        end
    end)

    return New "ScreenGui" {
        Name = "GrowthGaugeGui",
        Parent = player:WaitForChild("PlayerGui"),
        
        [Fusion.Children] = {
            New "Frame" {
                Name = "MainContainer",
                Position = UDim2.new(0, 20, 1, -20),
                Size = UDim2.fromOffset(250, 80),
                AnchorPoint = Vector2.new(0, 1),
                BackgroundTransparency = 1,
                
                [Fusion.Children] = {
                    -- Profile Circle (Placeholder for player Image)
                    New "Frame" {
                        Name = "ProfileCircle",
                        Size = UDim2.fromOffset(70, 70),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        
                        [Fusion.Children] = {
                            New "UICorner" { CornerRadius = UDim.new(1, 0) },
                            New "UIStroke" { 
                                Color = Color3.fromRGB(230, 126, 34),
                                Thickness = 3 
                            },
                        }
                    },
                    
                    -- Content Area (Name + Money + Gauge)
                    New "Frame" {
                        Name = "InfoPanel",
                        Size = UDim2.new(1, -60, 0, 55),
                        Position = UDim2.new(0, 50, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                        BackgroundTransparency = 0.2,
                        ZIndex = -1, -- Behind circle
                        
                        [Fusion.Children] = {
                            New "UICorner" { CornerRadius = UDim.new(0, 12) },
                            
                            -- Player Name
                            New "TextLabel" {
                                Name = "PlayerName",
                                Text = player.Name,
                                Size = UDim2.new(1, -20, 0, 20),
                                Position = UDim2.new(0, 30, 0, 8),
                                TextXAlignment = Enum.TextXAlignment.Left,
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                Font = Enum.Font.GothamBold,
                                TextSize = 16,
                                BackgroundTransparency = 1
                            },
                            
                            -- Growth Bar Background
                            New "Frame" {
                                Name = "GrowthBarBG",
                                Size = UDim2.new(1, -40, 0, 8),
                                Position = UDim2.new(0, 30, 1, -15),
                                BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                                
                               [Fusion.Children] = {
                                    New "UICorner" { CornerRadius = UDim.new(1, 0) },
                                    
                                    -- Growth Bar Fill
                                    New "Frame" {
                                        Name = "GrowthBarFill",
                                        Size = Computed(function()
                                            local scale = carrotScale:get()
                                            -- Progress: (scale - 1) / 4 => 0 to 1 as scale goes 1 to 5
                                            local progress = math.clamp((scale - 1) / 4, 0, 1)
                                            return UDim2.fromScale(progress, 1)
                                        end),
                                        BackgroundColor3 = Color3.fromRGB(230, 126, 34), -- Carrot Orange
                                        
                                        [Fusion.Children] = {
                                            New "UICorner" { CornerRadius = UDim.new(1, 0) }
                                        }
                                    }
                                } 
                            },
                            
                            -- Scale Text (e.g. "x1.5")
                            New "TextLabel" {
                                Name = "ScaleText",
                                Text = Computed(function()
                                   return string.format("x%.1f", carrotScale:get()) 
                                end),
                                Size = UDim2.new(0, 40, 0, 20),
                                Position = UDim2.new(1, -10, 0, 8),
                                AnchorPoint = Vector2.new(1, 0),
                                TextXAlignment = Enum.TextXAlignment.Right,
                                TextColor3 = Color3.fromRGB(255, 200, 50),
                                Font = Enum.Font.GothamBold,
                                TextSize = 14,
                                BackgroundTransparency = 1
                            }
                        }
                    }
                }
            }
        }
    }
end

return GrowthGauge
