--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local ToolGiverService = Knit.CreateService({
    Name = "ToolGiverService",

    TOOL_DIRECTORY = ServerStorage :: ServerStorage

})

local function validateItemExists(itemName: string): boolean
    local item = ToolGiverService.TOOL_DIRECTORY:FindFirstChild(itemName)
    return item ~= nil
end

function ToolGiverService:GiveTool(player: Player, toolName: string): Tool | nil
    if not validateItemExists(toolName) then
        warn("Item does not exist")
        return nil
    end
    
    local tool = ToolGiverService.TOOL_DIRECTORY:FindFirstChild(toolName)
    local toolClone = tool:Clone()
    toolClone.Parent = player.Backpack
    return toolClone
end
    

function ToolGiverService:KnitInit() end

function ToolGiverService:KnitStart() end

return ToolGiverService
