for _, v in pairs(game:GetService("Players"):GetPlayers()) do
    if v.Team.Name == "SAC" then
        v:SetAttribute("operationState", "Armed")
        v:SetAttribute("locationState", "Restricted")
    end
end

for i = 1, 6 do
    task.wait(1)
    local Lighting = game:GetService("Lighting")
    Lighting.ClockTime += (1 / 6)
    print(Lighting.ClockTime)
end

for _, v in pairs(game:GetService("ServerStorage").CarStorage:GetChildren()) do
    print(v.Name)
end

local car = game:GetService("ServerStorage").CarStorage["Ford Expedition"]:Clone()
car.Parent = game:GetService("Workspace")
car:PivotTo(game.Players.Jas_nRuski.Character.HumanoidRootPart.CFrame)