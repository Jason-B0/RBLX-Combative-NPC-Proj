--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Engine = ReplicatedStorage.ACS_Engine :: Configuration |  Folder
local acsWorkspace = workspace.ACS_WorkSpace :: Folder
local Event = Engine.Events :: Folder
local Modules = Engine.Modules :: Folder

local Helper = script.Parent.Parent.Helper
local determineNextWaypoint = require(Helper.DetermineNextWaypoint)

local Promise = require(ReplicatedStorage.Packages.Promise)
local Types = require(ReplicatedStorage.Shared.Types)
local Weld = require(Helper.Weld)
local Hitmarker = require(Modules.Hitmarker)

--===============================================
local function CheckForHumanoid(instance: Instance)
	local humanoid = 
		if instance.Parent ~= nil then 
			instance.Parent:FindFirstChildOfClass("Humanoid") 
		elseif instance.Parent ~= nil and instance.Parent.Parent ~= nil then
			instance.Parent.Parent:FindFirstChildOfClass("Humanoid")
		else
			nil
		
	if humanoid then
		return true, humanoid
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
	local diff = playerPosition - ncpRootPart.Position
    local angle = math.atan2(diff.X, diff.Z) -- we just want the RootPart to orientate on one axis.

    local alignOrientation = ncpRootPart:FindFirstChildOfClass("AlignOrientation")
    alignOrientation.CFrame = CFrame.Angles(0, angle, 0)
	print(alignOrientation.CFrame)
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
	task.wait(.5)
	weldWeapon(npcTorso, weaponTool)
	local weaponRecoil = weaponTool:GetAttribute("RecoilSpread") :: number
	
	local plrCharacter = player.Character :: Types.Character | PVInstance
	local plrHumanoid = plrCharacter.Humanoid :: Humanoid
	
	return Promise.new(function(resolve, reject, onCancel)
		local resume = true
		
		task.spawn(function()
			while player ~= nil and resume and isAlive(npcHumanoid) do
				
				-- recompute path to move towards player
				npcObject.npcModel:SetAttribute("nextWaypointToken", 
					determineNextWaypoint(
						npcObject :: Types.NPCObject, 
						plrCharacter.HumanoidRootPart
					)
				)

				local distance = (npcHrp.Position - plrCharacter:GetPivot().Position).Magnitude
				local direction = (plrCharacter:GetPivot().Position - npcHrp.Position).Unit
				local bulletTravelDir = plrCharacter:GetPivot().Position + 
					Vector3.new(
						math.random(-distance * weaponRecoil, distance * weaponRecoil),
						math.random(-distance * weaponRecoil,distance * weaponRecoil),
						math.random(-distance * weaponRecoil,distance * weaponRecoil)
					)
				
				local raycastParams = RaycastParams.new()
				raycastParams.FilterDescendantsInstances = {npcObject.npcModel}
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude
				raycastParams.IgnoreWater = true
				
				local raycastResult = workspace:Raycast(npcHrp.Position, direction * distance, raycastParams)
				
				if raycastResult then
					-- TODO turn their entire body to player
					lookAt(plrCharacter.PrimaryPart.Position, npcHrp)
					
					-- FX
					task.spawn(function()
						gunHandle:FindFirstChildOfClass("Sound"):Play()
						gunHandle.Muzzle["FlashFX[Flash]"].Enabled = true
						gunHandle.Muzzle["FlashFX[Light]"].Enabled = true
						gunHandle.Muzzle["Smoke"].Enabled = true
						task.wait(.05)
						gunHandle.Muzzle["FlashFX[Flash]"].Enabled = false
						gunHandle.Muzzle["FlashFX[Light]"].Enabled = false
						gunHandle.Muzzle["Smoke"].Enabled = false
					end)
					
					-- shoot
					Event.ServerBullet:FireAllClients(
						npcObject.npcModel, 
						gunHandle.Muzzle.WorldCFrame.Position,
						(bulletTravelDir - gunHandle.Muzzle.WorldCFrame.Position).Unit,
						require(weaponTool.Settings),
						nil
					)
					
					local foundHum, humanoid = CheckForHumanoid(raycastResult.Instance)
					if foundHum == true and Players:GetPlayerFromCharacter(humanoid.Parent) then
						if humanoid.Health == 0 then 
							task.delay(2, function()
								npcObject.npcModel:SetAttribute("aggroPlayerName", "")
								npcObject.npcModel:SetAttribute("State", "Safe")
							end)
							break 
						end
						------ How much damage the gun inflicts1s
						local damage = weaponTool:GetAttribute("DamagePerShot")	
						humanoid:TakeDamage(damage)
						weaponTool:SetAttribute("Ammo", weaponTool:GetAttribute("Ammo") - 1)
					
					end
					
				end
				
				if onCancel() then
					task.spawn(function()
						resume = false
					end)
					break
				end
				
				if weaponTool:GetAttribute("Ammo") <= 0 then
					task.wait(3)
				end
				
				task.wait(.25)
			end
			
			task.wait(1)
			weaponTool:Destroy()
			resolve()
		end)
	end)
	
end