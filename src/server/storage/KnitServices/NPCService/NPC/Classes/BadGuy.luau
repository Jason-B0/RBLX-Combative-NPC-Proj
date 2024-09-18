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

local BadGuy = {}
BadGuy.__index = BadGuy
setmetatable(BadGuy, NPC)

function BadGuy.new(npcModel: Types.NPCModel, class: string?): any
	local newNPC = NPC.new(npcModel, "BadGuy") :: Types.NPC
	
	return setmetatable(newNPC, BadGuy)
end

function BadGuy:ChangeState(): ()
    local npcModel = self.npcModel :: Types.NPCModel
    local npcClass = npcModel:GetAttribute("Class") :: string
    local aggroPlayer = if npcModel:GetAttribute("aggroPlayer") ~= nil then Players:FindFirstChild(npcModel:GetAttribute("aggroPlayer")) else nil :: Player | nil
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

        stateHandlers[newState](aggroPlayer)

        resolve()
    end)
        
end

function BadGuy:Safe(): ()
    self.npcModel:SetAttribute("aggroPlayer", nil)
    self.npcModel:SetAttribute("playerToLookAt", nil)
end

function BadGuy:Curious(aggroPlayer: Player): ()
    self.npcModel:SetAttribute("playerToLookAt", aggroPlayer)
end

function BadGuy:Suspicious(aggroPlayer: Player): ()
    if self.npcModel:GetAttribute("playerToLookAt") ~= aggroPlayer.Name then
        self.npcModel:SetAttribute("playerToLookAt", aggroPlayer.Name)
    end
    local charToTrack = aggroPlayer.Character :: Types.Character
    self.npcModel:SetAttribute("NextWaypointToken",  
        determineNextWaypoint(
            self.npcModel :: Types.NPCModel, 
            charToTrack.HumanoidRootPart, 
            self.npcModel:GetAttribute("compromised")
        )
    )
end

function BadGuy:Alert(aggroPlayer: Player): ()
    local charToTrack = aggroPlayer.Character :: Types.Character
    local nextWaypoint = determineNextWaypoint(self.npcModel, charToTrack.HumanoidRootPart, false)

    self.npcModel:SetAttribute("compromised", true)
    if self.promises.movePromise ~= nil and self.promises.movePromise:getStatus() ~= "Started" then
        self.promises.movePromise:cancel()
        task.wait(1)
    end
        
    if self.promises.combatPromise ~= nil and self.promises.combatPromise:getStatus() == "Started" then
        self.promises.combatPromise:cancel()
    end
    
    self.promises.combatPromise = Combat(self, aggroPlayer)
    
    task.delay(2, function()
        if self.npcModel.Humanoid.Health > 0 then
            self.npcModel:SetAttribute("playerToLookAt", nil)
            self.npcModel:SetAttribute("State", "Hostile")
        end
    end)
end

function BadGuy:Hostile(aggroPlayer: Player): ()
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

return BadGuy