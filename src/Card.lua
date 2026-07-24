--[[
    Truco Argentino

    -- Card Class --

    A plain immutable value object, built once from a suit and a rank and
    read from everywhere else. Mirrors the "class wraps static data"
    convention from pokebowl's Pokemon.lua, backed by the lookup tables in
    src/card_defs.lua.

    See PRD 1 §3 for the field table.
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
    Module-level comparator (not an instance method) so it stays trivially
    testable in isolation, per PRD 1 §4. Lower trickTier wins a trick.

    Returns -1 if cardA beats cardB, 1 if cardB beats cardA, 0 for a parda
    (tied tier, regardless of suit).
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
