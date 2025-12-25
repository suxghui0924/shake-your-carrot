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
	local splashScale = scope:Spring(splashScaleGoal, 14, 0.5) -- Slightly snappier
    
    -- Observe message for "GO!" to trigger splash
    local messageObserver = scope:Observer(message)
    local disconnectObserver = messageObserver:onChange(function()
        if peek(message) == "GO!" then
            -- Reset to visible instantly (or fade in fast)
            splashTransparency:set(0)
			
			-- Trigger Pop-in animation
			splashScaleGoal:set(0, true)
            splashScaleGoal:set(1)

            -- Wait for teleport to happen (approx 2s in server) + extra time
            task.delay(4, function()
                splashTransparency:set(1)
                splashScaleGoal:set(0) 
            end)
        end
    end)
    
    -- Cleanup observer on destroy
    table.insert(scope, disconnectObserver)
    
    local gui = scope:New "ScreenGui" {
        Name = "AnnouncerUI",
        Parent = parent,
        ResetOnSpawn = false,
        DisplayOrder = 1000, 
        IgnoreGuiInset = true, 
        
        [Children] = {
            -- Main Game UI Container (Timer/Status)
            scope:New "Frame" {
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
            },
			
			-- REVISED GAME OVER BOARD
			scope:New "Frame" {
				Name = "RankingBoard",
                Size = UDim2.fromScale(1, 1), -- Full screen dim
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.4, -- Dark overlay
				Visible = scope:Computed(function(use)
					return use(stats) ~= nil
				end),
				
				[Children] = {
					-- Center Content
					scope:New "Frame" {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.5, 0.6), -- Sized properly
						BackgroundColor3 = Color3.fromRGB(35, 35, 40),
						
						[Children] = {
							scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
							scope:New "UIStroke" { Thickness = 3, Color = Color3.fromRGB(60, 60, 65) }, 
							
							scope:New "UIPadding" { 
								PaddingTop = UDim.new(0, 0), -- Header is separate
								PaddingBottom = UDim.new(0, 15), 
								PaddingLeft = UDim.new(0, 15), 
								PaddingRight = UDim.new(0, 15) 
							},
							
							scope:New "UIListLayout" {
								SortOrder = Enum.SortOrder.LayoutOrder,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								Padding = UDim.new(0, 0)
							},
							
							-- Header Section (Outside padding? No, moved inside)
							scope:New "Frame" {
								LayoutOrder = 1,
								Size = UDim2.new(1, 30, 0, 70), -- Slightly wider to cover corners? No, keep inside.
								BackgroundColor3 = Color3.fromRGB(25, 25, 30),
								BackgroundTransparency = 0,
								BorderSizePixel = 0,
								
								[Children] = {
									scope:New "UICorner" { CornerRadius = UDim.new(0, 12) }, -- Rounded top
									-- Square off bottom
									scope:New "Frame" {
										Size = UDim2.new(1, 0, 0.5, 0),
										Position = UDim2.fromScale(0, 0.5),
										BackgroundColor3 = Color3.fromRGB(25, 25, 30),
										BorderSizePixel = 0
									},
									
									scope:New "TextLabel" {
										Size = UDim2.fromScale(1, 1),
										Text = "GAME OVER",
										Font = Enum.Font.FredokaOne,
										TextSize = 40,
										TextColor3 = Color3.fromRGB(255, 255, 255),
										BackgroundTransparency = 1,
										[Children] = {
											scope:New "UIStroke" { Thickness = 2, Color = Color3.fromRGB(0,0,0) }
										}
									}
								}
							},
							
							-- Column Labels
							scope:New "Frame" {
								LayoutOrder = 2,
								Size = UDim2.new(1, 0, 0, 40),
								BackgroundTransparency = 1,
								[Children] = {
									scope:New "UIListLayout" { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5) },
									scope:New "TextLabel" { Text = "PLAYER", Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(150, 150, 150), Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left },
									scope:New "TextLabel" { Text = "KILLS", Size = UDim2.new(0.2, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(150, 150, 150), Font = Enum.Font.GothamBold, TextSize = 12 },
									scope:New "TextLabel" { Text = "DEATHS", Size = UDim2.new(0.2, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(150, 150, 150), Font = Enum.Font.GothamBold, TextSize = 12 },
								}
							},
							
							-- List Container
							scope:New "ScrollingFrame" {
								LayoutOrder = 3,
								Size = UDim2.new(1, 0, 1, -120), -- Fill rest
								BackgroundTransparency = 1,
								CanvasSize = UDim2.new(0, 0, 0, 0), 
								AutomaticCanvasSize = Enum.AutomaticSize.Y,
								ScrollBarThickness = 4,
								ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80),
								
								[Children] = {
									scope:New "UIListLayout" {
										SortOrder = Enum.SortOrder.LayoutOrder,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,
										Padding = UDim.new(0, 8)
									},
									
									ForValues(scope, scope:Computed(function(use)
										return use(stats) or {}
									end), function(use, scope, item)
										
										local rank = item.Rank or 99
										local isFirst = item == (use(stats) or {})[1]
										
										-- Card Style
										local bgColor = isFirst and Color3.fromRGB(241, 196, 15) or Color3.fromRGB(50, 50, 55)
										local textColor = isFirst and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(240, 240, 240)
										
										return scope:New "Frame" {
											Name = "PlayerCard",
											Size = UDim2.new(1, -5, 0, 50),
											BackgroundColor3 = bgColor,
											
											[Children] = {
												scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
												
												scope:New "UIListLayout" { 
													FillDirection = Enum.FillDirection.Horizontal, 
													VerticalAlignment = Enum.VerticalAlignment.Center, 
													Padding = UDim.new(0, 10),
													SortOrder = Enum.SortOrder.LayoutOrder
												},
												scope:New "UIPadding" { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) },
												
												-- Avatar
												scope:New "ImageLabel" {
													LayoutOrder = 1,
													Size = UDim2.new(0, 32, 0, 32),
													BackgroundColor3 = Color3.fromRGB(80, 80, 80),
													BackgroundTransparency = 0.5,
													Image = "rbxthumb://type=AvatarHeadShot&id=" .. (item.UserId or 0) .. "&w=150&h=150",
													[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(1, 0) } }
												},
												
												-- Name
												scope:New "TextLabel" { 
													LayoutOrder = 2,
													Text = item.Name, 
													Size = UDim2.new(0.6, -52, 1, 0), -- Flex fill roughly
													BackgroundTransparency = 1, 
													TextColor3 = textColor, 
													Font = Enum.Font.GothamBold, 
													TextSize = 16, 
													TextXAlignment = Enum.TextXAlignment.Left,
													TextTruncate = Enum.TextTruncate.AtEnd
												},
												
												-- Kills
												scope:New "TextLabel" { 
													LayoutOrder = 3,
													Text = tostring(item.Kills), 
													Size = UDim2.new(0.2, 0, 1, 0), 
													BackgroundTransparency = 1, 
													TextColor3 = textColor, 
													Font = Enum.Font.FredokaOne, 
													TextSize = 20
												},
												
												-- Deaths
												scope:New "TextLabel" { 
													LayoutOrder = 4,
													Text = tostring(item.Deaths), 
													Size = UDim2.new(0.2, 0, 1, 0), 
													BackgroundTransparency = 1, 
													TextColor3 = textColor, 
													Font = Enum.Font.FredokaOne, 
													TextSize = 20,
													TextTransparency = 0.5 -- Subtler
												},
											}
										}
									end)
								}
							}
						}
					}
				}
			},
            
            -- SPLASH SCREEN (Top Layer)
            scope:New "CanvasGroup" {
                Name = "SplashScreen",
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(1, 1, 1), 
                BackgroundTransparency = 0, 
                
                -- Opacity Control
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
                                Padding = UDim.new(0, -20) -- Tighter stacking
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
                                    scope:New "UIStroke" { Thickness = 4, Color = Color3.fromRGB(0, 0, 0), Transparency = 0, LineJoinMode = Enum.LineJoinMode.Round }, -- Strong black outline 
                                    -- scope:New "UIStroke" { Thickness = 3, Color = Color3.fromRGB(255, 255, 255), LineJoinMode = Enum.LineJoinMode.Round }, -- Clean white outline
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
                },
                
                -- Bind Transparency to Spring
                GroupTransparency = splashString,
                Visible = scope:Computed(function(use)
                    return use(splashString) < 1 
                end)
            }
        }
    }
    
    return gui
end

return AnnouncerUI
