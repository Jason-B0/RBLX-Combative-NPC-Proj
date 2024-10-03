--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Promise = require(ReplicatedStorage.Packages.Promise)
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

local Cartel = {}
Cartel.__index = Cartel
setmetatable(Cartel, NPC)

function Cartel.new(npcModel: Types.NPCModel, class: string?): any
	local newNPC = NPC.new(npcModel, "Cartel") :: Types.NPCObject
    newNPC.npcClass = "Cartel"
	newNPC.npcModel:SetAttribute("IsCombatant", true)
	return setmetatable(newNPC, Cartel)
end

function Cartel:ChangeState(): ()
    local npcModel = self.npcModel :: Types.NPCModel
    local npcClass = npcModel:GetAttribute("Class") :: string
    local aggroPlayerName = npcModel:GetAttribute("aggroPlayerName") :: string
    local newState = npcModel:GetAttribute("State")
    self:UpdateIndicator(newState)
    
    if self.promises.statePromise ~= nil and self.promises.statePromise:getStatus() == "Started" then
        self.promises.statePromise:cancel()
    end

    self.promises.statePromise = Promise.new(function(resolve, reject, onCancel)
        if onCancel(function()
            if self.promises.statePromise then
                self.promises.statePromise:cancel()
            end
        end) then
            return
        end

        if newState == "Safe" then
            self:Safe()
        elseif newState == "Curious" then
            self:Curious()
        elseif newState == "Suspicious" then
            self:Suspicious()
        elseif newState == "Alert" then
            self:Alert()
        elseif newState == "Hostile" then
            self:Hostile()
        end

        resolve()
    end)
        
end

function Cartel:Safe(): ()
    self.npcModel:SetAttribute("aggroPlayerName", "")
    self.npcModel:SetAttribute("playerToLookAt", "")
end

function Cartel:Curious(): ()
    local aggroPlayerName = self.npcModel:GetAttribute("aggroPlayerName") :: string
    self.npcModel:SetAttribute("playerToLookAt", aggroPlayerName)
end

function Cartel:Suspicious(): ()
    local aggroPlayerName = self.npcModel:GetAttribute("aggroPlayerName") :: string
    if self.npcModel:GetAttribute("playerToLookAt") ~= aggroPlayerName then
        self.npcModel:SetAttribute("playerToLookAt", aggroPlayerName)
    end
    local aggroPlayer = Players:FindFirstChild(aggroPlayerName) :: Player
    local charToTrack = aggroPlayer.Character :: Types.Character

    self.npcModel:SetAttribute("nextWaypointToken",  
        determineNextWaypoint(
            self :: Types.NPCObject, 
            charToTrack.HumanoidRootPart
        )
    )
end

function Cartel:Alert(): ()
    local aggroPlayerName = self.npcModel:GetAttribute("aggroPlayerName") :: string
    local aggroPlayer = Players:FindFirstChild(aggroPlayerName) :: Player
    local charToTrack = aggroPlayer.Character :: Types.Character
    
    if self.promises.movePromise ~= nil then
        self.promises.movePromise:cancel()
    end
        
    if self.promises.combatPromise ~= nil and self.promises.combatPromise:getStatus() == "Started" then
        self.promises.combatPromise:cancel()
    end
    
    task.delay(2, function()
        if self.npcModel.Humanoid.Health > 0 then
            self.npcModel:SetAttribute("playerToLookAt", "")
            self.npcModel:SetAttribute("State", "Hostile")
            self.promises.combatPromise = Combat(self, aggroPlayer)
        end
    end)
end

function Cartel:Hostile(): ()
    local aggroPlayerName = self.npcModel:GetAttribute("aggroPlayerName") :: string
    local aggroPlayer = Players:FindFirstChild(aggroPlayerName) :: Player
    local charToTrack = aggroPlayer.Character :: Types.Character
    local npcModel = self.npcModel :: Types.NPCModel
    
    if self.promises.movePromise ~= nil and self.promises.movePromise:getStatus() ~= "Started" then
        self.promises.movePromise:cancel()
        task.wait(1)
    end
    
end

return Cartel