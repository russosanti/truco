-- Rules for match winners and format

CHICO_TARGET = 30

function chicoWinner(playerScore, aiScore)
    if playerScore >= CHICO_TARGET then return 'player' end -- check >= in case we go over
    if aiScore >= CHICO_TARGET then return 'ai' end
    return nil
end

function chicosNeeded(matchFormat)
    return matchFormat == 'single_chico' and 1 or 2
end

-- Needing 2 covers "best of 3
function partidaWinner(chicosWon, matchFormat)
    local needed = chicosNeeded(matchFormat)
    if chicosWon.player >= needed then return 'player' end
    if chicosWon.ai >= needed then return 'ai' end
    return nil
end
