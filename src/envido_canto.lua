-- Envido's binding to the generic Canto engine: the call ladder + turning a
-- resolved outcome into (side, points) via the pure envido_rules functions.

ENVIDO_CANTO = {
    value = { envido = 2, real = 3 },        -- falta is a ceiling, excluded here
    isCeiling = function(callType) return callType == 'falta' end,
    -- envido stacks at most twice; a real leaves only falta; falta ends it
    nextCalls = function(calls)
        if calls[#calls] == 'falta' then return {} end
        local envidoCount, realCalled = 0, false
        for _, c in ipairs(calls) do
            if c == 'envido' then envidoCount = envidoCount + 1 end
            if c == 'real' then realCalled = true end
        end
        if realCalled then return { 'falta' } end
        if envidoCount < 2 then return { 'envido', 'real', 'falta' } end
        return { 'real', 'falta' }
    end,
}

-- Resolve a Canto outcome to the side that scores and how much.
function envidoAward(outcome, mano, humanHand, aiHand, humanScore, aiScore)
    local other = mano == 'human' and 'ai' or 'human'

    if outcome.kind == 'reject' then
        -- last caller wins the pre-call pot; a rejected ceiling still pays it (floored at 1)
        local points = outcome.ceiling and math.max(outcome.cumulative, 1)
            or rejectValue(outcome.cumulative, outcome.lastCallValue)
        return outcome.caller, points
    end

    -- accept: compare envido values (ties to mano)
    local manoVal = envidoValue(mano == 'human' and humanHand or aiHand)
    local pieVal = envidoValue(mano == 'human' and aiHand or humanHand)
    local winnerSide = envidoWinner(manoVal, pieVal) == 'mano' and mano or other
    local points = outcome.ceiling
        and faltaEnvidoValue(humanScore, aiScore, winnerSide)
        or outcome.cumulative
    return winnerSide, points
end
