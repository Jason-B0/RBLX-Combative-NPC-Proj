local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Knit = require(ReplicatedStorage.Packages.Knit)

local LocationState = {}
local PlayerStateService

task.spawn(function()
    Knit.OnStart():await():andThen(function()
        PlayerStateService = Knit.GetService("PlayerStateService")
    end)
end)

function LocationState:set(newState: string?)
	if not Knit.OnStart() then Knit.OnStart():await() end
	
	if newState ~= nil then
		PlayerStateService:UpdatePlayerState(LocalPlayer, "locationState", newState)
	else
		PlayerStateService:UpdatePlayerState(LocalPlayer, "locationState", "Safe")
	end
end

function LocationState:get(): string
	return LocalPlayer:GetAttribute("locationState")
end

return LocationState