local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HUDController
local WeaponService
local DeployService
local modules = ReplicatedStorage.shared.Modules
local CameraController
local PrimaryWeapons, Sidearms, Equipment
local Knit = require(ReplicatedStorage.shared.Knit)

local WeaponController = Knit.CreateController { Name = "WeaponController" }
local assets = ReplicatedStorage:WaitForChild("Assets")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local GRENADE_BLAST_TIME = 3
local currentLoadout = {
    Primary = "",
    Sidearm = "",
    Equipment = ""
}

local weaponAnims = {
    Primary = {},
    Sidearm = {},
    Equipment = {}
}

local weaponAmmos = {
    Primary = 0,
    Sidearm = 0,
    Equipment = 0
}

--Status variables
local firing = false
local swapping = false
local reloading = false
local aiming = false
local throwingStartTime = 0
local throwingEndTime = 0

local onHandWeaponType = "Primary"

function WeaponController.ShowImpactMark()
    
end

--Swap weapon to next weapon, Primary -> Sidearm -> Equipment -> Go back
function WeaponController.SwapCurrentWeapon()
    if onHandWeaponType == "Primary" then
        WeaponController.SwapWeaponTo("Sidearm")
    elseif onHandWeaponType == "Sidearm" then
        WeaponController.SwapWeaponTo("Equipment")
    else
        WeaponController.SwapWeaponTo("Primary")
    end
end

function WeaponController.SwapWeaponTo(weaponType: string)
    --Check if swap to is equipment and if player has enough equipment left to use
    if (swapping) or (weaponType == "Equipment" and weaponAmmos["Equipment"] <= 0) then
        return false
    end

    swapping = true
    local nameOfWeapon
    for _,v in ipairs(player.Backpack:GetChildren()) do
        if v:GetAttribute("ItemType") == weaponType then
            nameOfWeapon = v.Name
        end
    end

    --Unequip current weapon and equip new one
    player.Character.Humanoid:UnequipTools()

    --Stop the idle animation of to be swapped tool
    if onHandWeaponType == "Primary" or onHandWeaponType == "Sidearm" then
        weaponAnims[onHandWeaponType]["Idle"]:Stop()
    end

    if nameOfWeapon ~= nil and weaponType ~= "Equipment" then
         

        WeaponService.Equip:Fire(nameOfWeapon)

        weaponAnims[weaponType]["Idle"].Looped = true
        weaponAnims[weaponType]["Idle"]:Play()

        onHandWeaponType = weaponType

        HUDController.UpdateCurrentWeapon(weaponType, nameOfWeapon)
    end
    

    swapping = false
end

function WeaponController.ToggleAim()
    if aiming then
        
    else

    end
end

function WeaponController.Reload()
    --Check if eligible to reload
    if reloading == true then
        return false
    end

    reloading = true

    local tool = player.Character:FindFirstChildOfClass("Tool")

    --Play reload animation
    weaponAnims[onHandWeaponType]["Reload"].Stopped:Connect(function()
        tool.Mag.Transparency = 1

        task.wait(0.5)

        tool.Mag2.Transparency = 0
        tool.Mag.Transparency = 0

        if onHandWeaponType == "Primary" then
            weaponAmmos["Primary"] = PrimaryWeapons[currentLoadout["Primary"]].MagSize
        elseif onHandWeaponType == "Sidearm" then
            weaponAmmos["Primary"] = Sidearms[currentLoadout["Sidearm"]].MagSize
        end


        HUDController.UpdateAmmo(weaponAmmos["Primary"])

        reloading = false
    end)

    weaponAnims[onHandWeaponType]["Reload"]:Play()

    tool.Mag2.Transparency = 1
end

