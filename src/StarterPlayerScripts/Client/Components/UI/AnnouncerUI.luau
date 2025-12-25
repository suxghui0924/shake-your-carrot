local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
    
    -- Observe message for "GO!" to trigger splash
    local messageObserver = scope:Observer(message)
    local disconnectObserver = messageObserver:onChange(function()
        if peek(message) == "GO!" then
            -- Reset to visible instantly (or fade in fast)
            splashTransparency:set(0)
            
            -- Wait for teleport to happen (approx 2s in server) + extra time
            task.delay(4, function()
                splashTransparency:set(1)
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
            -- Main Game UI Container
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
			
			-- RANKING BOARD (Bottom Layer)
			scope:New "Frame" {
				Name = "RankingBoard",
                Size = UDim2.fromScale(0.6, 0.6),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.3,
				Visible = scope:Computed(function(use)
					return use(stats) ~= nil
				end),
				
				[Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 10) },
					scope:New "UIListLayout" {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        Padding = UDim.new(0, 10) 
                    },
					scope:New "UIPadding" { PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 20) },
					
					-- Header
					scope:New "TextLabel" {
						LayoutOrder = 1,
						Text = "GAME OVER",
						Font = Enum.Font.FredokaOne,
						TextSize = 48,
						TextColor3 = Color3.fromRGB(255, 50, 50),
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 60),
						[Children] = {
                            scope:New "UIStroke" {
                                Thickness = 3,
                                Color = Color3.fromRGB(0, 0, 0)
                            }
                        }
					},
					
					-- Stats Header
					scope:New "Frame" {
						LayoutOrder = 2,
						Size = UDim2.new(0.9, 0, 0, 30),
						BackgroundTransparency = 1,
						[Children] = {
							scope:New "UIListLayout" { FillDirection = Enum.FillDirection.Horizontal },
							scope:New "TextLabel" { Text = "Player", Size = UDim2.fromScale(0.6, 1), BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.FredokaOne, TextSize = 20 },
							scope:New "TextLabel" { Text = "Kills", Size = UDim2.fromScale(0.2, 1), BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.FredokaOne, TextSize = 20 },
							scope:New "TextLabel" { Text = "Deaths", Size = UDim2.fromScale(0.2, 1), BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.FredokaOne, TextSize = 20 },
						}
					},
					
					-- List
					scope:New "ScrollingFrame" {
						LayoutOrder = 3,
						Size = UDim2.new(0.9, 0, 0.7, 0),
						BackgroundTransparency = 1,
						CanvasSize = UDim2.new(0, 0, 0, 0), 
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						ScrollBarThickness = 6,
						
						[Children] = {
							scope:New "UIListLayout" {
								SortOrder = Enum.SortOrder.LayoutOrder,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								Padding = UDim.new(0, 5)
							},
							
							ForValues(scope, scope:Computed(function(use)
								return use(stats) or {}
							end), function(use, scope, item)
								return scope:New "Frame" {
									Size = UDim2.new(1, 0, 0, 40),
									BackgroundColor3 = Color3.fromRGB(255, 255, 255),
									BackgroundTransparency = 0.9,
									[Children] = {
										scope:New "UICorner" { CornerRadius = UDim.new(0, 5) },
										scope:New "UIListLayout" { FillDirection = Enum.FillDirection.Horizontal },
										scope:New "TextLabel" { Text = item.Name, Size = UDim2.fromScale(0.6, 1), BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.FredokaOne, TextSize = 18 },
										scope:New "TextLabel" { Text = tostring(item.Kills), Size = UDim2.fromScale(0.2, 1), BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.FredokaOne, TextSize = 18 },
										scope:New "TextLabel" { Text = tostring(item.Deaths), Size = UDim2.fromScale(0.2, 1), BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.FredokaOne, TextSize = 18 },
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
                BackgroundColor3 = Color3.new(1, 1, 1), -- White background or customized? User didn't specify BG, but fades usually involve a cover.
                -- Let's make it a nice radial gradient or just simple color.
                -- User image has "Shake Your Carrot" text. Let's assume white or light BG looks clean.
                BackgroundTransparency = 0, -- Controlled by GroupTransparency
                
                -- Opacity Control
                [Children] = {
                     scope:New "UIGradient" {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 212, 172)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                        }),
                        Rotation = 45
                     },
                     
                     scope:New "UIListLayout" {
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, -10) -- Stack tight
                     },
                     
                     -- "shake"
                     scope:New "TextLabel" {
                        Text = "shake",
                        Font = Enum.Font.FredokaOne,
                        TextSize = 80,
                        TextColor3 = Color3.fromRGB(255, 140, 0), -- Orange
                        BackgroundTransparency = 1,
                        AutomaticSize = Enum.AutomaticSize.XY,
                        [Children] = {
                            scope:New "UIStroke" { Thickness = 4, Color = Color3.fromRGB(255, 255, 255) }, -- White outline
                            -- Inner shadow or 2nd stroke workaround not easy in Fusion single stroke?
                            -- We can just do one thick white outline.
                        }
                     },
                     -- "your"
                     scope:New "TextLabel" {
                        Text = "your",
                        Font = Enum.Font.FredokaOne,
                        TextSize = 80,
                        TextColor3 = Color3.fromRGB(255, 140, 0),
                        BackgroundTransparency = 1,
                         AutomaticSize = Enum.AutomaticSize.XY,
                         [Children] = {
                            scope:New "UIStroke" { Thickness = 4, Color = Color3.fromRGB(255, 255, 255) }
                         }
                     },
                     -- "carrot!"
                     scope:New "TextLabel" {
                        Text = "carrot!",
                        Font = Enum.Font.FredokaOne,
                        TextSize = 80,
                        TextColor3 = Color3.fromRGB(255, 140, 0),
                        BackgroundTransparency = 1,
                         AutomaticSize = Enum.AutomaticSize.XY,
                         [Children] = {
                            scope:New "UIStroke" { Thickness = 4, Color = Color3.fromRGB(255, 255, 255) }
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
