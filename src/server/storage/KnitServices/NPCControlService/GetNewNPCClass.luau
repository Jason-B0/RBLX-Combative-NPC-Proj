return function(npcClass: string?)
	
	--// if a specific NPC class is specified, create that specific NPC class.
	if npcClass ~= nil then
		return npcClass
	end
	
	--// otherwise, generate a random class
	local class

	local random = math.random(1,100)

	if random == 5 then
		class = "Police"

	elseif random > 40 and random % 2 == 0 then
		class = "Dock Worker"

	elseif random == 45 or random == 55 then
		class = "Cartel"

	elseif random == 75 then
		class = "Dock Admin"

	else
		class = "Civilian"
	end
	
	return class
end