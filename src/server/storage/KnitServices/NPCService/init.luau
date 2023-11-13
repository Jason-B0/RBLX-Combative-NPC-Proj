--[[

]]

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Types = require(ReplicatedStorage.Shared.Types)

local NPCService = Knit.CreateService({
    Name = "NPCService",

    TAG_NAME = "NPC",
    npcs = {}
})

local NPCControlService
--=================================
function NPCService:Aggrovate(npc: Types.NPC, aggrovationMode: string)
    assert(
        aggrovationMode == "calm"
            or aggrovationMode == "curious"
            or aggrovationMode == "suspicious"
            or aggrovationMode == "alert",
        "Invalid aggrovation mode!"
    )
    
    
end

function NPCService:ActivateNPC(npc: Types.NPC)
    local npcType = npc.NPCType.Value
    local npcModel = npc.NPCModel.Value

    local npcControl = NPCControlService:CreateNPC(npcModel, npcType)
    npcControl:Activate()
end
--=================================
function NPCService:KnitStart()
    for _, npc: Types.NPC in pairs(CollectionService:GetTagged(self.TAG_NAME)) do
        if npc:FindFirstChildOfClass("Humanoid") then
            self:ActivateNPC(npc)
        end
    end

    CollectionService:GetInstanceAddedSignal(self.TAG_NAME):Connect(function(npc: Types.NPC)
        assert(npc:FindFirstChildOfClass("Humanoid"), "NPC does not have a humanoid!")
        self:ActivateNPC(npc)
    end)
end

function NPCService:KnitInit() end

return NPCService
