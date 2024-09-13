local LocalPlayer = game:GetService("Players").LocalPlayer


-- Determines NPC's aggorvation/reaction state based on player's location and current action
-- Returns a string indicating the NPC's aggro state
return function(): string
	local locationState = LocalPlayer:GetAttribute("locationState")
    local operationState = LocalPlayer:GetAttribute("operationState")
    local npcAggroState = nil

    if locationState == "Safe" then
        
        if operationState == "Safe" then
            npcAggroState = "Safe"
            
        elseif operationState == "Abnormal Action" then
            npcAggroState = "Curious"
            
        elseif operationState == "Illegal Action" then
            npcAggroState = "Suspicious"
            
        elseif operationState == "Armed" then
            npcAggroState = "Alert"

        elseif operationState == "Compromised" then
            npcAggroState = "Hostile"
            
        end
        
    elseif locationState == "Trespassing" then
        
        if operationState == "Safe" then
            npcAggroState = "Curious"
            
        elseif operationState == "Abnormal Action" then
            npcAggroState = "Suspicious"
            
        elseif operationState == "Illegal Action" then
            npcAggroState = "Alert"
            
        elseif operationState == "Armed" then
            npcAggroState = "Hostile"

        elseif operationState == "Compromised" then
            npcAggroState = "Hostile"
            
        end
    
    elseif locationState == "Restricted" then
        
        if operationState == "Safe" then
            npcAggroState = "Suspicious"
            
        elseif operationState == "Abnormal Action" then
            npcAggroState = "Alert"
            
        elseif operationState == "Illegal Action" then
            npcAggroState = "Alert"
            
        elseif operationState == "Armed" then
            npcAggroState = "Hostile"
            
        elseif operationState == "Compromised" then
            npcAggroState = "Hostile"
            
        end
   
    elseif locationState == "Hostile Area" then
        
        if operationState == "Safe" then
            npcAggroState = "Hostile"
            
        elseif operationState == "Abnormal Action" then
            npcAggroState = "Hostile"
            
        elseif operationState == "Illegal Action" then
            npcAggroState = "Hostile"
            
        elseif operationState == "Armed" then
            npcAggroState = "Hostile"
            
        elseif operationState == "Compromised" then
            npcAggroState = "Hostile"
            
        end
        
    end
    
    -- Default to safe if no state is found
    if npcAggroState == nil then
        warn("npcAggroState is nil")
        return "Safe"
    end
    
    return npcAggroState
end