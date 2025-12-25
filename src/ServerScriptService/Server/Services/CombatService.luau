local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Network = require(ReplicatedStorage.Shared.Network)
local Sounds = require(ReplicatedStorage.Shared.Sounds)

-- [HitboxClass Setup]
local function getCarrotScale(player)
	return player:GetAttribute("CarrotScale") or 1.0
end

local CombatService = {
    BASE_DAMAGE = 10,
    BASE_KNOCKBACK = 20,
}

function CombatService:Init()
	-- Configure HitboxClass (Physical Values inside the Module)
	-- We must require it on the server at least once to create the "HitboxClassRemote" for clients.
	local HitboxClass = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("HitboxClass"))

	Network.packets.carrotAttack.listen(function(data, player)
		-- [Lunge Logic on Swing]
		local character = player.Character
		if character and character.PrimaryPart then
			local scale = getCarrotScale(player)
			local lungeForce = 15 * scale
			character.PrimaryPart:ApplyImpulse(character.PrimaryPart.CFrame.LookVector * lungeForce * character.PrimaryPart.AssemblyMass)
		end
	end)
	
	Network.packets.carrotHit.listen(function(data, player)
		-- Validate Target
		if not data.target then return end
		local targetModel = data.target.Parent
		if not targetModel then return end
		local humanoid = targetModel:FindFirstChild("Humanoid")
		if not humanoid then return end
		
		self:HandleHit(player, humanoid, data.attackType)
	end)
end

function CombatService:HandleHit(attacker, targetHumanoid, attackType)
	local attackerChar = attacker.Character
	local targetChar = targetHumanoid.Parent
	
	if not attackerChar or not targetChar then return end
	
	local attackerRoot = attackerChar:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
	
	if not attackerRoot or not targetRoot then return end
	
	-- [VALIDATION] Distance Check (Sanity Check)
	-- Allow some leeway for latency (Ping compensation logic would be better but this is a rough guard)
	local carrotScale = attacker:GetAttribute("CarrotScale") or 1.0
	local maxReach = 9 * carrotScale + 6 -- Adjusted: Base reach + scale + buffer (Generous for lag)
	
	local distance = (attackerRoot.Position - targetRoot.Position).Magnitude
	if distance > maxReach then
		-- warn(attacker.Name .. " hit rejected (Too far): " .. distance .. " > " .. maxReach)
		return
	end
	
	-- [VALIDATION] Alive Folder Check (PVP allowed only in Alive)
	local aliveFolder = workspace:FindFirstChild("Alive")
	if not aliveFolder then return end
	
	if not attackerChar:IsDescendantOf(aliveFolder) or not targetChar:IsDescendantOf(aliveFolder) then
		return
	end
	
	-- Friendly Fire Check
	local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
	if targetPlayer and targetPlayer.Team == attacker.Team and attacker.Team ~= nil then
		return
	end

	self:ApplyDamage(attacker, targetHumanoid, carrotScale, attackType)
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
    
	-- Tag Humanoid for Kill Attribution
	local creatorTag = targetHumanoid:FindFirstChild("creator")
	if creatorTag then
		creatorTag:Destroy()
	end
	
	creatorTag = Instance.new("ObjectValue")
	creatorTag.Name = "creator"
	creatorTag.Value = attacker
	creatorTag.Parent = targetHumanoid
	game:GetService("Debris"):AddItem(creatorTag, 2) -- Tag lasts 2 seconds
	
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
    -- print("CombatService Started")
end

return CombatService
