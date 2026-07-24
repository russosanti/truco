--[[
    Truco Argentino

    -- card_defs --

    Global lookup tables for the card model, mirroring the pokebowl
    `X_defs.lua` convention (a plain module that sets globals, consumed by the
    matching class file -- here src/Card.lua). Pure data + tiny resolvers; no
    LÖVE dependency, so this loads under both `love .` and the `lua` test runner.

    See PRD 1 §4 (trick tiers), §5 (envido values), §7 (sprite quad layout).
]]

-- Canonical iteration order for building a deck (§3).
CARD_SUITS = { 'bastos', 'copas', 'espadas', 'oros' }
CARD_RANKS = { 1, 2, 3, 4, 5, 6, 7, 10, 11, 12 }

--[[
    Trick tier: lower wins (§4). Every rank shares one tier across suits,
    except 1 and 7, whose "bravas" split by suit -- so those two entries are
    per-suit tables and the rest are plain numbers. Resolve via trickTierFor().
]]
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

-- Sprite sheet layout (§7): row = suit, column = rank, row-major into the
-- quads produced by GenerateQuads(atlas, 130, 200).
CARD_SUIT_ROW_INDEX = { bastos = 0, copas = 1, espadas = 2, oros = 3 }

-- rank -> 0-based column, derived from CARD_RANKS order (1->0 ... 12->9).
CARD_RANK_COL_INDEX = {}
for col, rank in ipairs(CARD_RANKS) do
    CARD_RANK_COL_INDEX[rank] = col - 1
end

-- Resolve a card's trick tier, branching on the per-suit-vs-shared shape above.
function trickTierFor(suit, rank)
    local tier = CARD_TRICK_TIERS[rank]
    if type(tier) == 'table' then
        return tier[suit]
    end
    return tier
end

-- Envido/flor point value (§5): ranks 1-7 are worth their rank, 10/11/12 zero.
function envidoValueFor(rank)
    return rank <= 7 and rank or 0
end
