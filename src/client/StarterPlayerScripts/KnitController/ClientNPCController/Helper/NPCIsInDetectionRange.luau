local LocalPlayer = game:GetService("Players").LocalPlayer
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local NPC_FOV = 60
local IGNORED_TEAM_COLOR = BrickColor.new("Crimson")
local DETECTION_DISTANCE = {
	DAY_OUTDOOR = 100,
	NIGHT_OUTDOOR = 50,
	BRIGHT_INDOOR = 70,
	DARK_INDOOR = 10,
}

return function(npc: Types.NPCModel, disregardFOV: boolean?): boolean
    local function isInFieldOfView(unit: Vector3)
        local npcLook: Vector3 = npc.HumanoidRootPart.CFrame.LookVector
        local dotProd: number = unit:Dot(npcLook)
        local angle: number = math.deg(math.acos(dotProd))

        if angle <= NPC_FOV then
            return true
        end
        return false
    end

    local function checkLineOfSight(
        charModel: Model | Types.NPCModel,
        start: Vector3,
        targ: Vector3
    ): (boolean, number | nil)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = { charModel, Character }
        local result = workspace:Raycast(start, targ - start, raycastParams)

        if result ~= nil then
            if result.Instance.Parent == charModel then
                return true
            end
            return false
        end
        return true
    end

    -- ignore if the player is an admin
    if LocalPlayer.TeamColor == IGNORED_TEAM_COLOR then
        return false
    end

    -- ignore if NPC is dead, dead NPC can't see
    if npc.Humanoid.Health <= 0 then
        return false
    end

    local npcInRange, distanceInBetween = false, nil
    local distance = DETECTION_DISTANCE[npc:GetAttribute("DetectionDistance")]
    local humanoid: Humanoid, humanoidRootPart: BasePart

    humanoid = npc.Humanoid
    humanoidRootPart = npc.HumanoidRootPart

    if humanoid.Health > 0 then
        local diff: Vector3 = Character.HumanoidRootPart.Position - humanoidRootPart.Position
        local diffMagnitude: number = diff.Magnitude
        local diffUnit: Vector3 = diff.Unit

        if disregardFOV == true and diffMagnitude <= 150 then
            npcInRange = true
        elseif diffMagnitude <= distance then
            local isInFOV = isInFieldOfView(diffUnit)
            local hasLineOfSight =
                checkLineOfSight(npc, npc.Head.Position, Character.HumanoidRootPart.Position)
            if
                isInFOV
                and hasLineOfSight
                and (
                    distanceInBetween == nil
                    or (distanceInBetween ~= nil and diffMagnitude < distanceInBetween)
                )
            then
                npcInRange = true
                distanceInBetween = diffMagnitude
            end
        end
    end

    return npcInRange
end
