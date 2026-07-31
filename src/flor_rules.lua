-- Pure flor math (no LÖVE). Flor is three cards of one suit; holding one is
-- mandatory to declare, which is why nothing here decides anything.

function hasFlor(hand)
    if #hand < 3 then return false end
    local suit = hand[1].suit
    for _, card in ipairs(hand) do
        if card.suit ~= suit then return false end
    end
    return true
end

-- All three envido values plus 20. Range 20 (three figures, which are worth 0)
-- to 38 (7+6+5). Only meaningful for a hand that hasFlor.
function florValue(hand)
    local total = 20
    for _, card in ipairs(hand) do
        total = total + card.envidoValue
    end
    return total
end

-- Same shape as envidoWinner: higher takes it, ties go to mano.
function florWinner(manoValue, pieValue)
    return manoValue >= pieValue and 'mano' or 'pie'
end
