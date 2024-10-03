local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Types = require(ReplicatedStorage.Shared.Types)
local Knit = require(ReplicatedStorage.Packages.Knit)
local TokenService
task.spawn(function()
	Knit.OnStart():awaitStatus()
	TokenService = Knit.GetService("TokenService")
end)

local Config = require(script.Parent.Parent.Config)
local WAYPOINT_FOLDER = Config.NPC_WAYPOINT_DIR
local TRACKING_FOLDER = Config.NPC_WAYPOINT_TRACK_DIR
local EVADE_FOLDER = Config.NPC_WAYPOINT_EVADE_DIR

local function createWaypointPart(position: Vector3): BasePart
    local newWaypoint = Instance.new("Part")
    newWaypoint.Name = "Waypoint"
    newWaypoint.Anchored = true
    newWaypoint.CanCollide = false
    newWaypoint.Size = Vector3.new(1, 1, 1)
    newWaypoint.Transparency = 1
    newWaypoint.Position = position
    newWaypoint.Parent = WAYPOINT_FOLDER
    newWaypoint:SetAttribute("WaypointToken", TokenService:GenerateToken("wp"))
    return newWaypoint
end

-- Function that determines the next waypoint for an NPC to go to
-- Returns the token of the waypoint.
return function(npc: Types.NPCObject, targetPart: BasePart?): string
    local npcClass = npc.npcClass :: string
    local isCombatant = npc.npcModel:GetAttribute("IsCombatant") :: boolean
    
    -- if targetPart is provided, use it.
    if targetPart then
        local newWaypoint = createWaypointPart(targetPart.Position)
        return newWaypoint:GetAttribute("WaypointToken")
    end

    -- if NPC is compromised, determine if the NPC is a combatant or not.  
    if npc.npcModel:GetAttribute("State") == ("Alert" or "Hostile") then
        -- if true, and the targetPart was not provided, move to player's position
        if isCombatant == true then
            local aggroPlayer = Players:FindFirstChild(npc.npcModel:GetAttribute("aggroPlayerName"))
            if not aggroPlayer then
                error("Attempting to find player with name: " .. npc.npcModel:GetAttribute("aggroPlayerName") .. " but it does not exist.")
            end
            return createWaypointPart(aggroPlayer.Character.HumanoidRootPart.Position):GetAttribute("WaypointToken")
        else
            -- if NPC is not a combatant, then it will move towards a random waypoint by evasion.
            local evadeWaypoints = EVADE_FOLDER:GetChildren()
            return evadeWaypoints[math.random(1, #evadeWaypoints)]:GetAttribute("WaypointToken")
        end
    end

    -- otherwise, pick a random waypoint
    local waypoints = WAYPOINT_FOLDER:GetChildren()
    local waypoint = nil :: Types.Waypoint

    while waypoint == nil do
        local possibleWaypoint = waypoints[math.random(1, #waypoints)]

        if not possibleWaypoint:IsA("BasePart") then
            continue
        end

        if possibleWaypoint:GetAttribute("WaypointToken") == npc.npcModel:GetAttribute("nextWaypointToken") then
            continue
        end

        -- if NPC can access the waypoint, then try to select it
        local canAccessList = {}
        local attributeString = possibleWaypoint:GetAttribute("AccessibleNPCClasses")
 
        if string.lower(attributeString) == "everyone" then
            table.insert(canAccessList, "everyone")
        else
            for word in string.gmatch(attributeString, "[^,]+") do
                table.insert(canAccessList, word)
            end
        end
        
        for _, waypointAccessClass:string in pairs(canAccessList) do
            if waypointAccessClass == npcClass or waypointAccessClass == "everyone" then
                waypoint = possibleWaypoint :: Types.Waypoint
                break
            end
        end

        task.wait()
    end

    return waypoint:GetAttribute("WaypointToken") :: string
    
end