local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Knit = require(ReplicatedStorage.Packages.Knit)

local OperationState = {}
local PlayerStateService

task.spawn(function()
    Knit.OnStart():await():andThen(function()
        PlayerStateService = Knit.GetService("PlayerStateService")
    end)
end)

function OperationState:set(newState: string?)
    if not Knit.OnStart() then Knit.OnStart():await() end
    
    if newState ~= nil then
        PlayerStateService:UpdatePlayerState(LocalPlayer, "operationState", newState)
    else
        PlayerStateService:UpdatePlayerState(LocalPlayer, "operationState", "Safe")
    end
end

function OperationState:get(): string
    return LocalPlayer:GetAttribute("operationState")
end

return OperationState