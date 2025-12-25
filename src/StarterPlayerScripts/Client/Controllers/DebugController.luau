local LogService = game:GetService("LogService")
local TextChatService = game:GetService("TextChatService")

local DebugController = {}

local MessageData = {
	[Enum.MessageType.MessageError] = { color = "#FF4C4C" },
	[Enum.MessageType.MessageWarning] = { color = "#FFA500" },
}

function DebugController:DisplayLog(message, messageType)
	local data = MessageData[messageType]
	if not data then
		return
	end
	local richMessage = ("<b><font color='%s'>%s</font></b>"):format(data.color, message)
	TextChatService.TextChannels.RBXSystem:DisplaySystemMessage(richMessage)
end

function DebugController:Init()
	for _, log in ipairs(LogService:GetLogHistory()) do
		self:DisplayLog(log.message, log.messageType)
	end

	LogService.MessageOut:Connect(function(message, messageType)
		self:DisplayLog(message, messageType)
	end)
end

return DebugController
