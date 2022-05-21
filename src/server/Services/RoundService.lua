local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(game:GetService("ReplicatedStorage").shared.Knit)
local Timer = require(ReplicatedStorage.shared.Timer)
local CharacterService
local RoundService = Knit.CreateService {
    Name = "RoundService";
    Client = {
        VoteForMap = Knit.CreateSignal(),
        MapSelectionStarted = Knit.CreateSignal(),
        OnMapSelectionUpdate = Knit.CreateSignal(),

        SendStatusOfGameOnPlayerJoin = Knit.CreateSignal(),

        RoundEnded = Knit.CreateSignal(),
        RoundStarted = Knit.CreateSignal(),
    };
    
}

local ROUND_PLAYER_REQUIREMENT = 1
local MAP_VOTE_MAP_COUNT = 10
local MAP_VOTING_INTERVAL = 5

local mapVoteData = {
    --mapName = {Players voted for}
}
local assets: Folder = ReplicatedStorage:WaitForChild("Assets")
local maps: Folder = assets:WaitForChild("Maps")
local mapVotingStarted: boolean = true

local function GetMostVotedMap()
    local mostVotedMap
    local tempVoteCount = 0

    for mapName, votersList in pairs(mapVoteData) do
        if #votersList > tempVoteCount then
            mostVotedMap = mapName
        end
    end

    return mostVotedMap
end

local function AwaitForEnoughPlayersToStart()
    local timer = Timer.new(0.5)

    timer.Tick:Connect(function()
        if #Players:GetChildren() >= ROUND_PLAYER_REQUIREMENT then
            RoundService.StartMapSelection()
            timer:Destroy()
        end
    end)

    timer:Start()
end

---Starts round, loads map and notifies players to do UI adjustments
function RoundService.StartRound()
    local chosenMap = GetMostVotedMap()

    --If there was some equal status between votes on maps or no votes casted get a random map
    if chosenMap == nil then
        local random = Random.new()
        local mapList = maps:GetChildren()
        chosenMap =  mapList[random:NextInteger(1, #mapList)].Name
    end

    --Load the map
    local mapToLoad: Model = maps:FindFirstChild(chosenMap):Clone()
    mapToLoad.Parent = game.Workspace.CurrentMap

    --Start the round
    RoundService.Client.RoundStarted:FireAll()
end

---Finishes round, unloads map and directs players to main UI
function RoundService.EndRound(winnerPlayerUserId: number)
    --Let players know round ended and give them winner of round to display
    RoundService.Client.RoundEnded:FireAll(Players:GetPlayerByUserId(winnerPlayerUserId).DisplayName)
    
    --Wait for players to properly see who won
    task.wait(7.5)

    --Unload the map
    game.Workspace.CurrentMap:ClearAllChildren()

    --Remove characters of players
    for _,v in ipairs(Players:GetChildren()) do
        CharacterService.RemoveCharacter(v)
    end

    --Start match selection
    RoundService.StartMapSelection()
end

---
function RoundService.OnVoteForMap(player: Player, votedMap: string)
    --Check if voting in-place and existance of map
    if mapVotingStarted == false or maps[votedMap] == nil then
        return false
    end

    --Check if player voted for any map and if voted remove it from
    for mapName, votersList in pairs(mapVoteData) do
        local index = table.find(votersList, player)
        if index then
            table.remove(mapVoteData[mapName], index)
        end
    end

    --Add vote of player
    table.insert(mapVoteData[votedMap], player)

    RoundService.UpdateClientsWithMapVoting()
end

---
function RoundService.UpdateClientsWithMapVoting(timeLeft: number)
    --Only use mapName and voter count when sending voting data to clients to have low bandwith
    local mapVotingData = {}
    for mapName, mapVoters in pairs(mapVoteData) do
        mapVotingData[mapName] = #mapVoters
    end

    --Update players
    RoundService.Client.OnMapSelectionUpdate:FireAll(mapVotingData, timeLeft)
end

---Does Map Voting, awaits for pre-defined amount of time and when round 
function RoundService.StartMapSelection()
    mapVotingStarted = true

    --Empty the data table if it was usen
    mapVoteData = {}

    --Assemble a table of current maps, get amount of maps currently playable
    local mapsTable = maps:GetChildren()
    local amountOfMaps = #mapsTable

    --Create an empty table for maps that will be voted
    local chosenMaps = {}

    --Create random object per vote not for per loop cycle
    local randomObj = Random.new()

    --If there is not enough maps in game to do voting, just get all
    if amountOfMaps > MAP_VOTE_MAP_COUNT then
        for i = 1, MAP_VOTE_MAP_COUNT do
            local index = randomObj:NextInteger(1, amountOfMaps - i)
    
            if mapsTable[index] == nil then
                continue
            end
    
            --Chose map to vote for
            chosenMaps[i] = mapsTable[randomObj:NextInteger(1, amountOfMaps)].Name
    
            --Remove chosen map to not add same map more than once for voting
            mapsTable[i] = nil
        end
    else
        for _,v in ipairs(mapsTable) do
            table.insert(chosenMaps, v.Name)
        end
    end

    --Create default vote lists for chosen maps
    for _,mapName in pairs(chosenMaps) do
        mapVoteData[mapName] = {}
    end

    --Await for pre-defined amount of time for players to vote their selected map
    local timer = Timer.new(1)
    local progress = 0
    timer.Tick:Connect(function()
        if progress >= MAP_VOTING_INTERVAL then
            mapVotingStarted = false
            RoundService.StartRound()
            timer:Destroy()
        end

        progress += 1

        RoundService.UpdateClientsWithMapVoting(MAP_VOTING_INTERVAL - progress)
    end)

    --Let players open their map selection frames with the data they got
    print(chosenMaps)
    RoundService.Client.MapSelectionStarted:FireAll(chosenMaps)
    timer:Start()
end

function RoundService.Client:GetOnVoteMaps()
    local mapDataToReturn = {}

    for mapName, _ in pairs(mapVoteData) do
        table.insert(mapDataToReturn, mapName)
    end

    return mapDataToReturn
end

function RoundService.Client:GetPhaseOfGame()
    print(mapVotingStarted)
    return mapVotingStarted
end

function RoundService:KnitStart()
    CharacterService = Knit.GetService("CharacterService")
    if #Players:GetChildren() >= ROUND_PLAYER_REQUIREMENT then
        RoundService.StartMapSelection()
    else
        AwaitForEnoughPlayersToStart()
    end

    RoundService.Client.VoteForMap:Connect(RoundService.OnVoteForMap)
end

function RoundService:KnitInit() end

return RoundService