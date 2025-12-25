local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)

local Children = Fusion.Children
local New = Fusion.New
local Computed = Fusion.Computed
local Value = Fusion.Value
local Spring = Fusion.Spring
local Observer = Fusion.Observer
local peek = Fusion.peek

local SplashScreen = {}

function SplashScreen.new(scope, props)
    local message = props.message
    
    -- Splash Screen State
    local splashTransparency = scope:Value(1)
	local splashString = scope:Spring(splashTransparency, 30, 1)
	
	-- Splash Animation Values (Scale)
	local splashScaleGoal = scope:Value(0)
	local splashScale = scope:Spring(splashScaleGoal, 14, 0.5)
    
    -- Observe message for "GO!" to trigger splash
    local messageObserver = scope:Observer(message)
    local disconnectObserver = messageObserver:onChange(function()
        if peek(message) == "GO!" then
            -- Reset to visible instantly
            splashTransparency:set(0)
			
			-- Trigger Pop-in animation
			splashScaleGoal:set(0, true)
            splashScaleGoal:set(1)

            -- Wait for teleport to happen
            task.delay(4, function()
                splashTransparency:set(1)
                splashScaleGoal:set(0) 
            end)
        end
    end)
    
    table.insert(scope, disconnectObserver)

    return scope:New "CanvasGroup" {
        Name = "SplashScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(1, 1, 1), 
        BackgroundTransparency = 0, 
        GroupTransparency = splashString,
        Visible = scope:Computed(function(use)
            return use(splashString) < 1 
        end),
        
        [Children] = {
             scope:New "UIGradient" {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 240, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                }),
                Rotation = 45
             },
             
             -- Centered Content
             scope:New "Frame" {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                
                [Children] = {
                     scope:New "UIListLayout" {
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, -20)
                     },
					 
					 -- Scale Wrapper
					 scope:New "UIScale" { Scale = splashScale },
                     
                     -- "shake"
                     scope:New "TextLabel" {
                        Text = "shake",
                        Font = Enum.Font.FredokaOne,
                        TextSize = 100,
                        TextColor3 = Color3.fromRGB(255, 255, 255), 
                        BackgroundTransparency = 1,
                        AutomaticSize = Enum.AutomaticSize.XY,
                        [Children] = {
							scope:New "UIGradient" { Color = ColorSequence.new(Color3.fromRGB(255, 160, 20), Color3.fromRGB(255, 100, 0)), Rotation = 90 },
                            scope:New "UIStroke" { Thickness = 4, Color = Color3.fromRGB(0, 0, 0), Transparency = 0, LineJoinMode = Enum.LineJoinMode.Round }, 
                        }
                     },
                     -- "your"
                     scope:New "TextLabel" {
                        Text = "your",
                        Font = Enum.Font.FredokaOne,
                        TextSize = 90,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 1,
                         AutomaticSize = Enum.AutomaticSize.XY,
                         [Children] = {
							scope:New "UIGradient" { Color = ColorSequence.new(Color3.fromRGB(255, 180, 40), Color3.fromRGB(255, 120, 0)), Rotation = 90 },
                            scope:New "UIStroke" { Thickness = 3, Color = Color3.fromRGB(0, 0, 0), Transparency = 0, LineJoinMode = Enum.LineJoinMode.Round }
                         }
                     },
                     -- "carrot!"
                     scope:New "TextLabel" {
                        Text = "carrot!",
                        Font = Enum.Font.FredokaOne,
                        TextSize = 120,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 1,
                         AutomaticSize = Enum.AutomaticSize.XY,
                         [Children] = {
							scope:New "UIGradient" { Color = ColorSequence.new(Color3.fromRGB(255, 140, 20), Color3.fromRGB(255, 80, 0)), Rotation = 90 },
                            scope:New "UIStroke" { Thickness = 3, Color = Color3.fromRGB(0, 0, 0), Transparency = 0, LineJoinMode = Enum.LineJoinMode.Round }
                         }
                     }
                }
             }
        }
    }
end

return SplashScreen
