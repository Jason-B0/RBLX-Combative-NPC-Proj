local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)

local NPCService
local DetectionController = Knit.CreateController({
    Name = "DetectionController",

    NPC_TAG_NAME = "NPC",
    NPCs = {},
    
    DETECTION_DISTANCE = {
        DAY_OUTDOOR = 100,
        NIGHT_OUTDOOR = 50,
        BRIGHT_INDOOR = 70,
        DARK_INDOOR = 10,
    },
    
    REGIONS = {},
    
    NPC_FOV = 60,

    IGNORED_TEAM_COLOR = BrickColor.new("Crimson"),
    
    npcsInFOV = {},
})

local Character

--============ CONFIG =====================
local PLAYER_ATTRIBUTES = {
    
    locationState = "Safe" :: "Safe" | "Trespassing" | "Restricted" | "Hostile Area",
    operationState = "Safe" :: "Safe" | "Abnormal Action" | "Illegal Action" | "Armed" | "Compromised",
    disguisedForRegion = "",
    armed = false,
    shotsFired = false,
    
}
--============ HELPER =====================

--[[ 
    Detects if the an NPC in a given range is able to see the player.
    Returns the nearest NPC and the distance between the player and the NPC
]]
local function npcCanSeePlayer(npc: Types.NPCModel, disregardFOV: boolean?): boolean
    
    local function isInFieldOfView(unit: Vector3)
        local npcLook: Vector3 = npc.HumanoidRootPart.CFrame.LookVector
        local dotProd: number = unit:Dot(npcLook)
        local angle: number = math.deg(math.acos(dotProd))
        
        if angle <= DetectionController.NPC_FOV then
            return true
        end
        return false
    end
    
    local function checkLineOfSight(
        charModel: Model | Types.NPCModel,
        start: Vector3,
        targ: Vector3
    ): (boolean, number | nil)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances =
            { charModel, LocalPlayer.Character }
        local result = workspace:Raycast(start, targ - start, raycastParams)
        
        if result ~= nil then
            if result.Instance.Parent == charModel then
                return true
            end
            return false
        end
        return true
    end

    -- ignore if the player is an admin
    if LocalPlayer.TeamColor == DetectionController.IGNORED_TEAM_COLOR then
        return
    end
    
    local npcInRange, distanceInBetween = false, nil
    local distance = DetectionController.DETECTION_DISTANCE[npc:GetAttribute("DetectionDistance")]
    local humanoid: Humanoid, humanoidRootPart: BasePart

    humanoid = npc.Humanoid
    humanoidRootPart = npc.HumanoidRootPart
    
    if (humanoid.Health > 0) then
        local diff: Vector3 =  Character.HumanoidRootPart.Position - humanoidRootPart.Position
        local diffMagnitude: number = diff.Magnitude
        local diffUnit: Vector3 = diff.Unit
        
        if disregardFOV == true and diffMagnitude <= 150 then
            npcInRange = true
        elseif diffMagnitude <= distance then
            local isInFOV = isInFieldOfView(diffUnit)
            local hasLineOfSight = checkLineOfSight(npc, npc.Head.Position, Character.HumanoidRootPart.Position)
            if ( 
                    isInFOV and 
                    hasLineOfSight and 
                    (distanceInBetween == nil or (distanceInBetween ~= nil and diffMagnitude < distanceInBetween)) 
                )
            then
                npcInRange = true
                distanceInBetween = diffMagnitude
            end
        end
    end

    return npcInRange
    
end


--==========================================
local function determineNPCAggroState(): string
    local locationState = LocalPlayer:GetAttribute("locationState")
    local operationState = LocalPlayer:GetAttribute("operationState")
    local npcAggroState = ""
    
    if locationState == "Safe" then
        
        if operationState == "Safe" then
            npcAggroState = "Safe"
            
        elseif operationState == "Abnormal Action" then
            npcAggroState = "Curious"
            
        elseif operationState == "Illegal Action" then
            npcAggroState = "Suspicious"
            
        elseif operationState == "Armed" then
            npcAggroState = "Alert"

        elseif operationState == "Compromised" then
            npcAggroState = "Hostile"
            
        end
        
    elseif locationState == "Trespassing" then
        
        if operationState == "Safe" then
            npcAggroState = "Curious"
            
        elseif operationState == "Abnormal Action" then
            npcAggroState = "Suspicious"
            
        elseif operationState == "Illegal Action" then
            npcAggroState = "Alert"
            
        elseif operationState == "Armed" then
            npcAggroState = "Hostile"

        elseif operationState == "Compromised" then
            npcAggroState = "Hostile"
            
        end
    
    elseif locationState == "Restricted" then
        
        if operationState == "Safe" then
            npcAggroState = "Suspicious"
            
        elseif operationState == "Abnormal Action" then
            npcAggroState = "Alert"
            
        elseif operationState == "Illegal Action" then
            npcAggroState = "Alert"
            
        elseif operationState == "Armed" then
            npcAggroState = "Hostile"
            
        elseif operationState == "Compromised" then
            npcAggroState = "Hostile"
            
        end
   
    elseif locationState == "Hostile Area" then
        
        if operationState == "Safe" then
            npcAggroState = "Hostile"
            
        elseif operationState == "Abnormal Action" then
            npcAggroState = "Hostile"
            
        elseif operationState == "Illegal Action" then
            npcAggroState = "Hostile"
            
        elseif operationState == "Armed" then
            npcAggroState = "Hostile"
            
        elseif operationState == "Compromised" then
            npcAggroState = "Hostile"
            
        end
        
    end
    
    return npcAggroState
