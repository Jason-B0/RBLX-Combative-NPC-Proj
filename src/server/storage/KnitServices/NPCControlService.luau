--[[
	This service strictly tracks the status of all NPCs, creating them and assigning them tags, and
	assigning paths etc.
	Futhermore, this service also controlls whether NPCs are enabled or not.
	
	For internal functionalities of NPC, such as walking, attacking, tracking, etc.,
	it is handled by each NPC object.
]]

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Types = require(ReplicatedStorage.Shared.Types)

--=================================
local NPCControlService = Knit.CreateService({
    Name = "NPCControlService",
    Client = {},
    
    NPC_FOLDER = workspace.NPC,
        
})
--=================================

--=================================

--=================================
function NPCControlService:KnitStart()
    
end

function NPCControlService:KnitInit()
    
end

return NPCControlService
