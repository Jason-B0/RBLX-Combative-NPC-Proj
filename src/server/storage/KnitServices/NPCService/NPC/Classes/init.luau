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

type Signal<T...> = typeof(Signal.new())

export type NPCClass = {
    new: (npcModel: NPCModel, class: string?) -> NPCClass,
    
    npcModel: NPCModel,
    npcClass: string,
    npcGender: string,
    
    thisNPCFinishedMoving: Signal<any>,
    playerCurrentlyBeingTracked: Player,
    currentTask: Types.NPCEvent?,
    promises: { [any]: Promise },
    connections: { [any]: RBXScriptConnection },
    
    __index: NPCClass,

    Active: () -> (),

    ChangeState: () -> (),

    Safe: () -> (),
    Curious: () -> (),
    Suspicious: () -> (),
    Alert: () -> (),
    Hostile: () -> (),
    ChangeWaypoint: () -> (),
    ChangePlayerToLookAt: () -> (),
    
}

export type NPCModel = (Model & {
    HumanoidRootPart: BasePart,
    Humanoid: Humanoid & {
        HumanoidDescription: HumanoidDescription,
        Animator: Animator,
    },
    Torso: BasePart & {
        Neck: Motor6D,
        ["Left Shoulder"]: Motor6D,
        ["Right Shoulder"]: Motor6D,
        ["Left Hip"]: Motor6D,
        ["Right Hip"]: Motor6D,
    },
    Head: BasePart,
    StateBillboard: BillboardGui & {
        StateIndicator: ImageLabel,
    },
    Weapon: Types.WeaponTool?,

    -- Attributes
    Class: string,
    NextWaypointToken: string,

    -- Variables
    playerToTrack: string,
    State: "Safe" | "Curious" | "Suspicious" | "Alert" | "Hostile",
}) | Instance

type Promise = typeof(Promise.new(function() end))


local System = script.Parent
local TAG_NAME = "NPC"
local CONFIG = require(System.Config)

local TokenService
task.spawn(function()
    Knit.OnStart():andThen(function()
        TokenService = Knit.GetService("TokenService")
    end)
end)

--=========== NPC FUNCTIONS ================
local Helper = System.Helper
local Assets = System.Assets
local Actions = System.Actions
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

local function setCollisionGroup(_npcModel: NPCModel, _tagName: string)
    for _, v in pairs(_npcModel:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CollisionGroup = _tagName
        end
    end
end

local function determineGender() : string
    local random = math.random(1, 2)
    return if random == 1 then "Male" else "Female"
end

--=========== NPC CLASS ================
local NPC = {}
NPC.__index = NPC

local InitialProps = {
    npcModel = nil :: NPCModel | any,
    npcClass = "" :: string,
    thisNPCFinishedMoving = Signal.new(),
    playerCurrentlyBeingTracked = nil :: Player | nil,
    
    promises = {} :: {[any]: Promise},
    
    connections = {} :: {[any]: RBXScriptConnection},
}

function NPC.new(npcModel: NPCModel, class: string?)
    Knit.OnStart():awaitStatus()
    TokenService = Knit.GetService("TokenService")

    -- set up NPC model
    local newNPC = table.clone(InitialProps)
    local token = TokenService:GenerateToken("npc")
    local gender = determineGender()
    newNPC.npcModel = SetupModel(npcModel, token, class, gender) :: NPCModel
    newNPC.npcModel.Parent = CONFIG.NPC_CONTAINER_DIR

    setCollisionGroup(newNPC.npcModel, "NPC")
    CollectionService:AddTag(newNPC.npcModel, TAG_NAME)

    return setmetatable(newNPC, NPC)
end

function NPC:ChangeState(): ()
    local npcModel = self.npcModel :: NPCModel
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

        resolve()
    end)
        
end

