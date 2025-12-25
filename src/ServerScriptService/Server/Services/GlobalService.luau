local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")

local GlobalService = {}
GlobalService.__index = GlobalService

local topicPattern = "^[%w%/_%-]+$"

local function isValidTopic(t: string): boolean
	return typeof(t) == "string" and t ~= "" and string.match(t, topicPattern) ~= nil
end

local function encodePayload(d): string
	return (typeof(d) == "string") and d or HttpService:JSONEncode(d)
end

local function decodePayload(p)
	if typeof(p) ~= "string" then
		return p
	end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, p)
	return ok and decoded or p
end

local function backoff(attempt: number, baseDelay: number, jitter: boolean)
	local delaySec = baseDelay * (2 ^ (attempt - 1))
	if jitter then
		delaySec += math.random() * 0.2
	end
	task.wait(delaySec)
end

function GlobalService:Subscribe(topic: string, callback: (any) -> ()): RBXScriptConnection?
	if not isValidTopic(topic) then
		warn("[GlobalService] Invalid topic:", topic)
		return nil
	end

	local ok, subOrErr = pcall(function()
		return MessagingService:SubscribeAsync(topic, function(message)
			local data = decodePayload(message.Data)
			local s, e = pcall(callback, data)
			if not s then
				warn("[GlobalService] Callback error:", e)
			end
		end)
	end)

	if ok then
		return subOrErr
	else
		warn("[GlobalService] Failed to subscribe:", topic, subOrErr)
		return nil
	end
end

function GlobalService:Publish(topic: string, data: any, opts): (boolean, string?)
	if not isValidTopic(topic) then
		return false, "InvalidTopic"
	end

	opts = opts or {}
	local maxRetries = tonumber(opts.retries) or 5
	local baseDelay = tonumber(opts.baseDelay) or 1
	local useJitter = (opts.jitter ~= false)

	local payload = encodePayload(data)
	if #payload > 900 * 1024 then
		return false, "PayloadTooLarge"
	end

	local lastErr: string? = nil
	for attempt = 1, maxRetries do
		local ok, err = pcall(MessagingService.PublishAsync, MessagingService, topic, payload)
		if ok then
			return true, nil
		else
			lastErr = tostring(err)
			if attempt < maxRetries then
				backoff(attempt, baseDelay, useJitter)
			end
		end
	end

	warn("[GlobalService] Publish failed:", topic, lastErr)
	return false, lastErr
end

function GlobalService:Init()
end

return GlobalService
