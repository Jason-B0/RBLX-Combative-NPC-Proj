--!strict
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)
local Config = require(script.Parent.Parent.Config)
local Helper = script.Parent.Parent.Helper
local Assets = script.Parent.Parent.Assets
--=========== NPC CREATION HELPERS ================
local GetNewNPCClass = require(Helper.GetNewNPCClass)
local NPCAppearance = require(Assets.NPCAppearance)

local function convertToString(accessories: {}): string
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
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid") :: Humanoid

    -- set up NPC appearance
	local h: HumanoidDescription = Instance.new("HumanoidDescription", humanoid) :: HumanoidDescription
    h.Face = NPCAppearance:GetAsset("Face", nil, false) :: number

    local bodyColor = NPCAppearance:GetAsset("BodyColor", nil, false) :: Color3
    h.HeadColor = bodyColor
    h.LeftArmColor = bodyColor
    h.RightArmColor = bodyColor
    h.LeftLegColor = bodyColor
    h.RightLegColor = bodyColor
    h.TorsoColor = bodyColor

    h.Shirt = NPCAppearance:GetAsset("Shirt", npcClass, true) :: number
    h.Pants = NPCAppearance:GetAsset("Pants", npcClass, true) :: number
    
    local hairAccessory = NPCAppearance:GetAsset("HairAccessory", npcClass, true) :: {}
    local faceAccessory = NPCAppearance:GetAsset("FaceAccessory", npcClass, true) :: {}
    local frontAccessory = NPCAppearance:GetAsset("FrontAccessory", npcClass, true) :: {}

    h.HairAccessory = convertToString(hairAccessory)
    h.FaceAccessory = if faceAccessory then convertToString(faceAccessory) else ""
    h.FrontAccessory = if frontAccessory then convertToString(frontAccessory) else ""

	npcModel.Parent = Config.NPC_CONTAINER_DIR
	humanoid:ApplyDescriptionReset(h, Enum.AssetTypeVerification.Always)
    npcModel.HumanoidRootPart:SetNetworkOwner(nil)

	-- disable collision on accessory handles
	for _, accessory in pairs(npcModel:GetChildren()) do
        if accessory:IsA("Accessory") then
            for _, part in pairs(accessory:GetDescendants()) do
                if part:IsA("BasePart") then
					part.CanCollide = false
					part.CanQuery = false
					part.CanTouch = false
                end
            end
        end
    end

    -- set up NPC attributes
    for attribute, defaultValue in pairs(Config.NPC_DEFAULT_ATTRIBUTES) do
      	npcModel:SetAttribute(attribute, defaultValue)
    end

    -- set up NPC pre-determined attributes
    npcModel:SetAttribute("Tag", token)
    npcModel:SetAttribute("Class", npcClass)

    return npcModel
end