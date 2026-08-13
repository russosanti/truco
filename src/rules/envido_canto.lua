-- Pure envido scoring and logic, without any game state or UI
ENVIDO_CANTO = {
    value = { envido = 2, real = 3 },        -- falta is a ceiling, excluded here
    isCeiling = function(callType) return callType == 'falta' end,
    -- envido calls stacks at most twice (envido, envido) then you should call real or falta
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

-- Resolve a Canto outcome and how much. Envido values are passes in as calculated at the start (a card may be already played)
function envidoAward(outcome, mano, manoValue, pieValue, playerScore, aiScore)
    local other = otherSide(mano)

    if outcome.kind == 'reject' then
        -- last caller wins the pre-call pot; a rejected ceiling still pays it (floored at 1)
        local points = outcome.ceiling and math.max(outcome.cumulative, 1)
            or rejectValue(outcome.cumulative, outcome.lastCallValue)
        return outcome.caller, points
    end

    -- accept: compare envido values. On tie mano wins
    local winnerSide = envidoWinner(manoValue, pieValue) == 'mano' and mano or other
    local points = outcome.ceiling
        and faltaEnvidoValue(playerScore, aiScore, winnerSide)
        or outcome.cumulative
    return winnerSide, points
end
