local types = {}

export type NPCModel = Model & {
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
    Weapon: nil | (Tool & {
        Gun: Model & {
            Handle: BasePart?,
            Grip: BasePart?,
            Muzzle: BasePart,
        },
        Animation: ModuleScript,
        Setting: ModuleScript,
    }),
    
    -- Attributes
    Class: string,
    NextWaypointToken: string,
        
    -- Variables
    playerToTrack: string,
    State: "Safe" | "Curious" | "Suspicious" | "Alert" | "Hostile",
    
}

export type NPC = {
    NPCModel: NPCModel,   
    NPCType: string,
    ThisNPCFinishedMoving: Signal<T...>,
    PlayerCurrentlyBeingTracked: Player,
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
