--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Promise = require(ReplicatedStorage.Packages.Promise)
local Types = require(ReplicatedStorage.Shared.Types)
local NPC = require(script.Parent)

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
	local newNPC = NPC.new(npcModel, "Civilian") :: Types.NPCObject
    newNPC.npcClass = "Civilian"
	return setmetatable(newNPC, Civilian)
end

function Civilian:ChangeState(): ()
    local npcModel = self.npcModel :: Types.NPCModel
    local npcClass = npcModel:GetAttribute("Class") :: string
    local playerToTrack = if npcModel:GetAttribute("aggroPlayerName") ~= nil then Players:FindFirstChild(npcModel:GetAttribute("aggroPlayerName")) else nil :: Player | nil
    local charToTrack = if playerToTrack then playerToTrack.Character else nil :: Types.Character
    local newState = npcModel:GetAttribute("State")
    self:UpdateIndicator(newState)
    
    if self.promises.statePromise then
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

function Civilian:Safe(): ()
    self.npcModel:SetAttribute("aggroPlayerName", "")
    self.npcModel:SetAttribute("playerToLookAt", "")
end

function Civilian:Curious(): ()
    self.npcModel:SetAttribute("playerToLookAt", self.npcModel:GetAttribute("aggroPlayerName"))
end

function Civilian:Suspicious(): ()
    local playerToTrack =
        Players:FindFirstChild(self.npcModel:GetAttribute("aggroPlayerName")) :: Player
    if self.npcModel:GetAttribute("playerToLookAt") ~= playerToTrack.Name then
        self.npcModel:SetAttribute("playerToLookAt", playerToTrack.Name)
    end
    local charToTrack = playerToTrack.Character :: Types.Character
    self.npcModel:SetAttribute("nextWaypointToken",  
        determineNextWaypoint(
            self.npcModel :: Types.NPCModel, 
            charToTrack.HumanoidRootPart, 
            self.npcModel:GetAttribute("compromised")
        )
    )
end

function Civilian:Alert(): ()
    if self.promises.movePromise ~= nil and self.promises.movePromise:getStatus() ~= "Started" then
        self.promises.movePromise:cancel()
        task.wait(1)
    end

    self.npcModel:SetAttribute("nextWaypointToken",  
        determineNextWaypoint(
            self.npcModel :: Types.NPCModel, 
            nil, 
            self.npcModel:GetAttribute("compromised")
        )
    )
                
    task.delay(5, function()
        if self.npcModel.Humanoid.Health > 0 then
            -- TODO: Signal: call 911
            self.npcModel:SetAttribute("playerToLookAt", "")
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

    npcModel:SetAttribute("nextWaypointToken", 
		determineNextWaypoint(
			npcModel :: Types.NPCModel, 
			nil, 
			true
		)
	)
    
end

return Civilian
