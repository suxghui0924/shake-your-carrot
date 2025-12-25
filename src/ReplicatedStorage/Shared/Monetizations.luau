-- ReplicatedStorage/Shared/Monetizations.luau

return {
	Products = {
		-- Coins Bundles
		[1001] = {
			Name = "1,000 Coins",
			Description = "Get 1,000 coins immediately!",
			Amount = 1000,
			Type = "Coins",
		},
		[1002] = {
			Name = "5,000 Coins",
			Description = "Get 5,000 coins immediately!",
			Amount = 5000,
			Type = "Coins",
		},
		[1003] = {
			Name = "10,000 Coins",
			Description = "Get 10,000 coins immediately!",
			Amount = 10000,
			Type = "Coins",
		},
		
		-- Skins (Alternative purchase with Robux)
		[2001] = {
			Name = "Unlock Golden Carrot",
			SkinId = "Golden",
			Type = "Skin",
		},
	},
	GamePasses = {
		[3001] = {
			Name = "VIP Pass",
			Description = "Double coins and exclusive benefits!",
		},
	},
}
