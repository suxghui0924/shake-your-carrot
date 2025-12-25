local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Network = require(ReplicatedStorage.Shared.Network)
local SoundController = require(script.Parent.SoundController)

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Fusion = require(Packages.Fusion)

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local PopupComponent = require(PlayerScripts:WaitForChild("Fusion"):WaitForChild("Components"):WaitForChild("PopupComponent"))

local NotificiationController = {}
local scope = Fusion.scoped(Fusion)
local messages = scope:Value({})
local msgCounter = 0

function NotificiationController:Init()
    PopupComponent.new({
        scope = scope,
        Parent = PlayerGui,
        messages = messages,
        onRemove = function(id)
            local val = Fusion.peek(messages)
            if val[id] then
                local newMessages = table.clone(val)
                newMessages[id] = nil
                messages:set(newMessages)
            end
        end
    })

	Network.packets.sendNotification.listen(function(data)
		self:SendNotification(data.message, data.duration, nil, data.icon)
	end)
end


function NotificiationController:SendNotification(message: string, duration: number?, icon: string?)
	if not message then
		warn("무조건 메시지는 있어야합니다!")
		return	
	end

	duration = duration or 1.5

    -- Add to state
    local id = HttpService:GenerateGUID(false)
    local current = table.clone(Fusion.peek(messages))
    
    -- Optimization: Max active messages limit
    local MAX_MESSAGES = 5
    local count = 0
    local oldestId, lowestOrder = nil, math.huge
    
    for k, v in pairs(current) do
        count += 1
        if v.layoutOrder < lowestOrder then
            lowestOrder = v.layoutOrder
            oldestId = k
        end
    end
    
    if count >= MAX_MESSAGES and oldestId then
        current[oldestId] = nil
    end

    msgCounter += 1
    current[id] = {
        message = message,
        duration = duration,
        layoutOrder = msgCounter,
        createdAt = os.clock(),
        icon = icon
    }
    messages:set(current)

	SoundController:PlaySound("Notification", nil, 1)
end

return NotificiationController
