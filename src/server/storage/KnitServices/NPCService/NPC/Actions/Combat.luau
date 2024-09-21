--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Engine = ReplicatedStorage.ACS_Engine :: Configuration |  Folder
local acsWorkspace = workspace.ACS_WorkSpace :: Folder
local Event = Engine.Events :: Folder
local Modules = Engine.Modules :: Folder

local Helper = script.Parent.Parent.Helper
local determineNextWaypoint = require(Helper.DetermineNextWaypoint)
local playerIsInDetectionRange = require(Helper.PlayerIsInDetectionRange)

local Promise = require(ReplicatedStorage.Packages.Promise)
local Types = require(ReplicatedStorage.Shared.Types)
local Weld = require(Helper.Weld)
local Hitmarker = require(Modules.Hitmarker)

--===============================================
local function CheckForHumanoid(npcModel: NPCModel, instance: Instance)
	local playerToTrack = Players:FindFirstChild(npcModel:GetAttribute("aggroPlayerName")) :: Player | nil
	if playerToTrack ~= nil and instance:IsDescendantOf(playerToTrack.Character) then
		return true, playerToTrack.Character.Humanoid
	end
	return false, nil
end

local function equipWeapon(weaponName: string)
	assert(ServerStorage.Asset.WeaponFolder[weaponName], 
	"Invalid weapon name: "..weaponName)
	local newWeaponTool = ServerStorage.Asset.WeaponFolder[weaponName]:Clone() :: Model
	newWeaponTool.Name = "Weapon"
	return newWeaponTool
end

local function weldWeapon(torso: BasePart, weaponTool: Types.WeaponTool)
	
	local gunModel = weaponTool.Gun :: Model
	local gunHandle = gunModel.Handle or gunModel.Grip :: BasePart
	local anim = require(weaponTool.Animation)
	
	for _, basePart in pairs(gunModel:GetDescendants()) do
		if basePart:IsA("BasePart") and basePart ~= gunHandle then
			Weld:weld(basePart, gunHandle)
		end
	end
	
	Weld:weld(torso, gunHandle, "Handle", nil, anim.GunC1)
end

local function isAlive(humanoid: Humanoid)
	return humanoid.Health > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Dead
end

local function lookAt(playerPosition: Vector3, ncpRootPart: BasePart)
	local diff = ncpRootPart.Position - playerPosition
    local angle = math.atan2(diff.X, diff.Z) -- we just want the RootPart to orientate on one axis.

    local alignOrientation = ncpRootPart:FindFirstChildOfClass("AlignOrientation")
	alignOrientation.Enabled = true
    alignOrientation.CFrame = CFrame.new(0,0,0) * CFrame.Angles(0, angle, 0)
end

--===============================================


