return {
	NPC_DEFAULT_ATTRIBUTES = {
		-- attributes
		DetectionDistance = "DAY_OUTDOOR",
		Tag = "",
		Active = true,
		Class = "Civilian",
	
		-- Other NPC states
		playerToTrack = "",
		playerToLookAt = "",
		compromised = false,
		State = "Safe",
		NextWaypointToken = "",
		currentEventId = "	",
	};

	NPC_AVOID_DIR = workspace.GAME_WORKSPACE:FindFirstChild("NPCAvoid");

	NPC_WAYPOINT_DIR = workspace.GAME_WORKSPACE:FindFirstChild("NPC_Waypoints");
	NPC_WAYPOINT_EVADE_DIR = workspace.GAME_WORKSPACE:FindFirstChild("NPC_Waypoints"):FindFirstChild("EvadeWaypoints");
	NPC_WAYPOINT_TRACK_DIR = workspace.GAME_WORKSPACE:FindFirstChild("NPC_Waypoints"):FindFirstChild("TrackingFolder");

	NPC_CONTAINER_DIR = workspace.GAME_WORKSPACE:FindFirstChild("NPC");

}