--!strict
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)
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
local GetNewNPCClass = require(script.Parent.GetNewNPCClass)
local NPCAppearance = require(script.Parent.NPCAppearance)

--=========== MODULE ================
return function(npcModel: Types.NPCModel, token: string, class: string?)
    npcModel.Name = token
    
    -- set up NPC appearance
    local h: HumanoidDescription = Instance.new("HumanoidDescription", npcModel.Humanoid) :: HumanoidDescription
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

    h.Shirt = NPCAppearance:GetAsset("Shirt") :: Shirt
    h.Pants = NPCAppearance:GetAsset("Pants") :: Pants

    npcModel.Humanoid:ApplyDescriptionReset(h, Enum.AssetTypeVerification.Default)
    npcModel.HumanoidRootPart:SetNetworkOwner(nil)

    -- set up NPC attributes
    for attribute, defaultValue in pairs(NPC_DEFAULT_ATTRIBUTES) do
      npcModel:SetAttribute(attribute, defaultValue)
    end

    -- set up NPC pre-determined attributes
    npcModel:SetAttribute("Tag", token)
    npcModel:SetAttribute("Class", GetNewNPCClass(class))
    
    if class == "Police" then
        h.Shirt = 3523480603
        h.Pants = 11925065255
    elseif class == "Dock Worker" or class == "Dock Admin" then
        h.Shirt = 12963661140
        h.Pants = 6385501369
    elseif class == "Cartel" then
        h.Shirt = 6385493065
        h.Pants = 6385501369
    end

    return npcModel
end