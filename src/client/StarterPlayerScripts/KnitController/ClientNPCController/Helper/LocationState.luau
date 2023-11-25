local LocalPlayer = game:GetService("Players").LocalPlayer

local LocationState = {}

function LocationState:set(newState: string?)
	if newState ~= nil then
		LocalPlayer:SetAttribute("locationState", newState)
	else
		LocalPlayer:SetAttribute("locationState", "Safe")
	end
end

function LocationState:get(): string
	return LocalPlayer:GetAttribute("locationState")
end

return LocationState