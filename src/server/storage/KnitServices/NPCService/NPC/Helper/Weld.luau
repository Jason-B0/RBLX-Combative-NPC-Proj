--!strict
return {
	
	weld = function(p1: BasePart, p2: BasePart, c0: CFrame?, c1: CFrame?)
		local newWeld = Instance.new("Motor6D", p1)
		newWeld.Part0 = p1
		newWeld.Part1 = p2
		newWeld.Name = p2.Name
		newWeld.C0 = c0 or CFrame.new()
		newWeld.C1 = c1 or p1.CFrame:Inverse() * p2.CFrame
		return newWeld
	end;

	motor6D = function(x: BasePart, y: BasePart, motorName: string?, targetC1: CFrame?)
		local newMotor = Instance.new("Motor6D")
		newMotor.Name = motorName or y.Name
		newMotor.Part0 = x
		newMotor.Part1 = y
		local cJoint = CFrame.new(x.Position)
		local c0 = x.CFrame:Inverse() * cJoint
		local c1 = y.CFrame:Inverse() * cJoint
		newMotor.C0 = c0
		newMotor.C1 = targetC1 or c1
		newMotor.Parent = x
		return newMotor
	end
}