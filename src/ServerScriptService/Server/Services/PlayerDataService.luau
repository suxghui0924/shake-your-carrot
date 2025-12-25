-- ServerScriptService/Server/Services/PlayerDataService.luau

-- 서비스
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 패키지, 모듈
local ProfileService = require(ServerStorage.ServerPackages.ProfileService)
local ProfileTemplateModule = require(ReplicatedStorage.Shared.Data.ProfileTemplate)
local ProfileTemplate = ProfileTemplateModule.Template

-- 상수
local PROFILE_STORE_KEY = "PlayerData-v5"
local KICK_MESSAGES = {
	DATA_LOAD_FAILED = "데이터 로딩 도중 오류가 발생했습니다, 다시 시도해주세요.",
	DATA_CREATE_FAILED = "데이터 생성 도중 오류가 발생했습니다, 다시 시도해주세요.",
	DATA_CLEARED = "데이터가 초기화 되었습니다, 재접속 해주세요.",
}

-- 타입 정의
local SharedTypes = require(ReplicatedStorage.Shared.Data.ProfileTemplate)
type ProfileData = typeof(SharedTypes.Template)

export type Profile = {
	Data: ProfileData,
	Release: (self: Profile) -> (),
	Save: (self: Profile) -> (),
	ListenToRelease: (self: Profile, callback: () -> ()) -> (),
	AddUserId: (self: Profile, userId: number) -> (),
	Reconcile: (self: Profile) -> (),
	GlobalUpdates: any,
}

local PlayerDataService = {
	_playerProfiles = {} :: { [Player]: Profile },
}

local ProfileStore = ProfileService.GetProfileStore(PROFILE_STORE_KEY, ProfileTemplate)
if RunService:IsStudio() then
	ProfileStore = ProfileStore.Mock
end

local function getProfileKey(userId: number)
	return "Player_" .. userId
end

function PlayerDataService:CreatePlayerProfile(player: Player, profile: Profile): Profile?
	if not player or not profile then
		warn("CreatePlayerProfile: Invalid player or profile")
		return nil
	end
	if not player:IsDescendantOf(Players) then
		warn(string.format("CreatePlayerProfile: Player %s is no longer in game", player.Name))
		return nil
	end

	local existing = self._playerProfiles[player]
	if existing then
		warn(string.format("CreatePlayerProfile: Profile already exists for %s", player.Name))
		return existing
	end

	self._playerProfiles[player] = profile

	profile:ListenToRelease(function()
		self._playerProfiles[player] = nil
		if player:IsDescendantOf(Players) then
			player:Kick(KICK_MESSAGES.DATA_LOAD_FAILED)
		end
	end)

	return profile
end

function PlayerDataService:GetData(player: Player): ProfileData?
	local profile = self._playerProfiles[player]
	return profile and profile.Data or nil
end

function PlayerDataService:UpdateData(player: Player, key: string, data: any): boolean
	local profile = self._playerProfiles[player]
	if not profile then
		warn(string.format("UpdateData failed: No profile for %s", player and player.Name or "unknown"))
		return false
	end
	if not key or key == "" then
		warn(string.format("UpdateData failed: Invalid key for %s", player.Name))
		return false
	end

	if not ProfileTemplate[key] then
		if not string.match(key, "^Record%d+$") then
			warn(string.format("UpdateData: Key '%s' not found in Template", key))
			return false
		end
	end

	profile.Data[key] = data
	return true
end

function PlayerDataService:UpdateLeaderstats(player: Player, key: string, value: any)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local statValue = leaderstats:FindFirstChild(key)
	if statValue and statValue:IsA("NumberValue") then
		statValue.Value = value
	end
end

function PlayerDataService:SaveData(player: Player): boolean
	local profile = self._playerProfiles[player]
	if not profile then
		warn(string.format("SaveData: No profile found for %s", player and player.Name or "unknown"))
		return false
	end

	local ok = pcall(function()
		profile:Save()
	end)
	if not ok then
		warn(string.format("Profile save failed for %s", player.Name))
		return false
	end
	return true
