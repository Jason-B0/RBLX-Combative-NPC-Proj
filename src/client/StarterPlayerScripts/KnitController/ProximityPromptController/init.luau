local Knit = require(game:GetService('ReplicatedStorage').Packages.Knit)
local ProximityPromptService = game:GetService('ProximityPromptService')

local ProximityPromptController = Knit.CreateController {
	Name = 'ProximityPromptController';
}

local ClientNPCController

--=============================================================

function ProximityPromptController:KnitInit()
	
end

function ProximityPromptController:KnitStart()
	ClientNPCController = Knit.GetController(ClientNPCController)

    -- proximity prompt
    ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
        if prompt.Name == "NPCPrompt" then
            ClientNPCController:SetOperationState("Illegal Action")
        end
    end)

    ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt, player)
        if prompt.Name == "NPCPrompt" then
            ClientNPCController:SetOperationState("Safe")
        end
    end)
	
end

return ProximityPromptController