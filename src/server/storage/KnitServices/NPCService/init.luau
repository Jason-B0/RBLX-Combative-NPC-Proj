--[[

]]

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Types = require(ReplicatedStorage.Shared.Types)

local NPCService = Knit.CreateService({
    Name = "NPCService",

    TAG_NAME = "NPC",

    PATHFINDING_PARAM = {
        AgentRadius = 10,
        AgentHeight = 8,
        AgentCanJump = false,
        AgentCanClimb = true,
        WaypointSpacing = 10,
    },

    DETECTION_DISTANCE = {
        DAY_OUTDOOR = 100,
        NIGHT_OUTDOOR = 50,
        BRIGHT_INDOOR = 70,
        DARK_INDOOR = 10,
    },

    IGNORED_TEAM_COLOR = BrickColor.new("Crimson"),

    ThisNPCFinishedMoving = Signal.new(),
})

local NPCControlService
--=================================
local function findNearestPlayer(npc: Types.NPC)
    --[[
		Check if player is in field of view of NPC.

		Dot product references the NPC's look angle (in sin theta or x, refer to unit circle)
		-1 means straight ahead,
		0 means to the right or left.
		
		Any value above 0.2 is acceptable (mimicing average human field of view).  
		Negative values are not needed because Dot takes the absolute value of A & B, and 
		humans cant grow a set of eyes on the back of their head.
	]]
    local function isInFieldOfView(unit: Vector3)
        local npcLook: Vector3 = npc.HumanoidRootPart.CFrame.LookVector
        local dotProd: number = unit:Dot(npcLook)

        if dotProd > 0.2 then
            return true
        end
        return false
    end

    --[[
		Check if player is in line of sight with the NPC, no solid parts obstructing between the two.
	]]
    local function isNotObstructedByPart(
        character: Types.Character,
        originPos: Vector3,
        unit: Vector3,
        dist: number
    )
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances =
            { CollectionService:GetTagged(NPCService.TAG_NAME), npc }
        local ray = Ray.new(originPos, unit * dist)
        local result = workspace:Raycast(ray.Origin, ray.Direction, raycastParams)

        if result ~= nil then
            if result.Instance.Parent == character then
                return true
            end
            return false
        end
        return false
    end

    local nearestPlayer, distanceInBetween = nil, nil
    local distance = NPCService.DETECTION_DISTANCE[npc:GetAttribute("DetectionDistance")]
    local character: Types.Character, humanoid: Humanoid, humanoidRootPart: BasePart

    for _, player in pairs(Players:GetPlayers()) do
        if not player.Character then
            continue
        end

        character = player.Character
        humanoid = character.Humanoid
        humanoidRootPart = character.HumanoidRootPart

        if (humanoid.Health > 0) and player.TeamColor ~= NPCService.IGNORED_TEAM_COLOR then
            local diff: Vector3 = humanoidRootPart.Position - npc.HumanoidRootPart.Position
            local diffMagnitude: number = diff.Magnitude
            local diffUnit: Vector3 = diff.Unit

            if diffMagnitude <= distance then
                local isInFOV = isInFieldOfView(diffUnit)
                local isNotObstructed = isNotObstructedByPart(
                    character,
                    npc.HumanoidRootPart.Position,
                    diffUnit,
                    distance
                )

                if
                    isInFOV
                    and isNotObstructed
                    and (
                        distanceInBetween == nil
                        or (distanceInBetween ~= nil and diffMagnitude < distanceInBetween)
                    )
                then
                    nearestPlayer = player
                    distanceInBetween = diffMagnitude
                end
            end
        end
    end

    return nearestPlayer, distanceInBetween
end

local function turnHead(npc: Types.NPC, lookAt: Player | CFrame)
    local motor: Motor6D = npc.Torso:FindFirstChild("Neck") :: Motor6D

    if typeof(lookAt) == "Player" then
        local playerToLookAt: BasePart = lookAt.Character.Torso
        motor.C0 = npc.HumanoidRootPart.CFrame:PointToObjectSpace(
            npc.HumanoidRootPart.Position * playerToLookAt.Position
        )
    end
