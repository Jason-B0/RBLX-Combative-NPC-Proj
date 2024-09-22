--!strict
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
local Types = require(ReplicatedStorage.Shared.Types)

local NPCEvent = require(script.Events)
--=================================
local NPCControlService = Knit.CreateService({
    Name = "NPCControlService",
    Client = {},

	isMoveEnabled = false,
	isAttackEnabled = false,

	Config_Test = {
		["Cartel"] = 1,
		["Civilian"] = 0,
	},
	
	Config = {
		["Cartel"] = 50,
		["Civilian"] = 70,
	},
	
	NPCEvents = {} :: {Types.NPCEvent},
})
local NPCService
--=================================
local function spawnNPC(npcClass: string, position: CFrame?)
	assert(NPCControlService.Config[npcClass], "Invalid NPC type: ".. npcClass)
    local configToUse = if not RunService:IsStudio() then NPCControlService.Config[npcClass] else NPCControlService.Config_Test[npcClass]
	for _ = 1, configToUse do
		NPCService:CreateNewNPC(npcClass, position)
		task.wait(1)
	end
end

local function spawnSingleNPC(npcClass: string, position: CFrame?)
    assert(NPCControlService.Config[npcClass], "Invalid NPC type: " .. npcClass)
    task.spawn(function()
        NPCService:CreateNewNPC(npcClass, position)
    end)
end

--=================================

--[[
	This function creates all the NPCEvents and store them in the TASKS table.	
]]
function NPCControlService:CreateNPCEvents()
    for i = 1, self.Config.eventCount do
        local newNPCEvent = NPCEvent.new("Test", nil, "Dialogue", 1)
        table.insert(NPCControlService.NPCEvents, newNPCEvent)
    end
end

--[[
	This function assigns NPCs to it.
]]
function NPCControlService:AssignNPCtoNPCEvent()
	local npcList = NPCService:GetNPCList()
	
	for _, v: Types.NPCEvent in pairs(NPCControlService.NPCEvents) do
		local participantCount = 0
		
		for _, npc in pairs(npcList) do
			
			if not v.restriction or table.find(v.restriction, npc.npcClass) then
				
				-- reject if NPC is already assigned to an event
				if npc.CurrentTask then
					continue
				end
				
				-- npc is assigned to event out of chance
				local chance = 1/#npcList
				if math.random() <= chance then
					participantCount += 1
					
					-- if max participants is reached, stop assigning NPCs to this event
					if participantCount >= v.maxParticipants then
						break
					end
				end
				
			end
			
			
		end
		
	end
	
end

function NPCControlService.Client:CreateNewSingleNPC(
    player: Player,
    class: string,
    position: Vector3
)
	return self.Server:CreateNewNPCAdminAuth(player, class, position)
end

function NPCControlService:CreateNewNPCAdminAuth(player: Player, class: string, position: CFrame)
    if player:GetRankInGroup(11023841) >= 5 then
		spawnSingleNPC(class, position)
		return true
	end
	return false
end

function NPCControlService:SpecialEvent()
	return true
end

function NPCControlService:KnitStart()
    NPCService = Knit.GetService("NPCService")
	for i, v in pairs(NPCControlService.Config) do
		task.spawn(function() 
			spawnNPC(i)
		end)
	end
end

function NPCControlService:KnitInit()
    PhysicsService:RegisterCollisionGroup("NPC")
    PhysicsService:CollisionGroupSetCollidable("NPC", "NPC", false)
end

return NPCControlService
