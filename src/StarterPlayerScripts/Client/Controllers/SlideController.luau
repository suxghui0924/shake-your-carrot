local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local SlideController = {}

--// Settings matches user provided Logic
local Settings = {
	Cooldown = 0.5,
	BaseSpeed = 55,
	HipHeight = {
		Normal = 0, -- Default HipHeight (will read from humanoid)
		Slide = -2, -- Slide HipHeight
	},
	MaxMultiplier = 2,
	SpeedChangeRate = {
		Forward = 1,
		Upward = 2,
		Downward = 1,
	},
	PushOnCancel = true,
	PushVelocity = {
		Forward = 50,
		Up = 50,
	},
}

--// State
local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local rootPart = nil
local animator = nil
local slideAnimTrack = nil

local isSliding = false
local canSlide = true
local posCheckConnection = nil

local slideVelocity = nil
local alignGyro = nil
local currentMultiplier = 1

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

--// Assets
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Animations = Assets:WaitForChild("Animations")
local SoundsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Sounds", 5)

local slideLoopSound = nil
local slideCancelSound = nil
local baseVolume = 1

function SlideController:Init()
	player.CharacterAdded:Connect(function(char)
		self:OnCharacterAdded(char)
	end)
	if player.Character then
		self:OnCharacterAdded(player.Character)
	end
	
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.C then
			self:StartSlide()
		elseif input.KeyCode == Enum.KeyCode.Space then
			if isSliding then
				self:CancelSlide()
			end
		end
	end)
	
	print("[SlideController] Init completed")
end

function SlideController:OnCharacterAdded(char)
	self:StopSlide() -- Safety cleanup of previous state
	
	-- Explicitly destroy old sounds if they still exist (orphaned)
	if slideLoopSound then 
		slideLoopSound:Stop()
		slideLoopSound:Destroy()
		slideLoopSound = nil 
	end
	if slideCancelSound then 
		slideCancelSound:Destroy()
		slideCancelSound = nil 
	end
	
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
	animator = humanoid:WaitForChild("Animator")
	
	rayParams.FilterDescendantsInstances = {character}
	
	-- Create NEW Sound instances for this character
	if SoundsFolder then
		local loop = SoundsFolder:FindFirstChild("Slide_Loop")
		if loop then 
			slideLoopSound = loop:Clone()
			slideLoopSound.Name = "SlideLoop"
			slideLoopSound.Looped = true -- Force Loop
			slideLoopSound.Parent = rootPart
			baseVolume = slideLoopSound.Volume
			print("[SlideController] SlideLoop sound loaded. Vol:", baseVolume)
		else
			warn("[SlideController] Slide_Loop sound NOT found in Assets/Sounds")
		end
		
		local cancel = SoundsFolder:FindFirstChild("Slide_Cancel")
		if cancel then
			slideCancelSound = cancel:Clone()
			slideCancelSound.Name = "SlideCancel"
			slideCancelSound.Parent = rootPart
			print("[SlideController] SlideCancel sound loaded.")
		else
			warn("[SlideController] Slide_Cancel sound NOT found in Assets/Sounds")
		end
	else
		warn("[SlideController] Assets/Sounds folder NOT found")
	end
	
	-- Load Animation
	local anim = Animations:FindFirstChild("Slide")
	if anim and anim:IsA("Animation") then
		slideAnimTrack = animator:LoadAnimation(anim)
		slideAnimTrack.Priority = Enum.AnimationPriority.Action -- CRITICAL FIX: Action Priority overrides Run
	else
		warn("[SlideController] Slide animation missing in Assets.Animations")
	end
	
	Settings.HipHeight.Normal = humanoid.HipHeight -- Capture default
end

