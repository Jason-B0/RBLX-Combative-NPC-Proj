local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local GiveGear = require(script.GiveGear)
local GiveTool = require(script.GiveTool)

local ProximityHandler = Knit.CreateService({
    Name = "ProximityHandler",
})

--==========================================

-- Helper function to set the transparency of the model to either 1 or the original transparency it was stored to
local function setModelTransparency(promptPart: BasePart, visible: boolean): nil
    
    local promptParent = promptPart.Parent :: Model
    
    for _, part in pairs(promptParent:GetDescendants()) do
        if part:IsA("BasePart") then
            
            part:SetAttribute("OriginalTransparency", visible == false and part.Transparency)
            
            part.Transparency = visible == false and 1 or part:GetAttribute("OriginalTransparency")
            
            if visible == true then
                part:SetAttribute("OriginalTransparency", nil)
            end
            
        end
    end
    return nil
end

function ProximityHandler:GiveItem(prompt: ProximityPrompt, player: Player)
    local itemType = prompt:GetAttribute("ItemType")
    local itemName = prompt:GetAttribute("ItemName")
    local modelRespawnTime = prompt:GetAttribute("ModelRespawnTime")
    
    if itemType == "Gear" then
        GiveGear(player, itemName)
    elseif itemType == "Tool" then
        GiveTool(player, itemName)
    end
    
    if modelRespawnTime then
        task.defer(function()
            prompt.Enabled = false
            setModelTransparency(prompt.Parent :: BasePart, false)
            task.wait(modelRespawnTime)
            setModelTransparency(prompt.Parent :: BasePart, true)
            prompt.Enabled = false
        end)
    end
    
end

--==========================================

function ProximityHandler:KnitInit() end

function ProximityHandler:KnitStart()
    ProximityPromptService.PromptTriggered:Connect(ProximityHandler.GiveItem)
end

return ProximityHandler
