local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local Knit = require(ReplicatedStorage.Packages.Knit)
local TokenService = task.spawn(function()
	Knit.OnStart():awaitStatus()
	return Knit.GetService("TokenService")
end)

local WAYPOINT_FOLDER = workspace.NPC_Waypoints :: Folder
local TRACKING_FOLDER = WAYPOINT_FOLDER:FindFirstChild("TrackingFolder") :: Folder
local EVADE_FOLDER = WAYPOINT_FOLDER:FindFirstChild("EvadeWaypoints") :: Folder

return function(npc: Types.NPCModel, targetPart: BasePart?, isEvading: boolean?): string

    local npcClass = npc:GetAttribute("Class") :: string

    -- if targetPart is provided, return it
    if targetPart then
        -- create a new waypoint at targetPart
        local newWaypoint = Instance.new("Part")
        newWaypoint.Name = "Waypoint"
        newWaypoint.Anchored = true
        newWaypoint.CanCollide = false
        newWaypoint.Size = Vector3.new(1, 1, 1)
        newWaypoint.Transparency = 1
        newWaypoint.Position = targetPart.Position
        newWaypoint.Parent = TRACKING_FOLDER
        newWaypoint:SetAttribute("WaypointToken", TokenService:GenerateToken("twp"))
        return newWaypoint:GetAttribute("WaypointToken")
    end

    -- if evading, pick a random evade waypoint
    if isEvading then
        local evadeWaypoints = EVADE_FOLDER:GetChildren()
        return evadeWaypoints[math.random(1, #evadeWaypoints)]:GetAttribute("WaypointToken")
    end

    -- otherwise, pick a random waypoint
    local waypoints = WAYPOINT_FOLDER:GetChildren()
    local waypoint = nil :: Types.Waypoint

    while waypoint == nil do
        local possibleWaypoint = waypoints[math.random(1, #waypoints)]

        if not possibleWaypoint:IsA("BasePart") then
            continue
        end

        -- if NPC can access the waypoint it,
        -- then return it
        if
            npcClass == "Civilian"
            and (possibleWaypoint:GetAttribute("CanPublicAccess") == true)
        then
            waypoint = possibleWaypoint :: Types.Waypoint
        elseif
            npcClass == "Police"
            and (
                possibleWaypoint:GetAttribute("CanPoliceAccess") == true
                or possibleWaypoint:GetAttribute("CanPublicAccess") == true
                or possibleWaypoint:GetAttribute("CanDockAdminAccess") == true
                or possibleWaypoint:GetAttribute("CanDockWorkerAccess") == true
                or possibleWaypoint:GetAttribute("CanCartelAccess") == true
                or possibleWaypoint:GetAttribute("CanConstructionWorkerAccess") == true
            )
        then
            waypoint = possibleWaypoint :: Types.Waypoint
        elseif
            npcClass == "DockWorker"
            and (
                possibleWaypoint:GetAttribute("CanDockWorkerAccess") == true
                or possibleWaypoint:GetAttribute("CanPublicAccess") == true
            )
        then
            waypoint = possibleWaypoint :: Types.Waypoint
        elseif
            npcClass == "DockAdmin"
            and (
                possibleWaypoint:GetAttribute("CanDockAdminAccess") == true
                or possibleWaypoint:GetAttribute("CanDockWorkerAccess") == true
                or possibleWaypoint:GetAttribute("CanPublicAccess") == true
            )
        then
            waypoint = possibleWaypoint :: Types.Waypoint
        elseif
            npcClass == "Cartel"
            and (
                possibleWaypoint:GetAttribute("CanCartelAccess") == true
                or possibleWaypoint:GetAttribute("CanDockWorkerAccess") == true
                or possibleWaypoint:GetAttribute("CanPublicAccess") == true
            )
        then
            waypoint = possibleWaypoint :: Types.Waypoint
        elseif
            npcClass == "ConstructionWorker"
            and (
                possibleWaypoint:GetAttribute("CanConstructionWorkerAccess") == true
                or possibleWaypoint:GetAttribute("CanPublicAccess") == true
            )
        then
            waypoint = possibleWaypoint :: Types.Waypoint
        end
        task.wait()
    end

    return waypoint:GetAttribute("WaypointToken") :: string
    
end