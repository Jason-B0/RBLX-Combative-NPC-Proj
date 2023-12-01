local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)

local TokenService
--=========== MODULE ================	
local NPCEvent = {}
NPCEvent.__index = NPCEvent

function NPCEvent.new(name: string, restriction: {string}?, taskType: string, counter: number, maxParticipants: number?)
    Knit.OnStart():awaitStatus()
	TokenService = Knit.GetService("TokenService")
	local newNPCEvent = {
		name = name,
		token = TokenService:GenerateToken("event"),
		evtType = taskType,
		restriction = restriction,
		maxParticipants = maxParticipants or 0,
		counter = 0,
		targetCount = counter,
		connections = {},
		promises = {},
	} :: Types.NPCEvent
	
	-- determine max participants
	if newNPCEvent.maxParticipants == 0 then
        if taskType == "Dialogue" then
            newNPCEvent.maxParticipants = maxParticipants or math.random(1, 2)
        elseif taskType == "RecursiveTask" then
            newNPCEvent.maxParticipants = maxParticipants or math.random(1, 5)
        elseif taskType == "InfinitiveTask" then
            newNPCEvent.maxParticipants = maxParticipants or math.random(1, 5)
        elseif taskType == "OneTimeTask" then
            newNPCEvent.maxParticipants = maxParticipants or math.random(1, 5)
        end
	end
	
	return setmetatable(newNPCEvent, NPCEvent)
end

-- methods
function NPCEvent:Start()
	-- get NPCs to do the task
	self.connections.incrementCounter = Signal.new()
	self.connections.incrementCounter:Connect(function()
		self.counter += 1
		if self.counter >= self.targetCount then
			self.connections.incrementCounter:Disconnect()
			self.connections.incrementCounter = nil
		end
	end)
end



-- getters
function NPCEvent:GetName()
	return self.name
end

function NPCEvent:GetToken()
	return self.token
end

function NPCEvent:GetType()
	return self.evtType
end

function NPCEvent:GetCounter()
	return self.counter
end

function NPCEvent:GetMaxParticipants()
	return self.maxParticipants
end

function NPCEvent:GetTargetCount()
	return self.targetCount
end

function NPCEvent:GetNPCs()
	return self.NPCs
end

function NPCEvent:GetPromises()
	return self.promises
end

-- setters
function NPCEvent:SetCounter(counter: number)
	self.counter = counter
end

function NPCEvent:SetMaxParticipants(maxParticipants: number)
	self.maxParticipants = maxParticipants
end

function NPCEvent:SetTargetCount(targetCount: number)
	self.targetCount = targetCount
end




return NPCEvent
