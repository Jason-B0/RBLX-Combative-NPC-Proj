--!strict
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)
local Helper = script.Parent.Helper
local Modules = script.Parent.Modules
--=========== CONFIG ================
local NPC_DEFAULT_ATTRIBUTES = {
	State = "Safe",
	NextWaypointToken = "",
	DetectionDistance = "DAY_OUTDOOR",
	Tag = "",
	Active = true,
  Class = "Civilian",
  
	-- Other NPC states
  playerToTrack = "",
  playerToLookAt = "",
  compromised = false,
}

--=========== NPC CREATION HELPERS ================
local GetNewNPCClass = require(Helper.GetNewNPCClass)
local NPCAppearance = require(Modules.NPCAppearance)

--=========== MODULE ================
return function(npcModel: Types.NPCModel, token: string, class: string?)
    npcModel.Name = token
    
    -- set up NPC appearance
    local h: HumanoidDescription = Instance.new("HumanoidDescription", npcModel.Humanoid) :: HumanoidDescription
    h.Face = NPCAppearance:GetAsset("Face")
    
    h.FrontAccessory = table.unpack(NPCAppearance:GetAsset("FrontAccessories") :: table)
    h.FaceAccessory = table.unpack(NPCAppearance:GetAsset("FaceAccessories") :: table)
    h.HairAccessory = NPCAppearance:GetAsset("Hair")

    local bodyColor = NPCAppearance:GetAsset("BodyColor") :: Color3
    h.HeadColor = bodyColor
    h.LeftArmColor = bodyColor
    h.RightArmColor = bodyColor
    h.LeftLegColor = bodyColor
    h.RightLegColor = bodyColor
    h.TorsoColor = bodyColor

    h.Shirt = NPCAppearance:GetAsset("Shirt") :: number
    h.Pants = NPCAppearance:GetAsset("Pants") :: number
    

    npcModel.Humanoid:ApplyDescriptionReset(h, Enum.AssetTypeVerification.Default)
    npcModel.HumanoidRootPart:SetNetworkOwner(nil)

    -- set up NPC attributes
    for attribute, defaultValue in pairs(NPC_DEFAULT_ATTRIBUTES) do
      npcModel:SetAttribute(attribute, defaultValue)
    end

    -- set up NPC pre-determined attributes
    npcModel:SetAttribute("Tag", token)
    npcModel:SetAttribute("Class", GetNewNPCClass(class))

    return npcModel
end