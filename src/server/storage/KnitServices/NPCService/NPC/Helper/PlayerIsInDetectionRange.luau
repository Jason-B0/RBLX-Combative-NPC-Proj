local Players = game:GetService("Players")
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)
local Config = require(script.Parent.Parent.Config)

local NPC_FOV = 60
local IGNORED_TEAM_COLOR = BrickColor.new("Crimson")
local GAME_WORKSPACE = workspace:WaitForChild("GAME_WORKSPACE") :: Folder
local DETECTION_DISTANCE = {
	DAY_OUTDOOR = 100,
	NIGHT_OUTDOOR = 50,
	BRIGHT_INDOOR = 70,
	DARK_INDOOR = 10,
}

local function checkLineOfSight(
    npcChar: Model | Types.NPCModel,
    plrChar: Model | Types.Character,
    start: Vector3,
    targ: Vector3
): (boolean, number | nil)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { npcChar, plrChar, GAME_WORKSPACE }
    local result = workspace:Raycast(start, targ - start, raycastParams) :: RaycastResult
    
    if result == nil then
        return true
    end
    return false
end

return function(npcModel: Types.NPCModel, targPlayer: Player, disregardFOV: boolean?): boolean

    local plrChar = targPlayer.Character

    -- ignore if the player is an admin
    if targPlayer.TeamColor == IGNORED_TEAM_COLOR then
        return false
    end

    -- ignore if player is dead, dead player can't see
    if plrChar.Humanoid.Health <= 0 then
        return false
    end

    local plrInRange = false
    local distance = DETECTION_DISTANCE[npcModel:GetAttribute("DetectionDistance")]
    local plrHumanoid: Humanoid, plrHrp: BasePart

    plrHumanoid = plrChar.Humanoid :: Humanoid
    plrHrp = plrChar.HumanoidRootPart

    if plrHumanoid.Health > 0 then
        local diff: Vector3 = npcModel.HumanoidRootPart.Position - plrHrp.Position
        local diffMagnitude: number = diff.Magnitude
        local diffUnit: Vector3 = diff.Unit

        if disregardFOV == true and diffMagnitude <= 150 then
            plrInRange = true
        elseif diffMagnitude <= distance then
            local hasLineOfSight =
                checkLineOfSight(npcModel, plrChar, npcModel.HumanoidRootPart.Position, plrHrp.Position)
            if hasLineOfSight then
                plrInRange = true
            end
        end
    end
    return plrInRange
end
