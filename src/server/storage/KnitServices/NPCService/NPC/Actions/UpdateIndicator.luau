local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)

local DETECTION_DISTANCE = {
	DAY_OUTDOOR = 100,
	NIGHT_OUTDOOR = 50,
	BRIGHT_INDOOR = 70,
	DARK_INDOOR = 10,
}

local INDICATOR_COLOR = {
	["Safe"] = Color3.fromRGB(255, 255, 255),
	["Curious"] = Color3.fromRGB(255, 255, 255),
	["Suspicious"] = Color3.fromRGB(225, 225, 0),
	["Alert"] = Color3.fromRGB(255, 170, 0),
	["Hostile"] = Color3.fromRGB(255, 0, 0),
}

return function(self, state: string)
	local stateIndicator = self.NPCModel.StateBillboard.StateIndicator :: ImageLabel
	
	if state == "Safe" then
		stateIndicator.Visible = false
	else
		stateIndicator.Visible = true
	end
	
	stateIndicator.ImageColor3 = INDICATOR_COLOR[state]
	
end