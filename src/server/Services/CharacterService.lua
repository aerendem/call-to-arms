local Knit = require(game:GetService("ReplicatedStorage").shared.Knit)

local CharacterService = Knit.CreateService {
    Name = "CharacterService";
    Client = {
        CharacterDied = Knit.CreateSignal(),
        SetCamera = Knit.CreateSignal(),
    };
}

function CharacterService.CreateCharacter(): Model
    local character
  
    character:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
    character.Parent = workspace.Characters

    return character
end

function CharacterService.SpawnCharacter(player: Player, character: Character)
    local character = game.StarterPlayer.StarterCharacter

    --Find suitable position in current map
    local pos = CFrame.new(0,0,0)

    character:SetPrimaryPartCFrame(pos)
    character.Parent = workspace.Characters

    player.Character = character

    return player.Character
end

function CharacterService.RemoveCharacter(player: Player)
    --Don't call Destroy() if character is already removed
    if player.Character == nil then
        return false
    end

    --Tell client-side to fix their camera
    CharacterService.Client.SetCamera:Fire(player)

    --Remove character from game
    player.Character:Destroy()

    --Tell client-side to open their deployment UI
    CharacterService.Client.CharacterDied:Fire(player)
end

function CharacterService:KnitStart()
    
end


function CharacterService:KnitInit()
    
end


return CharacterService