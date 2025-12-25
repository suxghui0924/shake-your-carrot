local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local MovementController = {}

-- [[ SETTINGS ]]
local RUN_SPEED = 26
local WALK_SPEED = 16

local SLIDE_SETTINGS = {
	Cooldown = 0.5,
	BaseSpeed = 55,
	HipHeight = {
		Normal = 0,
		Slide = -2,
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

-- [[ STATE ]]
local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local rootPart = nil
local animator = nil

-- Run State
local runAnimationTrack = nil
local isRunning = false

-- Slide State
local slideAnimTrack = nil
local isSliding = false
local canSlide = true
local slideVelocity = nil
local alignGyro = nil
local currentMultiplier = 1
local slideLoopSound = nil
local slideCancelSound = nil
local baseVolume = 1
local posCheckConnection = nil

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- [[ CONSTANTS ]]
local ASSETS = ReplicatedStorage:WaitForChild("Assets")

function MovementController:Init()
	player.CharacterAdded:Connect(function(char)
		self:OnCharacterAdded(char)
	end)
	if player.Character then
		self:OnCharacterAdded(player.Character)
	end

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		
		if input.KeyCode == Enum.KeyCode.LeftShift then
			self:SetRunning(true)
		elseif input.KeyCode == Enum.KeyCode.C then
			self:StartSlide()
		elseif input.KeyCode == Enum.KeyCode.Space then
			if isSliding then
				self:CancelSlide(true)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			self:SetRunning(false)
		end
	end)
	
	RunService.RenderStepped:Connect(function(dt)
		self:Update(dt)
	end)
	
	player:GetAttributeChangedSignal("CarrotScale"):Connect(function()
		self:UpdateWalkSpeed()
	end)
	
	print("[MovementController] Initialized")
end

function MovementController:OnCharacterAdded(char)
	self:StopSlide() 
	
	-- Cleanup Sounds
	if slideLoopSound then slideLoopSound:Destroy() slideLoopSound = nil end
	if slideCancelSound then slideCancelSound:Destroy() slideCancelSound = nil end
	
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
	animator = humanoid:WaitForChild("Animator")
	
	rayParams.FilterDescendantsInstances = {character}
	SLIDE_SETTINGS.HipHeight.Normal = humanoid.HipHeight

	-- Load Run Animation
	local runAnimParams = ASSETS:WaitForChild("Animations"):WaitForChild("Run", 5)
	if runAnimParams and runAnimParams:IsA("Animation") then
		runAnimationTrack = animator:LoadAnimation(runAnimParams)
		runAnimationTrack.Priority = Enum.AnimationPriority.Movement
		runAnimationTrack.Looped = true
	end
	
	-- Load Slide Animation
	local slideAnimParams = ASSETS:WaitForChild("Animations"):WaitForChild("Slide", 5)
	if slideAnimParams and slideAnimParams:IsA("Animation") then
		slideAnimTrack = animator:LoadAnimation(slideAnimParams)
		slideAnimTrack.Priority = Enum.AnimationPriority.Action
	end
	
	-- Load Sounds
	local SoundsFolder = ASSETS:WaitForChild("Sounds", 5)
	if SoundsFolder then
		local loop = SoundsFolder:FindFirstChild("Slide_Loop")
		if loop then 
			slideLoopSound = loop:Clone()
			slideLoopSound.Name = "SlideLoop"
			slideLoopSound.Looped = true
			slideLoopSound.Parent = rootPart
			baseVolume = slideLoopSound.Volume
		end
		
		local cancel = SoundsFolder:FindFirstChild("Slide_Cancel")
		if cancel then
			slideCancelSound = cancel:Clone()
			slideCancelSound.Name = "SlideCancel"
			slideCancelSound.Parent = rootPart
		end
	end
	
	self:UpdateWalkSpeed()
end

-- [[ RUN LOGIC ]]
function MovementController:SetRunning(state)
	isRunning = state
	self:UpdateWalkSpeed()
	
	if not isRunning and runAnimationTrack and runAnimationTrack.IsPlaying then
		runAnimationTrack:Stop(0.2)
	end
end

function MovementController:UpdateWalkSpeed()
	if not humanoid then return end
	
	local scale = player:GetAttribute("CarrotScale") or 1.0
	local baseSpeed = isRunning and RUN_SPEED or WALK_SPEED
	
	-- Scaling Penalty
	local penalty = math.max(0, (scale - 1.0) * 2.5)
	local finalSpeed = math.max(8, baseSpeed - penalty)
	
	humanoid.WalkSpeed = finalSpeed
end

-- [[ SLIDE LOGIC ]]
function MovementController:StartSlide()
	if isSliding or not canSlide or not rootPart or not humanoid then return end
	
	-- Ground Check
	local rayDir = -rootPart.CFrame.UpVector * 5
	local result = workspace:Raycast(rootPart.Position, rayDir, rayParams)
	if not result then return end
	
	isSliding = true
	canSlide = false
	
	-- Animations
	if slideAnimTrack then slideAnimTrack:Play(0.15) end
	if runAnimationTrack and runAnimationTrack.IsPlaying then runAnimationTrack:Stop(0.1) end
	
	-- Audio
	if slideLoopSound then slideLoopSound:Play() end
	
	humanoid.HipHeight = SLIDE_SETTINGS.HipHeight.Slide
	
	-- Physics
	slideVelocity = Instance.new("BodyVelocity")
	slideVelocity.Name = "SlideVelocity"
	slideVelocity.MaxForce = Vector3.new(40000, 0, 40000)
	slideVelocity.Parent = rootPart
	
	alignGyro = Instance.new("BodyGyro")
	alignGyro.Name = "SlideGyro"
	alignGyro.MaxTorque = Vector3.new(3e5, 3e5, 3e5)
	alignGyro.P = 10000
	alignGyro.Parent = rootPart
	
	currentMultiplier = 1
end

function MovementController:StopSlide()
	isSliding = false
	
	if slideVelocity then slideVelocity:Destroy() slideVelocity = nil end
	if alignGyro then alignGyro:Destroy() alignGyro = nil end
	if slideAnimTrack then slideAnimTrack:Stop(0.2) end
	if slideLoopSound then slideLoopSound:Stop() end
	if humanoid then humanoid.HipHeight = SLIDE_SETTINGS.HipHeight.Normal end
	
	task.delay(SLIDE_SETTINGS.Cooldown, function()
		canSlide = true
	end)
end

function MovementController:CancelSlide(isJump)
	if slideCancelSound then slideCancelSound:Play() end
	self:StopSlide()
	
	if SLIDE_SETTINGS.PushOnCancel and rootPart then
		local push = Instance.new("BodyVelocity")
		push.MaxForce = Vector3.new(40000, 40000, 40000)
		
		local upForce = SLIDE_SETTINGS.PushVelocity.Up
		if isJump then upForce = upForce * 1.8 end
		
		push.Velocity = (rootPart.CFrame.LookVector * (SLIDE_SETTINGS.PushVelocity.Forward * currentMultiplier)) + (Vector3.new(0,1,0) * upForce)
		push.Parent = rootPart
		Debris:AddItem(push, 0.15)
	end
end

-- [[ UPDATE LOOP ]]
function MovementController:Update(dt)
	if not humanoid then return end

	-- Run Animation Logic
	if not isSliding then
		local isMoving = humanoid.MoveDirection.Magnitude > 0.1
		if isRunning and isMoving then
			if runAnimationTrack and not runAnimationTrack.IsPlaying then
				runAnimationTrack:Play(0.2)
			end
		else
			if runAnimationTrack and runAnimationTrack.IsPlaying then
				runAnimationTrack:Stop(0.2)
			end
		end
	end
	
	-- Slide Physics Loop
	if isSliding and rootPart and slideVelocity then
		if slideLoopSound and slideLoopSound.IsPlaying then
            slideLoopSound.Volume = math.clamp(baseVolume * currentMultiplier, 0, 10)
        end

		local checkDir = -rootPart.CFrame.UpVector * 10
		local hit = workspace:Raycast(rootPart.Position, checkDir, rayParams)
		
		if hit then
			local rightVec = rootPart.CFrame.RightVector
			local upVec = hit.Normal
			local newFace = rightVec:Cross(upVec)
			alignGyro.CFrame = CFrame.fromMatrix(rootPart.Position, rightVec, upVec, newFace)
			
			-- Determine slope angle for acceleration
			local verticalChange = newFace.Y -- Approximate? No, previousY logic was better for actual displacement.
			-- Let's stick to Raycast normal Y component? 
			-- Normal.Y == 1 means flat. Normal.Y < 1 means slope.
			-- Actually, the old logic tracked previousY frame-by-frame. I should probably restore that or use simpler physics.
			-- Simpler: `humanoid.MoveDirection` dot `UpVector`? No.
			-- I'll use the lookVector.Y relative to flat?
			local slopeY = rootPart.CFrame.LookVector.Y
			
			if slopeY > 0.1 then -- Going Up
				currentMultiplier = math.clamp(currentMultiplier - SLIDE_SETTINGS.SpeedChangeRate.Upward * dt, 0, SLIDE_SETTINGS.MaxMultiplier)
			elseif slopeY < -0.1 then -- Going Down
				currentMultiplier = math.clamp(currentMultiplier + SLIDE_SETTINGS.SpeedChangeRate.Downward * dt, 0, SLIDE_SETTINGS.MaxMultiplier)
			else -- Flat
				currentMultiplier = math.clamp(currentMultiplier - SLIDE_SETTINGS.SpeedChangeRate.Forward * dt, 0, SLIDE_SETTINGS.MaxMultiplier)
			end
		end

		local scale = player:GetAttribute("CarrotScale") or 1.0
		local scalePenalty = math.max(0, (scale - 1.0) * 10)
		local adjustedBaseSpeed = math.max(20, SLIDE_SETTINGS.BaseSpeed - scalePenalty)
		
		slideVelocity.Velocity = rootPart.CFrame.LookVector * (adjustedBaseSpeed * currentMultiplier)
		
		if currentMultiplier < 0.1 or not hit then
			self:StopSlide()
		end
	elseif isSliding then
		-- Fallback if rootPart missing
		self:StopSlide()
	end
end

return MovementController
