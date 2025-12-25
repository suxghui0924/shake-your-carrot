-- Carrot Skins Data
-- Defines all available carrot skins in the game

local CarrotSkins = {
	["Default"] = {
		Name = "기본 당근",
		Description = "평범하지만 믿음직한 우리들의 기본 당근입니다.",
		Skill = "특수 능력 없음",
		Rarity = "Common",
		AssetPath = "ReplicatedStorage.Assets.Carrots.기본 당근",
		Color = Color3.fromRGB(255, 140, 0),
		Material = Enum.Material.SmoothPlastic,
		Unlocked = true,
		CoinPrice = 0,
		RobuxPrice = 0, -- ProductID if applicable
	},
	
	["Golden"] = {
		Name = "황금 당근",
		Description = "눈부신 금빛으로 적들의 눈을 멀게 할지도 모릅니다.",
		Skill = "골드 획득량 15% 증가",
		Rarity = "Legendary",
		AssetPath = "ReplicatedStorage.Assets.Carrots.황금 당근",
		Color = Color3.fromRGB(255, 215, 0),
		Material = Enum.Material.Neon,
		Unlocked = false,
		CoinPrice = 10000,
		RobuxPrice = 1234567, -- Placeholder ProductID
	},
	
	["Rainbow"] = {
		Name = "무지개 당근",
		Description = "일곱 빛깔 꿈을 담은 신비로운 당근입니다.",
		Skill = "공격 범위 10% 증가",
		Rarity = "Epic",
		AssetPath = "ReplicatedStorage.Assets.Carrots.무지개 당근",
		Color = Color3.fromRGB(255, 100, 255),
		Material = Enum.Material.Neon,
		Unlocked = false,
		CoinPrice = 5000,
		RobuxPrice = 2345678, -- Placeholder ProductID
	},
	
	["Frenzy"] = {
		Name = "광란의 당근",
		Description = "주체할 수 없는 힘이 넘쳐흐르는 당근입니다!",
		Skill = "공격 속도 20% 증가",
		Rarity = "Heroic",
		AssetPath = "ReplicatedStorage.Assets.Carrots.광란의 당근",
		Color = Color3.fromRGB(255, 0, 0),
		Material = Enum.Material.Neon,
		Unlocked = false,
		CoinPrice = 7500,
		RobuxPrice = 3456789, -- Placeholder ProductID
	},
}

return CarrotSkins
