local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

local WAYPOINT_FOLDER = workspace.NPC_Waypoints :: Folder

return function(waypointToken:string)
    for _, waypoint in pairs(WAYPOINT_FOLDER:GetDescendants()) do
        if waypoint:GetAttribute("WaypointToken") == waypointToken then
            return waypoint :: Types.Waypoint
        end
    end
    return nil :: Types.Waypoint
end