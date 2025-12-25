export type ProfileData = {
	Money: number,
	Settings: { [string]: any },
}

local ProfileTemplate: ProfileData = {
	Money = 50000,
	EquippedTree = "DefaultTree",
	Settings = {},
}

return ProfileTemplate
