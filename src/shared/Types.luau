local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
type Promise = typeof(Promise.new(function() end))
type Signal<T> = typeof(Signal.new())
local types = {}

export type NPCEvent = {
    name: string;
    token: string;
    evtType: "Dialogue" | "RecursiveTask" | "InfinitiveTask" | "OneTimeTask";
    restriction: {string}?;
    counter: number;
    maxParticipants: number;
    targetCount: number;
    connections: {[number]: RBXScriptConnection};
    promises: {[any]: Promise};    
}

export type NPCClass = {
    new: (npcModel: NPCModel, class: string?) -> NPCObject,
    __index: NPCClass,
}

export type NPCObject = {
    npcModel: NPCModel,
    npcClass: string,
    thisNPCFinishedMoving: Signal<any>,
    playerCurrentlyBeingTracked: Player,
    currentTask: NPCEvent?,
    promises: {[any]: Promise},
    connections: {[any]: RBXScriptConnection},

    Active: () -> (),

    ChangeState: () -> (),

    Safe: () -> (),
    Curious: () -> (),
    Suspicious: () -> (),
    Alert: () -> (),
    Hostile: () -> (),
    
    ChangeWaypoint: () -> (),
    ChangePlayerToLookAt: () -> (),
}

export type NPCModel = (Model & {
    HumanoidRootPart: BasePart,
    Humanoid: Humanoid & {
        HumanoidDescription: HumanoidDescription, Animator: Animator 
    },
    Torso: BasePart & {
        Neck: Motor6D,
        ["Left Shoulder"]: Motor6D,
        ["Right Shoulder"]: Motor6D,
        ["Left Hip"]: Motor6D,
        ["Right Hip"]: Motor6D,
    },
    Head: BasePart,
    StateBillboard: BillboardGui & {
        StateIndicator: ImageLabel,
    },
    Weapon: WeaponTool?,
    
    -- Attributes
    Class: string,
    IsCombatant: boolean,
    
    -- Variables
    aggroPlayerName: string,
    nextWaypointToken: string,
    currentEventId: string,
    State: "Safe" | "Curious" | "Suspicious" | "Alert" | "Hostile",
    
}) | Instance

export type WeaponTool = Tool & {
	Gun: Model & {
		Handle: BasePart & {
			Muzzle: Attachment & {
				["FlashFX[Flash]"]: ParticleEmitter,
				["FlashFX[Light]"]: PointLight,
				Smoke: ParticleEmitter,
			}
		},
	},	
	Animation: ModuleScript,
    Settings: ModuleScript,
}

export type Waypoint = BasePart & {
    CanPublicAccess: boolean;
    CanPoliceAccess: boolean;
    CanConstructionWorkerAccess: boolean;
    CanDockWorkerAccess: boolean;
    CanDockAdminAccess: boolean;
    CanCartelAccess: boolean;
    WaypointToken: string;
}

export type Character = Model & {
    Humanoid: Humanoid,
    HumanoidRootPart: BasePart,
    Torso: BasePart,
    Head: BasePart,
}

return types