return function(npcObject: Types.NPCObject, player: Player)
	
	local npcHead = npcObject.npcModel.Head :: BasePart
	local npcHumanoid = npcObject.npcModel.Humanoid :: Humanoid
	local npcNeck = npcObject.npcModel.Torso.Neck :: Motor6D
	local npcTorso = npcObject.npcModel.Torso :: BasePart
	local npcHrp = npcObject.npcModel.HumanoidRootPart :: BasePart
	
	-- set up weapon
	local weaponTool = equipWeapon("CZ75") :: Types.WeaponTool | Instance
	weaponTool.Parent = npcObject.npcModel
	local gunModel = weaponTool.Gun :: Model
	local gunHandle = gunModel:FindFirstChild("Handle") or gunModel:FindFirstChild("Grip") :: BasePart
	weldWeapon(npcTorso, weaponTool)
	task.wait(.5)
	local weaponRecoil = weaponTool:GetAttribute("RecoilSpread") :: number
	
	local plrCharacter = player.Character :: Types.Character | PVInstance
	local plrHumanoid = plrCharacter.Humanoid :: Humanoid

	return Promise.new(function(resolve, reject, onCancel)
		local resume = true

		local constantlyAimAtPlayer = RunService.Heartbeat:Connect(function()
			if player ~= nil and isAlive(npcHumanoid) then
				lookAt(plrCharacter.PrimaryPart.Position, npcHrp)
			end
		end)

		if onCancel() then
			resume = false
			constantlyAimAtPlayer:Disconnect()
		end

		-- loop 1: constantly aim at player and track its position
		task.spawn(function()	
			while player ~= nil and resume and isAlive(npcHumanoid) do
				-- recompute path to move towards player
				npcObject.npcModel:SetAttribute("nextWaypointToken", 
					determineNextWaypoint(
						npcObject :: Types.NPCObject, 
						plrCharacter.HumanoidRootPart
					)
				)
				task.wait(0.25)
			end
		end)

		-- loop 2: shoot at player if in range and in line of sight
		task.spawn(function()
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {npcObject.npcModel}
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.IgnoreWater = true

			while player ~= nil and resume and isAlive(npcHumanoid) do	
				-- if player isn't in detection range nor FOV then continue
				if playerIsInDetectionRange(npcObject.npcModel, player, false) == false then
					task.wait(60 / weaponTool:GetAttribute("FireRate"))
					continue
				end

				-- shoot if player is in remote range, is in line of sight, and mag isn't empty
				local distance = (npcHrp.Position - plrCharacter:GetPivot().Position).Magnitude
				local direction = (plrCharacter:GetPivot().Position - npcHrp.Position).Unit
				local bulletTravelDir = plrCharacter:GetPivot().Position + 
					Vector3.new(
						math.random(-distance * weaponRecoil, distance * weaponRecoil),
						math.random(-distance * weaponRecoil,distance * weaponRecoil),
						math.random(-distance * weaponRecoil,distance * weaponRecoil)
					)

				if weaponTool:GetAttribute("Ammo") > 0 then
					-- fire bullet
					Event.ServerBullet:FireAllClients(
						npcObject.npcModel, 
						gunHandle.Muzzle.WorldCFrame.Position,
						(bulletTravelDir - gunHandle.Muzzle.WorldCFrame.Position).Unit,
						require(weaponTool.Settings),
						nil
					)
					-- play FX
					gunHandle:FindFirstChildOfClass("Sound"):Play()
					gunHandle.Muzzle["FlashFX[Flash]"].Enabled = true
					gunHandle.Muzzle["FlashFX[Light]"].Enabled = true
					gunHandle.Muzzle["Smoke"].Enabled = true
					task.wait(.05)
					gunHandle.Muzzle["FlashFX[Flash]"].Enabled = false
					gunHandle.Muzzle["FlashFX[Light]"].Enabled = false
					gunHandle.Muzzle["Smoke"].Enabled = false
				else
					-- if the mag is empty then reload
					task.wait(3)
					weaponTool:SetAttribute("Ammo", weaponTool:GetAttribute("MaxAmmo"))
				end

				-- check for hits
				local raycastResult = workspace:Raycast(npcHrp.Position, direction * distance, raycastParams)
				if raycastResult then
			
					local foundHum, humanoid = CheckForHumanoid(npcObject.npcModel, raycastResult.Instance)
					if foundHum == true and Players:GetPlayerFromCharacter(humanoid.Parent) then
						-- inflict damage and reduce ammo
						local damage = weaponTool:GetAttribute("DamagePerShot")	
						humanoid:TakeDamage(damage)
						weaponTool:SetAttribute("Ammo", weaponTool:GetAttribute("Ammo") - 1)
						
					else
						-- if the mag is empty then reload
						task.wait(3)
						weaponTool:SetAttribute("Ammo", weaponTool:GetAttribute("MaxAmmo"))
					end
					
					-- if player is dead then stop
					if plrHumanoid.Health == 0 then
						task.delay(2, function()
							npcObject.npcModel:SetAttribute("aggroPlayerName", "")
							npcObject.npcModel:SetAttribute("State", "Safe")
						end)
						break 
					end
					
				end
				
				task.wait(60 / weaponTool:GetAttribute("FireRate"))
			end
			
			constantlyAimAtPlayer:Disconnect()
			npcHrp:FindFirstChildOfClass("AlignOrientation").Enabled = false
			task.wait(1)
			weaponTool:Destroy()
			resolve()
		end)
	end)
	
end