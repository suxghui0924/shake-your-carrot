local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Network = require(ReplicatedStorage.Shared.Network)
local ShapecastHitbox = require(Packages.shapecasthitbox)

local CombatService = {
    BASE_DAMAGE = 10,
    BASE_KNOCKBACK = 20,
    Hitboxes = {}, -- Cache for hitboxes [Player] = Hitbox
}

function CombatService:Init()
    -- Enable Debug Visualization for feedback
    ShapecastHitbox.Settings.Debug_Visible = true

    Network.packets.carrotAttack.listen(function(data, player)
        self:HandleAttack(player, data.attackType)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        if self.Hitboxes[player] then
            self.Hitboxes[player]:Destroy()
            self.Hitboxes[player] = nil
        end
    end)
end

function CombatService:HandleAttack(player, attackType)
    local character = player.Character
    if not character then return end
    
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChild("PrimaryPart") or character:FindFirstChild("RightHand")
    if not handle then return end
    
    -- [1] Create DmgPoint Attachment if missing
    local att = handle:FindFirstChild("DmgPoint")
    if not att then
        att = Instance.new("Attachment")
        att.Name = "DmgPoint"
        att.Position = Vector3.new(0, 0, 0) -- Center of handle? Adjust if needed.
        att.Parent = handle
    end
    
    local carrotScale = player:GetAttribute("CarrotScale") or 1.0
    local hitRadius = 2.5 * carrotScale
    
    -- [2] Get or Create Hitbox
    local hitbox = self.Hitboxes[player]
    if not hitbox or hitbox.Instance ~= handle then -- Recreate if weapon changed
        if hitbox then hitbox:Destroy() end
        hitbox = ShapecastHitbox.new(handle)
        self.Hitboxes[player] = hitbox
    end
    
    -- [3] Configure Cast (Spherecast based on scale)
    hitbox:SetCastData({
        CastType = "Spherecast",
        Radius = hitRadius,
    })
    
    -- [4] Hit Logic
    local hits = {} -- distinct hits per swing
    
    hitbox:OnHit(function(result)
        local target = result.Instance
        local humanoid = target.Parent:FindFirstChild("Humanoid") or target.Parent.Parent:FindFirstChild("Humanoid")
        
        if humanoid and humanoid.Health > 0 then
            local targetChar = humanoid.Parent
            if hits[targetChar] then return end -- Already hit this enemy this swing
            hits[targetChar] = true
            
            local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
            if targetPlayer and targetPlayer.Team == player.Team and player.Team ~= nil then
                return -- Friendly fire
            end
            
            self:ApplyDamage(player, humanoid, carrotScale, attackType)
        end
    end)
    
    -- [5] Start & Cleanup
    hitbox:HitStart(0.35) -- Duration of swing
    
    hitbox:OnStopped(function(cleanup)
        cleanup() -- Removes OnHit listeners
        table.clear(hits)
        -- We KEEP the hitbox instance for next swing, don't Destroy() it here
    end)
    
    -- [VISUALIZE HITBOX (Debug/Feedback)]
    -- Keeping the visualizer as User requested it, but maybe ShapecastHitbox has one?
    -- User asked for "Visualize" previously. I'll keep the simple Box for now as instant feedback,
    -- though it might not perfectly match the temporal cast.
    -- Actually, ShapecastHitbox usually has `ShapecastHitbox.Settings.Debug_Visible = true` but that's global.
    -- Let's stick to our own feedback for now or rely on the purely invisible mechanic if reliable.
    -- I will comment out the old One-shot raycast but keep the visual feedback part for 'feel'.
    
    -- [VISUALIZE HITBOX]
    -- User requested visualization. We are enabling the native Debug Mode in Init.
    -- Manual visualization removed to avoid clutter.
    
    local origin = character.PrimaryPart.Position
    local direction = character.PrimaryPart.CFrame.LookVector * (8 * carrotScale)
    
    -- Lunge
    local lungeForce = 15 * carrotScale
    character.PrimaryPart:ApplyImpulse(character.PrimaryPart.CFrame.LookVector * lungeForce * character.PrimaryPart.AssemblyMass)
end

function CombatService:ApplyDamage(attacker, targetHumanoid, scale, attackType)
    local targetPlayer = Players:GetPlayerFromCharacter(targetHumanoid.Parent)
    if targetPlayer and (targetPlayer:GetAttribute("HasShield") or targetHumanoid.Parent:GetAttribute("Invincible")) then
        print(attacker.Name .. " hit a protected player: " .. targetPlayer.Name)
        return
    end

    local damage = self.BASE_DAMAGE * scale
    local knockback = self.BASE_KNOCKBACK * scale
    
    if attackType == "Combo" then
        damage *= 1.5
    elseif attackType == "Charge" then
        damage *= 3
        knockback *= 2
    end
    
    targetHumanoid:TakeDamage(damage)
    
    -- Apply Knockback
    local targetRoot = targetHumanoid.Parent:FindFirstChild("HumanoidRootPart")
    if targetRoot then
        local attackerRoot = attacker.Character.PrimaryPart
        local direction = (targetRoot.Position - attackerRoot.Position).Unit
        targetRoot:ApplyImpulse(direction * knockback * targetRoot.AssemblyMass)
    end
    
end

function CombatService:Start()
    print("CombatService Started")
end

return CombatService
