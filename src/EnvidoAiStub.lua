-- Throwaway envido decisions. PRD 6 replaces this whole file; CantosState must
-- keep decision logic out here. Thresholds are arbitrary placeholders, picked
-- only so both the accept and reject paths get exercised in manual play.

EnvidoAiStub = {}

function EnvidoAiStub.chooseOpen(hand)
    return envidoValue(hand) >= 27 and 'envido' or 'pass'  -- never opens real/falta
end

function EnvidoAiStub.chooseResponse(hand)
    return envidoValue(hand) >= 24 and 'quiero' or 'noquiero'  -- never raises
end