function NPC:ChangeWaypoint(): ()

    local npcModel = self.npcModel :: NPCModel
    local waypoint = findWaypointGivenToken(npcModel:GetAttribute("NextWaypointToken"))
    local isCompromised = npcModel:GetAttribute("compromised") :: boolean
    local function computePath()
        task.delay(math.random(1, 5), function()
            local nextWaypoint = determineNextWaypoint(
                npcModel,
                nil,
                isCompromised
            )
            npcModel:SetAttribute("NextWaypointToken", nextWaypoint)
        end)
    end
    -- cancel any previous self.promises.movePromise
    if self.promises.movePromise ~= nil and self.promises.movePromise:getStatus() == "Started" then
        self.promises.movePromise:cancel()
    end

    -- create new self.promises.movePromise
    self.promises.movePromise = Promise.new(function(resolve, reject, onCancel)
        isCompromised = npcModel:GetAttribute("compromised") :: boolean

        self.promises.innerMovePromise = Move(self, waypoint)

        -- if cancelled, cancel self.promises.innerMovePromise
        if onCancel(function()
            self.promises.innerMovePromise:cancel()
        end) then
            return
        end

        -- catch path rejections
        self.promises.innerMovePromise:catch(function()
            task.wait(4)
            reject()
        end)

        -- wait for it to resolve
        self.promises.innerMovePromise:andThen(computePath, computePath)
        resolve()
    end):catch(function()
        computePath()
    end)
end

function NPC:ChangePlayerToLookAt(): ()
    local targetPlayer = if self.npcModel:GetAttribute("playerToLookAt") ~= nil
        then Players:FindFirstChild(self.npcModel:GetAttribute("playerToLookAt"))
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
    ragdollOnDeath(self.npcModel)
    disconnectAllPromises(self.promises)
    UpdateIndicator(self, "Safe")
end

function NPC:Destroy(): ()
    UpdateIndicator(self, "Safe")
    disconnectAllPromises(self.promises)
    CollectionService:RemoveTag(self.npcModel :: NPCModel, TAG_NAME)
    if not self.npcModel:IsDescendantOf(workspace) then
        disconnectAllConnections(self.connections)
    end
end

function NPC:Active(initPosition: CFrame?): ()
    self.connections.stateChangeConnection = self.npcModel:GetAttributeChangedSignal("State"):Connect(function()
        self:ChangeState()
    end)
    self.connections.waypointChangeConnection = self.npcModel:GetAttributeChangedSignal("NextWaypointToken"):Connect(function()
        self:ChangeWaypoint()
    end)
    self.connections.lookAtChangeConnection = self.npcModel:GetAttributeChangedSignal("playerToLookAt"):Connect(function()
        self:ChangePlayerToLookAt()
    end) 
    self.connections.diedConnection = self.npcModel.Humanoid.Died:Connect(function()
        self:Died()
    end)
    self.connections.destroyConnection = self.npcModel.AncestryChanged:Connect(function()
        if not self.npcModel:IsDescendantOf(workspace) then
            self:Destroy()
        end
    end)
    
    -- initialize move
    task.defer(function()
        local nextWaypointToken = determineNextWaypoint(self.npcModel, nil, self.npcModel:GetAttribute("compromised"))
        self.npcModel:PivotTo(
            if initPosition ~= nil then 
                initPosition 
            else 
                findWaypointGivenToken(nextWaypointToken):GetPivot()
            )
        task.wait(2)
        nextWaypointToken = determineNextWaypoint(self.npcModel, nil, self.npcModel:GetAttribute("compromised"))
        self.npcModel:SetAttribute("NextWaypointToken", nextWaypointToken)
    end)
    
end

function NPC:Safe(): ()
    error("Cannot be directly called, this is to be implemented by subclasses.")
end

function NPC:Curious(): ()
    error("Cannot be directly called, this is to be implemented by subclasses.")
end

function NPC:Suspicious(): ()
    error("Cannot be directly called, this is to be implemented by subclasses.")
end

function NPC:Alert(): ()
    error("Cannot be directly called, this is to be implemented by subclasses.")
end

function NPC:Hostile(): ()
    error("Cannot be directly called, this is to be implemented by subclasses.")
end

return NPC

