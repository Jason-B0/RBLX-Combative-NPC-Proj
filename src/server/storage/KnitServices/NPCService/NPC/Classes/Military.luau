--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local NPC = require(script.Parent.Parent)

--=========== MODULE ================

local Military = {} :: Types.NPCClass
Military.__index = Military

function Military.new(npcModel: Types.NPCModel, class: string?)
	local newNPCWorker = NPC.new(npcModel, "Military") :: Types.NPC
	
	return setmetatable(Military, newNPCWorker)
end

function NPC:Safe()
    self.NPCModel:SetAttribute("playerToTrack", nil)
    self.NPCModel:SetAttribute("playerToLookAt", nil)
end

function NPC:Curious()
    
end

function NPC:Suspicious()
   
end

function NPC:Alert()
    
end

function NPC:Hostile()
    
end

return Military