local RunService = game:GetService("RunService")

local SoftShutdownService = {
	_isStudio = RunService:IsStudio(),
	_isBound = false,
}

local DISPLAY_MIN_SECONDS = 7

function SoftShutdownService:_ensureBindToClose()
	if self._isBound then
		return
	end
	self._isBound = true

	game:BindToClose(function()
		if self._isStudio then
			return
		end

		workspace:SetAttribute("ShuttingDown", true)

		RunService.Heartbeat:Wait()

		local deadline = os.clock() + DISPLAY_MIN_SECONDS
		while os.clock() < deadline do
			task.wait()
		end
	end)
end

function SoftShutdownService:Init()
	self:_ensureBindToClose()
end

return SoftShutdownService
