local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Knit = require(ReplicatedStorage.Packages.Knit)

local LocationState = {}
local PlayerStateService

task.spawn(function()
    Knit.OnStart():andThen(function()
        PlayerStateService = Knit.GetService("PlayerStateService")
    end)
end)

function LocationState:set(newState: string?)
	if newState ~= nil then
		PlayerStateService:UpdatePlayerState("locationState", newState)
	else
		PlayerStateService:UpdatePlayerState("locationState", "Safe")
	end
end

function LocationState:get(): string
	return LocalPlayer:GetAttribute("locationState")
end

return LocationState