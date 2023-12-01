local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local ChatService = game:GetService("Chat")

type DialogueType = { {number & string} }
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
	
} :: { DialogueType }

--[[
	The dialogue event is a special event that is used to make NPCs talk to each other.
	A dialogue can be in any form.
]]
return function(npcs: {Types.NPCModel})
	local speakerCount = #npcs
	for _, dialogue in pairs(DIALOGUE) do
		
		-- determine speaker
		local speaker = npcs[speakerCount]
		if 
		
		ChatService:Chat(speaker, dialogue[2])
		task.wait(1)
		
		-- counter
		if speakerCount >= #npcs then
			speakerCount = 1
		else
			speakerCount += 1
		end
	end
	
end