function WeaponController.CastRay()
    --Get camera and CFrame
    local camera = workspace.CurrentCamera
    local cameraCF = camera.CFrame

    local lengthOfRay = 1000

    -- Set an origin and directional vector
	local rayOrigin = cameraCF.Position
	local rayDirection = cameraCF.LookVector * lengthOfRay

	-- Build a "RaycastParams" object and cast the ray
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {Players.LocalPlayer.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if raycastResult then
		local hitPart = raycastResult.Instance
        print(raycastResult.Instance.Name)
		-- Check if the part is a child of Characters folder and if character has atleast 1 health
        if not (hitPart.Parent:FindFirstChildOfClass("Humanoid") or hitPart.Parent.Parent:FindFirstChildOfClass("Humanoid")) then
            --Create bullet hole
            local bulletHole = assets.BulletHole:Clone()
            bulletHole.Position = raycastResult.Position
            bulletHole.CFrame = CFrame.new(raycastResult.Position, raycastResult.Position + raycastResult.Normal + cameraCF.LookVector )
            bulletHole.Parent = workspace

            Debris:AddItem(bulletHole, 15)
            return
        end

        local enemyHumanoid

        if hitPart.Parent:FindFirstChildOfClass("Humanoid") then
            enemyHumanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid")
        elseif hitPart.Parent.Parent:FindFirstChildOfClass("Humanoid") then
            enemyHumanoid = hitPart.Parent.Parent:FindFirstChildOfClass("Humanoid")
        end

        if enemyHumanoid and enemyHumanoid.Health > 0 then
            HUDController.ShowHitmark()
            local distance = math.abs((rayOrigin - enemyHumanoid.Parent:GetPrimaryPartCFrame().Position).Magnitude)
            WeaponService.VerifyHit:Fire({rayOrigin, rayDirection, raycastResult.Position, distance, enemyHumanoid.Parent})
        end
	end
end

function WeaponController.Fire()
    --If current weapon is equipment then take the time of start of press
	if onHandWeaponType == "Equipment" then
		if weaponAmmos["Equipment"] >= 0 then
			throwingStartTime = os.time()
		end
	end

    --Check if character spawned, equipped tool and has enough ammo
    if not player.Character or not player.Character:FindFirstChildOfClass("Tool") or weaponAmmos[onHandWeaponType] - 1 < 0 then
        return
    end

    --Check if player not doing any other action
    if reloading or swapping then
        return
    end

    --Substract ammo
    weaponAmmos[onHandWeaponType] -= 1

    --Update ammo on HUD
    HUDController.UpdateAmmo(weaponAmmos[onHandWeaponType], nil)

    --Cast a ray to middle of players camera
    WeaponController.CastRay()

    --Play sound and muzzle flash
    local tool = player.Character:FindFirstChildOfClass("Tool")
    tool.GunTip.Fire:Play()
    tool.GunTip.MuzzleFlash:Emit(1)

    --Let server know we casted a ray to verify
    CameraController.ApplyRecoil()
    
end

function WeaponController.StopFire()
    --If current weapon is equipment aka grenades then throw
	if onHandWeaponType == "Equipment" and weaponAmmos["Equipment"] >= 0 then
		throwingEndTime = os.time()
		local targetPosition = mouse.Hit.p
		
		if throwingEndTime - throwingStartTime > 0 then
			WeaponController.Throw(targetPosition)	
		end
	end
end

function WeaponController.Throw(mousePos)
	local speed
	local differance = throwingEndTime - throwingStartTime 
	
	if differance < 1 then
		speed = 100
	elseif differance < 2 then
		speed = 130
	elseif differance < 3 then
		speed = 160
	end
	
    --Throw sample grenade
	local grenade = ReplicatedStorage.Assets.Throwables.Grenade:Clone()

	grenade.CFrame = CFrame.new(player.Character.Head.Position, mousePos)
	grenade.Parent = workspace
	grenade.Velocity = grenade.CFrame.lookVector * speed

    --Use up all ammo
    weaponAmmos["Equipment"] = 0

    --Wait, blast and remove
    coroutine.wrap(function()
        task.wait(GRENADE_BLAST_TIME)
        WeaponService.ThrewGrenade:Fire(grenade.Position)
        grenade:Destroy()
    end)()
end

function WeaponController.OnDeploy(loadout: table)
    --Reset anim table
    weaponAnims = { Primary = {}, Sidearm = {}, Equipment = {}}
    currentLoadout = loadout

    print(loadout)
    --Get full mag sizes from config files
    weaponAmmos["Primary"] = PrimaryWeapons[loadout["Primary"]].MagSize
    weaponAmmos["Sidearms"] = Sidearms[loadout["Sidearm"]].MagSize
    weaponAmmos["Equipment"] = 1
    
    local otherWeapons = table.clone(loadout)
    otherWeapons["Primary"] = nil

    --Update weapons, load animations for them
    local humanoid = player.Character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")

    for weaponType, animTable in pairs(weaponAnims) do
        if weaponType == "Primary" then
            for animName, animId in pairs(PrimaryWeapons[loadout["Primary"]].Animations) do
                local anim = Instance.new("Animation")
                anim.AnimationId = animId
                weaponAnims[weaponType][animName] = animator:LoadAnimation(anim)
                anim:Destroy()
            end
        elseif weaponType == "Sidearm" then
            for animName, animId in pairs(Sidearms[loadout["Sidearm"]].Animations) do
                local anim = Instance.new("Animation")
                anim.AnimationId = animId
                weaponAnims[weaponType][animName] = animator:LoadAnimation(anim)
                anim:Destroy()
            end
        elseif weaponType == "Equipment" then
            --for animName, animId in pairs(Equipment[loadout["Equipment"]].Animations) do
            --    local anim = Instance.new("Animation")
            --    anim.AnimationId = animId
            --    weaponAnims[weaponType][animName] = animator:LoadAnimation(anim)
            --    anim:Destroy()
            --end
        end
    end

    --Update HUD
    HUDController.UpdateWeapons(loadout)
    HUDController.UpdateAmmo(weaponAmmos["Primary"])

    WeaponController.SwapWeaponTo("Primary")
end

function WeaponController:KnitStart()
    CameraController = Knit.GetController("CameraController")
    HUDController = Knit.GetController("HUDController")
    WeaponService = Knit.GetService("WeaponService")
    DeployService = Knit.GetService("DeployService")

    PrimaryWeapons = require(modules.PrimaryWeapons)
    Sidearms = require(modules.Sidearms)
    Equipment = require(modules.Equipment)

    --Update GUI weapons and current loadout when player got deployed
    DeployService.PlayerDeployed:Connect(WeaponController.OnDeploy)
    WeaponService.UpdateHealth:Connect(HUDController.UpdateHealth)
end

function WeaponController:KnitInit()
    
end

return WeaponController