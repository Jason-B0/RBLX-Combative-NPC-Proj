--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
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
    local playerToTrack =
        Players:FindFirstChild(self.NPCModel:GetAttribute("playerToTrack")) :: Player
    if self.NPCModel:GetAttribute("playerToLookAt") ~= playerToTrack.Name then
        self.NPCModel:SetAttribute("playerToLookAt", playerToTrack.Name)
    end
    local charToTrack = playerToTrack.Character :: Types.Character
    local nextWaypoint = determineNextWaypoint(
        self.NPCModel :: Types.NPCModel,
        charToTrack.HumanoidRootPart,
        self.NPCModel:GetAttribute("compromised")
    )
    self.NPCModel:SetAttribute("NextWaypointToken", nextWaypoint)
end

function NPC:Alert()
    
end

function NPC:Hostile()
    
end

return Military