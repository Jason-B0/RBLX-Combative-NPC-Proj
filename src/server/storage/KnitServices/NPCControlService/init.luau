--[[
	This service strictly tracks the status of all NPCs, creating them and assigning them tags, and
	assigning paths etc.
	Futhermore, this service also controlls whether NPCs are enabled or not.
	
	For internal functionalities of NPC, such as walking, attacking, tracking, etc.,
	it is handled by each NPC object.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)

--=================================
local NPCControlService = Knit.CreateService({
    Name = "NPCControlService",
    Client = {},
    
	Config_Test = {
		
		isMoveEnabled = false,
		isAttackEnabled = false,
		
		["Civilian"] = 3,
		["Police"] = 3,
		["Cartel"] = 3,
		["DockWorker"] = 3,
		["DockAdmin"] =  0,
	},
	
	Config = {
		["Civilian"] = 25,
		["Police"] = 10,
		["Cartel"] = 15,
		["DockWorker"] = 30,
		["DockAdmin"] = 0,
	},
	
	NPCEvents = {}
})
local NPCService
--=================================
local function spawnNPC(npcType: string)
	assert(NPCControlService.Config[npcType], "Invalid NPC type: "..npcType)
    task.spawn(function()
        for _ = 1,  if not RunService:IsStudio() then 
									NPCControlService.Config[npcType] 
								else 
									NPCControlService.Config_Test[npcType] 
		do
            NPCService:CreateNewNPC(npcType)
            task.wait(0.1)
        end
    end)
end

--=================================

--[[
	This function creates all the NPCEvents and store them in the TASKS table.	
]]
function NPCControlService:CreateNPCEvents()
	
end

--[[
	This function assigns NPCs to it.
]]
function NPCControlService:AssignNPCtoNPCEvent()
	
end


function NPCControlService:Start()
	for i, v in pairs(NPCControlService.Config) do
		spawnNPC(i)
	end
end

--=================================
Knit.OnStart():andThen(function()
	NPCControlService:Start()
end)

function NPCControlService:KnitStart()
    NPCService = Knit.GetService("NPCService")
end

function NPCControlService:KnitInit()
    PhysicsService:RegisterCollisionGroup("NPC")
    PhysicsService:CollisionGroupSetCollidable("NPC", "NPC", false)
end

return NPCControlService
