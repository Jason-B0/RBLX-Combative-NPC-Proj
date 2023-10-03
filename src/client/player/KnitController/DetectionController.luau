local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)

local DetectionController = Knit.CreateController({
    Name = "DetectionController",

    NPC_TAG_NAME = "NPC",
})

local LocalPlayer = Players.LocalPlayer
local Character

--==========================================

--==========================================
function DetectionController:Render()
    RunService:BindToRenderStep("Detection", Enum.RenderPriority.Camera, function() end)
end

--==========================================
function DetectionController:KnitInit()
    if not LocalPlayer.Character then
        Character = LocalPlayer.CharacterAdded:Wait()
    else
        Character = LocalPlayer.Character
    end
end

function DetectionController:KnitStart()
    for _, npc: Model in pairs(CollectionService:GetTagged(self.NPC_TAG_NAME)) do
        if npc:FindFirstChildOfClass("Humanoid") then
        end
    end

    CollectionService:GetInstanceAddedSignal(self.NPC_TAG_NAME):Connect(function(npc: Model)
        assert(npc:FindFirstChildOfClass("Humanoid"), "NPC does not have a humanoid!")
    end)

    if
        RunService:IsStudio()
        and script:GetAttribute("DEBUG_ENABLED") == true
        and script.Parent:GetAttribute("DEBUG_MODE") == true
    then
    end
end

return DetectionController
