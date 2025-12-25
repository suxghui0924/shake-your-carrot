-- src/StarterPlayerScripts/Fusion/Components/PopupComponent.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)

local Children = Fusion.Children

local PopupComponent = {}

function PopupComponent.new(props)
    local scope = props.scope
    local parent = props.Parent
    local messages = props.messages
    local onRemove = props.onRemove
    
    return scope:New "ScreenGui" {
        Name = "NotificationUI",
        Parent = parent,
        DisplayOrder = 1000,
        
        [Children] = {
            scope:New "Frame" {
                Name = "NotificationList",
                Size = UDim2.new(0, 300, 1, -100),
                Position = UDim2.new(1, -20, 0, 50),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                
                [Children] = {
                    scope:New "UIListLayout" {
                        Padding = UDim.new(0, 10),
                        HorizontalAlignment = Enum.HorizontalAlignment.Right,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        SortOrder = Enum.SortOrder.LayoutOrder
                    },
                    
                    scope:ForPairs(messages, function(_, id, data)
                        local msgScope = Fusion.scoped(Fusion)
                        
                        -- Entry animation
                        local offset = msgScope:Value(350)
                        task.spawn(function()
                            task.wait()
                            offset:set(0)
                        end)
                        
                        local animatedOffset = msgScope:Spring(offset, 20, 0.7)
                        
                        -- Auto-remove logic (if duration is provided)
                        if data.duration and data.duration > 0 then
                            task.delay(data.duration, function()
                                offset:set(350)
                                task.wait(0.5)
                                if onRemove then onRemove(id) end
                                Fusion.doCleanup(msgScope)
                            end)
                        end

                        return id, msgScope:New "Frame" {
                            Name = "NotificationCard",
                            Size = UDim2.new(1, 0, 0, 80),
                            Position = msgScope:Computed(function(use)
                                return UDim2.fromOffset(use(animatedOffset), 0)
                            end),
                            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                            BackgroundTransparency = 0.2,
                            LayoutOrder = data.layoutOrder,
                            
                            [Children] = {
                                msgScope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
                                msgScope:New "UIStroke" { Color = Color3.fromRGB(150, 150, 255), Thickness = 1, Transparency = 0.5 },
                                
                                msgScope:New "UIListLayout" {
                                    FillDirection = Enum.FillDirection.Horizontal,
                                    Padding = UDim.new(0, 10),
                                    VerticalAlignment = Enum.VerticalAlignment.Center,
                                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                                },

                                msgScope:New "UIPadding" {
                                    PaddingLeft = UDim.new(0, 10),
                                    PaddingRight = UDim.new(0, 10)
                                },

                                msgScope:New "ImageLabel" {
                                    Name = "Icon",
                                    Size = UDim2.fromOffset(40, 40),
                                    BackgroundTransparency = 1,
                                    Image = data.icon or "rbxassetid://6031225818", -- Default info icon
                                    Visible = msgScope:Computed(function()
                                        return data.icon ~= nil
                                    end)
                                },

                                msgScope:New "TextLabel" {
                                    Name = "MessageText",
                                    Size = UDim2.new(1, -50, 1, 0),
                                    BackgroundTransparency = 1,
                                    Text = data.message,
                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                    Font = Enum.Font.Gotham,
                                    TextSize = 14,
                                    TextWrapped = true,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                },
                            }
                        }
                    end)
                }
            }
        }
    }
end

return PopupComponent