end

function DetectionController:Render()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local torso = character:WaitForChild("Torso") :: BasePart
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Whitelist
    overlapParams.MaxParts = 5
    overlapParams.FilterDescendantsInstances = {torso}
    
    local function updateState()
        local locationState = LocalPlayer:GetAttribute("locationState")
        local operationState = LocalPlayer:GetAttribute("operationState")
        
        -- if player is completely safe, and they are not compromised, then all NPCs are removed from the table
        
        if locationState == "Safe" and operationState == "Safe" then
            for _, npcModel in pairs(self.npcsInFOV) do
                if npcModel:GetAttribute("State") == "Alert" or npcModel:GetAttribute("State") == "Hostile" then
                    return
                end
            end
        end
    end
    
    --===== UPDATE OPERATION STATE =====
    LocalPlayer.Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and child:GetAttribute("ToolType") == "Gun" then
            LocalPlayer:SetAttribute("operationState", "Armed")
        end
    end)
    
    LocalPlayer:GetAttributeChangedSignal("shotsFired"):Connect(function()
        if LocalPlayer:GetAttribute("shotsFired") == true then
            LocalPlayer:SetAttribute("operationState", "Compromised")
        end
    end)
    
    LocalPlayer:GetAttributeChangedSignal("locationState"):Connect(updateState)
    LocalPlayer:GetAttributeChangedSignal("operationState"):Connect(updateState)
    
    RunService:BindToRenderStep("Detection", Enum.RenderPriority.Camera.Value, function()
        
        --===== UPDATE LOCATION =====
        for regionName, regionBounds: Region3 in (self.REGIONS) do
            local partsInRegion = workspace:GetPartBoundsInBox(regionBounds.CFrame, regionBounds.Size, overlapParams)
            if #partsInRegion > 0 then
                if LocalPlayer:GetAttribute("disguisedForRegion") ~= regionName then
                    LocalPlayer:SetAttribute("locationState", "Trespassing")
                    break
                else
                    LocalPlayer:SetAttribute("locationState", "Safe")
                end
            else
                LocalPlayer:SetAttribute("locationState", "Safe")
            end
        end
        
        
        
        --=== UPDATE AGGRO STATE ===
        local goalAggroState = determineNPCAggroState()
        
        if goalAggroState ~= "Safe" then
            for _, npcModel in pairs(self.NPCs) do
            
                local npcInFOV = npcCanSeePlayer(npcModel)
                            
                -- if NPC is in range and not already in the table, add it to the table
                if npcInFOV == true then
                    
                    -- if NPC is not already in the table, add it to the table
                    if (not self.npcsInFOV[npcModel:GetAttribute("Tag")]) then
                        self.npcsInFOV[npcModel:GetAttribute("Tag")] = npcModel
                    end
    
                    -- update aggro state if it is not the same as the goal aggro state, e.g. it is elevated
                    if self.npcsInFOV[npcModel:GetAttribute("Tag")]:GetAttribute("State") ~= goalAggroState then
                        NPCService:AggrovateNPC(npcModel:GetAttribute("Tag"), goalAggroState)
                    end
                    
                -- if NPC is no longer in FOV, and it is in table, remove it from the table
                elseif npcInFOV ~= true and self.npcsInFOV[npcModel:GetAttribute("Tag")] ~= nil then
                    
                    if self.npcsInFOV[npcModel:GetAttribute("Tag")]:GetAttribute("State") ~= "Hostile" 
                    and self.npcsInFOV[npcModel:GetAttribute("Tag")]:GetAttribute("State") ~= "Alert" 
                    then
                        self.npcsInFOV[npcModel:GetAttribute("Tag")] = nil
                        NPCService:AggrovateNPC(npcModel:GetAttribute("Tag"), "Safe")
                    end 
                    
                end
                
            end
        end
        
        
    end)
    
    
end

--==========================================
function DetectionController:KnitInit()
    if not LocalPlayer.Character then
        Character = LocalPlayer.CharacterAdded:Wait()
    else
        Character = LocalPlayer.Character
    end
    
    self.REGIONS = {}
    
    for _, region: BasePart in pairs(workspace:FindFirstChild("Regions"):GetChildren()) do
        self.REGIONS[region.Name] = Region3.new(region.Position - region.Size/2, region.Position + region.Size/2)
    end
    
end

function DetectionController:KnitStart()
    -- Initialize service
    NPCService = Knit.GetService("NPCService")
    
    for _, npcModel: Model in pairs(CollectionService:GetTagged(self.NPC_TAG_NAME)) do
        if npcModel:FindFirstChildOfClass("Humanoid") then
            self.NPCs[npcModel:GetAttribute("Tag")] = npcModel
        end
    end

    CollectionService:GetInstanceAddedSignal(self.NPC_TAG_NAME):Connect(function(npcModel: Model)
        assert(npcModel:FindFirstChildOfClass("Humanoid"), "NPC does not have a humanoid!")
        self.NPCs[npcModel:GetAttribute("Tag")] = npcModel
    end)
    
    for i, v in pairs(PLAYER_ATTRIBUTES) do
        LocalPlayer:SetAttribute(tostring(i), v)
    end
    
    DetectionController:Render()
end

return DetectionController
