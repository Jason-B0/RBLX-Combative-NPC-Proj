local types = {}

export type NPC = {
    HumanoidRootPart: Instance,
    Humanoid: Humanoid,
    HumanoidDescription: HumanoidDescription,

    NPC_CLASS: string,
    State: string,
    NextWaypoint: Instance,
    Zone: number,
}

return types
