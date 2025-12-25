local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local spr = require(ReplicatedStorage.Packages.spr)

local LocalPlayer = Players.LocalPlayer

local SoundController = require(LocalPlayer.PlayerScripts.Client.Controllers.SoundController)

local ClickEffect = Component.new({
    Tag = "ClickEffect",
    Ancestors = { LocalPlayer:WaitForChild("PlayerGui") },
})

function ClickEffect:Construct()
    self._trove = Trove.new()
    self.clickInScale = 0.9
    self.clickOutScale = 1
end

function ClickEffect:Start()
    local gui = self.Instance
    assert(gui:IsA("GuiButton"), `{gui:GetFullName()}은 GuiButton이어야 합니다. 현재 클래스: {gui.ClassName}`)

    local uiScale = gui:FindFirstChildOfClass("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale")
        uiScale.Parent = gui
    end

    gui:SetAttribute("IsHovered", false)
    self._trove:Connect(gui.MouseEnter, function()
        gui:SetAttribute("IsHovered", true)
    end)
    self._trove:Connect(gui.MouseLeave, function()
        gui:SetAttribute("IsHovered", false)
    end)

    self._trove:Connect(gui.MouseButton1Down, function()
        spr.target(uiScale, 0.4, 3, {
            Scale = self.clickInScale,
        })
    end)

    self._trove:Connect(gui.MouseButton1Up, function()
        if gui:GetAttribute("IsHovered") then
            self.clickOutScale = 1.1
        else
            self.clickOutScale = 1.0
        end
        spr.target(uiScale, 0.4, 3, {
            Scale = self.clickOutScale,
        })
    end)

    self._trove:Connect(gui.MouseButton1Click, function()
        SoundController:PlaySound("Click")
    end)
end

function ClickEffect:Stop()
    self._trove:Destroy()
end

return ClickEffect
