local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local Network = require(ReplicatedStorage.Shared.Network)
local Sounds = require(ReplicatedStorage.Shared.Sounds)

local SoundController = {
	sounds = {},
	CurrentMusic = nil,
	IsLobbyMusic = true,
}

function SoundController:Init()
	-- Create SoundGroups
	local sfxGroup = SoundService:FindFirstChild("SFX")
	if not sfxGroup then
		sfxGroup = Instance.new("SoundGroup")
		sfxGroup.Name = "SFX"
		sfxGroup.Parent = SoundService
	end
	
	local musicGroup = SoundService:FindFirstChild("Music")
	if not musicGroup then
		musicGroup = Instance.new("SoundGroup")
		musicGroup.Name = "Music"
		musicGroup.Parent = SoundService
	end
	
	-- Listen to Round Status for Music and SFX
	Network.packets.roundStatusUpdate.listen(function(data)
		self:HandleRoundUpdate(data)
	end)
	
	-- Start Lobby Logic initially
	self:PlayLobbyMusic()
end

function SoundController:HandleRoundUpdate(data)
	local status = data.status
	local timeLeft = data.timeLeft
	local message = data.message
	
	-- 1. Music State Management
	if status == "Round" and self.IsLobbyMusic then
		self.IsLobbyMusic = false
		self:PlayGameMusic()
	elseif (status == "Intermission" or status == "Ended") and not self.IsLobbyMusic then
		self.IsLobbyMusic = true
		self:PlayLobbyMusic()
	end
	
	-- 2. Timer Beep (At 5, 4, 3, 2, 1 seconds left in Round)
	-- To avoid spamming on every packet (which might come often?), we need to check integer transitions or specific flag.
	-- RoundService typically sends updates every 1 second.
	if status == "Round" and timeLeft <= 5 and timeLeft > 0 then
		-- A simplified check: assumes we get one packet per second roughly.
		-- To be safe against double-plays, we could track 'lastBeepTime'. 
		-- usage of 'message' can also hint context.
		
		-- Use a customized playsound that allows overlap or checks cooldown if needed.
		-- For a beep, we usually want it exactly on the tick.
		-- Simple approach: If `timeLeft` changed from previously known value.
		-- State-based tracking:
		if self.LastTime != timeLeft then
			self:PlaySound("timer_beep")
			self.LastTime = timeLeft
		end
	else
		self.LastTime = nil
	end
	
	-- 3. Spin Start Sound
	-- Triggered exactly when "GO!" message appears
	if message == "GO!" then
		self:PlaySound("Spin_Start")
	end
end

function SoundController:PlayRandomMusic(folderName)
	-- Stop current music
	if self.CurrentMusic then
		local oldMusic = self.CurrentMusic
		-- Fade out
		task.spawn(function()
			local tween = game:GetService("TweenService"):Create(oldMusic, TweenInfo.new(1), {Volume = 0})
			tween:Play()
			tween.Completed:Wait()
			oldMusic:Stop()
			oldMusic:Destroy()
		end)
		self.CurrentMusic = nil
	end
	
	-- Find folder in Assets
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local soundsFolder = assets and assets:FindFirstChild("Sounds")
	local targetFolder = soundsFolder and soundsFolder:FindFirstChild(folderName)
	
	if targetFolder then
		local tracks = targetFolder:GetChildren()
		if #tracks > 0 then
			local randomTrack = tracks[math.random(1, #tracks)]
			
			local music = randomTrack:Clone()
			music.Parent = SoundService
			music.SoundGroup = SoundService:FindFirstChild("Music")
			music.Looped = true
			music.Volume = 0 -- Start at 0 for fade in
			music:Play()
			self.CurrentMusic = music
			
			-- Fade in
			game:GetService("TweenService"):Create(music, TweenInfo.new(1), {Volume = 0.5}):Play()
		end
	end
end

function SoundController:PlayLobbyMusic()
	self:PlayRandomMusic("Lobby")
end

function SoundController:PlayGameMusic()
	self:PlayRandomMusic("Game")
end

function SoundController:PlaySound(soundName: string, parent: Instance?, volume: number?)
	-- Check Assets first (Dynamic lookup requested by user for timer_beep/Spin_Start which might be in Assets/Sounds root?)
	-- User said: "Added timer_beep, Spin_Start to Assets.Sounds"
	local assetSound = nil
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local soundsFolder = assets and assets:FindFirstChild("Sounds")
	if soundsFolder then
		assetSound = soundsFolder:FindFirstChild(soundName)
	end
	
	if assetSound then
		local sound = assetSound:Clone()
		sound.Parent = parent or SoundService
		sound.Volume = volume or sound.Volume
		sound.SoundGroup = SoundService:FindFirstChild("SFX")
		sound:Play()
		game:GetService("Debris"):AddItem(sound, sound.TimeLength + 1)
		return
	end

	-- Fallback to Module Definitions
	local soundData = Sounds[soundName]
	if not soundData then
		-- warn(`"{soundName}" sound not found in Assets or Sounds module!`)
		return
	end

    local sound = Instance.new("Sound")
    sound.SoundId = soundData.SoundId
    sound.Volume = volume or soundData.Volume or 0.5
    sound.Name = soundName
	sound.Parent = parent or SoundService
	sound.SoundGroup = SoundService:FindFirstChild("SFX")
	
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 5)
end

function SoundController:OnStart()
    self:Init()
end

return SoundController
