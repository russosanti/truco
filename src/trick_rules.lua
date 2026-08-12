-- Pure trick-resolution rules (no LÖVE); the state classes only call these.

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

-- Who leads the next trick. A win keeps/passes the lead to the winner; a
-- tie hands the lead to mano regardless of who led the tied trick.
function nextLeader(trickResult, currentLeader, mano)
    if trickResult == 'tie' then
        return mano
    elseif trickResult == 'leader' then
        return currentLeader
    else
        return otherSide(currentLeader)
    end
end

-- Winning side ('human'/'ai') once the hand is settled, or nil to play on.
-- `wins` counts clean trick-wins only (ties never increment it), so the
-- number of pardas so far is exactly tricksPlayed - wins.human - wins.ai.
-- `firstTrickWinner` is the side that took trick 1, or nil if it was a parda.
--
-- The whole reglamento in one sentence: the winner of the EARLIEST non-parda
-- trick takes the hand, and mano takes it only when all three are pardas. The
-- branches below are that rule, ordered by when it becomes knowable.
function isHandDecided(wins, firstTrickWinner, tricksPlayed, mano)
    if wins.player >= 2 then return 'player' end   -- swept or won two clean tricks
    if wins.ai >= 2 then return 'ai' end

    local pardas = tricksPlayed - wins.player - wins.ai

    -- A parda plus a lead on clean wins locks the hand: 1 win + 1 tie takes
    -- it, whichever order they came in ("tie then win", "win then tie").
    if pardas >= 1 and wins.player ~= wins.ai then
        return wins.player > wins.ai and 'player' or 'ai'
    end

    -- Three tricks, still level. Either 1-1 with the third a parda -- the parda
    -- can only BE the third, since an earlier one alongside unequal wins ends
    -- the hand above -- so trick 1 decides it; or all three were pardas, and
    -- only then does mano take it.
    if tricksPlayed == 3 then
        return firstTrickWinner or mano
    end

    return nil  -- not settled; play another trick
end
