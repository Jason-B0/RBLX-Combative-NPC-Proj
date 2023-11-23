--[[ CONFIG ]] --

local NPC_COUNT = 1

local MOVE_ENABLED = true

--==============
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local npcs = {}

Knit.OnStart():andThen(function()
    
    if not RunService:IsStudio() then
        return
    end
    
    local NPCService = Knit.GetService("NPCService")

    task.spawn(function()
        for _ = 1, NPC_COUNT do
            local newNPC = NPCService:CreateNewNPC()
            table.insert(npcs, newNPC)
            
            task.wait(0.1)
        end
    end)
    
    
end)
