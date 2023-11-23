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
    
    REGIONS = {},
    
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

local determineNPCAggroState = require(script.DetermineNPCAggroState)
local npcIsInDetectionRange = require(script.NPCIsInDetectionRange)
local locationState = require(script.LocationState)
local operationState = require(script.OperationState)

--==========================================

function DetectionController:Render()
    local torso = Character:WaitForChild("Torso") :: BasePart
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Whitelist
    overlapParams.MaxParts = 5
    overlapParams.FilterDescendantsInstances = {torso}
    
    RunService:BindToRenderStep("Detection", Enum.RenderPriority.Camera.Value, function()
        
        -- Ignore if player is on the ignored team color
        if LocalPlayer.TeamColor == DetectionController.IGNORED_TEAM_COLOR then
            
            if not operationState:get() == "Safe" or not locationState:get() == "Safe" then
                locationState:set("Safe")
                operationState:set("Safe")
            end
            
            return
        end
        
        --===== UPDATE LOCATION =====
        for regionName, regionBounds: Region3 in (self.REGIONS) do
            local partsInRegion = workspace:GetPartBoundsInBox(regionBounds.CFrame, regionBounds.Size, overlapParams)
            if #partsInRegion > 0 then
                if LocalPlayer:GetAttribute("disguisedForRegion") ~= regionName then
                    locationState:set("Trespassing")
                    break
                else
                    locationState:set("Safe")
                end
            else
                locationState:set("Safe")
            end
        end
        
        --=== UPDATE AGGRO STATE ===
        local goalAggroState = determineNPCAggroState()
            
        if goalAggroState ~= "Safe" then
            for _, npcModel in pairs(self.NPCs) do
            
                local npcTag = npcModel:GetAttribute("Tag")
                local npcInFOV = npcIsInDetectionRange(npcModel)
                
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
            local toolType = child:GetAttribute("ToolType") :: string
            
            if toolType == "Gun" then
                operationState:set("Armed")
            elseif toolType == "Misc" then
                operationState:set("Abnormal Action")
            else
                operationState:set("Safe")
            end

        end
    end)
    
    Character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            operationState:set("Safe")
        end
    end)

    -- firing shots
    LocalPlayer:GetAttributeChangedSignal("shotsFired"):Connect(function()
        if LocalPlayer:GetAttribute("shotsFired") == true then
            operationState:set("Compromised")
        end
    end)
    
    -- removing character, which unbinds render step
    LocalPlayer.CharacterRemoving:Connect(function()
        RunService:UnbindFromRenderStep("Detection")
    end)
    
    -- disguise
    LocalPlayer:GetAttributeChangedSignal("disguisedForRegion"):Connect(function()
        if LocalPlayer:GetAttribute("disguisedForRegion") ~= "" then
            locationState:set("Safe")
        end
    end)
    
    -- proximity prompt
    ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
        if prompt.Name == "NPCPrompt" then
            operationState:set("Illegal Action")
        end
    end)
    
    ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt, player)
        if prompt.Name == "NPCPrompt" then
            operationState:set("Safe")
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
