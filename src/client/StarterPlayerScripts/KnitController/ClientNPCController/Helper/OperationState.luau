local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Knit = require(ReplicatedStorage.Packages.Knit)

local OperationState = {}
local PlayerStateService

task.spawn(function()
    Knit.OnStart():andThen(function()
        PlayerStateService = Knit.GetService("PlayerStateService")
    end)
end)

function OperationState:set(newState: string?)
    if newState ~= nil then
        PlayerStateService:UpdatePlayerState("operationState", newState)
    else
        PlayerStateService:UpdatePlayerState("operationState", "Safe")
    end
end

function OperationState:get(): string
    return LocalPlayer:GetAttribute("operationState")
end

return OperationState