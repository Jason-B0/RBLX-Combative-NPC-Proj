--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local NPC = require(script.Parent)
--=========== MODULE ================

local USNavyNPC = {}
USNavyNPC.__index = USNavyNPC
setmetatable(USNavyNPC, NPC)

function USNavyNPC.new(npcModel: NPC.NPCModel, class: string?)
	local newNPC = NPC.new(npcModel, "USNavy") :: NPC.NPCClass
	
	return setmetatable(newNPC, USNavyNPC)
end

function USNavyNPC:Safe(): ()
    self.npcModel:SetAttribute("playerToTrack", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

function USNavyNPC:Curious(): ()
    self.npcModel:SetAttribute("playerToLookAt", self.npcModel:GetAttribute("playerToTrack"))
end

function USNavyNPC:Suspicious(): ()
    self.npcModel:SetAttribute("playerToTrack", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

function USNavyNPC:Alert(): ()
    self.npcModel:SetAttribute("playerToTrack", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

function USNavyNPC:Hostile(): ()
    self.npcModel:SetAttribute("playerToTrack", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

return USNavyNPC
