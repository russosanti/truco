--[[
    Truco Argentino

    -- card_defs --

    Global lookup tables for the card model
]]

-- Iteration order for building a deck
CARD_SUITS = { 'bastos', 'copas', 'espadas', 'oros' }
CARD_RANKS = { 1, 2, 3, 4, 5, 6, 7, 10, 11, 12 }

-- Card order of importance
CARD_TRICK_TIERS = {
    [1]  = { espadas = 1, bastos = 2, oros = 7, copas = 7 },
    [7]  = { espadas = 3, oros = 4, bastos = 11, copas = 11 },
    [3]  = 5,
    [2]  = 6,
    [12] = 8,
    [11] = 9,
    [10] = 10,
    [6]  = 12,
    [5]  = 13,
    [4]  = 14,
}

-- Sprite layout
CARD_SUIT_ROW_INDEX = { bastos = 0, copas = 1, espadas = 2, oros = 3 }

-- rank -> 0-based column, derived from CARD_RANKS order (1->0 ... 12->9).
CARD_RANK_COL_INDEX = {}
for col, rank in ipairs(CARD_RANKS) do
    CARD_RANK_COL_INDEX[rank] = col - 1
end

-- Resolves card order
function trickTierFor(suit, rank)
    local tier = CARD_TRICK_TIERS[rank]
    if type(tier) == 'table' then
        return tier[suit]
    end
    return tier
end

-- Envido or flor values. 10, 11 and 12s have a 0 value.
function envidoValueFor(rank)
    return rank <= 7 and rank or 0
end
