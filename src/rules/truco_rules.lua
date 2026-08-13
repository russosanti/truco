-- Pure truco math + call gating
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

-- Answering a pending call with the next level up, or nil at Vale cuatro
function trucoRaiseCall(pending)
    if not pending or pending.level >= 4 then return nil end
    return pending.level + 1
end

-- Returns available call
function availableTrucoCall(trucoLevel, trucoLeader, side, pending)
    if pending then return nil end
    if trucoLevel == 0 then return 2 end
    if side == trucoLeader and trucoLevel < 4 then return trucoLevel + 1 end
    return nil
end
