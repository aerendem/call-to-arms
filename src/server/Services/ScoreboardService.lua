local Players = game:GetService("Players")
local Knit = require(game:GetService("ReplicatedStorage").shared.Knit)
local RoundService
local ScoreboardService = Knit.CreateService {
    Name = "ScoreboardService";
    Client = {
        OnScoreboardUpdate = Knit.CreateSignal(),
        UpdateOnKillFeed = Knit.CreateSignal(),
    };
    scoreboard = {},
}

local ROUND_WIN_KILL_AMOUNT = 2
local boardFields = {Kill = 0, Death = 0}

function ScoreboardService.IncreaseScore(playerUserId: number, scoreName: string)
    --Check for player existance and score name
    if Players:GetPlayerByUserId(playerUserId) == nil or boardFields[scoreName] == nil then
        return false
    end

    --Change the actual value in data
    ScoreboardService.scoreboard[playerUserId][scoreName] += 1

    --If changed score is Kill and equal or exceeded 25 mark the round win for player and end it
    if scoreName == "Kill" and ScoreboardService.scoreboard[playerUserId][scoreName] >= ROUND_WIN_KILL_AMOUNT then
        RoundService.EndRound(playerUserId)
    end

    
    --Proceed to notify to clients to update their screen
    ScoreboardService.UpdateScoreboard()
end

function ScoreboardService.UpdateScoreboard()
    ScoreboardService.Client.OnScoreboardUpdate:FireAll(ScoreboardService.scoreboard)
end

function ScoreboardService.ResetScoreboard()
    --Reset data
    for userId, detail in pairs(ScoreboardService.scoreboard) do
        ScoreboardService.scoreboard[userId] = boardFields
    end

    ScoreboardService.UpdateScoreboard()
end

function ScoreboardService:KnitStart()
    RoundService = Knit.GetService("RoundService")
    --Listen from client-side for add or removal of players from scoreboard
    Players.PlayerAdded:Connect(function(player: Player)
        ScoreboardService.scoreboard[player.UserId] = boardFields
    end)

    Players.PlayerRemoving:Connect(function(player: Player)
        ScoreboardService.scoreboard[player.UserId] = nil
    end)
end

function ScoreboardService:KnitInit()
    
end

return ScoreboardService