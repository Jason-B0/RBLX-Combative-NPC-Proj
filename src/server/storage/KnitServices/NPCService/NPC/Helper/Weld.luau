--!strict
local Weld = {}

function Weld:weld(p1: BasePart, p2: BasePart, motorName: string?, c0: CFrame?, c1: CFrame?)
	p1.Anchored = false
	p2.Anchored = false
	local newWeld = Instance.new("Motor6D", p1)
	newWeld.Part0 = p1
	newWeld.Part1 = p2
	newWeld.Name = motorName or p2.Name
	newWeld.C0 = c0 or CFrame.new()
	newWeld.C1 = c1 or p1.CFrame:Inverse() * p2.CFrame
	return newWeld
end

function Weld:motor6D(p1: BasePart, p2: BasePart, motorName: string?, targetC1: CFrame?)
	p1.Anchored = false
	p2.Anchored = false
	local newMotor = Instance.new("Motor6D")
	newMotor.Name = motorName or p2.Name
	newMotor.Part0 = p1
	newMotor.Part1 = p2
	local cJoint = CFrame.new(p1.Position)
	local c0 = p1.CFrame:Inverse() * cJoint
	local c1 = p2.CFrame:Inverse() * cJoint
	newMotor.C0 = c0
	newMotor.C1 = targetC1 or c1
	newMotor.Parent = p1
	return newMotor
end

return Weld