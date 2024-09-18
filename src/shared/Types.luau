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
