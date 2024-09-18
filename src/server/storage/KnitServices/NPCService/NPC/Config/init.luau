local ServerStorage = game:GetService("ServerStorage")
local GAME_WORKSPACE = workspace:WaitForChild("GAME_WORKSPACE")
return {
	NPC_DEFAULT_ATTRIBUTES = {
		-- attributes
		DetectionDistance = "DAY_OUTDOOR",
		Tag = "",
		Active = true,
		Class = "Civilian",
	
		-- Other NPC states
		aggroPlayerName = "",
		playerToLookAt = "",
		compromised = false,
		State = "Safe",
		NextWaypointToken = "",
		currentEventId = "",
	};

	NPC_ORG_MODEL = ServerStorage:WaitForChild("Asset"):WaitForChild("NPC") :: Model;

	NPC_AVOID_DIR = GAME_WORKSPACE:FindFirstChild("NPCAvoid");

	NPC_WAYPOINT_DIR = GAME_WORKSPACE:FindFirstChild("NPC_Waypoints");
	NPC_WAYPOINT_EVADE_DIR = GAME_WORKSPACE:FindFirstChild("NPC_Waypoints"):FindFirstChild("EvadeWaypoints");
	NPC_WAYPOINT_TRACK_DIR = GAME_WORKSPACE:FindFirstChild("NPC_Waypoints"):FindFirstChild("TrackingFolder");

	NPC_CONTAINER_DIR = GAME_WORKSPACE:FindFirstChild("NPC");

	DEBUG_ENABLED = false;
}
