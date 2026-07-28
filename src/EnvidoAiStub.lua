-- Throwaway envido decisions. PRD 6 replaces this whole file; TrickState must
-- keep decision logic out here. Thresholds are arbitrary placeholders, picked
-- only so both the accept and reject paths get exercised in manual play.
--
-- Both take the hand's envido VALUE, not the hand: by the time the pie answers,
-- the mano may already have played a card, and re-deriving from a 2-card hand
-- would read a number the player never had. TrickState snapshots it at deal.

EnvidoAiStub = {}

function EnvidoAiStub.chooseOpen(value)
    return value >= 27 and 'envido' or 'pass'  -- never opens real/falta
end

function EnvidoAiStub.chooseResponse(value)
    return value >= 24 and 'quiero' or 'noquiero'  -- never raises
end
