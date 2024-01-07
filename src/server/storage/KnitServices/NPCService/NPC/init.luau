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
local TRACKING_FOLDER = WAYPOINT_FOLDER:FindFirstChild("TrackingFolder") :: Folder
local EVADE_FOLDER = WAYPOINT_FOLDER:FindFirstChild("EvadeWaypoints") :: Folder

local TokenService, NPCService
task.spawn(function() -- Knit initialization
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
        local possibleWaypoint = waypoints[math.random(1, #waypoints)] :: Types.Waypoint
        
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
local function findWaypointGivenToken(waypointToken:string): Instance | nil
    for _, waypoint in pairs(WAYPOINT_FOLDER:GetDescendants()) do
        if waypoint:GetAttribute("WaypointToken") == waypointToken then
            return waypoint
        end
    end
    return nil
end

local function disconnectAllPromises(prom: {[any]: Promise | nil})
    for _, promise: Promise in pairs(prom) do
        if promise ~= nil and promise:getStatus() == "Started" then    
            promise:cancel()
            promise = nil
        end
    end
end

local function disconnectAllConnections(conn: {[any]: RBXScriptConnection | nil})
    for _, connection: RBXScriptConnection | nil in pairs(conn) do
        if connection ~= nil then    
            connection:Disconnect()
            connection = nil
        end
    end
end

local function ragdollOnDeath(npcModel: Types.NPCModel)
    for _, joint in pairs(npcModel:GetDescendants()) do
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
    newNPC.PlayerCurrentlyBeingTracked = nil :: Player | nil
	
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
    local promises = {
        ["statePromise"] = nil :: Promise,
        ["movePromise"] = nil :: Promise,
        ["innerMovePromise"] = nil :: Promise,
        ["innerLookPromise"] = nil :: Promise,
        ["combatPromise"] = nil :: Promise,
        ["lookPromise"] = nil :: Promise,
    }
    
    local connections = {
        ["stateChangeConnection"] = nil :: RBXScriptConnection | nil,
        ["waypointChangeConnection"] = nil :: RBXScriptConnection | nil,
        ["lookAtChangeConnection"] = nil :: RBXScriptConnection | nil,
        ["combatConnection"] = nil :: RBXScriptConnection | nil,
    }

    local npcModel = self.NPCModel :: Types.NPCModel
    
    -- listen for NPC's state changing signal
    -- every other mechanism depends on this
    connections.stateChangeConnection = self.NPCModel:GetAttributeChangedSignal("State"):Connect(function()
        
        local npcClass = npcModel:GetAttribute("Class") :: "Civilian" | "Police" | "Dock Worker" | "Dock Admin" | "Cartel"
        local playerToTrack = if npcModel:GetAttribute("playerToTrack") ~= nil then Players:FindFirstChild(npcModel:GetAttribute("playerToTrack")) else nil :: Player | nil
        local charToTrack = if playerToTrack then playerToTrack.Character else nil :: Types.Character
        local newState = npcModel:GetAttribute("State")

        UpdateIndicator(self, newState)
        
        if promises.statePromise then
            promises.statePromise:cancel()
        end
        
        promises.statePromise = Promise.new(function(resolve, reject, onCancel)
            
            if onCancel(function()
                promises.statePromise:cancel()
            end) then
                return
            end
            
            local nextWaypoint
            
            if newState == "Safe" then
                npcModel:SetAttribute("playerToTrack", nil)
                npcModel:SetAttribute("playerToLookAt", nil)
                
            elseif newState == "Curious" then
                npcModel:SetAttribute("playerToLookAt", playerToTrack.Name)
                
            elseif newState == "Suspicious" then
                if npcModel:GetAttribute("playerToLookAt") ~= playerToTrack.Name then
                    npcModel:SetAttribute("playerToLookAt", playerToTrack.Name)
                end
                nextWaypoint = determineNextWaypoint(npcModel, charToTrack.HumanoidRootPart, npcModel:GetAttribute("compromised"))
                
            elseif newState == "Alert" then
                npcModel:SetAttribute("compromised", true)
                if promises.movePromise ~= nil and promises.movePromise:getStatus() ~= "Started" then
                    promises.movePromise:cancel()
                    task.wait(1)
                end
                if npcClass == "Police" or npcClass == "Cartel" then
                    nextWaypoint = determineNextWaypoint(npcModel, charToTrack.HumanoidRootPart, npcModel:GetAttribute("compromised"))
                    
                    if promises.combatPromise ~= nil and promises.combatPromise:getStatus() == "Started" then
                        promises.combatPromise:cancel()
                    end
                    
                    promises.combatPromise = Combat(self, playerToTrack)
                    
                    task.delay(2, function()
                        if npcModel.Humanoid.Health > 0 then
                            npcModel:SetAttribute("playerToLookAt", nil)
                            npcModel:SetAttribute("State", "Hostile")
                        end
                    end)
                else
                    nextWaypoint = determineNextWaypoint(npcModel, nil, true)
                    
                    task.delay(5, function()
                        if npcModel.Humanoid.Health > 0 then
                            -- TODO: Signal: call 911
                            npcModel:SetAttribute("playerToLookAt", nil)
                            npcModel:SetAttribute("State", "Hostile")
                            -- TODO: Signal: total compromised
                        end
                    end)
                    
                end
                
                
            elseif newState == "Hostile" then
                npcModel:SetAttribute("compromised", true)
                if promises.movePromise ~= nil and promises.movePromise:getStatus() ~= "Started" then
                    promises.movePromise:cancel()
                    task.wait(1)
                end
                if npcClass == "Police" or npcClass == "Cartel" then
                    nextWaypoint = determineNextWaypoint(npcModel, charToTrack.HumanoidRootPart, npcModel:GetAttribute("compromised"))
                    
                    if promises.combatPromise ~= nil and promises.combatPromise:getStatus() ~= "Started" then
                        promises.combatPromise = Combat(self, playerToTrack)
                    end

                else
                    nextWaypoint = determineNextWaypoint(npcModel, nil, true)
                    
                end
                
            end
             
            if nextWaypoint then
                npcModel:SetAttribute("NextWaypointToken", nextWaypoint)
            end
            
            resolve()
        end)
        
    end)
    
	-- listen for NPC's next waypoint changing signal
    connections.waypointChangeConnection = npcModel:GetAttributeChangedSignal("NextWaypointToken"):Connect(function()  
        
        local waypoint = findWaypointGivenToken(npcModel:GetAttribute("NextWaypointToken")):: Types.Waypoint | nil
        
        if waypoint == nil then
            return
        end
        
        -- cancel any previous promises.movePromise
        if promises.movePromise ~= nil and promises.movePromise:getStatus() == "Started" then
            promises.movePromise:cancel()
        end
        
        -- create new promises.movePromise
        promises.movePromise = Promise.new(function(resolve, reject, onCancel)
            
            local function computePath()
                task.delay(math.random(1, 5), function()
                    local nextWaypoint = determineNextWaypoint(npcModel, nil, npcModel:GetAttribute("compromised"))
                    npcModel:SetAttribute("NextWaypointToken", nextWaypoint)
                end)
                resolve()
            end
            
            promises.innerMovePromise = Move(self, waypoint):catch(function()
                task.wait(4)
                computePath()
            end)
            
            -- if cancelled, cancel promises.innerMovePromise
            if onCancel(function()
                promises.innerMovePromise:cancel()
            end) then
                return
            end
            
            -- catch path rejections
            promises.innerMovePromise:catch(function()
                task.wait(4)
                computePath()
            end)
            
            -- wait for it to resolve
            promises.innerMovePromise:andThen(computePath, computePath)
            
            
        end)
        
    end)
	
    -- listen for NPC's turn head signal
    connections.lookAtChangeConnection = npcModel:GetAttributeChangedSignal("playerToLookAt"):Connect(function()
        local targetPlayer = 
            if npcModel:GetAttribute("playerToLookAt") ~= nil then 
             Players:FindFirstChild(npcModel:GetAttribute("playerToLookAt")) 
            else 
                nil 
            :: Player | nil
        
        -- cancel any previous promises.lookPromise
        if promises.lookPromise ~= nil and self.PlayerCurrentlyBeingTracked ~= targetPlayer then
            promises.lookPromise:cancel()
        end
        
        -- set new player to track
        self.PlayerCurrentlyBeingTracked = targetPlayer
        
        -- create new promises.lookPromise
        if self.PlayerCurrentlyBeingTracked ~= nil then
            promises.lookPromise = Promise.new(function(resolve, reject, onCancel)
                
                promises.innerLookPromise = HeadTrackPlayer(self, self.PlayerCurrentlyBeingTracked)
                
                if onCancel(function()
                    promises.innerLookPromise:cancel()
                end) then
                    return
                end
                
                promises.innerLookPromise:await()
                
            end)
                
        end
        
    end) 
    
    -- listen for death
    npcModel.Humanoid.Died:Connect(function()
        ragdollOnDeath(npcModel)
        disconnectAllPromises(promises)
        UpdateIndicator(self, "Safe")
        disconnectAllConnections(connections)
    end)
    
    -- listen for NPC's parent changing signal
    npcModel.AncestryChanged:Connect(function()
        UpdateIndicator(self, "Safe")
        disconnectAllPromises(promises)
        CollectionService:RemoveTag(npcModel, TAG_NAME)
        if not npcModel:IsDescendantOf(workspace) then
        disconnectAllConnections(connections)
        end
    end)
    
    -- initialize move
    task.spawn(function()
        local nextWaypointToken = determineNextWaypoint(npcModel, nil, npcModel:GetAttribute("compromised"))
        local waypoint = findWaypointGivenToken(nextWaypointToken) :: Types.Waypoint | nil
        if waypoint == nil then return end
        npcModel:PivotTo(waypoint:GetPivot())
        task.wait(0.5)
        nextWaypointToken = determineNextWaypoint(npcModel, nil, npcModel:GetAttribute("compromised"))
        npcModel:SetAttribute("NextWaypointToken", nextWaypointToken)
    end)
    
end

return NPC
