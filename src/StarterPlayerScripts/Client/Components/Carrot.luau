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
    
    -- Main Container (Bottom Right)
    local container = Instance.new("Frame")
    container.Size = UDim2.fromOffset(160, 110)
    container.Position = UDim2.new(1, -30, 1, -30)
    container.AnchorPoint = Vector2.new(1, 1)
    container.BackgroundTransparency = 1
    container.Parent = screen
    
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Right
    list.VerticalAlignment = Enum.VerticalAlignment.Bottom
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = container

    -- Helper to create a hint row
    local function createRow(key, action, layoutOrder)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 45)
        row.BackgroundTransparency = 1
        row.LayoutOrder = layoutOrder
        row.Parent = container
        
        local rowList = Instance.new("UIListLayout")
        rowList.FillDirection = Enum.FillDirection.Horizontal
        rowList.HorizontalAlignment = Enum.HorizontalAlignment.Right
        rowList.VerticalAlignment = Enum.VerticalAlignment.Center
        rowList.Padding = UDim.new(0, 10)
        rowList.Parent = row
        
        -- Action Label
        local label = Instance.new("TextLabel")
        label.Text = action
        label.Font = Enum.Font.FredokaOne
        label.TextSize = 22
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextXAlignment = Enum.TextXAlignment.Right
        label.BackgroundTransparency = 1
        label.AutomaticSize = Enum.AutomaticSize.XY
        label.LayoutOrder = 1
        label.TextStrokeTransparency = 0.5
        label.Parent = row
        
        -- Key Icon (Keycap Style)
        local keyFrame = Instance.new("Frame")
        keyFrame.Size = UDim2.fromOffset(42, 42)
        keyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35) -- Dark Key Body
        keyFrame.BorderSizePixel = 0
        keyFrame.LayoutOrder = 2
        keyFrame.Parent = row
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = keyFrame
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(80, 80, 90) -- Lighter edge
        stroke.Thickness = 2
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = keyFrame
        
        -- Key Bottom Shadow (3D effect)
        local shadow = Instance.new("Frame")
        shadow.ZIndex = 0
        shadow.Size = UDim2.new(1, 0, 1, 4) -- Sticks out bottom
        shadow.Position = UDim2.new(0, 0, 0, 0)
        shadow.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        shadow.BorderSizePixel = 0
        shadow.Parent = keyFrame
        
        local shadowCorner = Instance.new("UICorner")
        shadowCorner.CornerRadius = UDim.new(0, 8)
        shadowCorner.Parent = shadow
        
        -- Key Text
        local keyText = Instance.new("TextLabel")
        keyText.Size = UDim2.fromScale(1, 1)
        keyText.BackgroundTransparency = 1
        keyText.Text = key
        keyText.Font = Enum.Font.FredokaOne
        keyText.TextSize = 20
        keyText.TextColor3 = Color3.fromRGB(220, 220, 230)
        keyText.Parent = keyFrame
        keyText.ZIndex = 2
        
        -- Orange Accent for Q
        if key == "Q" then
             keyFrame.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
             stroke.Color = Color3.fromRGB(255, 150, 50)
             shadow.BackgroundColor3 = Color3.fromRGB(180, 60, 0)
             keyText.TextColor3 = Color3.fromHex("#FFFFFF")
        end
        
        return row
    end
    
    -- Add Hints
    createRow("LMB", "ATTACK", 1)
    createRow("Q", "SHAKE", 2)
    
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
    
    -- 1. Highlight Effect (Existing)
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
    
    -- 2. Particle Burst
    self:PlayGrowthParticles()
    
    -- 3. Floating Text
    self:SpawnFloatingText()
end

function Carrot:PlayGrowthParticles()
    local tool = self.Instance
    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChild("PrimaryPart") or tool:FindFirstChildOfClass("BasePart")
    if not handle then return end
    
    local att = Instance.new("Attachment")
    att.Parent = handle
    
    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = "rbxassetid://1266170131" -- Generic sparkle/star
    emitter.Color = ColorSequence.new(Color3.fromRGB(255, 170, 0))
    emitter.LightEmission = 1
    emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
    emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    emitter.Lifetime = NumberRange.new(0.5, 1)
    emitter.Speed = NumberRange.new(5, 10)
    emitter.SpreadAngle = Vector2.new(360, 360)
    emitter.Rate = 0
    emitter.Parent = att
    
    emitter:Emit(20)
    
    Debris:AddItem(att, 2)
end



function Carrot:SpawnFloatingText()
    local character = Players.LocalPlayer.Character
    local head = character and character:FindFirstChild("Head")
    if not head then return end
    
    local scale = Players.LocalPlayer:GetAttribute("CarrotScale") or 1.0
    
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.fromScale(4, 2)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = head
    billboard.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = string.format("x%.1f GROWTH!", scale)
    label.Font = Enum.Font.FredokaOne
    label.TextColor3 = Color3.fromRGB(255, 200, 50)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Parent = billboard
    
    -- Animate up and fade
    local tInfo = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TweenService:Create(billboard, tInfo, {StudsOffset = Vector3.new(0, 6, 0)}):Play()
    
    TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
    
    Debris:AddItem(billboard, 1.2)
end

function Carrot:PlayAttackFeedback(attackType)
    local soundConfig = Sounds.Swing
    if soundConfig then
        local sound = Instance.new("Sound")
        sound.SoundId = soundConfig.SoundId
        sound.Volume = soundConfig.Volume or 1
        -- Random pitch for variety
        sound.PlaybackSpeed = 0.9 + (math.random() * 0.2)
        sound.Parent = self.Instance.PrimaryPart or self.Instance:FindFirstChild("Handle") or self.Instance:FindFirstChildOfClass("BasePart")
        sound:Play()
        Debris:AddItem(sound, 2)
    end
end

function Carrot:Stop()
    self._trove:Clean()
end

return Carrot
