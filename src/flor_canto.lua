-- Flor's binding to the generic Canto engine, mirroring envido_canto.lua.
-- Unlike envido, flor's levels are FIXED rather than additive (3 / 6 / al
-- resto), so the engine's `cumulative` is meaningless here -- lastCallValue plus
-- the ceiling flag carry everything the award needs. Nothing in canto.lua had to
-- change for that; envido's falta ceiling already ignores cumulative the same way.

FLOR_BASE = 3        -- both declared, nobody escalated
FLOR_CONTRA = 6      -- Contraflor accepted

FLOR_CANTO = {
    value = { flor = FLOR_BASE, contraflor = FLOR_CONTRA },
    isCeiling = function(callType) return callType == 'resto' end,
    -- a strict ladder: flor -> contraflor -> al resto. Keeping it strict is what
    -- makes every rung's reject exactly the value of the rung below it.
    nextCalls = function(calls)
        local last = calls[#calls]
        if last == 'flor' then return { 'contraflor' } end
        if last == 'contraflor' then return { 'resto' } end
        return {}
    end,
}

-- Resolve a flor outcome to (side, points). Values are snapshotted at deal like
-- envido's, and a rejected call ("con flor me achico") pays the rung below.
function florAward(outcome, mano, manoValue, pieValue, playerScore, aiScore)
    local other = otherSide(mano)

    if outcome.kind == 'reject' then
        return outcome.caller, outcome.ceiling and FLOR_CONTRA or FLOR_BASE
    end

    local winnerSide = florWinner(manoValue, pieValue) == 'mano' and mano or other
    -- al resto pays the falta plus the two declared flores (3 each)
    local points = outcome.ceiling
        and (faltaEnvidoValue(playerScore, aiScore, winnerSide) + 2 * FLOR_BASE)
        or outcome.lastCallValue
    return winnerSide, points
end
