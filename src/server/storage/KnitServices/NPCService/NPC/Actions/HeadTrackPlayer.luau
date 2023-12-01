local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)

local UPDATE_SPEED = 0.4
local HEAD_HORIZONTAL_FACTOR = 0.9
local HEAD_VERTICLE_FACTOR = 0.7
local DETECTION_DISTANCE = {
	DAY_OUTDOOR = 100,
	NIGHT_OUTDOOR = 50,
	BRIGHT_INDOOR = 70,
	DARK_INDOOR = 10,
}

return function(self, player: Player)
	local npcHead = self.NPCModel.Head :: BasePart
	local npcNeck = self.NPCModel.Torso.Neck :: Motor6D
	local npcHrp = self.NPCModel.HumanoidRootPart :: BasePart
	local stateIndicator = self.NPCModel.StateBillboard.StateIndicator :: ImageLabel
	local npcNeckDefaultC0 = CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0)
	
	local function lookAt(neckC0: CFrame)
		npcNeck.C0 = npcNeck.C0:Lerp(neckC0, UPDATE_SPEED / 2)
	end
	
	return Promise.new(function(resolve, reject, onCancel)
		local resume = true
		
		task.spawn(function()
			while player ~= nil and resume do
				stateIndicator.Visible = true
				local plrCharacter = player.Character
				if plrCharacter then
					local plrHead = plrCharacter:FindFirstChild("Head") :: BasePart
					-- look at player
					local dist = (npcHead.CFrame.Position - plrHead.CFrame.Position).Magnitude
					local diff = npcHead.CFrame.Y - plrHead.CFrame.Y

					if dist > DETECTION_DISTANCE[self.NPCModel:GetAttribute("DetectionDistance")] then
						break
					end
					
					lookAt(
						npcNeckDefaultC0 *
						CFrame.Angles(
							(math.atan(diff / dist) * HEAD_VERTICLE_FACTOR),
							0,
							((
								(npcHead.CFrame.Position - plrHead.CFrame.Position).Unit
							):Cross(npcHrp.CFrame.LookVector)).Y * HEAD_HORIZONTAL_FACTOR))
							
					if onCancel() then
						stateIndicator.Visible = false
						task.spawn(function()
							lookAt(npcNeckDefaultC0)
						end)
						break
					end
				end
				
				task.wait()
			end
		end)
		
	end)
	
end