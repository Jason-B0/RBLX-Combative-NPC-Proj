local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local Knit = require(ReplicatedStorage.Packages.Knit)
local TokenService = task.spawn(function()
	Knit.OnStart():awaitStatus()
	return Knit.GetService("TokenService")
end)

local Config = require(script.Parent.Parent.Config)
local WAYPOINT_FOLDER = Config.NPC_WAYPOINT_DIR
local TRACKING_FOLDER = Config.NPC_WAYPOINT_TRACK_DIR
local EVADE_FOLDER = Config.NPC_WAYPOINT_EVADE_DIR

-- Function that determines the next waypoint for an NPC to go to
-- Returns the token of the waypoint.
return function(npc: Types.NPCModel, targetPart: BasePart?, isEvading: boolean | nil): string

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

        if possibleWaypoint:GetAttribute("WaypointToken") == npc:GetAttribute("NextWaypointToken") then
            continue
        end

        -- if NPC can access the waypoint, then try to select it
        local canAccessList = {}
        local attributeString = possibleWaypoint:GetAttribute("AccessibleNPCClasses")
 
        for word in string.gmatch(attributeString, '([^,]+)') do
            table.insert(canAccessList, word)
        end
        
        for _, class:string in pairs(canAccessList) do
            if class == npcClass or string.lower(class) == "everyone" then
                waypoint = possibleWaypoint :: Types.Waypoint
                break
            end
        end

        task.wait()
    end

    return waypoint:GetAttribute("WaypointToken") :: string
    
end