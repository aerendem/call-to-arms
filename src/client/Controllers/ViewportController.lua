--KNIIT
local Knit = require(game:GetService("ReplicatedStorage").shared.Knit)

--SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')
local Debris = game:GetService('Debris')

--MODULES
local Settings = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Modules"):WaitForChild("CameraSettings"))

--VARIABLES
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local aimOffset = Vector3.new(0,0,0) 
local ArmParts = {}
local armsVisible = Settings.ARM_TRANSPARENCY ~= 1
local sway = Vector3.new(0,0,0)
local walkSway = CFrame.new(0,0,0)
local strafeSway = CFrame.Angles(0,0,0)
local jumpSway = CFrame.new(0,0,0)
local jumpSwayGoal = Instance.new("CFrameValue")
local character, humanoid, humanoidRootPart, waist,  upperTorso,  lowerTorso,  rootHip,  leftShoulder,  rightShoulder,  leftArm,  rightArm

--Table that keeps fake Motor6D objects and body parts
local fakeParts = {
	["viewModel"] 		  	= nil,
	["fHumanoidRootPart"] 	= nil,
	["fUpperTorso"] 		= nil,
	["fLowerTorso"] 		= nil,
	["fWaist"] 				= nil,
	["fLeftShoulder"] 		= nil,
	["fRightShoulder"] 		= nil,
	["fRootHip"] 			= nil,
}


local ViewportController = Knit.CreateController { 
	Name = "ViewportController",
	Enabled = false,
	IsRunning = false,
	RenderConnection = nil,
	INCLUDE_JUMP_SWAY = nil,

}

--Creates fake body parts for positioning arms in firs person mode
function ViewportController:CreateFakes()
	fakeParts.viewModel = Instance.new("Model")
	fakeParts.viewModel.Name = "ViewModel"

	fakeParts.fHumanoidRootPart = Instance.new("Part")
	fakeParts.fHumanoidRootPart.Name = "HumanoidRootPart"
	fakeParts.fHumanoidRootPart.CanCollide = false
	fakeParts.fHumanoidRootPart.CanTouch = false
	fakeParts.fHumanoidRootPart.Anchored = true
	fakeParts.fHumanoidRootPart.Transparency = 1
	fakeParts.fHumanoidRootPart.Parent = fakeParts.viewModel

	fakeParts.viewModel.PrimaryPart = fakeParts.fHumanoidRootPart
	fakeParts.viewModel.WorldPivot = fakeParts.fHumanoidRootPart.CFrame + fakeParts.fHumanoidRootPart.CFrame.UpVector*5

	fakeParts.fUpperTorso = Instance.new("Part")
	fakeParts.fUpperTorso.Name = "UpperTorso"
	fakeParts.fUpperTorso.CanCollide = false
	fakeParts.fUpperTorso.CanTouch = false
	fakeParts.fUpperTorso.Transparency = 1
	fakeParts.fUpperTorso.Parent = fakeParts.viewModel

	fakeParts.fLowerTorso = Instance.new("Part")
	fakeParts.fLowerTorso.Name = "LowerTorso"
	fakeParts.fLowerTorso.CanCollide = false
	fakeParts.fLowerTorso.Anchored = false
	fakeParts.fLowerTorso.CanTouch = false
	fakeParts.fLowerTorso.Transparency = 1
	fakeParts.fLowerTorso.Parent = fakeParts.viewModel
end

--Adds character arm parts in a table
function ViewportController:CreateArmPartList(character: Model)
	table.insert(ArmParts, character:WaitForChild("RightLowerArm"))
	table.insert(ArmParts, character:WaitForChild("LeftUpperArm"))
	table.insert(ArmParts, character:WaitForChild("RightUpperArm"))
	table.insert(ArmParts, character:WaitForChild("LeftLowerArm"))
	table.insert(ArmParts, character:WaitForChild("RightLowerArm"))
	table.insert(ArmParts, character:WaitForChild("LeftHand"))
	table.insert(ArmParts, character:WaitForChild("RightHand"))
end

