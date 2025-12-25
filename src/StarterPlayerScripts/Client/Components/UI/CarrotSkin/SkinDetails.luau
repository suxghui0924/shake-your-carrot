local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)
local Network = require(ReplicatedStorage.Shared.Network)
local ProfileTemplateModule = require(ReplicatedStorage.Shared.Data.ProfileTemplate)
local CarrotSkins = ProfileTemplateModule.Skins

local Children = Fusion.Children
local New = Fusion.New
local Computed = Fusion.Computed
local Value = Fusion.Value
local Spring = Fusion.Spring
local peek = Fusion.peek

local SkinViewport = require(script.Parent.SkinViewport)

local SkinDetails = {}

local THEME = {
	BG_SEC = Color3.fromRGB(30, 30, 36),
	TEXT_MAIN = Color3.fromRGB(255, 255, 255),
	TEXT_DIM = Color3.fromRGB(180, 180, 190),
    ACCENT_GREEN = Color3.fromRGB(80, 220, 100),
    ACCENT_ORANGE = Color3.fromRGB(255, 120, 40),
}

local RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Rare = Color3.fromRGB(50, 150, 255),
	Epic = Color3.fromRGB(180, 60, 255),
	Heroic = Color3.fromRGB(255, 50, 50),
	Legendary = Color3.fromRGB(255, 200, 0),
}

function SkinDetails.new(scope, props)
    local SelectedSkin = props.SelectedSkin
    local UnlockedSkins = props.UnlockedSkins
    local EquippedSkin = props.EquippedSkin
    local PreviewRotation = props.PreviewRotation

    -- Action Button Hover State
    local isHoveringAction = scope:Value(false)
    local actionScale = scope:Spring(scope:Computed(function(use) return use(isHoveringAction) and 1.05 or 1.0 end), 20, 0.8)

	return {
		scope:New "UIPadding" { PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,10), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10) },
		scope:New "UIListLayout" { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center },
		
		-- 3D PREVIEW BOX
		scope:New "Frame" {
			Size = UDim2.fromOffset(280, 240),
			BackgroundColor3 = Color3.new(0,0,0),
			BackgroundTransparency = 0.5,
			[Children] = {
				scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
				SkinViewport.new(scope, {
                    SelectedSkin = SelectedSkin,
                    PreviewRotation = PreviewRotation
                })
			}
		},
		
		-- INFO
		scope:New "TextLabel" {
			Text = scope:Computed(function(use) 
				local s = CarrotSkins[use(SelectedSkin)]
				return s and s.Name or "Unknown"
			end),
			Font = Enum.Font.FredokaOne,
			TextSize = 24,
			TextColor3 = THEME.TEXT_MAIN,
			Size = UDim2.new(1,0,0,30),
			BackgroundTransparency = 1,
		},
		
		scope:New "TextLabel" {
			Text = scope:Computed(function(use) 
				local s = CarrotSkins[use(SelectedSkin)]
				return s and s.Rarity or ""
			end),
			Font = Enum.Font.Code,
			TextSize = 16,
			TextColor3 = scope:Computed(function(use)
				local s = CarrotSkins[use(SelectedSkin)]
				return s and RARITY_COLORS[s.Rarity] or THEME.TEXT_DIM
			end),
			Size = UDim2.new(1,0,0,20),
			BackgroundTransparency = 1,
		},
		
		scope:New "TextLabel" {
			Text = scope:Computed(function(use) 
				local s = CarrotSkins[use(SelectedSkin)]
				return s and s.Description or ""
			end),
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextColor3 = THEME.TEXT_DIM,
			Size = UDim2.new(1,0,0,60),
			BackgroundTransparency = 1,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
		},
		
		-- ACTION BUTTON
		scope:New "TextButton" {
			Size = UDim2.new(1, 0, 0, 50),
			BackgroundColor3 = scope:Computed(function(use)
				local id = use(SelectedSkin)
				local unlocked = table.find(use(UnlockedSkins), id) or id == "Default"
				return unlocked and THEME.ACCENT_GREEN or THEME.ACCENT_ORANGE
			end),
			Text = scope:Computed(function(use)
				local id = use(SelectedSkin)
				local unlocked = table.find(use(UnlockedSkins), id) or id == "Default"
				if unlocked then
					return use(EquippedSkin) == id and "EQUIPPED" or "EQUIP"
				else
					local p = CarrotSkins[id] and CarrotSkins[id].CoinPrice or 0
					return "BUY " .. p .. " 💰"
				end
			end),
			Font = Enum.Font.FredokaOne,
			TextSize = 20,
			TextColor3 = Color3.new(1,1,1),
            [Fusion.OnEvent "MouseEnter"] = function() isHoveringAction:set(true) end,
            [Fusion.OnEvent "MouseLeave"] = function() isHoveringAction:set(false) end,
            [Fusion.OnEvent "Activated"] = function()
				local id = peek(SelectedSkin)
				local unlocked = table.find(peek(UnlockedSkins), id) or id == "Default"
				if unlocked then
					Network.packets.equipSkin.send({ skinId = id })
				else
					Network.packets.buySkin.send({ skinId = id })
				end
			end,
			[Children] = {
                scope:New "UIScale" { Scale = actionScale },
				scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
                scope:New "UIStroke" { Color = Color3.new(1,1,1), Thickness = 2, Transparency = 0.5 },
			},
		}
	}
end

return SkinDetails
