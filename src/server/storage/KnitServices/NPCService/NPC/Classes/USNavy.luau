--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Promise = require(ReplicatedStorage.Packages.Promise)
local Types = require(ReplicatedStorage.Shared.Types)
local NPC = require(script.Parent.Superclass)
--=========== MODULE ================

local USNavyNPC = {}
USNavyNPC.__index = USNavyNPC
setmetatable(USNavyNPC, NPC)

function USNavyNPC.new(npcModel: Types.NPCModel, class: string?)
	local newNPC = NPC.new(npcModel, "USNavy") :: Types.NPC
	
	return setmetatable(newNPC, USNavyNPC)
end

function USNavyNPC:ChangeState(): ()
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

function USNavyNPC:Safe(): ()
    self.npcModel:SetAttribute("aggroPlayer", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

function USNavyNPC:Curious(): ()
    self.npcModel:SetAttribute("playerToLookAt", self.npcModel:GetAttribute("aggroPlayer"))
end

function USNavyNPC:Suspicious(): ()
    self.npcModel:SetAttribute("aggroPlayer", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

function USNavyNPC:Alert(): ()
    self.npcModel:SetAttribute("aggroPlayer", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

function USNavyNPC:Hostile(): ()
    self.npcModel:SetAttribute("aggroPlayer", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

return USNavyNPC
