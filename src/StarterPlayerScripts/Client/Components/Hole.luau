local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Component = require(Packages:WaitForChild("Component"))
local Trove = require(Packages:WaitForChild("Trove"))
local RunService = game:GetService("RunService")
local Fusion = require(Packages:WaitForChild("Fusion"))
local peek = Fusion.peek
local Children = Fusion.Children

local Client = script.Parent.Parent
local SoundController = require(Client.Controllers:WaitForChild("SoundController"))

local Hole = Component.new({
	Tag = "Hole",
	Ancestors = {workspace},
})

local COOLDOWN_TIME = 10

function Hole:Construct()
	self._trove = Trove.new()
	self.Scope = Fusion.scoped(Fusion)
	self.Holes = {} 
	
	-- Fusion State
	self.CooldownLeft = self.Scope:Value(0)
	self.IsCooldown = self.Scope:Computed(function(use)
		return use(self.CooldownLeft) > 0
	end)
	
	self:CreateCooldownUI()
end

function Hole:Start()
	local folder = self.Instance
	
	for _, child in ipairs(folder:GetChildren()) do
		self:RegisterChild(child)
	end
	
	self._trove:Connect(folder.ChildAdded, function(child)
		self:RegisterChild(child)
	end)
	
	-- Countdown Loop
	self._trove:Connect(RunService.Heartbeat, function(dt)
		local current = peek(self.CooldownLeft)
		if current > 0 then
			self.CooldownLeft:set(math.max(0, current - dt))
		end
	end)
end

function Hole:RegisterChild(child)
	if child.Name == "Hole" and child:IsA("Model") then
		local hit = child:WaitForChild("Hit", 5)
		if hit then
			table.insert(self.Holes, {Model = child, Hit = hit})
			self._trove:Connect(hit.Touched, function(otherPart)
				self:OnTouch(child, otherPart)
			end)
		end
	end
end

function Hole:OnTouch(sourceHoleModel, otherPart)
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then return end
	if not otherPart:IsDescendantOf(character) then return end
	
	-- Cooldown Check
	if peek(self.CooldownLeft) > 0 then return end
	
	-- Set Cooldown
	self.CooldownLeft:set(COOLDOWN_TIME)
	
	self:Teleport(character, sourceHoleModel)
end

function Hole:Teleport(character, sourceModel)
	-- Play Sound
	SoundController:PlaySound("aquaaaaaa")
	
	local candidates = {}
	for _, data in ipairs(self.Holes) do
		if data.Model ~= sourceModel then
			table.insert(candidates, data)
		end
	end
	
	if #candidates > 0 then
		local dest = candidates[math.random(1, #candidates)]
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local destPos = dest.Hit.Position + Vector3.new(0, 3, 0)
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			hrp.CFrame = CFrame.new(destPos)
		end
	else
		warn("Hole component: No other holes to teleport to!")
	end
end

function Hole:CreateCooldownUI()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	
	local screen = self.Scope:New "ScreenGui" {
		Name = "HoleCooldownUI",
		Parent = playerGui,
		Enabled = self.IsCooldown,
		
		[Children] = {
			self.Scope:New "Frame" {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.85),
				Size = UDim2.fromOffset(200, 50),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.5,
				
				[Children] = {
					self.Scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
					
					self.Scope:New "TextLabel" {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = self.Scope:Computed(function(use)
							local t = use(self.CooldownLeft)
							return string.format("COOLDOWN: %.1f", t)
						end),
						TextColor3 = Color3.fromRGB(255, 100, 100),
						Font = Enum.Font.FredokaOne,
						TextSize = 24
					}
				}
			}
		}
	}
	
	self._trove:Add(screen)
end

function Hole:Stop()
	self._trove:Clean()
	self.Scope:doCleanup()
end

return Hole
