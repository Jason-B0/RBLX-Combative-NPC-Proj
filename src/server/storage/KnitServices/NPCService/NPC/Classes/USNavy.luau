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

function USNavyNPC:Safe(): ()
    self.npcModel:SetAttribute("aggroPlayerName", "")
    self.npcModel:SetAttribute("playerToLookAt", "")
end

function USNavyNPC:Curious(): ()
    self.npcModel:SetAttribute("playerToLookAt", self.npcModel:GetAttribute("aggroPlayerName"))
end

function USNavyNPC:Suspicious(): ()
    self.npcModel:SetAttribute("aggroPlayerName", "")
    self.npcModel:SetAttribute("playerToLookAt", "")
end

function USNavyNPC:Alert(): ()
    self.npcModel:SetAttribute("aggroPlayerName", "")
    self.npcModel:SetAttribute("playerToLookAt", "")
end

function USNavyNPC:Hostile(): ()
    self.npcModel:SetAttribute("aggroPlayerName", "")
    self.npcModel:SetAttribute("playerToLookAt", "")
end

return USNavyNPC
