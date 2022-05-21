local Knit = require(game:GetService("ReplicatedStorage").shared.Knit)

--SERVICES
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ViewportController
local CharacterService

--MODULES
local Settings = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Modules"):WaitForChild("CameraSettings"))

--VARIABLES
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local character,humanoid


local CameraController = Knit.CreateController {
	Name = "CameraController",
	Enabled = true
}

--Bridge function between caller and ViewportController
function CameraController.ApplyRecoil()
	ViewportController.RecoilAnimation()
end

--Sets player's camera to firs person mode
function CameraController.SetFirstPersonCamera()
	CameraController.Enabled = true
	UserInputService.MouseIconEnabled = false
	camera.CameraType = Enum.CameraType.Custom
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	ViewportController:Enable()
end

--Sets player's camera
function CameraController.SetFixedCamera()
	CameraController.Enabled = false
	ViewportController.Disable()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(Vector3.new(0,0,0), Vector3.new(0,0,0))
	UserInputService.MouseIconEnabled = true
end

--Initializes for first person camera mode
function CameraController.Initialize()
	--ViewportController:CreateFakes()
	--ViewportController:Setup()
end

function CameraController:KnitStart()
	CharacterService = Knit.GetService("CharacterService")
	ViewportController = Knit.GetController("ViewportController")
	
	while player.Character == nil do
		task.wait(0.01)
	end
	character = player.Character
	
	while character:WaitForChild("Humanoid") == nil do
		task.wait(0.01)
	end
	
	humanoid = character.Humanoid

	CameraController.Initialize()

	if player.CameraMode == Enum.CameraMode.LockFirstPerson then
		CameraController.SetFirstPersonCamera()
	end

	humanoid.Running:Connect(function(speed)
		ViewportController.IsRunning = speed ~= 0
	end)

	--Listens for cahracter 's jumping and landing. Applies sway and camera movement to the viewmodel
	humanoid.StateChanged:Connect(function(oldstate, newstate)
		if ViewportController.IsFirstPerson and Settings.INCLUDE_JUMP_SWAY then 
			if newstate == Enum.HumanoidStateType.Landed then
				ViewportController:LandingAnimation()
			elseif newstate == Enum.HumanoidStateType.Freefall then 
				ViewportController:JumpAnimation()
			end
		end
	end)

	--[[ --Detects if player locks first person mode during a live game
	player.Changed:Connect(function(property)
		if property == "CameraMaxZoomDistance" or property == "CameraMode" then
			if player.CameraMaxZoomDistance <= 0.5 or player.CameraMode == Enum.CameraMode.LockFirstPerson then
				CameraController.SetFirstPersonCamera()
			end
		end
	end) ]]
	
	--Listens character dying
	humanoid.Died:Connect(function()
		CameraController.SetFixedCamera()
	end)
	
	--Sets first person camera in each render stepped
	ViewportController.RenderConnection = RunService.RenderStepped:Connect(function()
		if CameraController.Enabled then
			if player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
				CameraController.SetFirstPersonCamera()
			end
			ViewportController:Update()
		end
	end)

	--Set camera on dying or match end
	CharacterService.SetCamera:Connect(CameraController.SetFixedCamera)
end

function CameraController:KnitInit()
	
end


return CameraController