local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Fusion = require(Packages.Fusion)

local Children = Fusion.Children

-- Sub-Components
local HUD = script.Parent.HUD
local StatusHUD = require(HUD.StatusHUD)
local SplashScreen = require(HUD.SplashScreen)
local GameOverBoard = require(HUD.GameOverBoard)

local AnnouncerUI = {}

function AnnouncerUI.new(props)
    local scope = props.scope
    
    local parent = props.Parent
    
    local gui = scope:New "ScreenGui" {
        Name = "AnnouncerUI",
        Parent = parent,
        ResetOnSpawn = false,
        DisplayOrder = 1000, 
        IgnoreGuiInset = true, 
        
        [Children] = {
			-- Status (Top Bar)
			StatusHUD.new(scope, props),
			
			-- Game Over Leaderboard
			GameOverBoard.new(scope, props),
            
            -- Splash Screen (Overlay)
			SplashScreen.new(scope, props)
        }
    }
    
    return gui
end

return AnnouncerUI
