--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local NPC = require(script.Parent.Parent)

--=========== MODULE ================

local MilitaryNPC = {}
MilitaryNPC.__index = MilitaryNPC
setmetatable(MilitaryNPC, NPC)

function MilitaryNPC:new(npcModel: Types.NPCModel, class: string?)
	local newNPC = NPC:new(npcModel, "Military") :: Types.NPC
	
	return setmetatable(newNPC, MilitaryNPC)
end

function MilitaryNPC:Safe()
    self.NPCModel:SetAttribute("playerToTrack", nil)
    self.NPCModel:SetAttribute("playerToLookAt", nil)
end

function MilitaryNPC:Curious()
    self.NPCModel:SetAttribute("playerToLookAt", self.NPCModel:GetAttribute("playerToTrack"))
end

function MilitaryNPC:Suspicious()
    self.NPCModel:SetAttribute("playerToTrack", nil)
    self.NPCModel:SetAttribute("playerToLookAt", nil)
end

function MilitaryNPC:Alert()
    self.NPCModel:SetAttribute("playerToTrack", nil)
    self.NPCModel:SetAttribute("playerToLookAt", nil)
end

function MilitaryNPC:Hostile()
    self.NPCModel:SetAttribute("playerToTrack", nil)
    self.NPCModel:SetAttribute("playerToLookAt", nil)
end

return MilitaryNPC
