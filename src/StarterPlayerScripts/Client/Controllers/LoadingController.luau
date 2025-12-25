local ReplicatedFirst = game:GetService("ReplicatedFirst")

local LoadingScreen = require(script.Parent.Parent.Components.UI.LoadingScreen)

local LoadingController = {}

function LoadingController:Init()
	-- Remove default Roblox loading screen
	ReplicatedFirst:RemoveDefaultLoadingScreen()
	
	local screen = LoadingScreen.new()
	
	-- Simulation + Real loading
	task.spawn(function()
		local totalSteps = 100 -- Fake steps for smooth animation
		local currentStep = 0
		
		-- Fake loading part 1 (Fast start)
		for i = 1, 20 do
			currentStep += 1
			screen:Update(currentStep / totalSteps)
			task.wait(math.random(0.01, 0.05))
		end
		
		-- Real Preloading (if any specific assets, we add them here)
		-- Since we passed generic services, PreloadAsync will be quick or recursive depending on needs.
		-- For now, we trust the game streaming or basic replication.
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end

		-- Fake loading part 2 (After loaded, finish)
		for i = 21, totalSteps do
			currentStep += 1
			screen:Update(currentStep / totalSteps)
			task.wait(math.random(0.01, 0.05))
		end
		
		-- Finish
		screen:Update(1)
		task.wait(0.5) -- Briefly show 100%
		screen:Destroy()
	end)
end

return LoadingController
