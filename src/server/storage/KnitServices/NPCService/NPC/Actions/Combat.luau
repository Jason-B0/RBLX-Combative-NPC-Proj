--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Engine = ReplicatedStorage.ACS_Engine :: Configuration |  Folder
local acsWorkspace = workspace.ACS_WorkSpace :: Folder
local Event = Engine.Events :: Folder
local Modules = Engine.Modules :: Folder

local Helper = script.Parent.Parent.Helper

local Promise = require(ReplicatedStorage.Packages.Promise)
local Types = require(ReplicatedStorage.Shared.Types)
local Weld = require(Helper.Weld)
local Hitmarker = require(Modules.Hitmarker)

--===============================================
local function CheckForHumanoid(instance: Instance)
	local humanoid = instance.Parent:FindFirstChildOfClass("Humanoid") or
		instance.Parent.Parent:FindFirstChildOfClass("Humanoid")
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

local function lookAt(target: Vector3, eye: Vector3)
	local forwardVector = (eye - target).Unit
	local upVector = Vector3.new(0, 1, 0)
	-- You have to remember the right hand rule or google search to get this right
	local rightVector = forwardVector:Cross(upVector)
	local upVector2 = rightVector:Cross(forwardVector)

	return CFrame.fromMatrix(eye, rightVector, upVector2)
end
--===============================================


return function(self: Types.NPC, player: Player)
	
	local npcHead = self.NPCModel.Head :: BasePart
	local npcHumanoid = self.NPCModel.Humanoid :: Humanoid
	local npcNeck = self.NPCModel.Torso.Neck :: Motor6D
	local npcTorso = self.NPCModel.Torso :: BasePart
	local npcHrp = self.NPCModel.HumanoidRootPart :: BasePart
	
	local weaponTool = equipWeapon("CZ75") :: Types.WeaponTool
	weaponTool.Parent = self.NPCModel
	local gunModel = weaponTool.Gun :: Model
	local gunHandle = gunModel.Handle or gunModel.Grip :: BasePart
	task.wait(.5)
	weldWeapon(npcTorso, weaponTool)
	local weaponRecoil = weaponTool:GetAttribute("RecoilSpread") :: number
	
	local plrCharacter = player.Character :: Types.Character
	local plrHumanoid = plrCharacter:FindFirstChildOfClass("Humanoid") :: Humanoid
	
	return Promise.new(function(resolve, reject, onCancel)
		local resume = true
		
		task.spawn(function()
			while player ~= nil and resume and isAlive(npcHumanoid) do
				
				local distance = (npcHrp.Position - plrCharacter:GetPivot().Position).Magnitude
				local direction = (plrCharacter:GetPivot().Position - npcHrp.Position).Unit
				local bulletTravelDir = plrCharacter:GetPivot().Position + 
					Vector3.new(
						math.random(-distance * weaponRecoil, distance * weaponRecoil),
						math.random(-distance * weaponRecoil,distance * weaponRecoil),
						math.random(-distance * weaponRecoil,distance * weaponRecoil)
					)
				
				local raycastParams = RaycastParams.new()
				raycastParams.FilterDescendantsInstances = {self.NPCModel}
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude
				raycastParams.IgnoreWater = true
				
				local raycastResult = workspace:Raycast(npcHrp.Position, direction * distance, raycastParams)
				
				if raycastResult then
					-- turn their entire body to player
					local targetCFrame = lookAt(plrCharacter.PrimaryPart.Position, npcHrp.Position)
					
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
						self.NPCModel, 
						gunHandle.Muzzle.WorldCFrame.Position,
						(bulletTravelDir - gunHandle.Muzzle.WorldCFrame.Position).Unit,
						require(weaponTool.Settings),
						nil
					)
					
					local foundHum, humanoid = CheckForHumanoid(raycastResult.Instance)
					if foundHum == true and Players:GetPlayerFromCharacter(humanoid.Parent) then
						if humanoid.Health == 0 then 
							task.delay(2, function()
								self.NPCModel:SetAttribute("playerToTrack", nil)
								self.NPCModel:SetAttribute("State", "Safe")
								self.NPCModel:SetAttribute("compromised", false)
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