local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(game:GetService("ReplicatedStorage").shared.Knit)
local ScoreboardService
local RoundService
local Timer = require(ReplicatedStorage.shared.Timer)
local HUDController = Knit.CreateController { Name = "HUDController" }

local MAX_NUMBER_OF_FRAMES_ON_KILL_FEED = 5
local KILL_FEED_VISIBILITY_TIME = 7
local HITMARK_VISIBILITY_TIME = 0.1

local iconAssets = ReplicatedStorage.Assets.Icons
local guiAssets = ReplicatedStorage.Assets.Gui
local hud: ScreenGui
local effectsGui: ScreenGui
local hitmarkDebounce = false

function HUDController.SetStateOfHUD(state: boolean)
    hud.Enabled = state
end

function HUDController.OnRoundEnd(winnerPlayerName: string)
    --Show winner
    hud.WinnerPlayer.Text = winnerPlayerName

    hud.WinnerLabel.Visible = true
    hud.WinnerPlayer.Visible = true

    --Make winner labels invisible after 10 secs
    local timer = Timer.new(1)
    local progress = 0
    timer.Tick:Connect(function()
        if progress >= 10 then
            hud.WinnerLabel.Visible = false
            hud.WinnerPlayer.Visible = false
            timer:Destroy()
        end
        progress += 1
    end)
    timer:Start()
end

function HUDController.ShowHitmark()
    if hitmarkDebounce ~= true then
        hitmarkDebounce = true
        hud.Crosshair.Hitmark.Visible = true
        coroutine.wrap(function()
            task.wait(HITMARK_VISIBILITY_TIME)
            hud.Crosshair.Hitmark.Visible = false
            hitmarkDebounce = false
        end)()
    else
        return
    end
end

function HUDController.UpdateAmmo(currentAmmo: number, ammoLeft: number)
    hud.AmmoCount.CurrentAmmo.Text = currentAmmo
    hud.AmmoCount.AmmoLeft.Text = "inf"
end

function HUDController.UpdateWeapons(loadout: table)
    --Set images for all
    for _,v in ipairs(hud.UnequippedWeapons:GetChildren()) do
        if v:IsA("GuiButton") then
            local image = iconAssets.Weapons:FindFirstChild(loadout[v.Name]) 

            if image then
                v.Image = image.Image
            else
                v.Image = ""
            end
        end
    end

    --Change icon of current weapon and label of weapon name too
    HUDController.UpdateCurrentWeapon("Primary", loadout["Primary"])
end

function HUDController.UpdateCurrentWeapon(swappedWeaponType: string, name: string)
    for _,v in ipairs(hud.UnequippedWeapons:GetChildren()) do
        if v:IsA("GuiButton") and v.Name == swappedWeaponType then
            v.Visible = false
        elseif v:IsA("GuiButton") then
            v.Visible = true
        end
    end

    hud.CurrentWeapon.Image = hud.UnequippedWeapons[swappedWeaponType].Image
    hud.CurrentWeapon.WeaponLabel.Text = name
end

function HUDController.UpdateHealth(newHealth: number, maxHealth: number)
    --Set transparency for red outline based on if it's full health or damaged
    if newHealth == 100 then 
        hud.Health.UIGradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0), -- (time, value)
            NumberSequenceKeypoint.new(1, 0)
        }
    else
        --Get middle point for number sequence
        local midPoint = 1 / (100 / newHealth)

        --Set transparency for red outline
        hud.Health.UIGradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0), -- (time, value)
            NumberSequenceKeypoint.new(midPoint, 1),
            NumberSequenceKeypoint.new(1, 1)
        }
    end
end

function HUDController.UpdateKillFeed(killerName: string, nameOfKilled: string)
    --If current kill feed frames are higher than predefined limit than remove the oldest one
    local amountOfFeedOnScreen = #hud.KillFeed:GetChildren() - 2 --Substracting 2 because of example frame and layout object

    --Remove oldest one
    if amountOfFeedOnScreen + 1 > MAX_NUMBER_OF_FRAMES_ON_KILL_FEED then
        if hud.KillFeed:GetChildren()[3] then
            hud.KillFeed:GetChildren()[3]:Destroy()
        end
    end

    --Add new one
    local feedFrame = hud.KillFeed.KillFrame:Clone()
    feedFrame.Killed.Text = nameOfKilled
    feedFrame.Killer.Text = killerName

    local order = (#hud.KillFeed:GetChildren() - 2) + 1

    feedFrame.Name = order
    feedFrame.LayoutOrder = order

    feedFrame.Visible = true

    --Set time for the one created to remove after some time
    local progress = 0

    Timer.Simple(1, function()
        if progress >= KILL_FEED_VISIBILITY_TIME then
            if feedFrame then 
                feedFrame:Destroy() 
            end
        end
        progress += 1

        if not feedFrame then 
            return
        end
    end)

    feedFrame.Parent = hud.KillFeed
end

function HUDController.UpdateScoreboard(scoreboard)
    for userId, scoreTable in pairs(scoreboard) do
        for scoreName, score in pairs(scoreTable) do
            hud.Scoreboard.Content[userId][scoreName].Text = score

            --Set order as well, glow the frame if it's the top player
            if scoreName == "Kill" then
                hud.Scoreboard.Content[userId].LayoutOrder = score
            end
        end
    end
end

function HUDController.CreateNewScoreboardField(player: Player)
    local frame = hud.Scoreboard.Content.Playerboard:Clone()
    frame.Name = player.UserId --Keeping frame with UserId for to prevent confusion with players with same username
    frame.PlayerName.Text = player.Name
    frame.Kill.Text = 0
    frame.Death.Text = 0

    frame.Visible = true

    frame.Parent = hud.Scoreboard.Content

    return frame
end

function HUDController.BuildScoreboard()
    local playerList = Players:GetChildren()

    --Create fields for existing players in-game
    for _,v in ipairs(playerList) do
        HUDController.CreateNewScoreboardField(v)
    end

    --Listen from client-side for add or removal of players from scoreboard
    Players.ChildAdded:Connect(function(child:Player)
        HUDController.CreateNewScoreboardField(child)
    end)

    Players.ChildRemoved:Connect(function(child: Player)
        if hud.Scoreboard.Content[child.UserId] then
            hud.Scoreboard.Content[child.UserId]:Destroy()
        end
    end)

    --Listen for updates
    ScoreboardService.OnScoreboardUpdate:Connect(HUDController.UpdateScoreboard)
end

function HUDController:KnitStart()
    ScoreboardService = Knit.GetService("ScoreboardService")
    RoundService = Knit.GetService("RoundService")

    hud = guiAssets.HUD:Clone()
    hud.Parent = Players.LocalPlayer.PlayerGui

    effectsGui = guiAssets.Effects:Clone()
    effectsGui.Parent = Players.LocalPlayer.PlayerGui

    HUDController.BuildScoreboard()

    RoundService.RoundEnded:Connect(HUDController.OnRoundEnd)
    ScoreboardService.UpdateOnKillFeed:Connect(HUDController.UpdateKillFeed)
end

function HUDController:KnitInit()
    
end

return HUDController