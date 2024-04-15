local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

local Config = require(script.Parent.Parent.Config)
local WAYPOINT_FOLDER = Config.NPC_WAYPOINT_DIR

return function(waypointToken:string)
    for _, waypoint in pairs(WAYPOINT_FOLDER:GetDescendants()) do
        if waypoint:GetAttribute("WaypointToken") == waypointToken then
            return waypoint :: Types.Waypoint
        end
    end
    return nil :: Types.Waypoint
end