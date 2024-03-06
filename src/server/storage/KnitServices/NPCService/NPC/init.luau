--!strict

-- NPC Abstract class

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Types = require(ReplicatedStorage.Shared.Types)

local TAG_NAME = "NPC"
local CONFIG = require(script.Config)

local TokenService
task.spawn(function()
    Knit.OnStart():andThen(function()
        TokenService = Knit.GetService("TokenService")
    end)
end)

type Promise = typeof(Promise.new(function() end))


--=========== NPC FUNCTIONS ================

local Helper = script.Helper
local Assets = script.Assets
local Actions = script.Actions
local SetupModel = require(Actions.SetupModel)
local Move = require(Actions.Move)
local HeadTrackPlayer = require(Actions.HeadTrackPlayer)
local UpdateIndicator = require(Actions.UpdateIndicator)
local Combat = require(Actions.Combat)

--=========== HELPERS ======================

local ragdollOnDeath = require(Helper.RagdollOnDeath)
local determineNextWaypoint = require(Helper.DetermineNextWaypoint)
local findWaypointGivenToken = require(Helper.FindWaypointWithToken)
local disconnectAllPromises = function(prom: {[any]: Promise})
    for _, promise: Promise | nil in pairs(prom) do
        if promise ~= nil and promise:getStatus() == "Started" then    
            promise:cancel()
            promise = nil
        end
    end
end
local disconnectAllConnections = function(conn: {[any]: RBXScriptConnection})
    for _, connection: RBXScriptConnection | nil in pairs(conn) do
        if connection ~= nil then    
            connection:Disconnect()
            connection = nil
        end
    end
end

--=========== NPC CLASS ================
local NPC = {}
NPC.__index = NPC

local InitialProps = {
    npcModel = nil :: Types.NPCModel,
    npcClass = "" :: string,
    thisNPCFinishedMoving = Signal.new(),
    playerCurrentlyBeingTracked = nil :: Player | nil,
    currentTask = nil :: Types.NPCEvent?,
    
    promises = {} :: {[any]: Promise},
    
    connections = {} :: {[any]: RBXScriptConnection},
}