end

local function calculatePath(npc: Types.NPC, destination: Part)
    assert(destination:IsA("BasePart"), "destination is not a basepart.")
    local path = PathfindingService:CreatePath(NPCService.PATHFINDING_PARAM)
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    local waypoints
    local nextWaypointIndex
    local reachedConnection
    local blockedConnection

    return Promise.new(function(resolve, reject, onCancel)
        path:ComputeAsync(npc.HumanoidRootPart.Position, destination.Position)

        if path.Status ~= Enum.PathStatus.Success then
            reject(warn("Could not calculate path"))
        end

        waypoints = path:GetWaypoints()

        -- Detect if path becomes blocked
        blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
            -- Check if the obstacle is further down the path
            if blockedWaypointIndex >= nextWaypointIndex then
                -- Stop detecting path blockage until path is re-computed
                reachedConnection:Disconnect()
                blockedConnection:Disconnect()
                -- Call function to re-compute new path
                reject("Waypoint blocked, recompute.")
            end
        end)

        -- Detect when movement to next waypoint is complete
        if not reachedConnection then
            reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
                if reached and nextWaypointIndex < #waypoints then
                    -- Increase waypoint index and move to next waypoint
                    nextWaypointIndex += 1
                    humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
                else
                    reachedConnection:Disconnect()
                    blockedConnection:Disconnect()
                    resolve("Reached destination")
                end
            end)
        end

        -- Initially move to second waypoint (first waypoint is path start; skip it)
        nextWaypointIndex = 2
        humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
    end)
end
--=================================
function NPCService:ActivateNPC(npc: Types.NPC)
    local function detection()
        return Promise.new(function(resolve, reject, onCancel)
            local active = true
            local lookingAtPlayer = false
            local originCFrame = CFrame.new()

            onCancel(function()
                active = false
            end)

            while active do
                --[[
                    TODO: Refactor
                    
                    Instruction:
                    
                    Remove while loop (since it is not the server's responsibility to handle this), and move findNearestPlayer() to client, where client will instead find the nearest NPC that they can see.
                    
                    The server NPC will only worry about turning head, setting alert status, etc.
                ]]
                task.wait(0.1)

                local player, distance = findNearestPlayer(npc)

                if player and distance then
                    originCFrame = npc.HumanoidRootPart:FindFirstChild("Neck") :: Motor6D
                    originCFrame = originCFrame.C0

                    turnHead(npc, player)
                else
                    turnHead(npc, originCFrame)
                end
            end
            resolve("successfully ended!")
        end)
    end

    local promise = detection()

    npc:GetAttributeChangedSignal("NextWaypoint"):Connect(function()
        local res, msg = calculatePath(
            npc,
            workspace.PathNodes:FindFirstChild(npc:GetAttribute("NextWaypoint"))
        ):await()
        self.ThisNPCFinishedMoving:Fire(nil, npc, res, msg)
    end)

    npc:GetAttributeChangedSignal("Active"):Connect(function()
        print("Active changed, cancelling this promise!")
        promise:cancel():andThen(print)
    end)
end

--=================================
function NPCService:KnitStart()
    for _, npc: Types.NPC in pairs(CollectionService:GetTagged(self.TAG_NAME)) do
        if npc:FindFirstChildOfClass("Humanoid") then
            self:ActivateNPC(npc)
        end
    end

    CollectionService:GetInstanceAddedSignal(self.TAG_NAME):Connect(function(npc: Types.NPC)
        assert(npc:FindFirstChildOfClass("Humanoid"), "NPC does not have a humanoid!")
        self:ActivateNPC(npc)
    end)
end

function NPCService:KnitInit() end

return NPCService
