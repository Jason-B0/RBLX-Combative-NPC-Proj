local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Roact = require(game:GetService("ReplicatedStorage").Packages.Roact)
local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)

local e = Roact.createElement

local UIController = Knit.CreateController({
    Name = "UIController",
    existingUITree = nil,
})

UIController.PageChanged = Signal.new()
UIController.InputToggleChanged = Signal.new()
--==========================================
function UIController:ToggleInput(newState)
    self.InputToggleChanged:Fire(newState)
end

function UIController:SwitchToPage(newPage)
    self.PageChanged:Fire(newPage)
end

function UIController:MountUI()
    local app = require(LocalPlayer.PlayerGui:WaitForChild("NewSystem").App)
    self:UnmountUI()
    self.existingUITree = Roact.mount(e(app), LocalPlayer.PlayerGui, "DatabaseSystemUI")
end

function UIController:UnmountUI()
    if self.existingUITree then
        Roact.unmount(self.existingUITree)
        self.existingUITree = nil
    end
end
--==========================================
function UIController:KnitInit()
    if
        RunService:IsStudio()
        and script:GetAttribute("DEBUG_ENABLED") == true
        and script.Parent:GetAttribute("DEBUG_MODE") == true
    then
        self:MountUI()
    end
end

function UIController:KnitStart() end

return UIController
