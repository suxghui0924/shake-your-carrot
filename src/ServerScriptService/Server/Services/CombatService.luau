local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Network = require(ReplicatedStorage.Shared.Network)
local Sounds = require(ReplicatedStorage.Shared.Sounds)

-- [HitboxClass Setup]
local HitboxClass = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("HitboxClass"))
-- Note: User mentioned "Select your Alive folder". We need to set it via code or maybe the module handles it?
-- Docs: "select your Alive folder... within HitboxClass's settings folder". 
-- If modifying the Module script structure is hard via code, we might need to rely on defaults or configure it if exposed via API.
-- Docs say: "Class Settings... Alive Folder". It doesn't explicitly say how to set it via script if it's a "Setting Folder" inside the module.
-- BUT, typically these modules have `HitboxClass.Settings.Alive = ...` or similar.
-- Let's try to set it if possible, otherwise assume user configured it or it defaults to Workspace?
-- Actually, the docs say "HitboxClass cannot run without this being set."
-- Let's look at the docs again: "Next, select your Alive folder within HitboxClass's settings folder." -> Sounds like an ObjectValue in Studio.
-- However, we are scripting. Let's hope we can set it via `HitboxClass.Settings.Alive`.
-- Wait, "Class Settings" heading in docs lists "Alive Folder".
-- If it's a Module, usually `require(HitboxClass).Settings.Alive = workspace`. Let's try that.

local CombatService = {
    BASE_DAMAGE = 10,
    BASE_KNOCKBACK = 20,
}

function CombatService:Init()
    -- Configure HitboxClass (Physical Values inside the Module)
    local hpModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("HitboxClass")
    local settingsFolder = hpModule:FindFirstChild("Settings")
    
    if settingsFolder then
        local aliveValue = settingsFolder:FindFirstChild("Alive")
        if aliveValue and aliveValue:IsA("ObjectValue") then
            aliveValue.Value = workspace
            print("CombatService: HitboxClass 'Alive' set to Workspace.")
        else
            warn("CombatService: 'Alive' ObjectValue not found in HitboxClass.Settings. Please configure it manually if needed.")
        end
    else
        warn("CombatService: HitboxClass 'Settings' folder not found. Please ensure the module is installed correctly.")
    end

    Network.packets.carrotAttack.listen(function(data, player)
        self:HandleAttack(player, data.attackType)
    end)
end

function CombatService:HandleAttack(player, attackType)
    local character = player.Character
    if not character then return end
    
    local tool = character:FindFirstChildOfClass("Tool")
    -- Weapon check optional? If they fired the event they probably have it, 
    -- but good to verify they are holding the correct tool or just any tool?
    -- Actually, user said "Self hit is possible", so we need to be careful.
    
    local function cleanup() end 
    
    local carrotScale = player:GetAttribute("CarrotScale") or 1.0
    
    -- Hitbox Dimensions (Square/Cube per user request)
    local sizeX = 5 * carrotScale
    local sizeY = 5 * carrotScale -- Reduced from 8 (was too tall)
    local sizeZ = 5 * carrotScale
    
    -- Position: Closer to character (Back Face at -1.0)
    local offsetZ = -1.0 - (sizeZ / 2) 
    
    -- [Create Hitbox Part]
    local hbPart = Instance.new("Part")
    hbPart.Name = "Hitbox_" .. player.Name
    hbPart.Size = Vector3.new(sizeX, sizeY, sizeZ)
    hbPart.Shape = Enum.PartType.Block
    hbPart.CanCollide = false
    hbPart.Massless = true
    hbPart.Transparency = 1 
    hbPart.Parent = workspace
    
    -- Position relative to Character: Lowered by 1.5 studs
    hbPart.CFrame = character.PrimaryPart.CFrame * CFrame.new(0, -1.5, offsetZ)
    
    local params = {
        SizeOrPart = hbPart,
        Debug = true, 
        DebounceTime = 0.5,
        Blacklist = {character},
    }
    
    local hitbox, connected = HitboxClass.new(params)
    
    if not hitbox then
        warn("Failed to create Hitbox for " .. player.Name)
        hbPart:Destroy()
        return
    end
    
    -- Weld to Character (follow rotation/movement)
    -- "WeldTo... with an offset defined by OffsetCFrame"
    -- Since we want it in FRONT, we weld to PrimaryPart with offset.
    hitbox:WeldTo(character.PrimaryPart, CFrame.new(0, 0, offsetZ))
    
    hitbox.HitSomeone:Connect(function(hitModels)
        for _, model in ipairs(hitModels) do
            local humanoid = model:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                -- Friendly Fire Check
                local targetPlayer = Players:GetPlayerFromCharacter(model)
                if targetPlayer and targetPlayer.Team == player.Team and player.Team ~= nil then
                    continue
                end
                
                -- Play Hit Sound
                local sound = Instance.new("Sound")
                sound.Name = "HitSound"
                sound.SoundId = Sounds.Hit.SoundId
                sound.Volume = Sounds.Hit.Volume
                sound.Parent = model:FindFirstChild("Head") or model.PrimaryPart
                sound:Play()
                game:GetService("Debris"):AddItem(sound, 1)
                
                self:ApplyDamage(player, humanoid, carrotScale, attackType)
            end
        end
    end)
    
    hitbox:Start()
    
    -- Cleanup after swing duration
    task.delay(0.35, function()
        hitbox:Stop()
        hitbox:Destroy()
        hbPart:Destroy()
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
