local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Knit = require(game:GetService("ReplicatedStorage").shared.Knit)
local Kits = require(ReplicatedStorage.shared.Modules.Kits)
local HUDController
local RoundService
local DeployService
local CharacterService
local CameraController
local DeployScreenController = Knit.CreateController { Name = "DeployScreenController" }

local guiAssets = ReplicatedStorage.Assets.Gui
local player: Player
local deployUI: ScreenGui
local kitChosen: boolean = false

function DeployScreenController.LoadSelectedMapsToVote(chosenMaps: table)
    --Clear old maps on vote 
    for _,v in ipairs(deployUI.MapSelection:GetChildren()) do
        if v:IsA("GuiButton") and v.Name ~= "ExampleMapButton" then
            v:Destroy()
        end
    end

    --Set scale of UIGridLayout based on number of maps to show for voting
    local amountOfMapsToDisplay = #chosenMaps
    local x = (1 / amountOfMapsToDisplay) - amountOfMapsToDisplay * 0.02
    local y = (2 / amountOfMapsToDisplay) - amountOfMapsToDisplay * 0.02
    deployUI.MapSelection.UIGridLayout.CellSize = UDim2.fromScale(x, y)

    --Load the maps
    for _,mapName in pairs(chosenMaps) do
        print(chosenMaps)
        local mapButton = deployUI.MapSelection.ExampleMapButton:Clone()
        mapButton.Name = mapName
        mapButton.MapName.Text = mapName
        mapButton.Visible = true

        --Check if map has icon to show
        local image = ReplicatedStorage.Assets.Icons:FindFirstChild(mapName, true) 
        
        if image then
            mapButton.MapPhoto.Image = image.Image
            mapButton.MapPhoto.Visible = true
        end
        --Bind click event to let player choose it
        mapButton.Activated:Connect(function()
            for _,v in ipairs(deployUI.MapSelection:GetChildren()) do
                if v:IsA("GuiButton") and v.Name == mapName then
                    v.UIStroke.Color = Color3.fromRGB(212, 177, 22)
                    v.Voted.Visible = true
                elseif v:IsA("GuiButton") then
                    v.UIStroke.Color = Color3.fromRGB(57, 57, 57)
                    v.Voted.Visible = false
                end
            end

            DeployScreenController.VoteForMap(mapName)
        end)

        mapButton.Parent = deployUI.MapSelection
    end


    --Before displaying maps check for status of round once more
    local voteStarted = RoundService:GetPhaseOfGame()
    if voteStarted == false then
        DeployScreenController.DisplayKitSelection()
    else
        DeployScreenController.DisplayMapSelection()
    end
end

--Gets the data of vote numbers and shows
function DeployScreenController.OnUpdateToMapVoting(mapVotes: table, timeLeft: number)
    --Just to not wait for servers update if voting already over
    if timeLeft ~= nil and timeLeft <= 0 then
        DeployScreenController.DisplayKitSelection()
    end

    for mapName, voteCount in pairs(mapVotes) do
        --If maps are still loading then don't count votes
        if deployUI.MapSelection:FindFirstChild(mapName) == nil then
            return
        end
        deployUI.MapSelection[mapName].VoteCount.Text = voteCount
    end

    --If time left for voting is provided then update that too
    if timeLeft ~= nil then
        deployUI.MapSelectionTimeLeft.Text = timeLeft
    end
end

function DeployScreenController.VoteForMap(chosenMapName: string)
    RoundService.VoteForMap:Fire(chosenMapName)

    --Before voting check for status of game
    local voteStarted = RoundService:GetPhaseOfGame()
    if voteStarted == false then
        DeployScreenController.DisplayKitSelection()
    else
        DeployScreenController.DisplayMapSelection()
    end
end

function DeployScreenController.DisplayKitSelection()
    DeployScreenController.SetStateOfDeployScreen(true)

    deployUI.MapSelection.Visible = false
    deployUI.MapSelectionLabel.Visible = false
    deployUI.MapSelectionTimeLeft.Visible = false

    deployUI.KitSelection.Visible = true
    deployUI.Deploy.Visible = true
end

function DeployScreenController.DisplayMapSelection()
    DeployScreenController.SetStateOfDeployScreen(true)
    
    deployUI.KitSelection.Visible = false
    deployUI.Deploy.Visible = false

    deployUI.MapSelection.Visible = true
    deployUI.MapSelectionLabel.Visible = true
    deployUI.MapSelectionTimeLeft.Visible = true
end

function DeployScreenController.SetStateOfDeployScreen(state: boolean)
    deployUI.Enabled = state
end

function DeployScreenController.SelectKit(kitName: string)
    --Send request to server to verify kit selection
    DeployService.SelectKit:Fire(kitName)

    kitChosen = true
