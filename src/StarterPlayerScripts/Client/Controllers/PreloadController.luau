local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Sounds = require(ReplicatedStorage.Shared.Sounds)

local PreloadController = {}

function PreloadController:Init()
	task.spawn(function()
		local assets = {}
		
		-- 1. Sounds
		-- print("Preloading Sounds...")
		for _, config in pairs(Sounds) do
			if config.SoundId then
				table.insert(assets, config.SoundId)
			end
		end
		
		-- 2. Animations
		local animFolder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Animations")
		if animFolder then
			-- print("Preloading Animations...")
			for _, anim in ipairs(animFolder:GetChildren()) do
				if anim:IsA("Animation") then
					table.insert(assets, anim)
				end
			end
		end
		
		-- 3. Carrot Skins (Meshes/Textures)
		local carrotFolder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Carrots")
		if carrotFolder then
			-- print("Preloading Skins...")
			for _, skin in ipairs(carrotFolder:GetDescendants()) do
				if skin:IsA("MeshPart") or skin:IsA("Texture") or skin:IsA("Decal") then
					table.insert(assets, skin)
				end
			end
		end
		
		-- Execute Preload
		local startTime = os.clock()
		ContentProvider:PreloadAsync(assets)
		local duration = os.clock() - startTime
		
		-- print(string.format("Preload Complete! Loaded %d assets in %.2f seconds.", #assets, duration))
	end)
end

return PreloadController
