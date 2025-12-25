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
        att.Position = Vector3.new(0, 1, -3) -- Forward (-Z) and slightly up
        att.Parent = handle
    else
        att.Position = Vector3.new(0, 1, -3)
    end
    
    local carrotScale = player:GetAttribute("CarrotScale") or 1.0
    local hitRadius = 2.5 * carrotScale
    
    -- [2] Get or Create Hitbox
    local hitbox = self.Hitboxes[player]
    if not hitbox or hitbox.Instance ~= handle then
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
            
            -- Prevent Self-Hit
            if targetChar == character then return end
            
            if hits[targetChar] then return end 
            hits[targetChar] = true
            
            local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
            if targetPlayer and targetPlayer.Team == player.Team and player.Team ~= nil then
                return -- Friendly fire
            end
            
            self:ApplyDamage(player, humanoid, carrotScale, attackType)
        end
    end)
    
    -- [5] Start & Cleanup using RaycastParams for filtering
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    hitbox:HitStart(0.35, params)
    
    hitbox:OnStopped(function(cleanup)
        cleanup() 
        table.clear(hits)
    end)
    
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
