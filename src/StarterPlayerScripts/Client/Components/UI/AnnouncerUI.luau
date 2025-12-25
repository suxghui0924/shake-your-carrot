local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)

local Children = Fusion.Children
local New = Fusion.New
local Computed = Fusion.Computed
local Value = Fusion.Value
local Tween = Fusion.Tween
local Spring = Fusion.Spring

local ForValues = Fusion.ForValues
local Observer = Fusion.Observer
local peek = Fusion.peek

local AnnouncerUI = {}

function AnnouncerUI.new(props)
    local scope = props.scope
    local status = props.status
    local timeLeft = props.timeLeft
    local message = props.message
    local stats = props.stats
    
    local parent = props.Parent
    
    -- Splash Screen State
    local splashTransparency = scope:Value(1)
	local splashString = scope:Spring(splashTransparency, 30, 1)
	-- Splash Animation Values (Scale/Rotation)
	local splashScaleGoal = scope:Value(0)
	local splashScale = scope:Spring(splashScaleGoal, 12, 0.6) -- Bouncy scale
	local splashRotation = scope:Value(0)
    
    -- Observe message for "GO!" to trigger splash
    local messageObserver = scope:Observer(message)
    local disconnectObserver = messageObserver:onChange(function()
        if peek(message) == "GO!" then
            -- Reset to visible instantly (or fade in fast)
            splashTransparency:set(0)
			
			-- Trigger Pop-in animation
			splashScaleGoal:set(0, true) -- Force reset to 0 instantly if supported or just set
            -- Fusion 0.3 Value:set(newValue, forceUpdate?) - usually just set(newValue)
            -- To ensure animation plays, we need it to start at 0 and go to 1.
            -- If it's already 0, just setting to 1 triggers spring.
            -- If it was 1 (from previous round?), we reset to 0 then 1.
            
            splashScaleGoal:set(0)
            -- Small delay inside frame or just rely on next update?
            -- Let's just set to 1. The spring will travel 0->1.
            splashScaleGoal:set(1)

            -- Wait for teleport to happen (approx 2s in server) + extra time
            task.delay(4, function()
                splashTransparency:set(1)
                splashScaleGoal:set(0) -- Reset scale for next time?
            end)
        end
    end)
    
    -- Cleanup observer on destroy (if scope handles it, great, but let's be safe if we could)
    table.insert(scope, disconnectObserver)
    
    local gui = scope:New "ScreenGui" {
        Name = "AnnouncerUI",
        Parent = parent,
        ResetOnSpawn = false,
        DisplayOrder = 1000, -- Highest priority
        IgnoreGuiInset = true, 
        
        [Children] = {
            -- Main Game UI Container (Timer/Status)
            scope:New "Frame" {
                Name = "Container",
                Size = UDim2.new(1, 0, 0.2, 0),
                Position = UDim2.fromScale(0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                
                [Children] = {
                    scope:New "UIPadding" { PaddingTop = UDim.new(0, 10) }, 
                    scope:New "UIListLayout" {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Top, 
                        Padding = UDim.new(0, 5)
                    },

                    -- Main Message
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
                            
                            if m == "GO!" then return "" end -- Hide "GO!" text if splash is showing
                            
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
                        Visible = scope:Computed(function(use)
							-- Hide during ranking
							return use(stats) == nil
						end),
                        
                        [Children] = {
                            scope:New "UIStroke" {
                                Thickness = 2,
                                Color = Color3.fromRGB(0, 0, 0)
                            }
                        }
                    },
                    
                    -- Timer
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
                                return Color3.fromRGB(255, 50, 50) 
                            end
                            return Color3.fromRGB(255, 200, 50) 
                        end),
                        Font = Enum.Font.FredokaOne,
                        TextSize = 32,
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
            },
			
			-- PREMIUM RANKING BOARD (Bottom Layer)
			scope:New "Frame" {
				Name = "RankingBoard",
                Size = UDim2.fromScale(0.5, 0.6),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(30, 30, 35),
				BackgroundTransparency = 0.1,
				Visible = scope:Computed(function(use)
					return use(stats) ~= nil
				end),
				
				[Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 15) },
					scope:New "UIStroke" { Thickness = 2, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.8 },
					scope:New "UIPadding" { PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 20), PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20) },
					
					scope:New "UIListLayout" {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        Padding = UDim.new(0, 15) 
                    },
					
					-- Header
					scope:New "TextLabel" {
						LayoutOrder = 1,
						Text = "GAME OVER",
						Font = Enum.Font.FredokaOne,
						TextSize = 42,
						TextColor3 = Color3.fromRGB(250, 250, 250),
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 50),
						[Children] = {
							scope:New "UIStroke" { Thickness = 2, Color = Color3.fromRGB(255, 100, 100) },
							scope:New "UIGradient" {
								Color = ColorSequence.new({
									ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
									ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
								}),
								Rotation = 90
							}
                        }
					},
					
					-- Column Headers
					scope:New "Frame" {
						LayoutOrder = 2,
						Size = UDim2.new(1, 0, 0, 30),
						BackgroundTransparency = 1,
						[Children] = {
							scope:New "UIListLayout" { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10) },
							scope:New "TextLabel" { Text = "Player", Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(150, 150, 150), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left },
							scope:New "TextLabel" { Text = "Kills", Size = UDim2.new(0.2, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(150, 150, 150), Font = Enum.Font.GothamBold, TextSize = 14 },
							scope:New "TextLabel" { Text = "Deaths", Size = UDim2.new(0.2, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(150, 150, 150), Font = Enum.Font.GothamBold, TextSize = 14 },
						}
					},
					
					-- List
					scope:New "ScrollingFrame" {
						LayoutOrder = 3,
						Size = UDim2.new(1, 0, 0.7, 0),
						BackgroundTransparency = 1,
						CanvasSize = UDim2.new(0, 0, 0, 0), 
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						ScrollBarThickness = 4,
						ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200),
						
						[Children] = {
							scope:New "UIListLayout" {
								SortOrder = Enum.SortOrder.LayoutOrder,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								Padding = UDim.new(0, 8)
							},
							
							ForValues(scope, scope:Computed(function(use)
								return use(stats) or {}
							end), function(use, scope, item)
								
								local isFirst = item.Rank == 1 or item == (use(stats) or {})[1] -- Assuming sorted
								local bgColor = isFirst and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(50, 50, 55)
								local textColor = isFirst and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(255, 255, 255)
								
								return scope:New "Frame" {
									Name = "Card",
									Size = UDim2.new(1, -10, 0, 50),
									BackgroundColor3 = bgColor,
									BackgroundTransparency = 0,
									
									[Children] = {
										scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
										scope:New "UIStroke" { Thickness = 1, Color = Color3.fromRGB(255, 255, 255), Transparency = isFirst and 0 or 0.8 },
										scope:New "UIPadding" { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) },
										
										scope:New "UIListLayout" { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10) },
										
										-- Avatar
										scope:New "ImageLabel" {
											Size = UDim2.new(0, 30, 0, 30),
											BackgroundColor3 = Color3.fromRGB(200, 200, 200),
											BackgroundTransparency = 0.5,
											Image = "rbxthumb://type=AvatarHeadShot&id=" .. (item.UserId or 0) .. "&w=150&h=150",
											[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(1, 0) } }
										},
										
										-- Name
										scope:New "TextLabel" { 
											Text = item.Name, 
											Size = UDim2.new(0.5, -40, 1, 0), 
											BackgroundTransparency = 1, 
											TextColor3 = textColor, 
											Font = Enum.Font.GothamBold, 
											TextSize = 16, 
											TextXAlignment = Enum.TextXAlignment.Left,
											TextTruncate = Enum.TextTruncate.AtEnd
										},
										
										-- Kills
										scope:New "TextLabel" { Text = tostring(item.Kills), Size = UDim2.new(0.2, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = textColor, Font = Enum.Font.FredokaOne, TextSize = 18 },
										
										-- Deaths
										scope:New "TextLabel" { Text = tostring(item.Deaths), Size = UDim2.new(0.2, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = textColor, Font = Enum.Font.FredokaOne, TextSize = 18 },
									}
								}
							end)
						}
					}
				}
			},
            
            -- SPLASH SCREEN (Top Layer)
            scope:New "CanvasGroup" {
                Name = "SplashScreen",
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(1, 1, 1), 
                BackgroundTransparency = 0, -- Controlled by GroupTransparency
                
                -- Opacity Control
                [Children] = {
                     scope:New "UIGradient" {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 245, 230)),
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
                                Padding = UDim.new(0, -15) -- Overlap slightly for bubbly feel
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
									scope:New "UIGradient" { Color = ColorSequence.new(Color3.fromRGB(255, 180, 50), Color3.fromRGB(255, 100, 0)), Rotation = 90 },
                                    scope:New "UIStroke" { Thickness = 6, Color = Color3.fromRGB(255, 255, 255), LineJoinMode = Enum.LineJoinMode.Round }, 
									scope:New "UIStroke" { Thickness = 12, Color = Color3.fromRGB(255, 140, 0), Transparency = 0.5, LineJoinMode = Enum.LineJoinMode.Round } -- Outer glow fake
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
									scope:New "UIGradient" { Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 120, 0)), Rotation = 90 },
                                    scope:New "UIStroke" { Thickness = 6, Color = Color3.fromRGB(255, 255, 255), LineJoinMode = Enum.LineJoinMode.Round }
                                 }
                             },
                             -- "carrot!"
                             scope:New "TextLabel" {
                                Text = "carrot!",
                                Font = Enum.Font.FredokaOne,
                                TextSize = 110,
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                BackgroundTransparency = 1,
                                 AutomaticSize = Enum.AutomaticSize.XY,
                                 [Children] = {
									scope:New "UIGradient" { Color = ColorSequence.new(Color3.fromRGB(255, 160, 40), Color3.fromRGB(255, 80, 0)), Rotation = 90 },
                                    scope:New "UIStroke" { Thickness = 6, Color = Color3.fromRGB(255, 255, 255), LineJoinMode = Enum.LineJoinMode.Round }
                                 }
                             }
                        }
                     }
                },
                
                -- Bind Transparency to Spring
                GroupTransparency = splashString,
                Visible = scope:Computed(function(use)
                    return use(splashString) < 1 -- Hide when fully transparent
                end)
            }
        }
    }
    
    return gui
end

return AnnouncerUI
