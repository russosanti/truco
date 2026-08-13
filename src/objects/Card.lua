--[[
    Truco Argentino

    -- Card Class --

    Represent a single card
]]

Card = Class{}

function Card:init(suit, rank)
    self.suit = suit
    self.rank = rank
    self.id = suit .. '_' .. rank

    self.trickTier = trickTierFor(suit, rank)
    self.envidoValue = envidoValueFor(rank)

    local suitRow = CARD_SUIT_ROW_INDEX[suit]
    local rankCol = CARD_RANK_COL_INDEX[rank]
    self.spriteQuadIndex = suitRow * 10 + rankCol + 1
end

--[[
    Returns -1 if cardA beats cardB, 1 if cardB beats cardA, 0 for a parda
]]
function Card.compareTrick(cardA, cardB)
    if cardA.trickTier < cardB.trickTier then
        return -1
    elseif cardB.trickTier < cardA.trickTier then
        return 1
    else
        return 0
    end
end
