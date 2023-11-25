local LocalPlayer = game:GetService("Players").LocalPlayer

local OperationState = {}

function OperationState:set(newState: string?)
    if newState ~= nil then
        LocalPlayer:SetAttribute("operationState", newState)
    else
        LocalPlayer:SetAttribute("operationState", "Safe")
    end
end

function OperationState:get(): string
    return LocalPlayer:GetAttribute("operationState")
end

return OperationState