--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TopbarPlus = require(ReplicatedStorage.Packages.TopbarPlus)
local CmdrClient = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local Admins = require(ReplicatedStorage.Shared.Admins)

local TOGGLE_KEY = Enum.KeyCode.F2
local ICON_LABEL = "Cmdr"
local ICON_CAPTION = "Cmdr 열기 / 닫기 (F2)"

local CmdrController = {}

function CmdrController:_addIcon()
	local icon = TopbarPlus.new()
	icon:align("Right")
	icon:oneClick(true)
	icon:setLabel(ICON_LABEL)
	icon:setCaption(ICON_CAPTION)

	icon:bindEvent("selected", function()
		CmdrClient:Show()
	end)
end

function CmdrController:Init()
	local localPlayer = Players.LocalPlayer
	assert(localPlayer, "플레이어 찾을 수 없음")

	if not Admins[localPlayer.UserId] then
		CmdrClient:SetEnabled(false)
		return
	end

	CmdrClient:SetActivationKeys({ TOGGLE_KEY })
	CmdrClient:SetEnabled(true)
	self:_addIcon()
end

return CmdrController
