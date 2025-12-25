local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)

local Children = Fusion.Children
local New = Fusion.New
local Computed = Fusion.Computed
local ForValues = Fusion.ForValues

local GameOverBoard = {}

function GameOverBoard.new(scope, props)
    local stats = props.stats

    return scope:New "Frame" {
        Name = "RankingBoard",
        Size = UDim2.fromScale(1, 1), 
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.4, 
        Visible = scope:Computed(function(use)
            return use(stats) ~= nil
        end),
        
        [Children] = {
            -- Center Content
            scope:New "Frame" {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(0.5, 0.6), 
                BackgroundColor3 = Color3.fromRGB(35, 35, 40),
                
                [Children] = {
                    scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
                    scope:New "UIStroke" { Thickness = 3, Color = Color3.fromRGB(60, 60, 65) }, 
                    
                    scope:New "UIPadding" { 
                        PaddingTop = UDim.new(0, 0), 
                        PaddingBottom = UDim.new(0, 15), 
                        PaddingLeft = UDim.new(0, 15), 
                        PaddingRight = UDim.new(0, 15) 
                    },
                    
                    scope:New "UIListLayout" {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        Padding = UDim.new(0, 0)
                    },
                    
                    -- Header Section
                    scope:New "Frame" {
                        LayoutOrder = 1,
                        Size = UDim2.new(1, 30, 0, 70),
                        BackgroundColor3 = Color3.fromRGB(25, 25, 30),
                        BackgroundTransparency = 0,
                        BorderSizePixel = 0,
                        
                        [Children] = {
                            scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
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
                        Size = UDim2.new(1, 0, 1, -120),
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
                                            Size = UDim2.new(0.6, -52, 1, 0), 
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
                                            TextTransparency = 0.5
                                        },
                                    }
                                }
                            end)
                        }
                    }
                }
            }
        }
    }
end

return GameOverBoard
