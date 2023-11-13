--!strict

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Types = require(ReplicatedStorage.Shared.Types)

local TAG_NAME = "NPC"
local PATHFINDING_PARAM = {
        AgentRadius = 10,
        AgentHeight = 8,
        AgentCanJump = false,
        AgentCanClimb = true,
        WaypointSpacing = 10,
    }

local DETECTION_DISTANCE = {
        DAY_OUTDOOR = 100,
        NIGHT_OUTDOOR = 50,
        BRIGHT_INDOOR = 70,
        DARK_INDOOR = 10,
    }

local IGNORED_TEAM_COLOR = BrickColor.new("Crimson")
--=================================

--=================================
local NPC = {}
NPC.__index = NPC

export type NPC = typeof(NPC.new())

function NPC.new(npcModel: Types.NPC, npcType: string)
	local newNPC = {
		NPCModel = nil :: Types.NPC,
		NPCType = nil :: string,
		ThisNPCFinishedMoving = nil,
	}
	setmetatable(newNPC, NPC)
	
	newNPC.NPCModel = npcModel
	newNPC.ThisNPCFinishedMoving = Signal.new()
	
	return newNPC
end

--=================================
function NPC:Active()
	
    local function detection()
        return Promise.new(function(resolve, reject, onCancel)
            local active = true
            local lookingAtPlayer = false
            local originCFrame = CFrame.new()

            onCancel(function()
                active = false
            end)

            
            resolve("successfully ended!")
        end)
    end

    local function move(destination: Part)
        assert(destination:IsA("BasePart"), "destination is not a basepart.")
        local path = PathfindingService:CreatePath(PATHFINDING_PARAM)
        local humanoid = self.NPCModel:FindFirstChildOfClass("Humanoid")
        local waypoints
        local nextWaypointIndex
        local reachedConnection
        local blockedConnection

        return Promise.new(function(resolve, reject, onCancel)
            path:ComputeAsync(self.NPCModel.HumanoidRootPart.Position, destination.Position)

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

			onCancel(function()
                reachedConnection:Disconnect()
                blockedConnection:Disconnect()
			end)
			
            -- Initially move to second waypoint (first waypoint is path start; skip it)
            nextWaypointIndex = 2
            humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
        end)
    end
	
	local function aggrovated(player: Player, aggrovationMode: string)
		if aggrovationMode == "calm" then
            
        elseif aggrovationMode == "curious" then
            
		end
	end
	
    local detectionPromise = detection()
	local movementPromise = move()

	-- move npc to next waypoint
    self.NPCModel:GetAttributeChangedSignal("NextWaypoint"):Connect(function()
        local res, msg = move(
            self.NPCModel,
            workspace.PathNodes:FindFirstChild(self.NPCModel:GetAttribute("NextWaypoint"))
        ):await()
		
    end)

	
	
	-- enable and disable NPC as needed
    self.NPCModel:GetAttributeChangedSignal("Active"):Connect(function()
        print("Active changed, cancelling this detectionPromise!")
        detectionPromise:cancel():andThen(print)
    end)
end



return NPC