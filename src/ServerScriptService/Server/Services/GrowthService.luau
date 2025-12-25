local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Network = require(ReplicatedStorage.Shared.Network)

local GrowthService = {
    Growths = {}, -- [Player] = CurrentScale
}

function GrowthService:Init()
    Network.packets.shakeCarrot.listen(function(_, player)
        self:GrowCarrot(player)
    end)

    Players.PlayerAdded:Connect(function(player)
        self.Growths[player] = 1.0
        player.CharacterAdded:Connect(function(character)
            self:ApplyScale(player, self.Growths[player])
            
            -- Respawn Protection
            character:SetAttribute("Invincible", true)
            local highlight = Instance.new("Highlight")
            highlight.Parent = character
            highlight.FillColor = Color3.fromRGB(241, 196, 15)
            
            task.delay(3, function()
                if character and character.Parent then
                    character:SetAttribute("Invincible", false)
                    highlight:Destroy()
                end
            end)

            local humanoid = character:WaitForChild("Humanoid")
            humanoid.Died:Connect(function()
                self:ResetGrowth(player)
            end)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.Growths[player] = nil
    end)

    CollectionService:GetInstanceAddedSignal("Carrot"):Connect(function(instance)
        if instance:IsA("Tool") then
            task.wait() -- Wait for ancestry to be set
            local player = self:GetToolOwner(instance)
            if player then
                local scale = self.Growths[player] or 1.0
                self:ScaleTool(instance, scale)
            end
        end
    end)
end

function GrowthService:GetToolOwner(tool)
    local parent = tool.Parent
    if parent:IsA("Model") and Players:GetPlayerFromCharacter(parent) then
        return Players:GetPlayerFromCharacter(parent)
    elseif parent:IsA("Backpack") and parent.Parent:IsA("Player") then
        return parent.Parent
    end
    return nil
end

function GrowthService:GrowCarrot(player)
	local currentScale = self.Growths[player] or 1.0
	
	-- Get player character size to calculate max carrot size
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- Increase Max Scale Limit significantly
	local maxScale = 20.0
	
	-- Reduced growth rate: 1% per shake (was 5%)
	local nextScale = currentScale * 1.01
	
	-- Clamp to max size
	nextScale = math.min(nextScale, maxScale)
	
	self.Growths[player] = nextScale
	self:ApplyScale(player, nextScale)
end

function GrowthService:ResetGrowth(player)
    self.Growths[player] = 1.0
    self:ApplyScale(player, 1.0)
end

function GrowthService:ApplyScale(player, scale)
    local character = player.Character
    if not character then return end
    
    player:SetAttribute("CarrotScale", scale)
    
    -- Update WalkSpeed (Speed Penalty: Base 16, -1 speed per 0.4 scale above 1.0)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local baseSpeed = 16
        local penalty = (scale - 1.0) * 2.5 -- 0.4 increase = 1 point penalty
        humanoid.WalkSpeed = math.max(10, baseSpeed - penalty)
    end

    -- Sync scale to all tagged "Carrot" tools owned by the player
    local taggedTools = CollectionService:GetTagged("Carrot")
    for _, tool in ipairs(taggedTools) do
        if tool:IsDescendantOf(character) or tool:IsDescendantOf(player.Backpack) then
            self:ScaleTool(tool, scale)
        end
    end
end

function GrowthService:ScaleTool(tool, scale)
    for _, part in ipairs(tool:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:GetAttribute("OriginalSize") then
                part:SetAttribute("OriginalSize", part.Size)
            end
            part.Size = part:GetAttribute("OriginalSize") * scale
        end
    end
end

function GrowthService:Start()
    print("GrowthService Started")
end

return GrowthService
