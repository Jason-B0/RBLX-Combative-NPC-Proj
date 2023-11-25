--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Engine = ReplicatedStorage.ACS_Engine :: Configuration |  Folder
local ACS_Storage = workspace.ACS_Storage :: Folder
local Event = Engine.Events :: Folder
local Modules = Engine.Modules :: Folder

local Helper = script.Parent.Parent.Helper

local Promise = require(ReplicatedStorage.Packages.Promise)
local Types = require(ReplicatedStorage.Shared.Types)
local Weld = require(Helper.Weld)
local Hitmarker = require(Modules.Hitmarker)

--===============================================
type WeaponTool = Tool & {
	Gun: Model & {
		Handle: BasePart?,
		Grip: BasePart?,
		Muzzle: BasePart,
	},	
	Animation: ModuleScript,
}

local function weldWeapon(torso: BasePart, weaponTool: WeaponTool)
	
	local gunModel = weaponTool.Gun :: Model
	local gunHandle = gunModel.Handle or gunModel.Grip :: BasePart
	
	for _, basePart in pairs(gunModel:GetDescendants()) do
		if basePart:IsA("BasePart") and basePart ~= gunHandle then
			Weld:weld(gunHandle, basePart)
		end
	end
	
	Weld:motor6D(torso, gunHandle)
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
	
	local weapon = self.NPCModel.Weapon
	local weaponRecoil = weapon:GetAttribute("RecoilSperad") :: number
	
	local plrCharacter = player.Character :: Types.Character
	local plrHumanoid = plrCharacter:FindFirstChildOfClass("Humanoid") :: Humanoid
	
	weldWeapon(npcTorso, weapon)
	
	return Promise.new(function(resolve, reject, onCancel)
		local resume = true
		
		task.spawn(function()
			while player ~= nil and resume and isAlive(npcHumanoid) do
				
				local distance = (npcHrp.Position - plrCharacter.PrimaryPart.Position).Magnitude
				local direction = (plrCharacter.PrimaryPart.Position - npcHrp.Position).Unit
				local bulletTravelDir = plrCharacter.WorldPivot.Position + 
					Vector3.new(
						math.random(-distance * weaponRecoil, distance * weaponRecoil),
						math.random(-distance* weaponRecoil,distance * weaponRecoil),
						math.random(-distance* weaponRecoil,distance * weaponRecoil)
					) + plrCharacter.Torso.CFrame.LookVector
				
				local raycastParams = RaycastParams.new()
				raycastParams.FilterDescendantsInstances = {plrCharacter}
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.IgnoreWater = true
				
				local raycastResult = workspace:Raycast(npcHrp.Position, direction * distance, raycastParams)
				
				if raycastResult then
					-- turn their entire body to player
					local targetCFrame = lookAt(plrCharacter.PrimaryPart.Position, npcHrp.Position)
					npcHrp.CFrame = targetCFrame
					-- shoot
					Event.ServerBullet:FireAllClients(
						self.NPCModel, 
						weapon.Gun.Muzzle.Position,
						(bulletTravelDir - weapon.Gun.Muzzle.Position).Unit,
						weapon.Setting,
						nil
					)
				end
				
				task.wait(.5)
			end
		end)
	end)
	
end