local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)
local ProfileTemplateModule = require(ReplicatedStorage.Shared.Data.ProfileTemplate)
local CarrotSkins = ProfileTemplateModule.Skins

local Children = Fusion.Children
local New = Fusion.New
local peek = Fusion.peek

local SkinViewport = {}

function SkinViewport.new(scope, props)
    local SelectedSkin = props.SelectedSkin
    local PreviewRotation = props.PreviewRotation -- Value

	local world = Instance.new("WorldModel")
	local cam = Instance.new("Camera")
	cam.FieldOfView = 50
	
	local currentDist = 5
	
	local function updateCamera()
		local angle = peek(PreviewRotation)
		-- Rotate camera around center
		local rot = CFrame.Angles(0, math.rad(angle), 0)
		local tilt = CFrame.Angles(math.rad(-15), 0, 0)
		cam.CFrame = CFrame.new(0, 0, 0) * rot * tilt * CFrame.new(0, 0, currentDist)
	end

	local function update()
		world:ClearAllChildren()
		local id = peek(SelectedSkin)
		local skin = CarrotSkins[id]
		if not skin then return end
		
		-- Asset Loader Helper
		local function getAssetFromPath(path)
			local segments = string.split(path, ".")
			local current = game
			for _, segment in ipairs(segments) do
				current = current:FindFirstChild(segment)
				if not current then return nil end
			end
			return current
		end

		local asset = getAssetFromPath(skin.AssetPath)
		if not asset then
			local folder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Carrots")
			if folder then
				asset = folder:FindFirstChild(skin.Name)
			end
		end
		
		if asset then
			asset = asset:Clone()
			asset.Parent = world
			
			-- Center Asset
			local min = Vector3.new(math.huge, math.huge, math.huge)
			local max = Vector3.new(-math.huge, -math.huge, -math.huge)
			
			for _, d in ipairs(asset:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					local size = d.Size
					local cf = d.CFrame
					local corners = {
						cf * Vector3.new(size.X/2, size.Y/2, size.Z/2),
						cf * Vector3.new(size.X/2, size.Y/2, -size.Z/2),
						cf * Vector3.new(size.X/2, -size.Y/2, size.Z/2),
						cf * Vector3.new(size.X/2, -size.Y/2, -size.Z/2),
						cf * Vector3.new(-size.X/2, size.Y/2, size.Z/2),
						cf * Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
						cf * Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
						cf * Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
					}
					for _, c in ipairs(corners) do
						min = Vector3.new(math.min(min.X, c.X), math.min(min.Y, c.Y), math.min(min.Z, c.Z))
						max = Vector3.new(math.max(max.X, c.X), math.max(max.Y, c.Y), math.max(max.Z, c.Z))
					end
				end
			end
			
			local center = (min + max) / 2
			local size = max - min
			local maxDim = math.max(size.X, size.Y, size.Z)
			-- currentDist = maxDim * 1.5 
			currentDist = math.max(maxDim * 1.5, 3)
			
			for _, d in ipairs(asset:GetDescendants()) do
				if d:IsA("BasePart") then d.CFrame = d.CFrame - center end
			end
		else
			-- Fallback box
			local box = Instance.new("Part")
			box.Size = Vector3.new(1.5, 1.5, 1.5)
			box.Material = Enum.Material.Neon
			box.Parent = world
			currentDist = 5
		end
		updateCamera()
	end
	
	-- Observers
	local trove = scope:Observer(SelectedSkin):onChange(update)
    table.insert(scope, trove)
    
	task.defer(update)
	
	-- Rotate Camera
	local trove2 = scope:Observer(PreviewRotation):onChange(updateCamera)
    table.insert(scope, trove2)
	
	return scope:New "ViewportFrame" {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		CurrentCamera = cam,
		Ambient = Color3.fromRGB(150, 150, 150),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(1, 1, 1),
		[Children] = { world }
	}
end

return SkinViewport
