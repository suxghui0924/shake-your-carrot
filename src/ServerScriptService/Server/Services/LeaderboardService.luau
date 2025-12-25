local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CoinLeaderboardStore = DataStoreService:GetOrderedDataStore("GlobalCoinLeaderboard_v1")
local PlayerDataService

local LeaderboardService = {}

function LeaderboardService:UpdateLeaderboard()
	local success, errorMessage = pcall(function()
		local pages = CoinLeaderboardStore:GetSortedAsync(false, 100)
		local data = pages:GetCurrentPage()
		
		local leaderboardData = {}
		for _, entry in ipairs(data) do
			local userId = tonumber(entry.key)
			local name = "[Unknown]"
			pcall(function()
				name = Players:GetNameFromUserIdAsync(userId)
			end)
			
			table.insert(leaderboardData, {
				UserId = userId,
				Name = name,
				Coins = entry.value
			})
		end
		
		-- Store this in a folder or attribute for the client to read
		ReplicatedStorage:SetAttribute("LeaderboardData", game:GetService("HttpService"):JSONEncode(leaderboardData))
	end)
	
	if not success then
		warn("[LeaderboardService] Error updating leaderboard:", errorMessage)
	end
end

function LeaderboardService:SavePlayerData(player)
	if not PlayerDataService then
		local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
		PlayerDataService = require(Server:WaitForChild("Services"):WaitForChild("PlayerDataService"))
	end

	local profileData = PlayerDataService:GetData(player)
	if profileData and profileData.Money then
		pcall(function()
			CoinLeaderboardStore:SetAsync(tostring(player.UserId), profileData.Money)
		end)
	end
end

function LeaderboardService:Init()
	-- Update leaderboard every 2 minutes
	task.spawn(function()
		while true do
			self:UpdateLeaderboard()
			task.wait(120)
		end
	end)
	
	-- Save data when player leaves
	Players.PlayerRemoving:Connect(function(player)
		self:SavePlayerData(player)
	end)
	
	-- Periodically save all players (every 5 mins)
	task.spawn(function()
		while true do
			task.wait(300)
			for _, player in ipairs(Players:GetPlayers()) do
				self:SavePlayerData(player)
			end
		end
	end)
end

return LeaderboardService
