local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Shared.Network)

local CombatService = {
    BASE_DAMAGE = 10,
    BASE_KNOCKBACK = 20,
}

function CombatService:Init()
    Network.packets.carrotAttack.listen(function(data, player)
        self:HandleAttack(player, data.attackType)
    end)
end



function CombatService:HandleAttack(player, attackType)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    local carrotScale = player:GetAttribute("CarrotScale") or 1.0
    
    -- Hit detection logic
    -- Reach: Base 8 studs, scales with carrot size.
    local hitRadius = 2.5 * carrotScale
    local hitDistance = 8 * carrotScale
    
    local origin = character.PrimaryPart.Position
    local direction = character.PrimaryPart.CFrame.LookVector * hitDistance
    
    -- Lunge Effect: Help slow players close the gap
    local lungeForce = 15 * carrotScale
    character.PrimaryPart:ApplyImpulse(character.PrimaryPart.CFrame.LookVector * lungeForce * character.PrimaryPart.AssemblyMass)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = workspace:Spherecast(origin, hitRadius, direction, raycastParams)
    
    -- [VISUALIZE HITBOX]
    local viz = Instance.new("Part")
    viz.Anchored = true
    viz.CanCollide = false
    viz.Material = Enum.Material.Neon
    viz.Color = Color3.fromRGB(255, 0, 0)
    viz.Transparency = 0.7
    
    local dist = direction.Magnitude
    local fwd = direction.Unit
    local center = origin + (fwd * (dist / 2))
    
    -- Spherecast is a swept sphere. Approximating with a cylinder/capsule look is hard with just a part.
    -- A cylinder along the ray is decent.
    viz.Shape = Enum.PartType.Cylinder
    viz.Size = Vector3.new(dist, hitRadius*2, hitRadius*2) -- Cylinder uses X as length in recent updates? Or Y? Actually Cylinder mesh rotates.
    -- Let's just use a Block for simplicity covering the area, or a series of spheres.
    -- Better: CFrame.lookAt(center, center + fwd) * CFrame.Angles(0, math.rad(90), 0) for Cylinder?
    -- Let's stick to a simple block representing the ray length + radius
    viz.Shape = Enum.PartType.Block
    viz.Size = Vector3.new(hitRadius*2, hitRadius*2, dist)
    viz.CFrame = CFrame.lookAt(center, center + fwd)
    
    viz.Parent = workspace
    game:GetService("Debris"):AddItem(viz, 0.2)
    
    if result and result.Instance then
        local targetHumanoid = result.Instance.Parent:FindFirstChild("Humanoid")
        if not targetHumanoid then
            targetHumanoid = result.Instance.Parent.Parent:FindFirstChild("Humanoid")
        end
        
        if targetHumanoid and targetHumanoid.Health > 0 then
            local targetPlayer = Players:GetPlayerFromCharacter(targetHumanoid.Parent)
            if targetPlayer and targetPlayer.Team == player.Team and player.Team ~= nil then
                -- Friendly fire ignored
                return
            end
            
            self:ApplyDamage(player, targetHumanoid, carrotScale, attackType)
        end
    end
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
