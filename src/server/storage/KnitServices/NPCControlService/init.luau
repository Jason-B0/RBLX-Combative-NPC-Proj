--[[
	This service strictly tracks the status of all NPCs, creating them and assigning them tags, and
	assigning paths etc.
	Futhermore, this service also controlls whether NPCs are enabled or not.
	
	For internal functionalities of NPC, such as walking, attacking, tracking, etc.,
	it is handled by NPCService.
]]

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)

local NPCControlService = Knit.CreateService({
    Name = "NPCControlService",
    Client = {},

    OnDestinationReachedSignal = Signal.new(),
})
local NPCService, TokenService

local Asset = ServerStorage.Asset
local GetNewNPCClass = require(script.GetNewNPCClass)
local NPCAppearance = require(script.NPCAppearance)

--=================================

function NPCControlService:CreateNewNPC()
    local newNPC = Asset.NPC:Clone()
    newNPC.Name = TokenService:GenerateToken("npc")
    newNPC.Parent = workspace.NPC

    --// set up AI appearance
    local h = Instance.new("HumanoidDescription", newNPC.Humanoid)

    local npcClass = GetNewNPCClass() -- TODO: make use of it

    h.Face = NPCAppearance:GetAsset("Face")
    --h.FaceAccessory = NPCAppearance:GetAsset("FaceAccessories")
    h.HairAccessory = NPCAppearance:GetAsset("Hair")

    local bodyColor = NPCAppearance:GetAsset("BodyColor")
    h.HeadColor = bodyColor
    h.LeftArmColor = bodyColor
    h.RightArmColor = bodyColor
    h.LeftLegColor = bodyColor
    h.RightLegColor = bodyColor
    h.TorsoColor = bodyColor

    h.Shirt = NPCAppearance:GetAsset("Shirt")
    h.Pants = NPCAppearance:GetAsset("Pants")

    newNPC.Humanoid:ApplyDescriptionReset(h, Enum.AssetTypeVerification.Default)
    newNPC.HumanoidRootPart:SetNetworkOwner(nil)

    --// set up collision group
    for _, v in pairs(newNPC:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CollisionGroup = "NPC"
        end
    end

    --// set up AI class and status
    newNPC:SetAttribute("NPC_CLASS", npcClass)
    newNPC:SetAttribute("State", "idle")
    newNPC:SetAttribute("NextWaypoint", nil)
    newNPC:SetAttribute("Zone", 0)
    newNPC:SetAttribute("DetectionDistance", "DAY_OUTDOOR")
    newNPC:SetAttribute("Tag", newNPC.Name)
    newNPC:SetAttribute("Active", true)

    CollectionService:AddTag(newNPC, "NPC")
    return newNPC
end

function NPCControlService:MoveNPC(npc, waypoint: string)
    assert(CollectionService:HasTag(npc, "NPC"), "This character does not have an NPC tag.")
    npc:SetAttribute("NextWaypoint", waypoint)
end

function NPCControlService:OnDestinationReached(npc, res: boolean, msg: string?)
    if res == true then
        NPCControlService.OnDestinationReachedSignal:Fire(npc, true)
    else
        NPCControlService.OnDestinationReachedSignal:Fire(npc, false, msg)
    end
end

function NPCControlService:GetDestination(npc)
    return npc:GetAttribute("NextWaypoint")
end
--=================================
function NPCControlService:KnitStart()
    NPCService = Knit.GetService("NPCService")
    TokenService = Knit.GetService("TokenService")
    NPCService.ThisNPCFinishedMoving:Connect(self.OnDestinationReached)
end

function NPCControlService:KnitInit()
    PhysicsService:RegisterCollisionGroup("NPC")
    PhysicsService:CollisionGroupSetCollidable("NPC", "NPC", false)
end

return NPCControlService
