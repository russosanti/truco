-- Pure truco math + call gating (no LÖVE); TrickState only calls these.
-- Level is the accepted value: 2 Truco, 3 Retruco, 4 Vale cuatro.

TRUCO_NAME = { [2] = 'Truco', [3] = 'Retruco', [4] = 'Vale cuatro' }

-- No quiero pays the previous level (Truco 2->1, Retruco 3->2, Vale cuatro 4->3).
function trucoRejectValue(level)
    return level - 1
end

-- Fold concedes the current accepted value, or the 1-point base if never called.
function trucoFoldValue(trucoLevel)
    return trucoLevel > 0 and trucoLevel or 1
end

-- Answering a pending call with the next level up, or nil at Vale cuatro. This
-- is a quiero and a raise in one move -- the escalation alternates sides as it's
-- answered, so nobody waits for their turn to come round to raise.
function trucoRaiseCall(pending)
    if not pending or pending.level >= 4 then return nil end
    return pending.level + 1
end

-- The level `side` may call right now, or nil. Either side opens Truco while
-- nothing's accepted; after that only trucoLeader (the last accepter) may raise,
-- one step at a time, up to Vale cuatro. Nothing is callable while one's pending.
function availableTrucoCall(trucoLevel, trucoLeader, side, pending)
    if pending then return nil end
    if trucoLevel == 0 then return 2 end
    if side == trucoLeader and trucoLevel < 4 then return trucoLevel + 1 end
    return nil
end
