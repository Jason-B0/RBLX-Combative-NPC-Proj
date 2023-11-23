local LocalPlayer = game:GetService("Players").LocalPlayer

return {

    update = function(newState: string?)
        if newState ~= nil then
            LocalPlayer:SetAttribute("operationState", newState)
        else
            LocalPlayer:SetAttribute("operationState", "Safe")
        end
    end,

    get = function(): string
        return LocalPlayer:GetAttribute("operationState")
    end,
}
