--!strict
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)
local Types = require(ReplicatedStorage.Shared.Types)
--============================

local PATHFINDING_PARAM = {
    AgentRadius = 5,
    AgentHeight = 8,
    AgentCanJump = true,
    AgentCanClimb = true,
    WaypointSpacing = 5,
    Costs = {
        Concrete = 4,
        Rock = 5,
        Asphalt = 10,
        Grass = 20,
        
        NPCAvoid = math.huge,
    }
}
--============================
return function(self, destination: Types.Waypoint | BasePart)
        local path = PathfindingService:CreatePath(PATHFINDING_PARAM)
        local humanoid = self.NPCModel:FindFirstChildOfClass("Humanoid")
        local destParent = destination.Parent :: Instance
        local waypoints
        local nextWaypointIndex
        local reachedConnection = nil :: RBXScriptConnection  | nil
        local blockedConnection = nil :: RBXScriptConnection  | nil
		
		-- Promise allowing NPC to move to destination
        return Promise.new(function(resolve, reject, onCancel)
            path:ComputeAsync(self.NPCModel.HumanoidRootPart.Position, destination.Position)
            
            if path.Status ~= Enum.PathStatus.Success then
                warn("Could not calculate path\nDestination: " .. destination:GetAttribute("WaypointToken"))
                task.wait(0.5)
                reject()
            end

            waypoints = path:GetWaypoints()

            -- Detect if path becomes blocked
            blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex: number)
                -- Check if the obstacle is further down the path
                if blockedWaypointIndex >= nextWaypointIndex then
                    -- Stop detecting path blockage until path is re-computed
                    if blockedConnection ~= nil then
                        blockedConnection:Disconnect()
                    end
                    if reachedConnection ~= nil then
                        reachedConnection:Disconnect()
                    end
                    -- Call function to re-compute new path
                    warn("Waypoint blocked, recompute.")
                    reject()
                end
            end)

            -- Detect when movement to next waypoint is complete
            if reachedConnection == nil then
                reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
                    task.spawn(function()
                        local thisWPIndex = nextWaypointIndex 
                        task.wait(5)
                        if thisWPIndex == nextWaypointIndex then
                            warn("Waypoint timed out, recompute.")
                            reachedConnection:Disconnect()
                            if blockedConnection ~= nil then
                                blockedConnection:Disconnect()
                            end
                            reject()
                        end
                    end)
                    if reached and nextWaypointIndex < #waypoints then
                        -- Increase waypoint index and move to next waypoint
                        nextWaypointIndex += 1
                        humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
                    else
                        if destParent.Name == "TrackingFolder" then
                            destination:Destroy()
                        end
                        reachedConnection:Disconnect()
                        if blockedConnection ~= nil then
                            blockedConnection:Disconnect()
                        end
                        resolve("Reached destination")
                    end
                end)
            end

			onCancel(function()
                if destParent.Name == "TrackingFolder" then
                    destination:Destroy()
                end
                if reachedConnection ~= nil then
                    reachedConnection:Disconnect()
                end
                if blockedConnection ~= nil then
                    blockedConnection:Disconnect()
                end
			end)
			
            -- Initially move to second waypoint (first waypoint is path start; skip it)
            nextWaypointIndex = 2
            humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
        end)
    end