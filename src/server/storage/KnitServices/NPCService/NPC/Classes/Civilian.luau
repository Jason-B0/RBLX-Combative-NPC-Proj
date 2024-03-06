--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Types = require(ReplicatedStorage.Shared.Types)
local NPC = require(script.Parent.Parent)

--=========== NPC FUNCTIONS ================

local Helper = script.Parent.Parent.Helper
local Assets = script.Parent.Parent.Assets
local Actions = script.Parent.Parent.Actions
local Combat = require(Actions.Combat)
local HeadTrackPlayer = require(Actions.HeadTrackPlayer)
local Move = require(Actions.Move)
local SetupModel = require(Actions.SetupModel)
local UpdateIndicator = require(Actions.UpdateIndicator)

--=========== HELPERS ======================

local determineNextWaypoint = require(Helper.DetermineNextWaypoint)
local findWaypointGivenToken = require(Helper.FindWaypointWithToken)
local ragdollOnDeath = require(Helper.RagdollOnDeath)
local disconnectAllPromises = function(prom: { [any]: Promise })
    for _, promise: Promise in pairs(prom) do
        if promise ~= nil and promise:getStatus() == "Started" then
            promise:cancel()
            promise = nil
        end
    end
end
local disconnectAllConnections = function(conn: { [any]: RBXScriptConnection })
    for _, connection: RBXScriptConnection | nil in pairs(conn) do
        if connection ~= nil then
            connection:Disconnect()
            connection = nil
        end
    end
end

--=========== MODULE ================

local Civilian = {}
Civilian.__index = Civilian
setmetatable(Civilian, NPC)

function Civilian:new(npcModel: Types.NPCModel, class: string?): any
	local newNPC = NPC:new(npcModel, "Civilian") :: Types.NPC
	
	return setmetatable(newNPC, Civilian)
end

function Civilian:Safe()
    self.NPCModel:SetAttribute("playerToTrack", nil)
    self.NPCModel:SetAttribute("playerToLookAt", nil)
end

function Civilian:Curious()
    self.NPCModel:SetAttribute("playerToLookAt", self.NPCModel:GetAttribute("playerToTrack"))
end

function Civilian:Suspicious()
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

function Civilian:Alert()
    self.NPCModel:SetAttribute("playerToTrack", nil)
    self.NPCModel:SetAttribute("playerToLookAt", nil)
end

function Civilian:Hostile()
    self.NPCModel:SetAttribute("playerToTrack", nil)
    self.NPCModel:SetAttribute("playerToLookAt", nil)
end

return Civilian