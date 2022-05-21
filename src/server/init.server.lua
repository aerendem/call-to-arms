local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.shared:WaitForChild("Knit"))

Knit.AddServices(script.Services)
Knit.Start({
	Middleware = {
		Inbound = {
			function(_player, _args)
				return true
			end
		},
	},
}):andThen(function()
	print("Knit started!")
end):catch(warn)