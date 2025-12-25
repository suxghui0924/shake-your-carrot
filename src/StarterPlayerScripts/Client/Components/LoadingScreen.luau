local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Fusion = require(Packages.Fusion)

local Children = Fusion.Children
local peek = Fusion.peek

local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen

function LoadingScreen.new()
	local self = setmetatable({}, LoadingScreen)
	
	self.Scope = Fusion.scoped(Fusion)
	
	-- State
	self.Progress = self.Scope:Value(0)
	self.Rotation = self.Scope:Value(0)
	self.IsVisible = self.Scope:Value(true)
	self.Time = self.Scope:Value(0)
	
	-- Theme Colors (Grow a Garden Style)
	local PASTEL_GREEN = Color3.fromRGB(180, 230, 160)
	local PASTEL_BLUE = Color3.fromRGB(180, 220, 240)
	local CREAM = Color3.fromRGB(255, 250, 240)
	local BROWN_STROKE = Color3.fromRGB(100, 70, 50)
	local CARROT_ORANGE = Color3.fromRGB(255, 140, 50)
	
	-- Animations
	local transparency = self.Scope:Spring(self.Scope:Computed(function(use)
		return use(self.IsVisible) and 0 or 1
	end), 20, 1)
	
	local fillSize = self.Scope:Spring(self.Scope:Computed(function(use)
		return UDim2.fromScale(use(self.Progress), 1)
	end), 25, 0.8)

	-- Floating Animation
	local floatOffset = self.Scope:Computed(function(use)
		return math.sin(use(self.Time) * 2) * 10 -- Bob up and down 10px
	end)

	self.ScreenGui = self.Scope:New "ScreenGui" {
		Name = "LoadingScreen",
		IgnoreGuiInset = true,
		DisplayOrder = 1000,
		ResetOnSpawn = false,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
		
		[Children] = {
			self.Scope:New "CanvasGroup" {
				Name = "Root",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = PASTEL_BLUE, -- Sky-ish background
				BorderSizePixel = 0,
				GroupTransparency = transparency,
				
				[Children] = {
					-- Background Pattern (Optional Dots/Grid)
					self.Scope:New "ImageLabel" {
						Name = "Pattern",
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Image = "rbxassetid://6073743871", -- Generic dot pattern
						ImageTransparency = 0.9,
						ImageColor3 = Color3.new(0, 0, 0),
						TileSize = UDim2.fromOffset(50, 50),
						ScaleType = Enum.ScaleType.Tile,
					},
					
					-- Main Card
					self.Scope:New "Frame" {
						Name = "Card",
						Size = UDim2.fromOffset(450, 350),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = CREAM,
						
						[Children] = {
							self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 30) },
							self.Scope:New "UIStroke" {
								Color = BROWN_STROKE,
								Thickness = 4,
							},
							self.Scope:New "UIPadding" {
								PaddingTop = UDim.new(0, 30),
								PaddingBottom = UDim.new(0, 30),
								PaddingLeft = UDim.new(0, 30),
								PaddingRight = UDim.new(0, 30),
							},
							self.Scope:New "UIListLayout" {
								SortOrder = Enum.SortOrder.LayoutOrder,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								Padding = UDim.new(0, 20),
							},
							
							-- Logo Area (Floating)
							self.Scope:New "Frame" {
								Name = "LogoArea",
								Size = UDim2.fromOffset(150, 150),
								BackgroundTransparency = 1,
								LayoutOrder = 1,
								
								[Children] = {
									self.Scope:New "ImageLabel" {
										Name = "Logo",
										Size = UDim2.fromScale(1, 1),
										Position = self.Scope:Computed(function(use)
											return UDim2.fromOffset(0, use(floatOffset))
										end),
										BackgroundTransparency = 1,
										Image = "rbxassetid://107851490416619",
										Rotation = self.Rotation,
									}
								}
							},
							
							-- Title
							self.Scope:New "TextLabel" {
								Name = "Title",
								Text = "Shake Your Carrot",
								Font = Enum.Font.FredokaOne,
								TextSize = 36,
								TextColor3 = BROWN_STROKE,
								BackgroundTransparency = 1,
								Size = UDim2.fromOffset(400, 40),
								LayoutOrder = 2,
							},
							
							-- Progress Bar Container
							self.Scope:New "Frame" {
								Name = "BarContainer",
								Size = UDim2.new(1, 0, 0, 30),
								LayoutOrder = 3,
								BackgroundColor3 = Color3.fromRGB(220, 220, 220),
								
								[Children] = {
									self.Scope:New "UICorner" { CornerRadius = UDim.new(1, 0) }, -- Capsule
									self.Scope:New "UIStroke" {
										Color = BROWN_STROKE,
										Thickness = 3,
									},
									
									-- Fill
									self.Scope:New "Frame" {
										Name = "Fill",
										Size = fillSize,
										BackgroundColor3 = PASTEL_GREEN,
										BorderSizePixel = 0,
										
										[Children] = {
											self.Scope:New "UICorner" { CornerRadius = UDim.new(1, 0) },
											self.Scope:New "Frame" {
												-- Shine line
												Size = UDim2.new(1, 0, 0.3, 0),
												BackgroundColor3 = Color3.new(1, 1, 1),
												BackgroundTransparency = 0.7,
												BorderSizePixel = 0,
											}
										}
									},
									
									-- Text Overlay
									self.Scope:New "TextLabel" {
										Name = "Percent",
										Size = UDim2.fromScale(1, 1),
										BackgroundTransparency = 1,
										Text = self.Scope:Computed(function(use)
											return math.floor(use(self.Progress) * 100) .. "%"
										end),
										Font = Enum.Font.FredokaOne,
										TextColor3 = BROWN_STROKE,
										TextSize = 18,
										ZIndex = 2,
									}
								}
							},
							
							-- Status Text
							self.Scope:New "TextLabel" {
								Name = "Status",
								Text = "Sprouting...",
								Font = Enum.Font.FredokaOne,
								TextSize = 20,
								TextColor3 = Color3.fromRGB(150, 120, 100),
								BackgroundTransparency = 1,
								Size = UDim2.fromOffset(400, 20),
								LayoutOrder = 4,
							}
						}
					}
				}
			}
		}
	}

	self:StartLoop()

	return self
