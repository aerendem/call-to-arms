local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kits = require(ReplicatedStorage.shared.Modules.Kits)
local CharacterService 
local Knit = require(game:GetService("ReplicatedStorage").shared.Knit)

local DeployService = Knit.CreateService {
    Name = "DeployService";
    Client = {
        SelectKit = Knit.CreateSignal(),
        PlayerDeployed = Knit.CreateSignal(),
    };
    PlayerKits = {},
}
local weaponAssets = ReplicatedStorage.Assets.Weapons

function DeployService.ApproveKit(player: Player, selectedKit: string)
    --Check if selected kit exists
    if Kits[selectedKit] == nil then
        return false
    end

    --Save kit
    DeployService.PlayerKits[player] = selectedKit
end

function DeployService:ApplyKitToCharacter(player: Player)
   --Get weapons and add to character
    local playerKit = DeployService.PlayerKits[player]
    local items = {}

    --Compile tools into a table
    for itemType, itemName in pairs(Kits[playerKit]) do
        local tool = weaponAssets[itemType]:FindFirstChild(itemName)

        if tool == nil then
            warn(itemName.." is non-existant")
            continue
        else
            table.insert(items, tool)
        end
    end

    --Add tools to character
    for _,tool in ipairs(items) do
        local copiedTool = tool:Clone()

        --TODO

        copiedTool.Parent = player.Character
    end

    return true
end

function DeployService.Client:DeployCharacter(player: Player)
    player:LoadCharacter()

    --Create character and complete necessary preparations
    --local character = CharacterService.CreateCharacter()

    --Parent it to workspace and in some other pos

    --Apply kit
    local applied = DeployService:ApplyKitToCharacter(player)

    --CharacterService.SpawnCharacter(player, character)
    DeployService.Client.PlayerDeployed:Fire(player, Kits[DeployService.PlayerKits[player]])

    --Return answer
    return applied
end

function DeployService:KnitStart()
    CharacterService = Knit.GetService("CharacterService")

    DeployService.Client.SelectKit:Connect(DeployService.ApproveKit)
end

function DeployService:KnitInit()
    
end

return DeployService