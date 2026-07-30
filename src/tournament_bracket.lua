-- Single-elimination bracket (PRD 8 §6): pure data + advancement, no drawing.
-- Match lengths come from the design doc's §7 table.

TOURNAMENT_ROUND_NAMES = { 'Round of 16', 'Quarterfinal', 'Semifinal', 'Final' }
TOURNAMENT_ROUND_FORMAT = { 'single_chico', 'single_chico', 'single_chico', 'best_of_3' }

-- Only the human's own path is ever really played, so the other 15 entrants
-- exist purely so the bracket looks and advances like a real one -- who wins
-- those matters only for which name turns up next round. A coin flip is enough.
function resolveOtherMatch(nameA, nameB)
    return math.random(2) == 1 and nameA or nameB
end

-- 16 slots (human dropped in a random one), paired (1,2) (3,4) ... Every round's
-- pairings are kept in `rounds` so the whole bracket can be drawn, not just the
-- round in play.
function buildBracket(humanName, aiNames)
    local slots = {}
    for i, name in ipairs(aiNames) do slots[i] = name end
    table.insert(slots, math.random(#slots + 1), humanName)

    local pairings = {}
    for i = 1, #slots, 2 do
        pairings[#pairings + 1] = { slots[i], slots[i + 1] }
    end

    return { humanName = humanName, round = 1, rounds = { pairings } }
end

-- The name facing the human this round, or nil once they're out of the bracket.
function humanOpponent(bracket)
    for _, pair in ipairs(bracket.rounds[bracket.round]) do
        if pair[1] == bracket.humanName then return pair[2] end
        if pair[2] == bracket.humanName then return pair[1] end
    end
    return nil
end

-- Resolve this round -- the human's match by `humanWon`, everything else by coin
-- flip -- and pair the winners up as the next round. A losing human is simply
-- not among the winners, which keeps 8 -> 4 -> 2 -> 1 well formed without this
-- pretending they play on; the tournament-over path lives in TournamentState.
-- `humanWon` is nil when the human is no longer in the bracket.
function advanceRound(bracket, humanWon)
    local winners = {}
    for _, pair in ipairs(bracket.rounds[bracket.round]) do
        local human = (pair[1] == bracket.humanName and 1)
            or (pair[2] == bracket.humanName and 2) or nil
        if human and humanWon ~= nil then
            winners[#winners + 1] = humanWon and bracket.humanName or pair[3 - human]
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
