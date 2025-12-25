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
