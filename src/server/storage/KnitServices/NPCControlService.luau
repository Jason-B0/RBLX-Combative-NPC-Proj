--[[
	This service strictly tracks the status of all NPCs, creating them and assigning them tags, and
	assigning paths etc.
	Futhermore, this service also controlls whether NPCs are enabled or not.
	
	For internal functionalities of NPC, such as walking, attacking, tracking, etc.,
	it is handled by each NPC object.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)

--=================================
local NPCControlService = Knit.CreateService({
    Name = "NPCControlService",
    Client = {},
    
	Config = {
		CIVILIAN = 50,
		POLICE = 50,
		OPFOR = 50,
		DOCK_WORKER = 50,
		DOCK_ADMIN = 50,
	}
})
local NPCService
--=================================
local function spawnNPC(npcType: string)
	assert(NPCControlService.Config[npcType], "Invalid NPC type: "..npcType)
    task.spawn(function()
        for _ = 1, NPCControlService.Config.CIVILIAN_COUNT do
            NPCService:CreateNewNPC()
            task.wait(0.1)
        end
    end)
end

function NPCControlService:Start()
    spawnNPC("CIVILIAN")
	spawnNPC("POLICE")
	spawnNPC("OPFOR")
	spawnNPC("DOCK_WORKER")
	spawnNPC("DOCK_ADMIN")
end

--=================================
function NPCControlService:KnitStart()
    NPCService = Knit.GetService("NPCService")
	
	if RunService:IsStudio() then
		return
	end
	
	self:Start()
	
end

function NPCControlService:KnitInit()
    
end

return NPCControlService
