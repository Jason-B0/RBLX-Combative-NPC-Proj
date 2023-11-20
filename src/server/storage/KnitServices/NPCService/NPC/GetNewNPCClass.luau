return function(npcClass: string?): string
	
	--// if a specific NPC class is specified, create that specific NPC class.
	if npcClass ~= nil then
		return npcClass
	end
	
	--// otherwise, generate a random class
	local class

	local random = math.random(1,50)

	-- random in range 5-10 is a Police
	-- random in range 20-25 is a Dock Worker
	-- random in range 40-43 is a Cartel
	-- random in range 46-50 is a Dock Admin
	-- otherwise is a Civilian
	if random >= 5 and random <= 10 then
		class = "Police"
	elseif random >= 20 and random <= 25 then
		class = "Dock Worker"
	elseif random >= 40 and random <= 43 then
		class = "Cartel"
	elseif random >= 46 and random <= 50 then
		class = "Dock Admin"
	else
		class = "Civilian"
	end
	
	return class :: string
end