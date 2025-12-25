--[[
    StarterPlayer/StarterPlayerScripts/Client/Components/UpDownEffect.luau
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

local UpDownEffect = Component.new({
    Tag = "UpDownEffect",
    Ancestors = { workspace },
})

function UpDownEffect:Construct()
    self._trove = Trove.new()
end

function UpDownEffect:Start()
    local instance = self.Instance
    assert(
        instance:IsA("Model") or instance:IsA("BasePart"),
        string.format("%s 는 Model 또는 BasePart여야 합니다. (현재: %s)", instance:GetFullName(), instance.ClassName)
    )

    local amplitude = tonumber(instance:GetAttribute("amplitude")) or 1
    local speed = tonumber(instance:GetAttribute("speed")) or 1

    if instance:IsA("Model") then
        local elapsed = 0
        local timeout = 5
        while not instance.PrimaryPart and elapsed < timeout do
            task.wait(0.1)  
            elapsed += 0.1
        end
        if not instance.PrimaryPart then
            warn(("[UpDownEffect] %s: PrimaryPart가 설정되지 않아 효과를 시작하지 않았습니다."):format(instance:GetFullName()))
            return
        end
    end

    local baseCF: CFrame
    local isModel = instance:IsA("Model")
    if isModel then
        baseCF = instance:GetPivot()
    else
        baseCF = instance.CFrame
    end

    local startTime = time()

    self._trove:Connect(RunService.Heartbeat, function()
        if not instance.Parent then return end

        local elapsedTime = time() - startTime
        local offsetY = math.sin(elapsedTime * speed) * amplitude

        local targetCF = baseCF + Vector3.new(0, offsetY, 0)

        if isModel then
            instance:PivotTo(targetCF)
        else
            instance.CFrame = targetCF
        end
    end)
end

function UpDownEffect:Stop()
    self._trove:Destroy()
end

return UpDownEffect
