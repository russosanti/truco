-- Pure trick-resolution rules

-- Who won a single trick, from the leader's point of view.
function resolveTrick(leaderCard, otherCard)
    local cmp = Card.compareTrick(leaderCard, otherCard)
    if cmp == -1 then
        return 'leader'
    elseif cmp == 1 then
        return 'other'
    else
        return 'tie'
    end
end

-- Who leads the next trick
function nextLeader(trickResult, currentLeader, mano)
    if trickResult == 'tie' then
        return mano
    elseif trickResult == 'leader' then
        return currentLeader
    else
        return otherSide(currentLeader)
    end
end

-- Winning side ('player'/'ai') once the hand is settled, or nil to play on.
function isHandDecided(wins, firstTrickWinner, tricksPlayed, mano)
    if wins.player >= 2 then return 'player' end   -- swept or won two clean tricks
    if wins.ai >= 2 then return 'ai' end

    local pardas = tricksPlayed - wins.player - wins.ai

    -- A parda plus a lead on clean wins locks the hand: 1 win + 1 tie is enough
    if pardas >= 1 and wins.player ~= wins.ai then
        return wins.player > wins.ai and 'player' or 'ai'
    end

    -- Three tricks, still level. Either 1-1 with the third a parda
    if tricksPlayed == 3 then
        return firstTrickWinner or mano
    end

    return nil  -- not settled, play another trick
end
