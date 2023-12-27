--[[
	This service strictly tracks the status of all NPCs, creating them and assigning them tags, and
	assigning paths etc.
	Futhermore, this service also controlls whether NPCs are enabled or not.
	
	For internal functionalities of NPC, such as walking, attacking, tracking, etc.,
	it is handled by each NPC object.
]]

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Types = require(ReplicatedStorage.Shared.Types)

local NPCObject = require(script.NPC)
--=================================
local NPCService = Knit.CreateService({
    Name = "NPCService",
    Client = {},
    
    TAG_NAME = "NPC",
    NPC_FOLDER = workspace.NPC,
    
    NPCs = {} :: {[string]: Types.NPCModel},
    AggrovateSignal = Signal.new(),
    
})
local TokenService
--=================================
local Asset = ServerStorage.Asset

--=================================

-- NPC aggrovation
function NPCService.Client:AggrovateNPC(player: Player, npcTag: string, newState: string)
    return self.Server:AggrovateNPC(player, npcTag, newState)
end

function NPCService:AggrovateNPC(player: Player, npcTag: string, newState: string)
    local npc = self.NPCs[npcTag]
    if npc then
        npc:SetAttribute("playerToTrack", player.Name or nil)
        npc:SetAttribute("State", newState)
    end
end

-- NPC kill
function NPCService.Client:KillNPC(_: Player, npcTag: string)
    return self.Server:KillNPC(npcTag)
end

function NPCService:KillNPC(npcTag: string)
    local npc = self.NPCs[npcTag]
    if npc then
        npc:FindFirstChildOfClass("Humanoid").Health = 0
    end
end

-- NPC creation
function NPCService:CreateNewNPC(class: string?, position: CFrame?)
    local newNPCModel = Asset.NPC:Clone()
    newNPCModel.Parent = self.NPC_FOLDER
    local newNPCObj = NPCObject.new(newNPCModel, class)
    newNPCObj:Active(position)
    
    return newNPCObj
end

-- Returns a copy of NPC list
function NPCService:GetNPCList()
    local npcList = {}
    for _, npc: Types.NPCModel in pairs(self.NPCs) do
        table.insert(npcList, npc)
    end
    return npcList
end
--=================================
function NPCService:KnitStart()
    NPCService = Knit.GetService("NPCService")
    TokenService = Knit.GetService("TokenService")
    
    -- add tagged NPC to the table
    for _, npc: Types.NPCModel in pairs(CollectionService:GetTagged(self.TAG_NAME)) do
        if npc:FindFirstChildOfClass("Humanoid") then
            self.NPCs[npc:GetAttribute("Tag")] = npc
        end
    end

	-- set up all waypoint to be tagged with a token
	for _, waypoint: Types.Waypoint in pairs(workspace.NPC_Waypoints:GetDescendants()) do
		if waypoint:IsA("BasePart") then
			waypoint:SetAttribute("WaypointToken", TokenService:GenerateToken("wp"))
		end
	end 
	
    CollectionService:GetInstanceAddedSignal(self.TAG_NAME):Connect(function(npc: Types.NPCModel)
        assert(npc:FindFirstChildOfClass("Humanoid"), "NPC does not have a humanoid!")
        self.NPCs[npc:GetAttribute("Tag")] = npc   
    end)
    
end

function NPCService:KnitInit()
    if workspace.GAME_WORKSPACE:FindFirstChild("NPCAvoid") then
        for _, v: BasePart | Model in pairs(workspace.GAME_WORKSPACE.NPCAvoid:GetChildren()) do
            local size
            if v:IsA("Model") then
                if v.PrimaryPart == nil then
                    size = v:GetExtentsSize()
                else
                    size = v.PrimaryPart.Size
                end
            elseif v:IsA("BasePart") then
                size = v.Size
            end
            
            if size == nil then continue end
            
            local newPart = Instance.new("Part")
            newPart.Name = "NPCAvoid"
            newPart.Size = size + Vector3.new(2,5,2)
            newPart.Locked = true
            newPart.Anchored = true
            newPart.CastShadow = false
            newPart.TopSurface = Enum.SurfaceType.Smooth
            newPart.BottomSurface = Enum.SurfaceType.Smooth
            newPart.LeftSurface = Enum.SurfaceType.Smooth
            newPart.RightSurface = Enum.SurfaceType.Smooth
            newPart.FrontSurface = Enum.SurfaceType.Smooth
            newPart.BackSurface = Enum.SurfaceType.Smooth
            newPart.CanCollide = false
            newPart.Color = Color3.fromRGB(225,225,0)
            newPart.Transparency = if RunService:IsStudio() then .8 else 1
            newPart.Parent = workspace.GAME_WORKSPACE.NPCAvoid:FindFirstChildOfClass("Folder")
            newPart:PivotTo(v:GetPivot())
            
            local pathfindingModifier = Instance.new("PathfindingModifier")
            pathfindingModifier.Name = "NPCAvoid"
            pathfindingModifier.Label = "NPCAvoid"
            pathfindingModifier.PassThrough = false
            pathfindingModifier.Parent = newPart
        
        end
    end
    
end

return NPCService
