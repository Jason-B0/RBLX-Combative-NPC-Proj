--!strict
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

local WAYPOINT_FOLDER = workspace.NPC_Waypoints :: Folder
local TRACKING_FOLDER = WAYPOINT_FOLDER.TrackingFolder :: Folder
local EVADE_FOLDER = WAYPOINT_FOLDER.EvadeWaypoints :: Folder

local TokenService, NPCService
task.spawn(function() -- Knit initialization
    Knit.OnStart():andThen(function()
        TokenService = Knit.GetService("TokenService")
    end)
end)

--=========== NPC FUNCTIONS ================
local Helper = script.Helper
local Assets = script.Assets 
local SetupModel = require(script.SetupModel)
local Move = require(script.Move)
local HeadTrackPlayer = require(script.HeadTrackPlayer)
local UpdateIndicator = require(script.UpdateIndicator)

--=========== HELPERS ======================
local function determineNextWaypoint(npc: Types.NPCModel, targetPart: BasePart?, isEvading: boolean?): string
    
    local npcClass = npc:GetAttribute("Class") :: string
    
    -- if targetPart is provided, return it
    if targetPart then
        -- create a new waypoint at targetPart
        local newWaypoint = Instance.new("Part")
        newWaypoint.Name = "Waypoint"
        newWaypoint.Anchored = true
        newWaypoint.CanCollide = false
        newWaypoint.Size = Vector3.new(1, 1, 1)
        newWaypoint.Transparency = 1
        newWaypoint.Position = targetPart.Position
        newWaypoint.Parent = TRACKING_FOLDER
        newWaypoint:SetAttribute("WaypointToken", TokenService:GenerateToken("twp"))
        return newWaypoint:GetAttribute("WaypointToken")
    end
    
    -- if evading, pick a random evade waypoint
    if isEvading then
        local eWaypoints = EVADE_FOLDER:GetChildren()
        return eWaypoints[math.random(1, #eWaypoints)]:GetAttribute("WaypointToken")
    end
    
    -- otherwise, pick a random waypoint
    local waypoints = WAYPOINT_FOLDER:GetChildren()
    local waypoint = nil :: Types.Waypoint
    
    while waypoint == nil do
        local possibleWaypoint = waypoints[math.random(1, #waypoints)]
        
        if not possibleWaypoint:IsA("BasePart")  then
            continue
        end
        
        -- if NPC can access the waypoint it,
        -- then return it
        if npcClass == "Civilian" and (
            possibleWaypoint:GetAttribute("CanPublicAccess") == true 
        ) then
            waypoint = possibleWaypoint
        
        elseif npcClass == "Police" and (
            possibleWaypoint:GetAttribute("CanPoliceAccess") == true or
            possibleWaypoint:GetAttribute("CanPublicAccess") == true or
            possibleWaypoint:GetAttribute("CanDockAdminAccess") == true or
            possibleWaypoint:GetAttribute("CanDockWorkerAccess") == true or
            possibleWaypoint:GetAttribute("CanCartelAccess") == true or
            possibleWaypoint:GetAttribute("CanConstructionWorkerAccess") == true
        ) then
            waypoint = possibleWaypoint
        
        elseif npcClass == "Dock Worker" and (
            possibleWaypoint:GetAttribute("CanDockWorkerAccess") == true or
            possibleWaypoint:GetAttribute("CanPublicAccess") == true
        ) then
            waypoint = possibleWaypoint
            
        elseif npcClass == "Dock Admin" and (
            possibleWaypoint:GetAttribute("CanDockAdminAccess") == true or
            possibleWaypoint:GetAttribute("CanDockWorkerAccess") == true or
            possibleWaypoint:GetAttribute("CanPublicAccess") == true
        ) then
            waypoint = possibleWaypoint
            
        elseif npcClass == "Cartel" and (
            possibleWaypoint:GetAttribute("CanCartelAccess") == true or
            possibleWaypoint:GetAttribute("CanDockWorkerAccess") == true or
            possibleWaypoint:GetAttribute("CanPublicAccess") == true
        ) then
            waypoint = possibleWaypoint
            
        elseif npcClass == "Construction Worker" and (
            possibleWaypoint:GetAttribute("CanConstructionWorkerAccess") == true or
            possibleWaypoint:GetAttribute("CanPublicAccess") == true
        ) then
            waypoint = possibleWaypoint
            
        end
        
    end
    
    return waypoint:GetAttribute("WaypointToken") :: string
    
end

-- find waypoint given token
local function findWaypointGivenToken(waypointToken:string)
    for _, waypoint: Types.Waypoint in pairs(WAYPOINT_FOLDER:GetDescendants()) do
        if waypoint:GetAttribute("WaypointToken") == waypointToken then
            return waypoint
        end
    end
end

local function disconnectAllPromises(...)
    local args = {...}
    
    for _, promise in pairs(args) do
        if promise ~= nil and promise:getStatus() == "Started" then
            promise:cancel()
        end
    end
end

local function disconnectAllConnections(conn: {})
    for _, connection: RBXScriptConnection in pairs(conn) do
        if connection ~= nil then    
            connection:Disconnect()
            connection = nil
        end
    end
end

local function ragdollOnDeath(npcModel: Types.NPCModel)
    for _, joint: Motor6D in pairs(npcModel:GetDescendants()) do
		if joint:IsA("Motor6D") then
			local socket = Instance.new("BallSocketConstraint")
			local a1 = Instance.new("Attachment")
			local a2 = Instance.new("Attachment")
			a1.Parent = joint.Part0
			a2.Parent = joint.Part1
			socket.Parent = joint.Parent
			socket.Attachment0 = a1
			socket.Attachment1 = a2
			a1.CFrame = joint.C0
			a2.CFrame = joint.C1
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			joint:Destroy()
		end
	end
end

--=========== NPC CLASS ================
local NPC = {}
NPC.__index = NPC

function NPC.new(npcModel: Types.NPCModel, class: string?)
    Knit.OnStart():awaitStatus()
    TokenService = Knit.GetService("TokenService")
	local newNPC = {}
    
    newNPC.NPCModel = nil :: Types.NPCModel
    newNPC.NPCType = "" :: string
    newNPC.ThisNPCFinishedMoving = Signal.new()
    newNPC.PlayerCurrentlyBeingTracked = nil :: Player
	
    -- set up NPC model
	newNPC.NPCModel = SetupModel(npcModel, TokenService:GenerateToken("npc"), class) :: Types.NPCModel
    newNPC.NPCModel.Parent = workspace.NPC

    -- set up collision group
    for _, v in pairs(newNPC.NPCModel:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CollisionGroup = TAG_NAME
        end
    end

    -- add tag to NPC
    CollectionService:AddTag(newNPC.NPCModel, TAG_NAME)
	
	return setmetatable(newNPC, NPC)
end


function NPC:Active()
    local lookPromise = nil
    local movePromise = nil
    local innerMovePromise = nil
    local innerLookPromise = nil
    local statePromise = nil
    
    local connections = {
        stateChangeConnection = nil :: RBXScriptConnection,
        waypointChangeConnection = nil :: RBXScriptConnection,
        lookAtChangeConnection = nil :: RBXScriptConnection,
    }
    -- listen for NPC's state changing signal
    -- every other mechanism depends on this
    connections.stateChangeConnection = self.NPCModel:GetAttributeChangedSignal("State"):Connect(function()
        
        local npcModel = self.NPCModel
        local npcClass = npcModel:GetAttribute("Class") :: "Civilian" | "Police" | "Dock Worker" | "Dock Admin" | "Cartel"
        local playerToTrack = if npcModel:GetAttribute("playerToTrack") ~= nil then Players:FindFirstChild(npcModel:GetAttribute("playerToTrack")) else nil :: Player
        local charToTrack = if playerToTrack then playerToTrack.Character else nil :: Types.Character
        local newState = npcModel:GetAttribute("State")

        UpdateIndicator(self, newState)
        
        if statePromise then
            statePromise:cancel()
        end
        
        statePromise = Promise.new(function(resolve, reject, onCancel)
            
            if onCancel(function()
                statePromise:cancel()
            end) then
                return
            end
            
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
                nextWaypoint = determineNextWaypoint(self.NPCModel, charToTrack.HumanoidRootPart, self.NPCModel:GetAttribute("compromised"))
                
            elseif newState == "Alert" then
                self.NPCModel:SetAttribute("compromised", true)
                
                if npcClass == "Police" or npcClass == "Cartel" then
                    nextWaypoint = determineNextWaypoint(self.NPCModel, charToTrack.HumanoidRootPart, self.NPCModel:GetAttribute("compromised"))
                    
                else
                    nextWaypoint = determineNextWaypoint(self.NPCModel, nil, true)
                    
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
                if npcClass == "Police" or npcClass == "Cartel" then
                    nextWaypoint = determineNextWaypoint(self.NPCModel, charToTrack.HumanoidRootPart, self.NPCModel:GetAttribute("compromised"))
                    
                else
                    nextWaypoint = determineNextWaypoint(self.NPCModel, nil, true)
                    
                end
                
            end
             
            if nextWaypoint then
                self.NPCModel:SetAttribute("NextWaypointToken", nextWaypoint)
            end
            
            resolve()
        end)
        
    end)
    
	-- listen for NPC's next waypoint changing signal
    connections.waypointChangeConnection = self.NPCModel:GetAttributeChangedSignal("NextWaypointToken"):Connect(function()  
        
        local waypoint = findWaypointGivenToken(self.NPCModel:GetAttribute("NextWaypointToken"))
        
        -- cancel any previous movePromise
        if movePromise ~= nil and movePromise:getStatus() == "Started" then
            movePromise:cancel()
        end
        
        -- create new movePromise
        movePromise = Promise.new(function(resolve, reject, onCancel)
            
            local function computePath()
                task.delay(math.random(1, 5), function()
                    local nextWaypoint = determineNextWaypoint(self.NPCModel, nil, self.NPCModel:GetAttribute("compromised"))
                    self.NPCModel:SetAttribute("NextWaypointToken", nextWaypoint)
                end)
                resolve()
            end
            
            innerMovePromise = Move(self, waypoint)
            
            -- if cancelled, cancel innerMovePromise
            if onCancel(function()
                innerMovePromise:cancel()
            end) then
                return
            end
            
            -- catch path rejections
            innerMovePromise:catch(function()
                computePath()
            end)
            
            -- wait for it to resolve
            innerMovePromise:andThen(computePath, computePath)
            
            
        end)
        
    end)
	
    -- listen for NPC's turn head signal
    connections.lookAtChangeConnection = self.NPCModel:GetAttributeChangedSignal("playerToLookAt"):Connect(function()
        local targetPlayer = 
            if self.NPCModel:GetAttribute("playerToLookAt") ~= nil then 
             Players:FindFirstChild(self.NPCModel:GetAttribute("playerToLookAt")) 
            else 
                nil 
            :: Player | nil
        
        -- cancel any previous lookPromise
        if lookPromise ~= nil and self.PlayerCurrentlyBeingTracked ~= targetPlayer then
            lookPromise:cancel()
        end
        
        -- set new player to track
        self.PlayerCurrentlyBeingTracked = targetPlayer
        
        -- create new lookPromise
        if self.PlayerCurrentlyBeingTracked ~= nil then
            lookPromise = Promise.new(function(resolve, reject, onCancel)
                
                innerLookPromise = HeadTrackPlayer(self, self.PlayerCurrentlyBeingTracked)
                
                if onCancel(function()
                    innerLookPromise:cancel()
                end) then
                    return
                end
                
                innerLookPromise:await()
                
            end)
                
        end
        
    end) 
    
    -- listen for death
    self.NPCModel.Humanoid.Died:Connect(function()
        ragdollOnDeath(self.NPCModel)
        disconnectAllPromises(statePromise, movePromise, lookPromise)
        UpdateIndicator(self, "Safe")
        disconnectAllConnections(connections)
    end)
    
    -- listen for NPC's parent changing signal
    self.NPCModel.AncestryChanged:Connect(function()
        UpdateIndicator(self, "Safe")
        disconnectAllPromises(statePromise, movePromise, lookPromise)
        CollectionService:RemoveTag(self.NPCModel, TAG_NAME)
        if not self.NPCModel:IsDescendantOf(workspace) then
        disconnectAllConnections(connections)
        end
    end)
    
    -- initialize move
    task.spawn(function()
        local nextWaypointToken = determineNextWaypoint(self.NPCModel, nil, self.NPCModel:GetAttribute("compromised"))
        self.NPCModel:PivotTo(findWaypointGivenToken(nextWaypointToken):GetPivot())
        task.wait(0.5)
        nextWaypointToken = determineNextWaypoint(self.NPCModel, nil, self.NPCModel:GetAttribute("compromised"))
        self.NPCModel:SetAttribute("NextWaypointToken", nextWaypointToken)
    end)
    
end



return NPC