function SlideController:StartSlide()
	if isSliding or not canSlide or not rootPart or not humanoid then return end
	
	-- Ground Check
	local rayDir = -rootPart.CFrame.UpVector * 5
	local result = workspace:Raycast(rootPart.Position, rayDir, rayParams)
	if not result then return end
	
	isSliding = true
	canSlide = false
	
	-- Play Animation
	if slideAnimTrack then
		slideAnimTrack:Play(0.15)
	end
	
	-- Play Sound
	if slideLoopSound then
		slideLoopSound:Play()
		print("[SlideController] Playing Slide Loop")
	end
	
	humanoid.HipHeight = Settings.HipHeight.Slide
	
	-- Physics
	slideVelocity = Instance.new("BodyVelocity")
	slideVelocity.Name = "SlideVelocity"
	slideVelocity.MaxForce = Vector3.new(40000, 0, 40000)
	slideVelocity.Velocity = rootPart.CFrame.LookVector * Settings.BaseSpeed
	slideVelocity.Parent = rootPart
	
	alignGyro = Instance.new("BodyGyro")
	alignGyro.Name = "SlideGyro"
	alignGyro.MaxTorque = Vector3.new(3e5, 3e5, 3e5)
	alignGyro.P = 10000
	alignGyro.Parent = rootPart
	
	local previousY = rootPart.Position.Y
	currentMultiplier = 1
	
	-- Heartbeat Loop
	posCheckConnection = RunService.Heartbeat:Connect(function(dt)
		-- Safety check: Stop if something key is missing
		if not isSliding or not rootPart or not rootPart.Parent or not slideVelocity then 
			self:StopSlide() 
			return 
		end
        
        -- Sound Volume Modulation
        if slideLoopSound and slideLoopSound.IsPlaying then
            slideLoopSound.Volume = math.clamp(baseVolume * currentMultiplier, 0, 10)
        end

		local currentY = rootPart.Position.Y
		local verticalChange = (currentY - previousY)
		previousY = currentY

		local checkDir = -rootPart.CFrame.UpVector * 10
		local hit = workspace:Raycast(rootPart.Position, checkDir, rayParams)

		-- Align to slope
		if hit then
			local rightVec = rootPart.CFrame.RightVector
			local upVec = hit.Normal
			local newFace = rightVec:Cross(upVec)
			alignGyro.CFrame = CFrame.fromMatrix(rootPart.Position, rightVec, upVec, newFace)
		end
		
		-- Velocity Calc
		slideVelocity.Velocity = rootPart.CFrame.LookVector * (Settings.BaseSpeed * currentMultiplier)
		
		if verticalChange < 0.1 and verticalChange > -0.1 then -- Flat
			currentMultiplier = math.clamp(currentMultiplier - Settings.SpeedChangeRate.Forward * dt, 0, Settings.MaxMultiplier)
		elseif verticalChange > 0 then -- Up
			currentMultiplier = math.clamp(currentMultiplier - Settings.SpeedChangeRate.Upward * dt, 0, Settings.MaxMultiplier)
		else -- Down (Slope)
			currentMultiplier = math.clamp(currentMultiplier + Settings.SpeedChangeRate.Downward * dt, 0, Settings.MaxMultiplier)
		end
		
		if currentMultiplier < 0.1 or not hit then
			self:StopSlide()
		end
	end)
end

function SlideController:StopSlide()
	-- Removed: if not isSliding then return end (Force cleanup always)
	isSliding = false
	
	if posCheckConnection then
		posCheckConnection:Disconnect()
		posCheckConnection = nil
	end
	
	if slideVelocity then slideVelocity:Destroy() end
	if alignGyro then alignGyro:Destroy() end
	
	if slideAnimTrack then slideAnimTrack:Stop(0.2) end
	
	-- Force Stop Sound logic
	if slideLoopSound then 
		slideLoopSound:Stop() 
		-- print("[SlideController] Stopped Slide Sound")
	end
	
	if humanoid then humanoid.HipHeight = Settings.HipHeight.Normal end
	
	task.delay(Settings.Cooldown, function()
		canSlide = true
	end)
end

function SlideController:CancelSlide()
	-- Play Cancel Sound
	if slideCancelSound then
		slideCancelSound:Play()
	end
	
	self:StopSlide()
	
	if Settings.PushOnCancel and rootPart then
		local push = Instance.new("BodyVelocity")
		push.MaxForce = Vector3.new(40000, 40000, 40000)
		push.Velocity = (rootPart.CFrame.LookVector * (Settings.PushVelocity.Forward * currentMultiplier)) + (Vector3.new(0,1,0) * Settings.PushVelocity.Up)
		push.Parent = rootPart
		Debris:AddItem(push, 0.15)
	end
end

return SlideController
