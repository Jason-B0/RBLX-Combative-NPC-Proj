local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

local function restoreDefaultCollisionGroup(_npcModel: Types.NPCModel)
	for _, v in pairs(_npcModel:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CollisionGroup = "Default"
		end
	end
end

local function selectRandomLimb(npcModel: Types.NPCModel)
	local limbs = {
		npcModel["Right Arm"],
		npcModel["Left Arm"],
		npcModel["Head"],
	}
	return limbs[math.random(1, #limbs)]
end

return function(npcModel: Types.NPCModel)
    for _, joint in pairs(npcModel:GetDescendants()) do
		if joint:IsA("Motor6D") then
			local socket = Instance.new("BallSocketConstraint")
			local a1 = Instance.new("Attachment")
			local a2 = Instance.new("Attachment")
			a1.Parent = joint.Part0
			a2.Parent = joint.Part1
			socket.Parent = joint.Parent
			socket.Attachment0 = a1
			socket.Attachment1 = a2
			a1.CFrame = joint.C0
			a2.CFrame = joint.C1
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			joint:Destroy()
		end
	end
	local part = selectRandomLimb(npcModel)
	part.CustomPhysicalProperties = PhysicalProperties.new(5, 0.3, 0.5)
	task.delay(3, function()
		part.CustomPhysicalProperties = PhysicalProperties.new(0.2, 0.3, 0.5)
	end)
	restoreDefaultCollisionGroup(npcModel)
end