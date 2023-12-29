local Knit = require(game:GetService('ReplicatedStorage').Packages.Knit)
local Players = game:GetService('Players')

local PlayerStateService = Knit.CreateService({
	Name = 'PlayerStateService',
	Client = {},
})

--============ CONFIG =====================
local PLAYER_ATTRIBUTES = {
    locationState = "Safe",
    operationState = "Safe",
    disguisedForRegion = " ",
}

--============ HELPER =====================
local function setupAttributes(player: Player)
    for i, v in pairs(PLAYER_ATTRIBUTES) do
        player:SetAttribute(i, v)
    end
end

for i, v in pairs(game:GetService("Players"):GetPlayers()) do
	
	v:SetAttribute("disguisedForRegion", "Dock")
end

--==========================================
function PlayerStateService.Client:UpdatePlayerState(player: Player, key: string, value: any)
	return self.Server:UpdatePlayerState(player, key, value)
end

function PlayerStateService:UpdatePlayerState(player: Player, key: string, value: any)
	local localPlayer = Players:GetPlayerByUserId(player.UserId)
	if localPlayer then
		localPlayer:SetAttribute(key, value)
	end
end

function PlayerStateService:KnitInit() end

function PlayerStateService:KnitStart()
	
	-- get current players and set up attributes
	for _, player in pairs(Players:GetPlayers()) do
		setupAttributes(player)
	end
	
	Players.PlayerAdded:Connect(setupAttributes)
end

return PlayerStateService