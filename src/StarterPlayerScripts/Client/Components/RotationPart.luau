local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)

local RotationPart = require(Packages.Component).new({
    Tag = "RotationPart";
    Ancestors = {workspace};
    Extensions = {};
})

local globalStartTime = tick()

function RotationPart:Construct()
    self._trove = Trove.new()
end

function RotationPart:Start()
    local instance = self.Instance
    self._trove:Add(instance)

    local startRotation
    local moveFunction

    if instance:IsA("Model") then
        startRotation = instance:GetPivot().Rotation
        moveFunction = function(newCFrame)
            instance:PivotTo(newCFrame)
        end
    elseif instance:IsA("BasePart") then
        startRotation = instance.CFrame.Rotation
        moveFunction = function(newCFrame)
            instance.CFrame = newCFrame
        end
    else
        warn("RotationPart component attached to an instance that is neither a BasePart nor a Model")
        return
    end

	self._trove:Connect(RunService.RenderStepped, function()
		local currentTime = tick()

		local speed = instance:GetAttribute("RotationSpeed") or 30  

		local rotationAngle = (currentTime - globalStartTime) * math.rad(speed)
		local rotation = CFrame.Angles(0, rotationAngle, 0)

		local currentPosition = instance:IsA("Model") and instance:GetPivot().Position or instance.Position
		local newCFrame = CFrame.new(currentPosition) * rotation * startRotation
		moveFunction(newCFrame)
	end)
end

function RotationPart:Stop()
    self._trove:Clean()
end

return RotationPart