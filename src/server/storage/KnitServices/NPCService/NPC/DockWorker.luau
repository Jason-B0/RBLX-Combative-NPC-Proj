local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local NPC = require(script.Parent)

--=========== MODULE ================

local DockWorker = {}
DockWorker.__index = DockWorker

function DockWorker.new(npcModel: Types.NPCModel, class: string?)
	local newNPCWorker = NPC.new(npcModel, "DockWorker") :: Types.NPC
	
	return setmetatable(DockWorker, newNPCWorker)
end

return DockWorker