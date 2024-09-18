local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)

local NPCService
local ClientNPCController = Knit.CreateController({
    Name = "ClientNPCController",

    NPC_TAG_NAME = "NPC",
    IGNORED_TEAM_COLOR = BrickColor.new("Maroon"),
    NPCs = {},
    
    REGIONS = {} :: Region,
    
    npcsInFOV = {},
})

local LocalPlayer = Players.LocalPlayer
local Character

type Region = {
    name: string,
    restriction: string,
    region: Region3,
}

--============ HELPER =====================
local Helper = script.Helper
local determineNPCAggroState = require(Helper.DetermineNPCAggroState)
local npcIsInDetectionRange = require(Helper.NPCIsInDetectionRange)
local locationState = require(Helper.LocationState)
local operationState = require(Helper.OperationState)

--==========================================
function ClientNPCController:SetOperationState(state: string)
    operationState:set(state)
end

function ClientNPCController:Render()
    local torso = Character:WaitForChild("Torso") :: BasePart
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Include
    overlapParams.MaxParts = 5
    overlapParams.FilterDescendantsInstances = {torso}
    
    RunService:BindToRenderStep("Detection", Enum.RenderPriority.Camera.Value, function()
        -- Ignore if player is on the ignored team color
        if LocalPlayer.TeamColor == ClientNPCController.IGNORED_TEAM_COLOR then
            if operationState:get() ~= "Safe" or locationState:get() ~= "Safe" then
                locationState:set("Safe")
                operationState:set("Safe")
            end
            
            return
        end
        
        --===== UPDATE LOCATION =====
        for _, region: Region in (self.REGIONS) do
            local partsInRegion = workspace:GetPartBoundsInBox(region.region.CFrame, region.region.Size, overlapParams)
            if #partsInRegion > 0 then
                if LocalPlayer:GetAttribute("disguisedForRegion") ~= region.restriction then
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
                local npcInFOV = npcIsInDetectionRange(npcModel, false)
                
                -- initiate if NPC is in FOV
                if npcInFOV == true then
                    
                    -- if NPC is not already in the table, add it to the table
                    if (not self.npcsInFOV[npcTag]) then
                        self.npcsInFOV[npcTag] = npcModel
                    end
    
                    -- update aggro state if it is not the same as the goal aggro state, e.g. it is elevated
                    if self.npcsInFOV[npcTag]:GetAttribute("State") ~= goalAggroState then
                        NPCService:AggrovateNPC(npcTag, goalAggroState)
                    end
                    
                -- if NPC is no longer in FOV, or it is dead, and it is in table, remove it from the table
                elseif 
                    (npcInFOV ~= true and self.npcsInFOV[npcTag] ~= nil) or (npcModel.Humanoid.Health <= 0)
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
    
end

--==========================================
function ClientNPCController:KnitInit()
    -- wait for character to load
    if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
    Character = LocalPlayer.Character
        
    -- set up regions
    for _, regionPart: BasePart in pairs(workspace:FindFirstChild("Regions"):GetChildren()) do
        local regionName = regionPart:GetAttribute("RegionName") :: string
        local regionSize = regionPart.Size
        local regionPos = regionPart.Position
        local regionRestriction = regionPart:GetAttribute("RegionRestriction") :: string  
         
        self.REGIONS[#self.REGIONS+1] = {
            name = regionName,
            restriction = regionRestriction,
            region = Region3.new(regionPos - regionSize/2, regionPos + regionSize/2),
        }
    end
    
end

function ClientNPCController:KnitStart()
    
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
        
    ClientNPCController:Render()
    
end

return ClientNPCController
