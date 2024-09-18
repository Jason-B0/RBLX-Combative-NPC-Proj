--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local NPC = require(script.Parent)
--=========== MODULE ================

local CSG1NPC = {}
CSG1NPC.__index = CSG1NPC
setmetatable(CSG1NPC, NPC)

function CSG1NPC.new(npcModel: NPC.NPCModel, class: string?)
	local newNPC = NPC.new(npcModel, "CSG1-1") :: NPC.NPCClass
	
	return setmetatable(newNPC, CSG1NPC)
end

function CSG1NPC:Safe(): ()
    self.npcModel:SetAttribute("playerToTrack", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

function CSG1NPC:Curious(): ()
    self.npcModel:SetAttribute("playerToLookAt", self.npcModel:GetAttribute("playerToTrack"))
end

function CSG1NPC:Suspicious(): ()
    self.npcModel:SetAttribute("playerToTrack", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

function CSG1NPC:Alert(): ()
    self.npcModel:SetAttribute("playerToTrack", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

function CSG1NPC:Hostile(): ()
    self.npcModel:SetAttribute("playerToTrack", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

return CSG1NPC
