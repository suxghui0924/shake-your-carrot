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
		},
		queries = {
			getLeaderboard = ByteNetMax.defineQuery({
				request = ByteNetMax.nothing,
				response = ByteNetMax.string, -- JSON encoded leaderboard data
			}),
		},
	}
end)
