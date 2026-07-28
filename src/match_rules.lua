-- Pure match-structure math (PRD 5): when a chico is won, and when enough
-- chicos add up to a partida. No LÖVE, no state -- HandLoopState calls these.

CHICO_TARGET = 30

-- Deliberately >=, not ==: falta envido and truco can both overshoot 30.
function chicoWinner(humanScore, aiScore)
    if humanScore >= CHICO_TARGET then return 'human' end
    if aiScore >= CHICO_TARGET then return 'ai' end
    return nil
end

function chicosNeeded(matchFormat)
    return matchFormat == 'single_chico' and 1 or 2
end

-- Needing 2 covers "best of 3, 3rd decisive at 1-1" on its own: 1-1 doesn't
-- satisfy this yet, and whoever takes the third chico necessarily reaches 2.
function partidaWinner(chicosWon, matchFormat)
    local needed = chicosNeeded(matchFormat)
    if chicosWon.human >= needed then return 'human' end
    if chicosWon.ai >= needed then return 'ai' end
    return nil
end
