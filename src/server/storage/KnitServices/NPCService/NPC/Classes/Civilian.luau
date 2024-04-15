--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Types = require(ReplicatedStorage.Shared.Types)
local NPC = require(script.Parent.Superclass)

--=========== NPC FUNCTIONS ================

local Helper = script.Parent.Parent.Helper
local Actions = script.Parent.Parent.Actions
local Combat = require(Actions.Combat)
local HeadTrackPlayer = require(Actions.HeadTrackPlayer)
local Move = require(Actions.Move)
local SetupModel = require(Actions.SetupModel)
local UpdateIndicator = require(Actions.UpdateIndicator)

--=========== HELPERS ======================

local determineNextWaypoint = require(Helper.DetermineNextWaypoint)


--=========== MODULE ================

local Civilian = {}
Civilian.__index = Civilian
setmetatable(Civilian, NPC)

function Civilian.new(npcModel: Types.NPCModel, class: string?): any
	local newNPC = NPC.new(npcModel, "Civilian") :: Types.NPC
	
	return setmetatable(newNPC, Civilian)
end

function Civilian:Safe(): ()
    self.npcModel:SetAttribute("playerToTrack", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

function Civilian:Curious(): ()
    self.npcModel:SetAttribute("playerToLookAt", self.npcModel:GetAttribute("playerToTrack"))
end

function Civilian:Suspicious(): ()
    local playerToTrack =
        Players:FindFirstChild(self.npcModel:GetAttribute("playerToTrack")) :: Player
    if self.npcModel:GetAttribute("playerToLookAt") ~= playerToTrack.Name then
        self.npcModel:SetAttribute("playerToLookAt", playerToTrack.Name)
    end
    local charToTrack = playerToTrack.Character :: Types.Character
    self.npcModel:SetAttribute("NextWaypointToken",  
        determineNextWaypoint(
            self.npcModel :: Types.NPCModel, 
            charToTrack.HumanoidRootPart, 
            self.npcModel:GetAttribute("compromised")
        )
    )
end

function Civilian:Alert(): ()
    self.npcModel:SetAttribute("compromised", true)
    if self.promises.movePromise ~= nil and self.promises.movePromise:getStatus() ~= "Started" then
        self.promises.movePromise:cancel()
        task.wait(1)
    end



    self.npcModel:SetAttribute("NextWaypointToken",  
        determineNextWaypoint(
            self.npcModel :: Types.NPCModel, 
            nil, 
            self.npcModel:GetAttribute("compromised")
        )
    )
                
    task.delay(5, function()
        if self.npcModel.Humanoid.Health > 0 then
            -- TODO: Signal: call 911
            self.npcModel:SetAttribute("playerToLookAt", nil)
            self.npcModel:SetAttribute("State", "Hostile")
            -- TODO: Signal: total compromised
        end
    end)
end

function Civilian:Hostile(): ()
    local npcModel = self.npcModel :: Types.NPCModel
    npcModel:SetAttribute("compromised", true)
    
    if self.promises.movePromise ~= nil and self.promises.movePromise:getStatus() ~= "Started" then
        self.promises.movePromise:cancel()
        task.wait(1)
    end

    npcModel:SetAttribute("NextWaypointToken", 
		determineNextWaypoint(
			npcModel :: Types.NPCModel, 
			nil, 
			true
		)
	)
    
end

return Civilian