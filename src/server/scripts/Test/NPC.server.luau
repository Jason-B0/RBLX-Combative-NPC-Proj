local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local npcs = {}

Knit.OnStart():andThen(function()
    print("NPC pathfinding started")
    local NPCControlService = Knit.GetService("NPCControlService")
    local NPCService = Knit.GetService("NPCService")

    local function move(npc, res, msg)
        if not table.find(npcs, npc) then
            return
        end
        local random = math.random(1, 5)

        while "Part" .. random == NPCControlService:GetDestination(npc) do
            random = math.random(1, 5)
        end

        NPCControlService:MoveNPC(npc, "Part" .. random)
    end

    NPCControlService.OnDestinationReachedSignal:Connect(move)

    task.spawn(function()
        for i = 1, 5 do
            local newNPC = NPCControlService:CreateNewNPC()
            table.insert(npcs, newNPC)
            local random = math.random(1, 5)
            NPCControlService:MoveNPC(newNPC, "Part" .. random)
            task.wait(5)
        end
    end)
end)
