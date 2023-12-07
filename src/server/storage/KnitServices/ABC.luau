for _, player in pairs(game:GetService("Players"):GetPlayers()) do
	if player then
		player:SetAttribute("disguisedForRegion", "Dock")
		print(player:GetAttribute("disguisedForRegion"))
	end
end