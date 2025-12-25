local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"))

local ItemService = {}

local ITEM_COOLDOWN = 180 -- 3 minutes

function ItemService:Init()
	Network.packets.itemPickup.listen(function(data, player)
		self:HandlePickup(player, data.itemInstance)
	end)
end

function ItemService:HandlePickup(player, itemInstance)
	if not itemInstance then return end
	
	local character = player.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	-- Distance Check (Proxy part or Model pivot)
	local proxy = itemInstance:FindFirstChild("proxy") or itemInstance
	local dist = (hrp.Position - proxy:GetPivot().Position).Magnitude
	if dist > 20 then 
		warn(string.format("ItemService: Pickup denied due to distance (%.1f)", dist))
		return 
	end
	
	-- Cooldown Check
	local nextAvailable = itemInstance:GetAttribute("NextAvailableTime") or 0
	local success, currentTime = pcall(function() return workspace:GetServerTime() end)
	if not success then
		currentTime = os.time()
	end
	
	if currentTime < nextAvailable then 
		warn("ItemService: Pickup denied due to cooldown")
		return 
	end
	
	-- Success! Set next cooldown
	itemInstance:SetAttribute("NextAvailableTime", currentTime + ITEM_COOLDOWN)
	
	-- Give Reward
	self:GiveReward(player, itemInstance)
end

function ItemService:GiveReward(player, itemInstance)
	local itemType = itemInstance:GetAttribute("Type") or itemInstance.Name
	local character = player.Character
	
	-- Give Reward
	local displayName = itemInstance:GetAttribute("Type") or itemInstance.Name
	local msg = string.format("%s을(를) 획득했습니다!", displayName)
	
	if itemType == "Water" then
		-- Growth Multiplier for 60 seconds
		player:SetAttribute("GrowthMultiplier", 2.0)
		task.delay(60, function()
			if player:GetAttribute("GrowthMultiplier") == 2.0 then
				player:SetAttribute("GrowthMultiplier", 1.0)
			end
		end)
		
		Network.packets.sendNotification.sendTo({
			message = msg .. " (당근 성장 2.0x 60초)",
			duration = 5
		}, player)
		
	elseif itemType == "Broccoli" then
		local humanoid = character and character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 50)
		end
		
		Network.packets.sendNotification.sendTo({
			message = msg .. " (체력 50 회복)",
			duration = 5
		}, player)
	end
end

function ItemService:Start()
	print("ItemService Started")
end

return ItemService
