export type ProfileData = {
	Money: number,
	EquippedSkin: string,
	UnlockedSkins: {string},
	Settings: { [string]: any },
}

local ProfileTemplate: ProfileData = {
	Money = 50000,
	EquippedSkin = "Default",
	UnlockedSkins = {"Default"}, -- Default skin is always unlocked
	Settings = {},
}

return ProfileTemplate
