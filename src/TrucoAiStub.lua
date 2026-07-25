-- Throwaway truco decisions. PRD 6 replaces this whole file. Deliberately dumb,
-- picked so both the accept and reject paths get exercised in manual play.

TrucoAiStub = {}

local function holdsBrava(hand)
    for _, card in ipairs(hand) do
        if card.trickTier <= 4 then return true end  -- tier 1-4 = "brava" (PRD 1 §4)
    end
    return false
end

-- Open or raise only while holding an unplayed brava; never otherwise.
function TrucoAiStub.wantsToCall(hand)
    return holdsBrava(hand)
end

-- Accept if holding a brava or already up a trick this hand; else fold the bet.
function TrucoAiStub.respond(hand, wonTrick)
    return (holdsBrava(hand) or wonTrick) and 'quiero' or 'noquiero'
end
