local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.shared.Knit)
local modules = ReplicatedStorage.shared.Modules
local PrimaryWeapons, Sidearms, Equipment
local ScoreboardService
local CharacterService
local WeaponService = Knit.CreateService {
    Name = "WeaponService";
    Client = {
        VerifyHit = Knit.CreateSignal(),
        Equip = Knit.CreateSignal(),
        Unequip = Knit.CreateSignal(),
        UpdateHealth = Knit.CreateSignal(),
        ThrewGrenade = Knit.CreateSignal(),
    };
}

local EXPLOSION_RADIUS

local function CreateMotor6D(character)
    local M6D = Instance.new("Motor6D")
    M6D.Enabled = true
    M6D.Name = "ToolGrip"
    M6D.Part0 = character.RightUpperArm
    M6D.Parent = character.RightUpperArm
end

function WeaponService.EquipItem(player: Player, toolName: string)
    print("EquipItem")
    if player.Character.RightUpperArm:FindFirstChild("ToolGrip") == nil then
        CreateMotor6D(player.Character)
    end
    print(player.Character.RightUpperArm.ToolGrip)
    local tool = player.Backpack[toolName]
    player.Character.Humanoid:EquipTool(tool)
    player.Character.RightUpperArm.ToolGrip.Part1 = tool.Handle1
end

function WeaponService.UnequipItem(player: Player, toolName: string)
    if player.Character.RightUpperArm:FindFirstChild("ToolGrip") ~= nil then
        player.Character.RightUpperArm.ToolGrip.Part1 = nil
    end
end

function WeaponService.MakeExplosion(player: Player, grenadePos: Vector3)
    --Currently there are no sanity or verification checks for grenades because of time constraints of this project
    local explosion = Instance.new("Explosion")
    explosion.BlastRadius = EXPLOSION_RADIUS
    explosion.Parent = workspace

end

function WeaponService.VerifyHit(player: Player, infoFromClient: table)
    --Check if player is close to where they are to verify
    if math.abs((infoFromClient[1] - player.Character:GetPrimaryPartCFrame().Position).Magnitude) > 25 then
        print("1")
        return false
    end

    --Check if target is close to where they are
    if math.abs((infoFromClient[3] - infoFromClient[5]:GetPrimaryPartCFrame().Position).Magnitude) > 25 then
        print("2")
        return false
    end

    --Check if server can cast a ray to point they did
    local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local raycastResult = workspace:Raycast(infoFromClient[1], infoFromClient[2], raycastParams)

	if raycastResult then
		local hitPart = raycastResult.Instance

        local enemyHumanoid

        if hitPart.Parent:FindFirstChildOfClass("Humanoid") then
            enemyHumanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid")
        elseif hitPart.Parent.Parent:FindFirstChildOfClass("Humanoid") then
            enemyHumanoid = hitPart.Parent.Parent:FindFirstChildOfClass("Humanoid")
        end

		-- Check if server hit something and it's same with character client supposedly hit
		if not enemyHumanoid and not enemyHumanoid == infoFromClient[5] then
            return false
        end


        local damageToGive
        local tool = player.Character:FindFirstChildOfClass("Tool")
        if not tool then
            return
        end

        if tool:GetAttribute("ItemType") == "Primary" then
            damageToGive = PrimaryWeapons[tool.Name].Damage
        elseif tool:GetAttribute("ItemType") == "Sidearm" then
            damageToGive = Sidearms[tool.Name].Damage
        elseif tool:GetAttribute("ItemType") == "Equipment" then
            damageToGive = Equipment[tool.Name].Damage
        end

        if enemyHumanoid.Health <= 0 then
            return 
        end

        enemyHumanoid.Health -= damageToGive

        local enemyPlayer = Players:GetPlayerFromCharacter(enemyHumanoid.Parent)
        WeaponService.Client.UpdateHealth:Fire(enemyPlayer, enemyHumanoid.Health)

        if enemyHumanoid.Health <= 0 then
            --Increase Kill score for killer
            ScoreboardService.IncreaseScore(player.UserId, "Kill")

            --Increase Death score for killed
            ScoreboardService.IncreaseScore(enemyPlayer.UserId, "Death")

            --Remove character of killed player
            CharacterService.RemoveCharacter(enemyPlayer)

            --Use Scoreboard's RemoteSignal for update on kill feed
            ScoreboardService.Client.UpdateOnKillFeed:FireAll(player.Name, enemyPlayer.Name)
        end
	end
end

function WeaponService:KnitStart()
    ScoreboardService = Knit.GetService("ScoreboardService")
    CharacterService = Knit.GetService("CharacterService")

    PrimaryWeapons = require(modules.PrimaryWeapons)
    Sidearms = require(modules.Sidearms)
    Equipment = require(modules.Equipment)

    WeaponService.Client.Equip:Connect(WeaponService.EquipItem)
    WeaponService.Client.VerifyHit:Connect(WeaponService.VerifyHit)
    WeaponService.Client.ThrewGrenade:Connect(WeaponService.MakeExplosion)
end

function WeaponService:KnitInit()
    
end

return WeaponService