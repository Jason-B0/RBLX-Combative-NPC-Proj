--!strict
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)
local Helper = script.Parent.Helper
local Assets = script.Parent.Assets
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
local NPCAppearance = require(Assets.NPCAppearance)

local function convertToString(accessories: table): string
	assert(type(accessories) == "table", "accessories must be a table")
    local allAccessories = ""
    for _, accessoryId: string in pairs(accessories) do
        allAccessories = allAccessories .. accessoryId .. ","
    end
	return allAccessories
end

--=========== MODULE ================
return function(npcModel: Types.NPCModel, token: string, class: string?)
    npcModel.Name = token
    local npcClass = GetNewNPCClass(class)

    -- set up NPC appearance
    local h: HumanoidDescription = Instance.new("HumanoidDescription", npcModel.Humanoid) :: HumanoidDescription
    h.Face = NPCAppearance:GetAsset("Face")

    local bodyColor = NPCAppearance:GetAsset("BodyColor") :: Color3
    h.HeadColor = bodyColor
    h.LeftArmColor = bodyColor
    h.RightArmColor = bodyColor
    h.LeftLegColor = bodyColor
    h.RightLegColor = bodyColor
    h.TorsoColor = bodyColor

	h.HairAccessory = NPCAppearance:GetAsset("Hair")
    h.Shirt = NPCAppearance:GetAsset("Shirt", npcClass, true) :: number
    h.Pants = NPCAppearance:GetAsset("Pants", npcClass, true) :: number
    
	local faceAccessory = NPCAppearance:GetAsset("FaceAccessory", npcClass, true)
	local frontAccessory = NPCAppearance:GetAsset("FrontAccessory", npcClass, true)
	
	h.FaceAccessory = if faceAccessory then convertToString(faceAccessory) else ""
	h.FrontAccessory = if frontAccessory then convertToString(frontAccessory) else ""

    npcModel.Humanoid:ApplyDescriptionReset(h, Enum.AssetTypeVerification.Default)
    npcModel.HumanoidRootPart:SetNetworkOwner(nil)

    -- set up NPC attributes
    for attribute, defaultValue in pairs(NPC_DEFAULT_ATTRIBUTES) do
      npcModel:SetAttribute(attribute, defaultValue)
    end

    -- set up NPC pre-determined attributes
    npcModel:SetAttribute("Tag", token)
    npcModel:SetAttribute("Class", npcClass)

    return npcModel
end