local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local spr = require(ReplicatedStorage.Packages.spr)

local LocalPlayer = Players.LocalPlayer

local SoundController = require(LocalPlayer.PlayerScripts.Client.Controllers.SoundController)

local HoverEffect = Component.new({
    Tag = "HoverEffect",
    Ancestors = { LocalPlayer:WaitForChild("PlayerGui") },
})

function HoverEffect:Construct()
    self._trove = Trove.new()
    self.hoverInScale = 1.1
    self.hoverOutScale = 1.0
end

function HoverEffect:Start()
	local gui = self.Instance
	assert(gui:IsA("GuiObject"), `{gui:GetFullName()}은 GuiObject이어야 합니다. 현재 클래스: {gui.ClassName}`)

	local uiScale = gui:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = gui
	end

	gui:SetAttribute("IsHovered", false)

	local function resetHover()
		gui:SetAttribute("IsHovered", false)
		spr.target(uiScale, 0.4, 3, { Scale = self.hoverOutScale })
	end

	self._trove:Connect(gui.MouseEnter, function()
		gui:SetAttribute("IsHovered", true)
		SoundController:PlaySound("Hover")
		spr.target(uiScale, 0.4, 3, { Scale = self.hoverInScale })
	end)

	self._trove:Connect(gui.MouseLeave, function()
		resetHover()
	end)
	
	if gui:IsA("GuiButton") then
		self._trove:Connect(gui.MouseButton1Click, function()
			resetHover()
		end)
	end
end

function HoverEffect:Stop()
    self._trove:Destroy()
end

return HoverEffect