end

function LoadingScreen:StartLoop()
	self.Active = true
	task.spawn(function()
		local spinState = "wait" -- "wait", "spin"
		local stateTimer = 0
		
		while self.Active do
			local dt = RunService.RenderStepped:Wait()
			self.Time:set(tick()) -- Update time for waving text
			
			-- Spin Logic
			stateTimer = stateTimer + dt
			
			if spinState == "spin" then
				local duration = 0.5
				if stateTimer >= duration then
					-- Finished this burst
					spinState = "wait"
					stateTimer = 0
				end
			elseif spinState == "wait" then
				if stateTimer > 0.3 then
					spinState = "spin"
					stateTimer = 0
					self:DoBurst()
				end
			end
		end
	end)
end

-- Separate coroutine for the burst to keep the main loop clean for text wave
function LoadingScreen:DoBurst()
	task.spawn(function()
		local startRot = peek(self.Rotation)
		local targetRot = startRot + 360
		local duration = 0.5
		local startTime = tick()
		
		while tick() - startTime < duration do
			if not self.Active then return end
			local alpha = (tick() - startTime) / duration
			local t = 1 - math.pow(2, -10 * alpha)
			self.Rotation:set(startRot + 360 * t)
			RunService.RenderStepped:Wait()
		end
		self.Rotation:set(targetRot)
	end)
end

function LoadingScreen:Update(percent)
	self.Progress:set(math.clamp(percent, 0, 1))
end

function LoadingScreen:Destroy()
	self.Active = false
	self.IsVisible:set(false)
	
	task.wait(1)
	
	self.Scope:doCleanup()
	self.ScreenGui:Destroy()
end

return LoadingScreen