function NPC:new(npcModel: Types.NPCModel, class: string?): any

    local function setCollisionGroup(_npcModel: Types.NPCModel, _tagName: string)
        for _, v in pairs(_npcModel:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CollisionGroup = _tagName
            end
        end
    end

    Knit.OnStart():awaitStatus()
    TokenService = Knit.GetService("TokenService")

    -- set up NPC model
    local newNPC = table.clone(InitialProps)
    newNPC.npcModel = SetupModel(npcModel, TokenService:GenerateToken("npc"), class) :: Types.NPCModel
    newNPC.npcModel.Parent = CONFIG.NPC_CONTAINER_DIR
    setmetatable(newNPC, NPC)

    setCollisionGroup(newNPC.npcModel, "NPC")
    CollectionService:AddTag(newNPC.npcModel, TAG_NAME)

    return newNPC
end


function NPC:Active(initPosition: CFrame?): ()

    self.connections.stateChangeConnection = self.NPCModel:GetAttributeChangedSignal("State"):Connect(self.ChangeState)
    self.connections.waypointChangeConnection = self.NPCModel:GetAttributeChangedSignal("NextWaypointToken"):Connect(self.ChangeWaypoint)
    self.connections.lookAtChangeConnection = self.NPCModel:GetAttributeChangedSignal("playerToLookAt"):Connect(self.ChangePlayerToLookAt) 
    self.connections.diedConnection = self.NPCModel.Humanoid.Died:Connect(self.Died)
    self.connections.ancestryChangedConnection = self.NPCModel.AncestryChanged:Connect(self.Destroy)
    
    -- initialize move
    task.defer(function()
        local nextWaypointToken = determineNextWaypoint(self.NPCModel :: Types.NPCModel, nil, self.NPCModel:GetAttribute("compromised"))
        self.NPCModel:PivotTo(
            if initPosition ~= nil then 
                initPosition 
            else 
                findWaypointGivenToken(nextWaypointToken):GetPivot()
            )
        task.wait(0.5)
        nextWaypointToken = determineNextWaypoint(self.NPCModel :: Types.NPCModel, nil, self.NPCModel:GetAttribute("compromised"))
        self.NPCModel:SetAttribute("NextWaypointToken", nextWaypointToken)
    end)
    
end


function NPC:ChangeState(): ()
    local npcModel = self.NPCModel :: Types.NPCModel
    local npcClass = npcModel:GetAttribute("Class") :: string
    local playerToTrack = if npcModel:GetAttribute("playerToTrack") ~= nil then Players:FindFirstChild(npcModel:GetAttribute("playerToTrack")) else nil :: Player | nil
    local charToTrack = if playerToTrack then playerToTrack.Character else nil :: Types.Character
    local newState = npcModel:GetAttribute("State")

    UpdateIndicator(self, newState)
    
    if self.promises.statePromise then
        self.promises.statePromise:cancel()
    end
    
    local stateHandlers = {
        ["Safe"] = self:Safe(),
        ["Curious"] = self:Curious(),
        ["Suspicious"] = self:Suspicious(),
        ["Alert"] = self:Alert(),
        ["Hostile"] = self:Hostile(),
    }
    
    self.promises.statePromise = Promise.new(function(resolve, reject, onCancel)
        
        if onCancel(function()
            if self.promises.statePromise then
                self.promises.statePromise:cancel()
            end
        end) then
            return
        end
        
        stateHandlers[newState]()
        
        --[[
        local nextWaypoint
        if newState == "Safe" then
            self.NPCModel:SetAttribute("playerToTrack", nil)
            self.NPCModel:SetAttribute("playerToLookAt", nil)
            
        elseif newState == "Curious" then
            self.NPCModel:SetAttribute("playerToLookAt", playerToTrack.Name)
            
        elseif newState == "Suspicious" then
            if self.NPCModel:GetAttribute("playerToLookAt") ~= playerToTrack.Name then
                self.NPCModel:SetAttribute("playerToLookAt", playerToTrack.Name)
            end
            nextWaypoint = determineNextWaypoint(self.NPCModel :: Types.NPCModel, charToTrack.HumanoidRootPart, self.NPCModel:GetAttribute("compromised"))
            
        elseif newState == "Alert" then
            self.NPCModel:SetAttribute("compromised", true)
            if self.promises.movePromise ~= nil and self.promises.movePromise:getStatus() ~= "Started" then
                self.promises.movePromise:cancel()
                task.wait(1)
            end
            if npcClass == "Police" or npcClass == "Cartel" then
                nextWaypoint = determineNextWaypoint(self.NPCModel :: Types.NPCModel, charToTrack.HumanoidRootPart, self.NPCModel:GetAttribute("compromised"))
                
                if self.promises.combatPromise ~= nil and self.promises.combatPromise:getStatus() == "Started" then
                    self.promises.combatPromise:cancel()
                end
                
                self.promises.combatPromise = Combat(self, playerToTrack)
                
                task.delay(2, function()
                    if self.NPCModel.Humanoid.Health > 0 then
                        self.NPCModel:SetAttribute("playerToLookAt", nil)
                        self.NPCModel:SetAttribute("State", "Hostile")
                    end
                end)
            else
                nextWaypoint = determineNextWaypoint(self.NPCModel :: Types.NPCModel, nil, true)
                
                task.delay(5, function()
                    if self.NPCModel.Humanoid.Health > 0 then
                        -- TODO: Signal: call 911
                        self.NPCModel:SetAttribute("playerToLookAt", nil)
                        self.NPCModel:SetAttribute("State", "Hostile")
                        -- TODO: Signal: total compromised
                    end
                end)
                
            end
            
            
        elseif newState == "Hostile" then
            self.NPCModel:SetAttribute("compromised", true)
            if self.promises.movePromise ~= nil and self.promises.movePromise:getStatus() ~= "Started" then
                self.promises.movePromise:cancel()
                task.wait(1)
            end
            if npcClass == "Police" or npcClass == "Cartel" then
                nextWaypoint = determineNextWaypoint(self.NPCModel :: Types.NPCModel, charToTrack.HumanoidRootPart, self.NPCModel:GetAttribute("compromised"))
                
                if self.promises.combatPromise ~= nil and self.promises.combatPromise:getStatus() ~= "Started" then
                    self.promises.combatPromise = Combat(self, playerToTrack)
                end

            else
                nextWaypoint = determineNextWaypoint(self.NPCModel :: Types.NPCModel, nil, true)
                
            end
            
        end
         
        if nextWaypoint then
            self.NPCModel:SetAttribute("NextWaypointToken", nextWaypoint)
        end
        ]] 
        resolve()
    end)
        
end


function NPC:Safe(): ()
    self.NPCModel:SetAttribute("playerToTrack", nil)
    self.NPCModel:SetAttribute("playerToLookAt", nil)
end

function NPC:Curious(): ()
    error("Cannot be directly called, this is to be implemented by subclasses.")
end

function NPC:Suspicious(): ()
    error("Cannot be directly called, this is to be implemented by subclasses.")
end

function NPC:Alert(): ()
    local npcModel = self.NPCModel :: Types.NPCModel
    npcModel:SetAttribute("compromised", true)
    
    if self.promises.movePromise ~= nil and self.promises.movePromise:getStatus() ~= "Started" then
        self.promises.movePromise:cancel()
        task.wait(1)
    end

    local nextWaypoint = determineNextWaypoint(npcModel :: Types.NPCModel, nil, true)

    task.delay(5, function()
        if npcModel.Humanoid.Health > 0 then
            -- TODO: Signal: call 911
            npcModel:SetAttribute("playerToLookAt", nil)
            npcModel:SetAttribute("State", "Hostile")
            npcModel:SetAttribute("NextWaypointToken", nextWaypoint)
            -- TODO: Signal: total compromised
        end
    end)
    
end

function NPC:Hostile(): ()
    local npcModel = self.NPCModel :: Types.NPCModel
    npcModel:SetAttribute("compromised", true)
    
    if self.promises.movePromise ~= nil and self.promises.movePromise:getStatus() ~= "Started" then
        self.promises.movePromise:cancel()
        task.wait(1)
    end

    local nextWaypoint = determineNextWaypoint(npcModel :: Types.NPCModel, nil, true)
    npcModel:SetAttribute("NextWaypointToken", nextWaypoint)
    
end

function NPC:ChangeWaypoint(): ()
    local npcModel = self.NPCModel :: Types.NPCModel
    local waypoint = findWaypointGivenToken(npcModel:GetAttribute("NextWaypointToken"))

    -- cancel any previous self.promises.movePromise
    if self.promises.movePromise ~= nil and self.promises.movePromise:getStatus() == "Started" then
        self.promises.movePromise:cancel()
    end

    -- create new self.promises.movePromise
    self.promises.movePromise = Promise.new(function(resolve, reject, onCancel)
        local isCompromised = npcModel:GetAttribute("compromised") :: boolean
        local function computePath()
            task.delay(math.random(1, 5), function()
                local nextWaypoint = determineNextWaypoint(
                    npcModel :: Types.NPCModel,
                    nil,
                    isCompromised
                )
                npcModel:SetAttribute("NextWaypointToken", nextWaypoint)
            end)
            resolve()
        end

        self.promises.innerMovePromise = Move(self, waypoint):catch(function()
            task.wait(4)
            computePath()
        end)

        -- if cancelled, cancel self.promises.innerMovePromise
        if onCancel(function()
            self.promises.innerMovePromise:cancel()
        end) then
            return
        end

        -- catch path rejections
        self.promises.innerMovePromise:catch(function()
            task.wait(4)
            computePath()
        end)

        -- wait for it to resolve
        self.promises.innerMovePromise:andThen(computePath, computePath)
    end)
end

function NPC:ChangePlayerToLookAt(): ()
    local targetPlayer = if self.NPCModel:GetAttribute("playerToLookAt") ~= nil
        then Players:FindFirstChild(self.NPCModel:GetAttribute("playerToLookAt"))
        else nil :: Player | nil

    -- cancel any previous promises.lookPromise
    if self.promises.lookPromise ~= nil and self.PlayerCurrentlyBeingTracked ~= targetPlayer then
        self.promises.lookPromise:cancel()
    end

    -- set new player to track
    self.PlayerCurrentlyBeingTracked = targetPlayer

    -- create new self.promises.lookPromise
    if self.PlayerCurrentlyBeingTracked ~= nil then
        self.promises.lookPromise = Promise.new(function(resolve, reject, onCancel)

            self.promises.innerLookPromise = HeadTrackPlayer(self, self.PlayerCurrentlyBeingTracked)

            if
                onCancel(function()
                    self.promises.innerLookPromise:cancel()
                end)
            then
                return
            end

            self.promises.innerLookPromise:await()
        end)
    end
end

function NPC:Died(): ()
    ragdollOnDeath(self.NPCModel)
    disconnectAllPromises(self.promises)
    UpdateIndicator(self, "Safe")
end

function NPC:Destroy(): ()
    UpdateIndicator(self, "Safe")
    disconnectAllPromises(self.promises)
    CollectionService:RemoveTag(self.NPCModel :: Types.NPCModel, TAG_NAME)
    if not self.NPCModel:IsDescendantOf(workspace) then
        disconnectAllConnections(self.connections)
    end
end

return NPC

