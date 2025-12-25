local ServerScriptService = game:GetService("ServerScriptService")

local Network = require(game.ReplicatedStorage.Shared.Network)
local GlobalService = require(ServerScriptService.Server.Services.GlobalService)

local TOPIC = "GlobalMessage"

local NAME_COLOR_PALETTE = {
	Color3.fromRGB(253, 41, 67),
	Color3.fromRGB(1, 162, 255),
	Color3.fromRGB(2, 184, 87),
	Color3.fromRGB(255, 154, 76),
	Color3.fromRGB(102, 86, 169),
	Color3.fromRGB(255, 204, 0),
	Color3.fromRGB(0, 183, 235),
	Color3.fromRGB(255, 102, 196),
}

task.spawn(function()
	GlobalService:Subscribe(TOPIC, function(data)
		local s = tostring(data.executorUserId)
		local h = 0
		for i = 1, #s do
			h = (h * 31 + string.byte(s, i)) % 0x7fffffff
		end
		local idx = (h % #NAME_COLOR_PALETTE) + 1
		local c = NAME_COLOR_PALETTE[idx]

		local nameColor = string.format(
			"#%02X%02X%02X",
			math.floor(c.R * 255 + 0.5),
			math.floor(c.G * 255 + 0.5),
			math.floor(c.B * 255 + 0.5)
		)

		local coloredName = `<font color="{nameColor}"> {data.executorName}</font>`
		local message = `{coloredName} {data.msg}`

        local icon = `rbxthumb://type=AvatarHeadShot&id={data.executorUserId}&w=48&h=48`

		Network.packets.sendNotification.sendToAll({
			message = message,
			duration = 5,
            icon = icon
		})
	end)
end)

return function(context, message: string)
	local executor = context.Executor
	if not executor then
		return "실행자를 찾을 수 없습니다."
	end

	GlobalService:Publish(TOPIC, {
		executorName = executor.Name,
		executorUserId = executor.UserId,
		msg = message,
	})
	return "성공적으로 메시지를 전송하였습니다."
end
