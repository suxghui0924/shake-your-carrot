local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Sounds = require(ReplicatedStorage.Shared.Sounds)

local SoundController = {
	sounds = {},
}

function SoundController:Init()
	-- Create SoundGroups
	if not SoundService:FindFirstChild("SFX") then
		local g = Instance.new("SoundGroup")
		g.Name = "SFX"
		g.Parent = SoundService
	end
	if not SoundService:FindFirstChild("Music") then
		local g = Instance.new("SoundGroup")
		g.Name = "Music"
		g.Parent = SoundService
	end

    -- Preload sounds? 
    -- For now, we just ensure the groups exist. 
    -- We can cache instances if needed, but creating new Sound instances on demand is often fine for simple SFX.
end

function SoundController:OnStart()
    self:Init()
end


function SoundController:PlaySound(soundName: string, parent: Instance?, volume: number?)
	local soundData = Sounds[soundName]
	if not soundData then
		warn(`"{soundName}" 사운드가 Sounds 모듈에 정의되지 않았습니다!`)
		return
	end

    local sound = Instance.new("Sound")
    sound.SoundId = soundData.SoundId
    sound.Volume = volume or soundData.Volume or 0.5
    sound.Name = soundName
	sound.Parent = parent or SoundService
	
	-- Assign SoundGroup
	if SoundService:FindFirstChild("SFX") and SoundService:FindFirstChild("Music") then
		local sfxGroup = SoundService.SFX
		local musicGroup = SoundService.Music
		
		-- Simple heuristic: if name contains "Music", assign to Music group
		if string.find(string.lower(soundName), "music") then
			sound.SoundGroup = musicGroup
		else
			sound.SoundGroup = sfxGroup
		end
	end
	
	sound:Play()

	task.spawn(function()
		sound.Ended:Wait()
		sound:Destroy()
	end)
end

return SoundController
