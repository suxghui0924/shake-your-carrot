local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AdminData = require(ReplicatedStorage.Shared.Admins)

return function(registry)
	registry:RegisterHook("BeforeRun", function(context)
		local executor = context.Executor
		if not executor then
			return "Executor를 찾을 수 없습니다."
		end

		local userId = executor.UserId
		local isAdmin = AdminData[userId] == true
		local isAdminCommand = context.Group == "Admin"

		if isAdminCommand and not isAdmin then
			return "권한이 없습니다."
		end

		return nil
	end)
end
