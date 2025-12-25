local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RunController = {}

local WALK_SPEED = 16
local RUN_SPEED = 26

local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local animator = nil

local runAnimationTrack = nil
local isRunning = false

function RunController:Init()
	-- Connect Character Added
	player.CharacterAdded:Connect(function(char)
		self:OnCharacterAdded(char)
	end)
	if player.Character then
		self:OnCharacterAdded(player.Character)
	end

	-- Input Handling
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.LeftShift then
			self:SetRunning(true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			self:SetRunning(false)
		end
	end)
	
	-- Update Loop (Check if moving)
	RunService.RenderStepped:Connect(function()
		self:Update()
	end)
	
	print("[RunController] Init completed")
end

function RunController:OnCharacterAdded(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")
	
	-- Load Animation
	-- Assumes ReplicatedStorage.Assets.Animations.Run exists as Animation object
	local animAsset = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Animations"):WaitForChild("Run", 10)
	if animAsset and animAsset:IsA("Animation") then
		runAnimationTrack = animator:LoadAnimation(animAsset)
		runAnimationTrack.Priority = Enum.AnimationPriority.Movement
		runAnimationTrack.Looped = true
	else
		warn("[RunController] Run animation not found in ReplicatedStorage.Assets.Animations")
	end
	
	self:SetRunning(isRunning) -- Re-apply state if respawned while holding key? (Edge case)
end

function RunController:SetRunning(state)
	isRunning = state
	if not humanoid then return end
	
	if isRunning then
		humanoid.WalkSpeed = RUN_SPEED
	else
		humanoid.WalkSpeed = WALK_SPEED
		-- Stop animation immediately if we stop running key
		if runAnimationTrack and runAnimationTrack.IsPlaying then
			runAnimationTrack:Stop(0.2)
		end
	end
end

function RunController:Update()
	if not humanoid or not runAnimationTrack then return end
	
	local isMoving = humanoid.MoveDirection.Magnitude > 0.1
	
	if isRunning and isMoving then
		if not runAnimationTrack.IsPlaying then
			runAnimationTrack:Play(0.2)
		end
	else
		if runAnimationTrack.IsPlaying then
			runAnimationTrack:Stop(0.2)
		end
	end
end

return RunController
