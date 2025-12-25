local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local ItemService = {}

function ItemService:Init()
    -- Spawning logic could go here
end

function ItemService:SpawnItem(itemType, position)
    local item = Instance.new("Part")
    item.Name = itemType .. "Drop"
    item.Position = position
    item.Size = Vector3.new(2, 2, 2)
    item.CanCollide = false
    item.Anchored = true
    item.Parent = workspace
    
    CollectionService:AddTag(item, "GameItem")
    item:SetAttribute("ItemType", itemType)
    
    -- Pick up logic
    item.Touched:Connect(function(other)
        local character = other.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if player then
            self:ApplyItemEffect(player, itemType)
            item:Destroy()
        end
    end)
end

function ItemService:ApplyItemEffect(player, itemType)
    local character = player.Character
    if not character then return end
    
    if itemType == "Broccoli" then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 30)
        end
    elseif itemType == "Lettuce" then
        -- Shield logic placeholder
        player:SetAttribute("HasShield", true)
        task.delay(10, function()
            player:SetAttribute("HasShield", false)
        end)
    end
end

function ItemService:Start()
    print("ItemService Started")
end

return ItemService
