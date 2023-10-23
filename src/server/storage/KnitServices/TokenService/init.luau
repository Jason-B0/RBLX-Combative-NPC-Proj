local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local TokenService = Knit.CreateService({
	Name = "TokenService",
})

function TokenService:GenerateToken(abbreviation: string?): string
	local token = tostring((math.random(0, tick()) + tonumber(tostring(os.time()):reverse():sub(1, 10)) :: number))
	
	if abbreviation then
		return abbreviation .. token
	end
	
	return token
end

function TokenService:KnitInit() end

function TokenService:KnitStart() end

return TokenService
