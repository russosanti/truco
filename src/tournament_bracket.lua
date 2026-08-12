-- Tournament brackets logic

TOURNAMENT_ROUND_NAMES = { 'Round of 16', 'Quarterfinal', 'Semifinal', 'Final' }
TOURNAMENT_ROUND_FORMAT = { 'single_chico', 'single_chico', 'single_chico', 'best_of_3' }

-- Decide AI vs AI match winner
function resolveOtherMatch(nameA, nameB)
    return math.random(2) == 1 and nameA or nameB
end

-- 16 slots. Player appears in random slot
function buildBracket(playerName, aiNames)
    local slots = {}
    for i, name in ipairs(aiNames) do
        slots[i] = name
    end
    table.insert(slots, math.random(#slots + 1), playerName)

    local pairings = {}
    for i = 1, #slots, 2 do
        pairings[#pairings + 1] = { slots[i], slots[i + 1] }
    end

    return { playerName = playerName, round = 1, rounds = { pairings } }
end

-- Who won round (r) match (m)
function matchWinner(bracket, r, m)
    local nextRound = bracket.rounds[r + 1]
    if not nextRound then
        return nil
    end
    local pair = nextRound[math.ceil(m / 2)]
    return pair and pair[(m - 1) % 2 + 1]
end

-- The name facing the player this round
function playerOpponent(bracket)
    for _, pair in ipairs(bracket.rounds[bracket.round]) do
        if pair[1] == bracket.playerName then return pair[2] end
        if pair[2] == bracket.playerName then return pair[1] end
    end
    return nil
end

-- Resolve this round winner
function advanceRound(bracket, playerWon)
    local winners = {}
    for _, pair in ipairs(bracket.rounds[bracket.round]) do
        local player = (pair[1] == bracket.playerName and 1)
            or (pair[2] == bracket.playerName and 2) or nil
        if player and playerWon ~= nil then
            winners[#winners + 1] = playerWon and bracket.playerName or pair[3 - player]
        else
            winners[#winners + 1] = resolveOtherMatch(pair[1], pair[2])
        end
    end

    local pairings = {}
    for i = 1, #winners, 2 do
        pairings[#pairings + 1] = { winners[i], winners[i + 1] }
    end

    bracket.round = bracket.round + 1
    bracket.rounds[bracket.round] = pairings
    return bracket
end
