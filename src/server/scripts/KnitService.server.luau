local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Services = game:GetService("ServerStorage").KnitServices

Knit.AddServicesDeep(Services)

Knit.Start()
    :andThen(function()
        print("Knit started on ser side.")
    end)
    :catch(warn)
