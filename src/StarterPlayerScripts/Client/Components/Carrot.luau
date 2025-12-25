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
    self.LastShakeTime = 0 -- For shake animation debounce
end

local ContextActionService = game:GetService("ContextActionService")

function Carrot:Start()
    local tool = self.Instance
    if not tool:IsA("Tool") then
        warn("Carrot component attached to non-tool instance:", tool.Name)
        return
    end

    -- [ INPUT: ATTACK (Left Click) ]
    self._trove:Connect(tool.Activated, function()
        self.ChargeStartTime = os.clock()
        self.IS_CHARGING = true
    end)

    self._trove:Connect(tool.Deactivated, function()
        if self.IS_CHARGING then
            local holdDuration = os.clock() - self.ChargeStartTime
            self.IS_CHARGING = false
            
            if holdDuration > 0.5 then
                self:PerformAttack("Charge")
            else
                self:HandleComboAttack()
            end
        end
    end)
    
    -- [ INPUT: SHAKE (Key 'Q') ]
    self:BindShakeAction()
    
    -- [ UI: Keybind Hint ]
    self:CreateKeybindHint()

    -- Visual Feedback on Growth
    local player = Players.LocalPlayer
    self._trove:Connect(player.AttributeChanged, function(attribute)
        if attribute == "CarrotScale" then
            self:OnScaleChanged()
        end
    end)
    
    -- Cleanup on Unequip
    self._trove:Connect(tool.Unequipped, function()
        ContextActionService:UnbindAction("ShakeCarrot")
        if self.KeybindUI then self.KeybindUI.Enabled = false end
    end)
    
    self._trove:Connect(tool.Equipped, function()
        self:BindShakeAction()
        if self.KeybindUI then self.KeybindUI.Enabled = true end
    end)
end

function Carrot:BindShakeAction()
    ContextActionService:BindAction("ShakeCarrot", function(name, state, input)
        if state == Enum.UserInputState.Begin then
            self:RequestShake()
        end
    end, true, Enum.KeyCode.Q)
    
    -- Set image for mobile button if needed
    ContextActionService:SetTitle("ShakeCarrot", "SHAKE")
end

function Carrot:CreateKeybindHint()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screen = Instance.new("ScreenGui")
    screen.Name = "CarrotKeybindHint"
    screen.Parent = playerGui
    screen.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(200, 50)
    frame.Position = UDim2.new(0.5, 0, 0.85, 0) -- Bottom Center
    frame.AnchorPoint = Vector2.new(0.5, 1)
    frame.BackgroundTransparency = 1
    frame.Parent = screen
    
    -- Key Icon
    local keyRef = Instance.new("TextLabel")
    keyRef.Size = UDim2.fromOffset(40, 40)
    keyRef.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    keyRef.BackgroundTransparency = 0.5
    keyRef.Text = "Q"
    keyRef.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyRef.Font = Enum.Font.FredokaOne
    keyRef.TextSize = 24
    keyRef.Parent = frame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = keyRef
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Parent = keyRef
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Text = "SHAKE!"
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.fromOffset(50, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.FredokaOne
    label.TextSize = 24
    label.TextColor3 = Color3.fromRGB(255, 170, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextStrokeTransparency = 0
    label.Parent = frame
    
    self.KeybindUI = screen
    self._trove:Add(screen)
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
    
    -- Debounce check
    local now = os.clock()
    if self.LastShakeTime and (now - self.LastShakeTime) < 0.6 then
        return -- Skip if animation played too recently
    end
    self.LastShakeTime = now
    
    -- Sound FX
    self:PlayGrowthSound()
    
    -- Shake Animation (Squash/Stretch)
    self:PlayShakeAnimation()
    
    -- Visual FX (Highlight/Glow)
    self:PlayGrowthVisuals()
    
    print("Carrot Component Scale Updated:", scale)
end

function Carrot:PlayShakeAnimation()
    local tool = self.Instance
    if not tool:IsA("Tool") then return end
    
    -- Get all parts in the tool
    local parts = {}
    for _, descendant in ipairs(tool:GetDescendants()) do
        if descendant:IsA("BasePart") then
            table.insert(parts, descendant)
        end
    end
    
    if #parts == 0 then return end
    
    -- Store original sizes
    local originalSizes = {}
    for _, part in ipairs(parts) do
        if not part:GetAttribute("OriginalShakeSize") then
            originalSizes[part] = part.Size
        else
            originalSizes[part] = part:GetAttribute("OriginalShakeSize")
        end
    end
    
    -- Squash/Stretch sequence using SIZE changes
    local scaleSequence = {
        -- Squash (compress vertically, expand horizontally)
        { Time = 0.08, Scale = Vector3.new(1.15, 0.85, 1.15), Easing = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
        -- Stretch (expand vertically, compress horizontally)
        { Time = 0.12, Scale = Vector3.new(0.85, 1.2, 0.85), Easing = Enum.EasingStyle.Back, Direction = Enum.EasingDirection.Out },
        -- Wobble 1
        { Time = 0.1, Scale = Vector3.new(1.08, 0.92, 1.08), Easing = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.InOut },
        -- Wobble 2
        { Time = 0.1, Scale = Vector3.new(0.95, 1.05, 0.95), Easing = Enum.EasingStyle.Sine, Direction = Enum.EasingDirection.InOut },
        -- Return to original
        { Time = 0.15, Scale = Vector3.new(1, 1, 1), Easing = Enum.EasingStyle.Elastic, Direction = Enum.EasingDirection.Out }
    }
    
    -- Play sequence
    local currentDelay = 0
    for _, step in ipairs(scaleSequence) do
        task.delay(currentDelay, function()
            for _, part in ipairs(parts) do
                if part and part.Parent then
                    local targetSize = originalSizes[part] * step.Scale
                    local tween = TweenService:Create(
                        part,
                        TweenInfo.new(step.Time, step.Easing, step.Direction),
                        {Size = targetSize}
                    )
                    tween:Play()
                end
            end
        end)
        currentDelay = currentDelay + step.Time
    end
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
