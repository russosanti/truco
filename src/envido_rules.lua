-- Two of the same suit: summed + 20
function envidoValue(hand)
    local best = 0
    local bySuit = {}
    for _, card in ipairs(hand) do
        if card.envidoValue > best then best = card.envidoValue end  -- different-suit fallback
        bySuit[card.suit] = bySuit[card.suit] or {}
        table.insert(bySuit[card.suit], card.envidoValue)
    end

    for _, vals in pairs(bySuit) do
        if #vals >= 2 then
            table.sort(vals, function(a, b) return a > b end)
            local pair = vals[1] + vals[2] + 20
            if pair > best then best = pair end
        end
    end
    return best
end

-- Ties go to mano
function envidoWinner(manoValue, pieValue)
    return manoValue >= pieValue and 'mano' or 'pie'
end

-- "No quiero": the last caller wins everything
function rejectValue(cumulative, lastCallValue)
    return math.max(cumulative - lastCallValue, 1)
end

-- Falta envido: if both sides are still in malas (leader < 15) the winner goes straight to 30 from their own score, otherwise it's whatever the leader needs to 30
function faltaEnvidoValue(playerScore, aiScore, winnerSide)
    local leader = math.max(playerScore, aiScore)
    if leader < 15 then
        return 30 - (winnerSide == 'player' and playerScore or aiScore)
    end
    return 30 - leader
end
