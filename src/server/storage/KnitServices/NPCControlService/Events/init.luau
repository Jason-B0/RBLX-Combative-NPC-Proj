local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)

--=========== MODULE ================	
local NPCEvent = {}
NPCEvent.__index = NPCEvent

function NPCEvent.new(name: string, restriction: {string}?, taskType: string, counter: number)
	local newNPCEvent = {
		name = name,
		evtType = taskType,
		restriction = restriction,
		counter = counter,
		connections = {},
		promises = {},
	} :: Types.NPCEvent
	
	return setmetatable(newNPCEvent, NPCEvent)
end

function 

return NPCEvent
