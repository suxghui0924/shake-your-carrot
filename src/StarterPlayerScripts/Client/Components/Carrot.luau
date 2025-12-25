local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)
local Trove = require(Packages.Trove)
local Network = require(ReplicatedStorage.Shared.Network)
local Sounds = require(ReplicatedStorage.Shared.Sounds)

local Carrot = Component.new({
    Tag = "Carrot",
    Ancestors = {workspace},
})

function Carrot:Construct()
    self._trove = Trove.new()
    self.ComboStep = 0
    self.LastAttackTime = 0
    self.COMBO_TIMEOUT = 1.0
    self.ChargeStartTime = 0
    self.IS_CHARGING = false
end

function Carrot:Start()
    local tool = self.Instance
    if not tool:IsA("Tool") then
        warn("Carrot component attached to non-tool instance:", tool.Name)
        return
    end

    self._trove:Connect(tool.Activated, function()
        self.ChargeStartTime = os.clock()
        self.IS_CHARGING = true
    end)

    self._trove:Connect(tool.Deactivated, function()
        if self.IS_CHARGING then
            local holdDuration = os.clock() - self.ChargeStartTime
            self.IS_CHARGING = false
            
            if holdDuration > 1.0 then
                self:PerformAttack("Charge")
            else
                -- If short click, we treat it as Shake + Combo step
                self:RequestShake()
                self:HandleComboAttack()
            end
        end
    end)

    -- Visual Feedback on Growth
    local player = Players.LocalPlayer
    self._trove:Connect(player.AttributeChanged, function(attribute)
        if attribute == "CarrotScale" then
            self:OnScaleChanged()
        end
    end)

    -- Initial scale check
    self:OnScaleChanged()
end

function Carrot:RequestShake()
    Network.packets.shakeCarrot.send()
end

function Carrot:HandleComboAttack()
    local now = os.clock()
    if now - self.LastAttackTime > self.COMBO_TIMEOUT then
        self.ComboStep = 1
    else
        self.ComboStep = (self.ComboStep % 3) + 1
    end
    
    self.LastAttackTime = now
    
    if self.ComboStep == 3 then
        self:PerformAttack("Combo")
    else
        self:PerformAttack("Normal")
    end
end

function Carrot:PerformAttack(attackType)
    Network.packets.carrotAttack.send({
        attackType = attackType
    })
    self:PlayAttackFeedback(attackType)
end

function Carrot:OnScaleChanged()
    local player = Players.LocalPlayer
    local scale = player:GetAttribute("CarrotScale") or 1.0
    
    -- Sound FX
    self:PlayGrowthSound()
    
    -- Visual FX (Highlight/Glow)
    self:PlayGrowthVisuals()
    
    print("Carrot Component Scale Updated:", scale)
end

function Carrot:PlayGrowthSound()
    local soundConfig = Sounds.Jjuuk
    if soundConfig then
        local sound = Instance.new("Sound")
        sound.SoundId = soundConfig.SoundId
        sound.Volume = soundConfig.Volume or 1
        sound.Parent = self.Instance.PrimaryPart or self.Instance:FindFirstChild("Handle") or self.Instance:FindFirstChildOfClass("BasePart")
        sound:Play()
        Debris:AddItem(sound, 2)
    end
end

function Carrot:PlayGrowthVisuals()
    local tool = self.Instance
    local highlight = tool:FindFirstChildOfClass("Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Parent = tool
    end
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.FillColor = Color3.fromRGB(255, 170, 0)
    
    TweenService:Create(highlight, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        FillTransparency = 1,
        OutlineTransparency = 1
    }):Play()
end

function Carrot:PlayAttackFeedback(attackType)
    -- Placeholder for per-tool animations
    print("Carrot Attack Feedback:", attackType)
end

function Carrot:Stop()
    self._trove:Clean()
end

return Carrot
