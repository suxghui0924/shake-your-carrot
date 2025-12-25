local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Fusion = require(script.Parent.Parent.Parent.Parent.Fusion)
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
                Name = "MainFrame",
                Position = UDim2.new(0, 20, 0.5, -100),
                Size = UDim2.new(0, 40, 0, 200),
                BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                BorderSizePixel = 0,
                
                [Fusion.Children] = {
                    New "Frame" {
                        Name = "Fill",
                        Position = UDim2.new(0, 0, 1, 0),
                        Size = Computed(function()
                            local scale = carrotScale:get()
                            local progress = math.min(1, (scale - 1) / 4) -- Max visual at 5x scale
                            return UDim2.new(1, 0, -progress, 0)
                        end),
                        AnchorPoint = Vector2.new(0, 1),
                        BackgroundColor3 = Color3.fromRGB(230, 126, 34),
                        BorderSizePixel = 0,
                    },
                    New "TextLabel" {
                        Text = Computed(function()
                            return string.format("x%.1f", carrotScale:get())
                        end),
                        Size = UDim2.new(1, 0, 0, 30),
                        Position = UDim2.new(0, 0, 1, 10),
                        BackgroundTransparency = 1,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextSize = 20,
                        Font = Enum.Font.GothamBold,
                    }
                }
            }
        }
    }
end

return GrowthGauge
