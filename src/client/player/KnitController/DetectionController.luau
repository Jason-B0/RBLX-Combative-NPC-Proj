local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)

local DetectionController = Knit.CreateController({
    Name = "DetectionController",

    NPC_TAG_NAME = "NPC",
    npcs = {},
    
    DETECTION_DISTANCE = {
        DAY_OUTDOOR = 100,
        NIGHT_OUTDOOR = 50,
        BRIGHT_INDOOR = 70,
        DARK_INDOOR = 10,
    },

    IGNORED_TEAM_COLOR = BrickColor.new("Crimson"),
    
    nearestNPC = nil,
    distanceInBetween = nil,
})

local LocalPlayer = Players.LocalPlayer
local Character

--=========================================='

--[[ 
    Detects if the an NPC in a given range is able to see the player.
    Returns the nearest NPC and the distance between the player and the NPC
]]
local function npcCanSeePlayer(npc: Types.NPC)
    
    -- ignore if the player is an admin
    if LocalPlayer.TeamColor == DetectionController.IGNORED_TEAM_COLOR then return end
    
    local function isInFieldOfView(unit: Vector3)
        local npcLook: Vector3 = npc.HumanoidRootPart.CFrame.LookVector
        local dotProd: number = unit:Dot(npcLook)

        if dotProd > 0.2 then
            return true
        end
        return false
    end

    local function isNotObstructedByPart(
        charModel: Types.Character,
        originPos: Vector3,
        unit: Vector3,
        dist: number
    )
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances =
            { charModel, npc }
        local ray = Ray.new(originPos, unit * dist)
        local result = workspace:Raycast(ray.Origin, ray.Direction, raycastParams)

        if result ~= nil then
            if result.Instance.Parent == charModel then
                return true
            end
            return false
        end
        return false
    end

    local nearestNPC, distanceInBetween = nil, nil
    local distance = DetectionController.DETECTION_DISTANCE[npc:GetAttribute("DetectionDistance")]
    local humanoid: Humanoid, humanoidRootPart: BasePart

    humanoid = npc.Humanoid
    humanoidRootPart = npc.HumanoidRootPart

    if (humanoid.Health > 0) then
        local diff: Vector3 = humanoidRootPart.Position - Character.HumanoidRootPart.Position
        local diffMagnitude: number = diff.Magnitude
        local diffUnit: Vector3 = diff.Unit

        if diffMagnitude <= distance then
            local isInFOV = isInFieldOfView(diffUnit)
            local isNotObstructed =
                isNotObstructedByPart(npc, Character.HumanoidRootPart.Position, diffUnit, distance)
            if ( isInFOV and isNotObstructed and (distanceInBetween == nil or (distanceInBetween ~= nil and diffMagnitude < distanceInBetween)) )
            then
                nearestNPC = npc
                distanceInBetween = diffMagnitude
            end
        end
    end

    return nearestNPC, distanceInBetween
    
end
--==========================================
function DetectionController:Render()
    RunService:BindToRenderStep("Detection", Enum.RenderPriority.Camera, function()
        for _, npc: Model in pairs(self.npcs) do
            
            local nearestNPC, distanceInBetween = npcCanSeePlayer(npc)
            
            if self.distanceInBetween < distanceInBetween then
                self.nearestNPC, self.distanceInBetween = nearestNPC, distanceInBetween
            end
            
        end
    end)
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
            self.npcs[npc.Name] = npc
        end
    end

    CollectionService:GetInstanceAddedSignal(self.NPC_TAG_NAME):Connect(function(npc: Model)
        assert(npc:FindFirstChildOfClass("Humanoid"), "NPC does not have a humanoid!")
        self.npcs[npc.Name] = npc
    end)

    if
        RunService:IsStudio()
        and script:GetAttribute("DEBUG_ENABLED") == true
        and script.Parent:GetAttribute("DEBUG_MODE") == true
    then
        -- do something eventually
    end
end

return DetectionController
