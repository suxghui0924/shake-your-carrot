local ByteNetMax = require(game.ReplicatedStorage.Packages["bytenet-max"])

return ByteNetMax.defineNamespace("Network", function()
	return {
		packets = {
			testPacket = ByteNetMax.definePacket({
				value = ByteNetMax.struct({
					nothing = ByteNetMax.nothing,
				}),
			}),
			sendNotification = ByteNetMax.definePacket({
				value = ByteNetMax.struct({
					message = ByteNetMax.string,
					duration = ByteNetMax.int16,
					icon = ByteNetMax.optional(ByteNetMax.string),
				}),
			}),
			submitWord = ByteNetMax.definePacket({
				value = ByteNetMax.struct({
					word = ByteNetMax.string,
				}),
			}),
			wordUpdate = ByteNetMax.definePacket({
				value = ByteNetMax.struct({
					currentWord = ByteNetMax.string,
					history = ByteNetMax.array(ByteNetMax.string),
					lastPlayer = ByteNetMax.optional(ByteNetMax.string),
				}),
			}),
			gameReset = ByteNetMax.definePacket({
				value = ByteNetMax.nothing,
			}),
			shakeCarrot = ByteNetMax.definePacket({
				value = ByteNetMax.nothing,
			}),
			carrotAttack = ByteNetMax.definePacket({
				value = ByteNetMax.struct({
					attackType = ByteNetMax.string, -- "Normal", "Combo", "Charge"
				}),
			}),
			equipSkin = ByteNetMax.definePacket({
				value = ByteNetMax.struct({
					skinId = ByteNetMax.string,
				}),
			}),
			buySkin = ByteNetMax.definePacket({
				value = ByteNetMax.struct({
					skinId = ByteNetMax.string,
				}),
			}),
			roundStatusUpdate = ByteNetMax.definePacket({
				value = ByteNetMax.struct({
					status = ByteNetMax.string, -- "Intermission", "Round", "Ended"
					timeLeft = ByteNetMax.int16,
					message = ByteNetMax.optional(ByteNetMax.string),
				}),
			}),
		},
		queries = {
			getLeaderboard = ByteNetMax.defineQuery({
				request = ByteNetMax.nothing,
				response = ByteNetMax.string, -- JSON encoded leaderboard data
			}),
		},
	}
end)
