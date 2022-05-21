local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.shared:WaitForChild("Knit"))

game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

Knit.AddControllers(script:WaitForChild("Controllers"))
Knit.Start({ServicePromises = false}):catch(warn):await()