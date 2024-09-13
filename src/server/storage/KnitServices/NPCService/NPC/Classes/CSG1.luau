local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Promise = require(ReplicatedStorage.Packages.Promise)
local Types = require(ReplicatedStorage.Shared.Types)
local NPC = require(script.Parent.Superclass)
--=========== MODULE ================

local CSG1NPC = setmetatable({}, NPC)
CSG1NPC.__index = CSG1NPC

function CSG1NPC.new(npcModel: Types.NPCModel)	
    local newNPC = NPC.new(npcModel, "CSG1")
	return setmetatable(newNPC, CSG1NPC)
end

function CSG1NPC:ChangeState(): ()
    local npcModel = self.npcModel :: Types.NPCModel
    local npcClass = npcModel:GetAttribute("Class") :: string
    local playerToTrack = if npcModel:GetAttribute("aggroPlayer") ~= nil then Players:FindFirstChild(npcModel:GetAttribute("aggroPlayer")) else nil :: Player | nil
    local charToTrack = if playerToTrack then playerToTrack.Character else nil :: Types.Character
    local newState = npcModel:GetAttribute("State")
    self:UpdateIndicator(newState)
    
    if self.promises.statePromise then
        self.promises.statePromise:cancel()
    end

    local stateHandlers = {
        ["Safe"] = self.Safe,
        ["Curious"] = self.Curious,
        ["Suspicious"] = self.Suspicious,
        ["Alert"] = self.Alert,
        ["Hostile"] = self.Hostile ,
    }

    self.promises.statePromise = Promise.new(function(resolve, reject, onCancel)

        if onCancel(function()
            if self.promises.statePromise then
                self.promises.statePromise:cancel()
            end
        end) then
            return
        end
        
        stateHandlers[newState](self)

        resolve()
    end)
        
end

function CSG1NPC:Safe(): ()
    self.npcModel:SetAttribute("aggroPlayer", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

function CSG1NPC:Curious(): ()
    self.npcModel:SetAttribute("playerToLookAt", self.npcModel:GetAttribute("aggroPlayer"))
end

function CSG1NPC:Suspicious(): ()
    self.npcModel:SetAttribute("aggroPlayer", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

function CSG1NPC:Alert(): ()
    self.npcModel:SetAttribute("aggroPlayer", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

function CSG1NPC:Hostile(): ()
    self.npcModel:SetAttribute("aggroPlayer", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

return CSG1NPC
