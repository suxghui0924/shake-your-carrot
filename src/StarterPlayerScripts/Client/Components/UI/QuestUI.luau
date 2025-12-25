local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)

local Children = Fusion.Children
local New = Fusion.New
local Computed = Fusion.Computed
local Value = Fusion.Value
local Spring = Fusion.Spring

local ForValues = Fusion.ForValues
local Observer = Fusion.Observer
local peek = Fusion.peek

local QuestUI = {}

function QuestUI.new(props)
	local scope = props.scope
	local quests = props.quests
	local isVisible = props.isVisible
	local onClaim = props.onClaim
	local onClaim = props.onClaim
	local parent = props.Parent
	
	local gui = scope:New "ScreenGui" {
		Name = "QuestUI",
		Parent = parent,
		ResetOnSpawn = false,
		
		[Children] = {
			-- Main Quest Window
			scope:New "Frame" {
				Name = "QuestWindow",
				Size = UDim2.fromOffset(300, 400),
				Position = UDim2.new(1, -100, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(30, 30, 35),
				Visible = isVisible,
				
				[Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 15) },
					scope:New "UIStroke" { Thickness = 2, Color = Color3.fromRGB(100, 100, 100) },
					scope:New "UIPadding" { PaddingTop = UDim.new(0, 15), PaddingBottom = UDim.new(0, 15), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15) },
					
					scope:New "UIListLayout" {
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						Padding = UDim.new(0, 10)
					},
					
					-- Header
					scope:New "TextLabel" {
						LayoutOrder = 1,
						Text = "DAILY QUESTS",
						Font = Enum.Font.FredokaOne,
						TextSize = 28,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 30),
					},
					
					-- Scroll List
					scope:New "ScrollingFrame" {
						LayoutOrder = 2,
						Size = UDim2.new(1, 0, 1, -40),
						BackgroundTransparency = 1,
						CanvasSize = UDim2.new(0, 0, 0, 0),
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						ScrollBarThickness = 4,
						
						[Children] = {
							scope:New "UIListLayout" {
								SortOrder = Enum.SortOrder.LayoutOrder,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								Padding = UDim.new(0, 8)
							},
							
							ForValues(scope, scope:Computed(function(use)
								return use(quests) or {}
							end), function(use, scope, item)
								
								local progress = item.Progress
								local target = item.Target
								local percent = math.clamp(progress / target, 0, 1)
								local isCompleted = item.Completed
								local isClaimed = item.Claimed
								
								return scope:New "Frame" {
									Name = "QuestCard",
									Size = UDim2.new(1, 0, 0, 80),
									BackgroundColor3 = Color3.fromRGB(50, 50, 55),
									
									[Children] = {
										scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
										scope:New "UIPadding" { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) },
										
										-- Title
										scope:New "TextLabel" {
											Text = item.Title,
											Size = UDim2.new(1, 0, 0, 20),
											BackgroundTransparency = 1,
											TextColor3 = Color3.fromRGB(255, 255, 255),
											Font = Enum.Font.GothamBold,
											TextSize = 14,
											TextXAlignment = Enum.TextXAlignment.Left
										},
										
										-- Progress Bar BG
										scope:New "Frame" {
											Position = UDim2.new(0, 0, 0, 25),
											Size = UDim2.new(1, 0, 0, 10),
											BackgroundColor3 = Color3.fromRGB(30, 30, 30),
											[Children] = {
												scope:New "UICorner" { CornerRadius = UDim.new(1, 0) },
												-- Fill
												scope:New "Frame" {
													Size = UDim2.fromScale(percent, 1),
													BackgroundColor3 = Color3.fromRGB(241, 196, 15),
													[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(1, 0) } }
												}
											}
										},
										
										-- Progress Text
										scope:New "TextLabel" {
											Position = UDim2.new(0, 0, 0, 40),
											Text = progress .. " / " .. target,
											Size = UDim2.new(1, 0, 0, 15),
											BackgroundTransparency = 1,
											TextColor3 = Color3.fromRGB(150, 150, 150),
											Font = Enum.Font.Gotham,
											TextSize = 12,
											TextXAlignment = Enum.TextXAlignment.Left
										},
										
										-- Claim Button (Only if completed and not claimed)
										scope:New "TextButton" {
											Visible = isCompleted and not isClaimed,
											Text = "CLAIM",
											Size = UDim2.new(0, 60, 0, 25),
											Position = UDim2.new(1, 0, 1, 0),
											AnchorPoint = Vector2.new(1, 1),
											BackgroundColor3 = Color3.fromRGB(46, 204, 113),
											TextColor3 = Color3.fromRGB(255, 255, 255),
											Font = Enum.Font.GothamBold,
											TextSize = 12,
											
											[Fusion.OnEvent("Activated")] = function()
												onClaim(item.Id)
											end,
											
											[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 4) } }
										},
										
										-- Completed Label
										scope:New "TextLabel" {
											Visible = isClaimed,
											Text = "COMPLETED",
											Size = UDim2.new(0, 80, 0, 25),
											Position = UDim2.new(1, 0, 1, 0),
											AnchorPoint = Vector2.new(1, 1),
											BackgroundTransparency = 1,
											TextColor3 = Color3.fromRGB(100, 100, 100),
											Font = Enum.Font.GothamBold,
											TextSize = 12,
											TextXAlignment = Enum.TextXAlignment.Right
										}
									}
								}
							end)
						}
					}
				}
			}
		}
	}
	
	return gui
end

return QuestUI