end

function PlayerDataService:ClearData(player: Player): boolean
	if not (RunService:IsStudio() and RunService:IsServer()) then
		warn("ClearData: Only available in Studio server")
		return false
	end
	if not player or not player.UserId then
		warn("ClearData: Invalid player")
		return false
	end

	local profile = self._playerProfiles[player]
	if not profile then
		local success, loadedProfile = pcall(function()
			return ProfileStore:LoadProfileAsync(getProfileKey(player.UserId), "ForceLoad")
		end)
		if not success or not loadedProfile then
			warn(string.format("ClearData: Failed to load profile for %s", player.Name))
			return false
		end
		profile = loadedProfile
	end

	for key, defaultValue in pairs(ProfileTemplate) do
		profile.Data[key] = defaultValue
	end

	if player:IsDescendantOf(Players) then
		player:Kick(KICK_MESSAGES.DATA_CLEARED)
	end

	return true
end

function PlayerDataService:_CreateLeaderstatValue(player: Player, leaderstats: Folder, key: string, defaultValue: any, currentValue: any)
	local valueObject = Instance.new("NumberValue")
	valueObject.Name = key
	valueObject.Value = currentValue or defaultValue
	valueObject.Parent = leaderstats

	valueObject.Changed:Connect(function(newValue)
		if player:IsDescendantOf(Players) then
			self:UpdateData(player, key, newValue)
		end
	end)



	return valueObject
end

function PlayerDataService:CreateLeaderstats(player: Player)
	local profile = self._playerProfiles[player]
	if not profile or not player:IsDescendantOf(Players) then
		warn(string.format("CreateLeaderstats: Invalid profile or player for %s", player and player.Name or "unknown"))
		return
	end

	local existing = player:FindFirstChild("leaderstats")
	if existing then
		existing:Destroy()
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local current = profile.Data["Money"]
	self:_CreateLeaderstatValue(player, leaderstats, "Money", ProfileTemplate["Money"], current)
end

function PlayerDataService:OnPlayerAdded(player: Player)
	if not player or not player.UserId then
		warn("OnPlayerAdded: Invalid player")
		return
	end

	local success, profile = pcall(function()
		return ProfileStore:LoadProfileAsync(getProfileKey(player.UserId), "ForceLoad")
	end)

	if not success or not profile then
		warn(string.format("Profile load failed for %s: %s", player.Name, tostring(profile)))
		player:Kick(KICK_MESSAGES.DATA_LOAD_FAILED)
		return
	end

	pcall(function()
		profile:AddUserId(player.UserId)
	end)
	pcall(function()
		profile:Reconcile()
	end)

	if not player:IsDescendantOf(Players) then
		profile:Release()
		return
	end

	local playerProfile = self:CreatePlayerProfile(player, profile)
	if not playerProfile then
		profile:Release()
		player:Kick(KICK_MESSAGES.DATA_CREATE_FAILED)
		return
	end

	self:CreateLeaderstats(player)

	player:SetAttribute("DataLoaded", true)
end

function PlayerDataService:OnPlayerRemoving(player: Player)
	if not player then
		warn("OnPlayerRemoving: Invalid player")
		return
	end

	local profile = self._playerProfiles[player]
	if profile then
		profile:Release()
		self._playerProfiles[player] = nil
	end
end

function PlayerDataService:Init()
	-- print("[PlayerDataService] Init started")
	self._playerProfiles = {}
	self._playerConnections = {}

	Players.PlayerAdded:Connect(function(player)
		-- print("[PlayerDataService] PlayerAdded event:", player.Name)
		self:OnPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:OnPlayerRemoving(player)
	end)

	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			-- print("[PlayerDataService] Processing existing player:", player.Name)
			self:OnPlayerAdded(player)
		end)
	end
end



return PlayerDataService
