-- src/StarterPlayerScripts/Client/Components/UI/WordChainUI.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

local WordChainUI = {}

function WordChainUI.new(props)
    local scope = props.scope
    local controller = props.Controller
    local parent = props.Parent
    
    local currentWord = controller.currentWord
    local history = controller.history
    local lastPlayer = controller.lastPlayer
    
    local textBox -- Forward declaration for reference in event handlers
    
    local gui = scope:New "ScreenGui" {
        Name = "WordChainUI",
        Parent = parent,
        ResetOnSpawn = false,
        DisplayOrder = 10,
        
        [Children] = {
            scope:New "Frame" {
                Name = "MainContainer",
                Size = UDim2.fromOffset(400, 300),
                Position = UDim2.new(0.05, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.fromRGB(30, 30, 35),
                BackgroundTransparency = 0.2,
                
                [Children] = {
                    scope:New "UICorner" { CornerRadius = UDim.new(0, 10) },
                    scope:New "UIStroke" { Color = Color3.fromRGB(150, 150, 255), Thickness = 2 },
                    
                    -- Title
                    scope:New "TextLabel" {
                        Name = "Title",
                        Size = UDim2.new(1, 0, 0.15, 0),
                        BackgroundTransparency = 1,
                        Text = "끝말잇기",
                        TextColor3 = Color3.new(1, 1, 1),
                        Font = Enum.Font.GothamBold,
                        TextSize = 24,
                    },
                    
                    -- Current Word Display
                    scope:New "Frame" {
                        Name = "CurrentWordBox",
                        Size = UDim2.new(0.9, 0, 0.2, 0),
                        Position = UDim2.fromScale(0.5, 0.25),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = Color3.fromRGB(50, 50, 70),
                        
                        [Children] = {
                            scope:New "UICorner" { CornerRadius = UDim.new(0, 6) },
                            scope:New "TextLabel" {
                                Size = UDim2.new(1, 0, 0.7, 0),
                                BackgroundTransparency = 1,
                                Text = scope:Computed(function(use)
                                    local word = use(currentWord)
                                    return word == "" and "게임을 시작하세요!" or word
                                end),
                                TextColor3 = Color3.fromRGB(255, 255, 100),
                                Font = Enum.Font.GothamBold,
                                TextSize = 28,
                            },
                            scope:New "TextLabel" {
                                Size = UDim2.new(1, 0, 0.3, 0),
                                Position = UDim2.fromScale(0, 0.7),
                                BackgroundTransparency = 1,
                                Text = scope:Computed(function(use)
                                    local player = use(lastPlayer)
                                    return player ~= "" and string.format("마지막 입력: %s", player) or ""
                                end),
                                TextColor3 = Color3.fromRGB(150, 150, 150),
                                Font = Enum.Font.Gotham,
                                TextSize = 10,
                            }
                        }
                    },
                    
                    -- History List
                    scope:New "ScrollingFrame" {
                        Name = "HistoryList",
                        Size = UDim2.new(0.9, 0, 0.4, 0),
                        Position = UDim2.fromScale(0.5, 0.6),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        CanvasSize = UDim2.fromScale(0, 5),
                        ScrollBarThickness = 4,

                        [Children] = {
                            scope:New "UIListLayout" {
                                Padding = UDim.new(0, 4),
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                VerticalAlignment = Enum.VerticalAlignment.Bottom
                            },
                            scope:ForPairs(history, function(_, index, word)
                                return index, scope:New "TextLabel" {
                                    Size = UDim2.new(1, 0, 0, 25),
                                    BackgroundTransparency = 1,
                                    Text = word,
                                    TextColor3 = Color3.fromRGB(200, 200, 200),
                                    Font = Enum.Font.Gotham,
                                    TextSize = 14,
                                    TextXAlignment = Enum.TextXAlignment.Left
                                }
                            end)
                        }
                    },
                    
                    -- Input Area (TextBox)
                    (function()
                        textBox = scope:New "TextBox" {
                            Name = "WordInput",
                            Size = UDim2.new(0.7, 0, 0.15, 0),
                            Position = UDim2.new(0.05, 0, 0.9, 0),
                            AnchorPoint = Vector2.new(0, 1),
                            BackgroundColor3 = Color3.fromRGB(40, 40, 45),
                            Text = "",
                            PlaceholderText = "단어를 입력하세요...",
                            TextColor3 = Color3.new(1, 1, 1),
                            Font = Enum.Font.Gotham,
                            TextSize = 16,
                            ClearTextOnFocus = true,
                            
                            [OnEvent "FocusLost"] = function(enterPressed)
                                if enterPressed then
                                    local text = textBox.Text
                                    if text ~= "" then
                                        controller:SubmitWord(text)
                                        textBox.Text = ""
                                    end
                                end
                            end,

                            [Children] = {
                                scope:New "UICorner" { CornerRadius = UDim.new(0, 6) },
                                scope:New "UIStroke" { Color = Color3.fromRGB(100, 100, 100), Thickness = 1 }
                            }
                        }
                        return textBox
                    end)(),
                    
                    -- Submit Button
                    scope:New "TextButton" {
                        Name = "SubmitButton",
                        Size = UDim2.new(0.2, 0, 0.15, 0),
                        Position = UDim2.new(0.95, 0, 0.9, 0),
                        AnchorPoint = Vector2.new(1, 1),
                        BackgroundColor3 = Color3.fromRGB(50, 150, 50),
                        Text = "전송",
                        TextColor3 = Color3.new(1, 1, 1),
                        Font = Enum.Font.GothamBold,
                        TextSize = 14,
                        
                        [OnEvent "MouseButton1Click"] = function()
                            local text = textBox.Text
                            if text ~= "" then
                                controller:SubmitWord(text)
                                textBox.Text = ""
                            end
                        end,
                        
                        [Children] = {
                            scope:New "UICorner" { CornerRadius = UDim.new(0, 6) }
                        }
                    }
                }
            }
        }
    }
    
    return gui
end

return WordChainUI
