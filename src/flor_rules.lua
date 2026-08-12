-- Flor is three cards of one suit holding one is mandatory to declare

function hasFlor(hand)
    if #hand < 3 then return false end
    local suit = hand[1].suit
    for _, card in ipairs(hand) do
        if card.suit ~= suit then return false end
    end
    return true
end

-- All three envido values plus 20
function florValue(hand)
    local total = 20
    for _, card in ipairs(hand) do
        total = total + card.envidoValue
    end
    return total
end

-- Same shape as envidoWinner, higher takes it, ties go to mano.
function florWinner(manoValue, pieValue)
    return manoValue >= pieValue and 'mano' or 'pie'
end
