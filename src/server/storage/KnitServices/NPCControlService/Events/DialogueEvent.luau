local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local Promise = require(ReplicatedStorage.Packages.Promise)
local ChatService = game:GetService("Chat")

local DIALOGUE = {
	--[[
		0 means whoever is next in order will speak
		any other number means whichever NPC is passed through will speak	
	]]
	
	{0, "NPC1 says this"},
	{0, "NPC2 says this"},
	{0, "NPC1 says that"},
	{0, "NPC2 says that"},
	{0, "NPC1 says bye"},
	{0, "NPC2 says bye"},
	
}

--[[
	The dialogue event is a special event that is used to make NPCs talk to each other.
	A dialogue can be in any form.
]]
return function(npcs: {Types.NPCModel})
	return Promise.new(function(resolve, reject)
        local speakerCount = #npcs

        -- get NPCs to face each other
        local npc1 = npcs[1]
        for _, npc in pairs(npcs) do
            if npc ~= npc1 then
                npc.HumanoidRootPart.CFrame = npc1.HumanoidRootPart.CFrame
                    * CFrame.new(
                        CFrame.lookAt(npc.HumanoidRootPart.Position, npc1.HumanoidRootPart.Position)
                            :ToOrientation()
                    )
            end
        end

		-- speak
        for _, dialogue in pairs(DIALOGUE) do

            -- determine speaker
            local speaker = npcs[speakerCount]

            ChatService:Chat(speaker, dialogue[2])
            task.wait(math.random(2,4))

            -- counter
            if speakerCount >= #npcs then
                speakerCount = 1
            else
                speakerCount += 1
            end
        end
	end)
	
end