--Defines character body parts to variables
function ViewportController:SetParts()
	while character == nil do
		task.wait(0.1)
	end
	 upperTorso 	=  character:WaitForChild("UpperTorso", 3)
	 lowerTorso 	=  character:WaitForChild("LowerTorso", 3) or nil
	 waist			=  upperTorso:WaitForChild("Waist", 3) or nil
	 rootHip 		=  humanoidRootPart:FindFirstChildOfClass("Motor6D") or nil
	 leftShoulder	=  character:WaitForChild("LeftUpperArm",3):WaitForChild("LeftShoulder",5)
	 rightShoulder 	=  character:WaitForChild("RightUpperArm",3):WaitForChild("RightShoulder",5)
	 leftArm 		=  character:WaitForChild("LeftUpperArm",3)
	 rightArm 		=  character:WaitForChild("RightUpperArm",3)
end

--Creates new Motor6D objects and sets their attachments for visualizing arms in first person mode
function ViewportController:Setup()
	ViewportController:SetParts()

	fakeParts.fLeftShoulder 		 =  leftShoulder:Clone()
	fakeParts.fLeftShoulder.Name 	 =  "LeftShoulderClone"
	fakeParts.fLeftShoulder.Parent   =  fakeParts.fUpperTorso 
	fakeParts.fLeftShoulder.Part0    =  leftArm 

	fakeParts.fRightShoulder 		 =  rightShoulder:Clone()
	fakeParts.fRightShoulder.Name 	 =  "RightShoulderClone"
	fakeParts.fRightShoulder.Parent  =  fakeParts.fUpperTorso 
	fakeParts.fRightShoulder.Part0   =  rightArm 

	ViewportController:CreateArmPartList(character)

	fakeParts.fUpperTorso.Size 		 =  upperTorso.Size
	fakeParts.fUpperTorso.CFrame 	 = fakeParts.fHumanoidRootPart.CFrame

	fakeParts.fRootHip 				 =  lowerTorso:FindFirstChild("Root"):Clone() 
	fakeParts.fRootHip.Parent		 = fakeParts.fLowerTorso
	fakeParts.fRootHip.Part0 		 = fakeParts.fHumanoidRootPart
	fakeParts.fRootHip.Part1 		 = fakeParts.fLowerTorso

	fakeParts.fHumanoidRootPart.Size = humanoidRootPart.Size

	fakeParts.fWaist = if Settings.WAIST_MOVEMENTS then  waist:Clone() else Instance.new("Weld")
	fakeParts.fWaist.Parent = fakeParts.fUpperTorso
	fakeParts.fWaist.Part0 = fakeParts.fLowerTorso
	fakeParts.fWaist.Part1 = fakeParts.fUpperTorso

	if not Settings.WAIST_MOVEMENTS then
		fakeParts.fWaist.C0 =  waist.C0
		fakeParts.fWaist.C1 =  waist.C1
	end
	
	fakeParts.fLowerTorso.Size =  lowerTorso.Size
		
end

--Sets arms transparencies
function ViewportController:SetArmTransparency(visible: boolean)
	if armsVisible then
		for _, part in ipairs(ArmParts) do
			part.LocalTransparencyModifier = if not visible then 1 else Settings.ARM_TRANSPARENCY
			part.CastShadow = not visible
		end
	end
end

--Disables real shoulders and enables viewmodel joints
function ViewportController:Enable()
	character = player.Character

	while character:WaitForChild("Humanoid") == nil do
		task.wait(0.01)
	end

	humanoid = character.Humanoid
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	ViewportController:CreateFakes()
	ViewportController:Setup()

	fakeParts.viewModel.Parent = workspace.CurrentCamera
	camera.CameraSubject = workspace[player.Name].Humanoid 

	fakeParts.fRightShoulder.Enabled = true
	fakeParts.fLeftShoulder.Enabled = true
	
	leftShoulder.Enabled = false
	rightShoulder.Enabled = false

	fakeParts.fRightShoulder.Part1 =  rightArm
	fakeParts.fRightShoulder.Part0 = fakeParts.fUpperTorso
	fakeParts.fRightShoulder.Parent = fakeParts.fUpperTorso

	fakeParts.fLeftShoulder.Part1 =  leftArm
	fakeParts.fLeftShoulder.Part0 = fakeParts.fUpperTorso
	fakeParts.fLeftShoulder.Parent = fakeParts.fUpperTorso
	
	ViewportController.Enabled = true
end

