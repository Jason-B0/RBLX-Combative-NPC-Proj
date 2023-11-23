local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
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

local LocalPlayer = Players.LocalPlayer
local Character

--============ CONFIG =====================
local PLAYER_ATTRIBUTES = {
    
    locationState = "Safe" :: "Safe" | "Trespassing" | "Restricted" | "Hostile Area",
    operationState = "Safe" :: "Safe" | "Abnormal Action" | "Illegal Action" | "Armed" | "Compromised",
    disguisedForRegion = "",
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
            { charModel, Character }
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
local function updateOperationState(newState: string?)
    if newState ~= nil then
        LocalPlayer:SetAttribute("operationState", newState)
    else
        LocalPlayer:SetAttribute("operationState", "Safe")
    end
end

local function updateLocationState(newState: string?)
    if newState ~= nil then
        LocalPlayer:SetAttribute("locationState", newState)
    else
        LocalPlayer:SetAttribute("locationState", "Safe")
    end
end

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
    local torso = Character:WaitForChild("Torso") :: BasePart
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Whitelist
    overlapParams.MaxParts = 5
    overlapParams.FilterDescendantsInstances = {torso}
    
    RunService:BindToRenderStep("Detection", Enum.RenderPriority.Camera.Value, function()
        
        --===== UPDATE LOCATION =====
        for regionName, regionBounds: Region3 in (self.REGIONS) do
            local partsInRegion = workspace:GetPartBoundsInBox(regionBounds.CFrame, regionBounds.Size, overlapParams)
            if #partsInRegion > 0 then
                if LocalPlayer:GetAttribute("disguisedForRegion") ~= regionName then
                    updateLocationState("Trespassing")
                    break
                else
                    updateLocationState("Safe")
                end
            else
                updateLocationState("Safe")
            end
        end
        
        --=== UPDATE AGGRO STATE ===
        local goalAggroState = determineNPCAggroState()
            
        if goalAggroState ~= "Safe" then
            for _, npcModel in pairs(self.NPCs) do
            
                local npcTag = npcModel:GetAttribute("Tag")
                local npcInFOV = npcCanSeePlayer(npcModel)
                
                -- if NPC is in FOV and not already in the table, add it to the table
                if npcInFOV == true then
                    
                    -- if NPC is not already in the table, add it to the table
                    if (not self.npcsInFOV[npcTag]) then
                        self.npcsInFOV[npcTag] = npcModel
                    end
    
                    -- update aggro state if it is not the same as the goal aggro state, e.g. it is elevated
                    if self.npcsInFOV[npcTag]:GetAttribute("State") ~= goalAggroState then
                        NPCService:AggrovateNPC(npcTag, goalAggroState)
                    end
                    
                -- if NPC is no longer in FOV, and it is in table, remove it from the table
                elseif 
                    (npcInFOV ~= true and self.npcsInFOV[npcTag] ~= nil)
                then
                    
                    if self.npcsInFOV[npcTag]:GetAttribute("State") ~= "Hostile" 
                    and self.npcsInFOV[npcTag]:GetAttribute("State") ~= "Alert" 
                    then
                        self.npcsInFOV[npcTag] = nil
                        NPCService:AggrovateNPC(npcTag, "Safe")
                    end 
                    
                end
                
            end
        end
        
        
    end)
    
    --===== UPDATE OPERATION STATE AND BIND LISTENERS =====
    
    -- equipping and unequipping tool
    Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            print(child:GetAttribute("ToolType"))
            local toolType = child:GetAttribute("ToolType") :: string
            
            if toolType == "Gun" then
                updateOperationState("Armed")
            elseif toolType == "Misc" then
                updateOperationState("Abnormal Action")
            else
                updateOperationState("Safe")
            end

        end
    end)
    
    Character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            updateOperationState("Safe")
        end
    end)

    
    LocalPlayer:GetAttributeChangedSignal("shotsFired"):Connect(function()
        if LocalPlayer:GetAttribute("shotsFired") == true then
            updateOperationState("Compromised")
        end
    end)
    
    Character.Humanoid.Died:Connect(function()
        RunService:UnbindFromRenderStep("Detection")
    end)
    
    LocalPlayer:GetAttributeChangedSignal("disguisedForRegion"):Connect(function()
        if LocalPlayer:GetAttribute("disguisedForRegion") ~= "" then
            updateLocationState("Safe")
        end
    end)
    
    ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
        if prompt.Name == "NPCPrompt" then
            updateOperationState("Illegal Action")
        end
    end)
    
    ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt, player)
        if prompt.Name == "NPCPrompt" then
            updateOperationState("Safe")
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
    -- wait for character to load
    if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
    Character = LocalPlayer.Character
    
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
    
    -- wait for character to load, then set up player
    LocalPlayer.CharacterAdded:Connect(function(character)
        for i, v in pairs(PLAYER_ATTRIBUTES) do
            LocalPlayer:SetAttribute(tostring(i), v)
        end
        DetectionController:Render()
    end)
    
    -- on first start
    for i, v in pairs(PLAYER_ATTRIBUTES) do
        LocalPlayer:SetAttribute(tostring(i), v)
    end
    DetectionController:Render()
    
end

return DetectionController
