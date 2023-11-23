local LocalPlayer = game:GetService("Players").LocalPlayer

return {
	
	update = function(newState: string?)
		if newState ~= nil then
			LocalPlayer:SetAttribute("locationState", newState)
		else
			LocalPlayer:SetAttribute("locationState", "Safe")
		end
	end,
	
	get = function(): string
		return LocalPlayer:GetAttribute("locationState")
	end,
	
}