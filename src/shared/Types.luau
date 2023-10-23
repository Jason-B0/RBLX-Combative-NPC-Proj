local types = {}

export type NPC = Model & {
    HumanoidRootPart: BasePart,
    Humanoid: Humanoid & {
        HumanoidDescription: HumanoidDescription, Animator: Animator 
    },
    HumanoidRootPart: BasePart,
    Torso: BasePart,
    Head: BasePart,

    NPC_CLASS: string,
    State: string,
    NextWaypoint: Instance,
    Zone: number,
}

export type Character = Model & {
    Humanoid: Humanoid,
    HumanoidRootPart: BasePart,
    Torso: BasePart,
    Head: BasePart,
}

return types