end

function DeployScreenController.Deploy()
    --If no kit choosen then don't proceed
    if kitChosen == false then
        return
    end

    --Disable deploy UI
    DeployScreenController.SetStateOfDeployScreen(false)

    --Enable dark screen from effects gui
    local darkeningTween = TweenService:Create(player.PlayerGui.Effects.DarkScreen, TweenInfo.new(.5), {BackgroundTransparency = 0})
    darkeningTween:Play()

    --Send request to server
    DeployService:DeployCharacter()

    --Disable Deploy UI
    task.wait(0.5)
    darkeningTween.Completed:Connect(function()
        deployUI.Enabled = false
    end)

    --Reset Health
    HUDController.UpdateHealth(100)

    --Enable HUD
    HUDController.SetStateOfHUD(true)

    --Set First Person View
    CameraController.SetFirstPersonCamera()

    --Remove dark screen effect
    TweenService:Create(player.PlayerGui.Effects.DarkScreen, TweenInfo.new(.5), {BackgroundTransparency = 1}):Play()
end

function DeployScreenController.LoadKitsToUI()
    for kitName, kitTable in pairs(Kits) do
        local kit = deployUI.KitSelection.Kit:Clone()
        kit.Name = kitName
        kit.KitName.Text = kitName

        --Set labels for kit items
        kit.PrimaryWeaponName.Text = kitTable.Primary
        kit.SidearmWeaponName.Text = kitTable.Sidearm
        kit.EquipmentName.Text = kitTable.Equipment

        --Set icons for kit items
        local primaryWeaponImage = ReplicatedStorage.Assets.Icons.Weapons:FindFirstChild(kitTable.Primary) 
        local sidearmImage = ReplicatedStorage.Assets.Icons.Weapons:FindFirstChild(kitTable.Sidearm) 
        local equipmentImage = ReplicatedStorage.Assets.Icons.Weapons:FindFirstChild(kitTable.Equipment) 

        if primaryWeaponImage then
            kit.PrimaryWeapon.Image = primaryWeaponImage.Image
        end
        if sidearmImage then
            kit.Sidearm.Image = sidearmImage.Image
        end
        if equipmentImage then
            kit.Equipment.Image = equipmentImage.Image
        end

        --Set necessary properties
        kit.Visible = true
        
        --Listen for clicks to set kit for player
        kit.Activated:Connect(function()
            --Do the necessary effects
            for _,v in ipairs(deployUI.KitSelection:GetChildren()) do
                if v:IsA("GuiButton") and v.Name == kitName then
                    v.UIStroke.Color = Color3.fromRGB(212, 177, 22)
                    v.ChosenLabel.Visible = true
                elseif v:IsA("GuiButton") then
                    v.UIStroke.Color = Color3.fromRGB(57, 57, 57)
                    v.ChosenLabel.Visible = false
                end
            end

            DeployScreenController.SelectKit(kitName)
        end)

        --Parent to frame as final act
        kit.Parent = deployUI.KitSelection
    end
    
end

function DeployScreenController:KnitStart()
    DeployService = Knit.GetService("DeployService")
    RoundService = Knit.GetService("RoundService")
    HUDController = Knit.GetController("HUDController")
    CharacterService = Knit.GetService("CharacterService")
    CameraController = Knit.GetController("CameraController")
    player = Players.LocalPlayer

    deployUI = guiAssets.DeployScreen:Clone()
    deployUI.Parent = player.PlayerGui

    DeployScreenController.LoadKitsToUI()

    deployUI.Deploy.Activated:Connect(function()
        DeployScreenController.Deploy()
    end)

    RoundService.MapSelectionStarted:Connect(DeployScreenController.LoadSelectedMapsToVote)
    RoundService.RoundStarted:Connect(DeployScreenController.DisplayKitSelection)
    RoundService.OnMapSelectionUpdate:Connect(DeployScreenController.OnUpdateToMapVoting)
    CharacterService.CharacterDied:Connect(function()
        HUDController.SetStateOfHUD(false)
        DeployScreenController.SetStateOfDeployScreen(true)
        DeployScreenController.DisplayKitSelection()
    end)

    --Check what phase in current server is and show proper screen based on that response
    local mapVotingStarted = RoundService:GetPhaseOfGame()

    if mapVotingStarted == false then
        DeployScreenController.DisplayKitSelection()
    elseif mapVotingStarted == true then
        local mapsOnVoting = RoundService:GetOnVoteMaps()
        print("MapsOnVoting")
        DeployScreenController.LoadSelectedMapsToVote(mapsOnVoting)
        DeployScreenController.DisplayMapSelection()
    end
end

function DeployScreenController:KnitInit()
    
end

return DeployScreenController