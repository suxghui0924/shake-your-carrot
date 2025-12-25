local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)
local ProfileTemplateModule = require(ReplicatedStorage.Shared.Data.ProfileTemplate)
local CarrotSkins = ProfileTemplateModule.Skins

local Children = Fusion.Children
local New = Fusion.New
local Computed = Fusion.Computed
local Value = Fusion.Value
local Spring = Fusion.Spring

local SkinGrid = {}

local THEME = {
	BG_MAIN = Color3.fromRGB(20, 20, 24),
	BG_PANEL = Color3.fromRGB(40, 40, 48),
	ACCENT_GREEN = Color3.fromRGB(80, 220, 100),
	TEXT_MAIN = Color3.fromRGB(255, 255, 255),
}

local RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Rare = Color3.fromRGB(50, 150, 255),
	Epic = Color3.fromRGB(180, 60, 255),
	Heroic = Color3.fromRGB(255, 50, 50),
	Legendary = Color3.fromRGB(255, 200, 0),
}

local function CreateMiniViewport(scope, id)
	local skin = CarrotSkins[id]
	if not skin then return nil end

	local world = Instance.new("WorldModel")
	local cam = Instance.new("Camera")
	cam.FieldOfView = 50
	
	-- Async load
	task.defer(function()
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
			if folder then asset = folder:FindFirstChild(skin.Name) end
		end
		
		if asset then
			asset = asset:Clone()
			asset.Parent = world
			
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
			local dist = math.max(size.Magnitude, 3) * 1.4 -- Zoom Out

			local rot = CFrame.Angles(0, math.rad(30), 0)
			local tilt = CFrame.Angles(math.rad(-15), 0, 0)
			
			for _, d in ipairs(asset:GetDescendants()) do
				if d:IsA("BasePart") then d.CFrame = d.CFrame - center end
			end
			
			cam.CFrame = CFrame.new(0, 0, 0) * rot * tilt * CFrame.new(0, 0, dist)
		end
	end)
	
	return scope:New "ViewportFrame" {
		Size = UDim2.fromScale(0.75, 0.75),
		Position = UDim2.fromScale(0.5, 0.4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		CurrentCamera = cam,
		Ambient = Color3.fromRGB(200, 200, 200),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-1, 1, 1),
		[Children] = { world }
	}
end

local function CreateSkinCard(scope, props)
    local id = props.id
    local skin = props.skin
    local SelectedSkin = props.SelectedSkin
    local UnlockedSkins = props.UnlockedSkins
    local EquippedSkin = props.EquippedSkin

	local isSelected = scope:Computed(function(use) return use(SelectedSkin) == id end)
	local isUnlocked = scope:Computed(function(use) return table.find(use(UnlockedSkins), id) or id == "Default" end)
	local isEquipped = scope:Computed(function(use) return use(EquippedSkin) == id end)
	
	local rarityColor = RARITY_COLORS[skin.Rarity] or Color3.new(1,1,1)

    local isHovering = scope:Value(false)
    local springScale = scope:Spring(scope:Computed(function(use) return use(isHovering) and 1.05 or 1.0 end), 20, 0.8)
	
	return scope:New "TextButton" {
		Text = "",
		BackgroundColor3 = scope:Computed(function(use) return use(isSelected) and THEME.BG_PANEL or THEME.BG_MAIN end),
		[Fusion.OnEvent "Activated"] = function()
			SelectedSkin:set(id)
		end,
        [Fusion.OnEvent "MouseEnter"] = function() isHovering:set(true) end,
        [Fusion.OnEvent "MouseLeave"] = function() isHovering:set(false) end,
		[Children] = {
            scope:New "UIScale" { Scale = springScale },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
			scope:New "UIStroke" {
				Color = scope:Computed(function(use) return use(isEquipped) and THEME.ACCENT_GREEN or rarityColor end),
				Thickness = scope:Computed(function(use) return use(isSelected) and 3 or 1 end),
				Transparency = scope:Computed(function(use) return use(isUnlocked) and 0 or 0.5 end)
			},
			
			-- Icon/Preview Image
            CreateMiniViewport(scope, id),
			
			-- Lock Overlay
			scope:New "Frame" {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 0.2, 
				Visible = scope:Computed(function(use) return not use(isUnlocked) end),
				[Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
					scope:New "TextLabel" {
						Text = "🔒",
						TextSize = 24,
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
					}
				}
			},

			-- Labels
			scope:New "TextLabel" {
				Text = skin.Name,
				Font = Enum.Font.FredokaOne,
				TextSize = 18,
				TextColor3 = THEME.TEXT_MAIN,
				Position = UDim2.fromScale(0.5, 0.75),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Size = UDim2.fromScale(0.9, 0.2),
                [Children] = {
                    scope:New "UIStroke" { Color = Color3.new(0,0,0), Thickness = 2, Transparency = 0.5 }
                }
			}
		}
	}
end

function SkinGrid.new(scope, props)
    local Tab = props.Tab
    local UnlockedSkins = props.UnlockedSkins
    local SelectedSkin = props.SelectedSkin
    local EquippedSkin = props.EquippedSkin
    
    local items = scope:Computed(function(use)
		local list = {}
		local unlocked = use(UnlockedSkins)
		local tab = use(Tab) -- "Skins" or "Shop"
		
		-- Get all potential keys
		local keys = {}
		for id, data in pairs(CarrotSkins) do
			local isUnlocked = table.find(unlocked, id) or id == "Default"
			
			if tab == "Skins" then
				if isUnlocked then table.insert(keys, id) end
			elseif tab == "Shop" then
				if not isUnlocked and data.CoinPrice then table.insert(keys, id) end
			end
		end

		table.sort(keys, function(a, b)
			if a == "Default" then return true end
			if b == "Default" then return false end
			return CarrotSkins[a].Name < CarrotSkins[b].Name
		end)

		for i, id in ipairs(keys) do
			local card = CreateSkinCard(scope, {
                id = id, 
                skin = CarrotSkins[id], 
                SelectedSkin = SelectedSkin, 
                UnlockedSkins = UnlockedSkins, 
                EquippedSkin = EquippedSkin
            })
			card.LayoutOrder = i
			table.insert(list, card)
		end
		
		return list
	end)

	return items 
end

return SkinGrid