-- Disables viewmodel joints and enables real character joints
function ViewportController:Disable()
	fakeParts.viewModel.Parent = nil

	
	fakeParts.fRightShoulder.Enabled = false
	fakeParts.fLeftShoulder.Enabled = false

	 leftShoulder.Parent =   leftArm 
	 leftShoulder.Part0 =  upperTorso
	 leftShoulder.Part1 =  leftArm

	 rightShoulder.Parent =  rightArm
	 rightShoulder.Part0 =  upperTorso
	 rightShoulder.Part1 =  rightArm

	 leftShoulder.Enabled = true
	 rightShoulder.Enabled = true

	ViewportController:SetArmTransparency(true)
end

--Controls player is in first person mode
function ViewportController:IsFirstPerson()
	return  player.CameraMode == Enum.CameraMode.LockFirstPerson
end

--Creates tween according to given parameters
function ViewportController:Tween(instance: CFrameValue, info: TweenInfo, properties: table): Tween
	return TweenService:Create(instance, info, properties)
end

function ViewportController.RecoilAnimation()
	local camEdit = Instance.new("CFrameValue")
	camEdit.Value = CFrame.new(0,0,0)*CFrame.Angles(math.rad(0.430)*Settings.SWAY_SIZE,0,0)

	local tweenInfo = TweenInfo.new((0.03*24)/Settings.SENSITIVITY, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local landRecovery = ViewportController:Tween(camEdit, tweenInfo, {Value = CFrame.new(0,0,0)})
	landRecovery:Play()
	Debris:AddItem(landRecovery, 3)

	-- Updates camera
	task.spawn(function()
		for i = 1,60 do
			camera.CFrame =  camera.CFrame*camEdit.Value
			RunService.Heartbeat:Wait()
		end
	end)
end

-- Animates the camera's landing "thump" and tweens a dummy cframe value for camera recoil
function ViewportController:LandingAnimation()
	
	local camEdit = Instance.new("CFrameValue")
	camEdit.Value = CFrame.new(0,0,0)*CFrame.Angles(math.rad(-0.75)*Settings.SWAY_SIZE,0,0)

	local tweenInfo = TweenInfo.new((0.03*6)/Settings.SENSITIVITY, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local landedRecoil =  ViewportController:Tween(camEdit, tweenInfo, {Value = CFrame.new(0,0,0)})
	landedRecoil:Play()
	Debris:AddItem(landedRecoil, 2)

	landedRecoil.Completed:Connect(function()
		camEdit.Value = CFrame.new(0,0,0)*CFrame.Angles(math.rad(0.225)*Settings.SWAY_SIZE,0,0)

		local tweenInfo = TweenInfo.new((0.03*24)/Settings.SENSITIVITY, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		local landRecovery =  ViewportController:Tween(camEdit, tweenInfo, {Value = CFrame.new(0,0,0)})
		landRecovery:Play()
		Debris:AddItem(landRecovery, 3)
	end)

	-- Updates camera
	task.spawn(function()
		for i = 1,60 do
			 camera.CFrame =  camera.CFrame*camEdit.Value
			RunService.Heartbeat:Wait()
		end
	end)

	-- animate the jump sway to make the viewmodel thump down on landing
	local tweenInfo = TweenInfo.new(0.15/Settings.SENSITIVITY, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local viewModelRecoil =  ViewportController:Tween(jumpSwayGoal, tweenInfo, {Value = CFrame.new(0,0,0)*CFrame.Angles(-math.rad(5)*Settings.SWAY_SIZE,0,0)})
	viewModelRecoil:Play()
	Debris:AddItem(viewModelRecoil, 2)

	viewModelRecoil.Completed:Connect(function()
		local tweenInfo = TweenInfo.new(0.7/Settings.SENSITIVITY, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		local viewModelRecovery =  ViewportController:Tween(jumpSwayGoal, tweenInfo, {Value = CFrame.new(0,0,0)})
		viewModelRecovery:Play()
		Debris:AddItem(viewModelRecovery, 2)
	end)
end

function ViewportController:JumpAnimation()
	local tweenInfo = TweenInfo.new(0.5/Settings.SENSITIVITY, Enum.EasingStyle.Sine)
	local viewModelJump =  ViewportController:Tween(jumpSwayGoal, tweenInfo, {Value = CFrame.new(0,0,0)*CFrame.Angles(math.rad(7.5)*Settings.SWAY_SIZE,0,0)})
	viewModelJump:Play()
	Debris:AddItem(viewModelJump, 2)
end

function ViewportController:Reset()
	ViewportController.RenderConnection:Disconnect()
	fakeParts.fLeftShoulder:Destroy()
	fakeParts.fRightShoulder:Destroy()
	fakeParts.viewModel:Destroy()

	if  upperTorso:FindFirstChild("Waist") then
		 upperTorso.Waist.Enabled = true
		 upperTorso.Anchored = false
	end

	ViewportController:SetArmTransparency(true)
end

function ViewportController:VisualizeArms()
	for _, part in ipairs(ArmParts) do
		part.LocalTransparencyModifier = 0
		part.Changed:connect(function (property)
			part.LocalTransparencyModifier = 0
		end)
	end
end

-- Updates arms and performs shoulder animations
function ViewportController:Update()
	
	ViewportController:VisualizeArms()
	
	if not ViewportController.Enabled then
		ViewportController:Enable()
		ViewportController:SetArmTransparency(true)
	end

	if ViewportController. IsRunning and Settings.INCLUDE_WALK_SWAY and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and humanoid:GetState() ~= Enum.HumanoidStateType.Landed then -- update walk sway if we are walking
		walkSway =
			walkSway:Lerp(
				CFrame.new(
					(0.1 * Settings.SWAY_SIZE) * math.sin(tick() * (2 * humanoid.WalkSpeed/4)),
					(0.1  *Settings.SWAY_SIZE) * math.cos(tick() * (4 * humanoid.WalkSpeed/4)),
					0) * CFrame.Angles(0, 0, (-.05 * Settings.SWAY_SIZE) * math.sin(tick() * (2 * humanoid.WalkSpeed/4)))
				, 0.1 * Settings.SENSITIVITY)

	else
		walkSway = walkSway:Lerp(CFrame.new(), 0.05*Settings.SENSITIVITY)
	end

	local delta = UserInputService:GetMouseDelta()
	
	if Settings.INCLUDE_CAMERA_SWAY then
		sway = sway:Lerp(Vector3.new(delta.X,delta.Y,delta.X/2), 0.1*Settings.SENSITIVITY)
	end

	if Settings.INCLUDE_STRAFE then
		local rz = humanoidRootPart.CFrame.RightVector:Dot(humanoid.MoveDirection)/(10/Settings.SWAY_SIZE) 
		strafeSway = strafeSway:Lerp(CFrame.Angles(0, 0, -rz), 0.1 * Settings.SENSITIVITY)
	end

	if ViewportController.INCLUDE_JUMP_SWAY then
		jumpSway = jumpSwayGoal.Value
	end

	fakeParts.fRightShoulder.Transform =  rightShoulder.Transform
	fakeParts.fLeftShoulder.Transform =  leftShoulder.Transform

	if Settings.WAIST_MOVEMENTS  then
		fakeParts.fWaist.Transform =  waist.Transform
	end

	local completedCFrame = ( camera.CFrame*walkSway*jumpSway*strafeSway*CFrame.Angles(math.rad(sway.Y*Settings.SWAY_SIZE),math.rad(sway.X*Settings.SWAY_SIZE)/10,math.rad(sway.Z*Settings.SWAY_SIZE)/2))+( camera.CFrame.UpVector*(-1.7-(Settings.HEAD_OFFSET.Y+(aimOffset.Y))))+( camera.CFrame.LookVector*(Settings.HEAD_OFFSET.Z+(aimOffset.Z)))+( camera.CFrame.RightVector*(-Settings.HEAD_OFFSET.X-(aimOffset.X)+(-(sway.X*Settings.SWAY_SIZE)/75)))

	fakeParts.viewModel:SetPrimaryPartCFrame(completedCFrame)
		
end

function ViewportController:KnitStart()
	while player.Character == nil do
		task.wait(0.01)
	end
	character = player.Character

	while character:WaitForChild("Humanoid") == nil do
		task.wait(0.01)
	end

	humanoid = character.Humanoid
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
end


function ViewportController:KnitInit()

end


return ViewportController