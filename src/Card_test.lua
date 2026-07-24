--[[
    Truco Argentino

    -- Card unit tests --

    Run via: lua lib/knife/test.lua src/Card_test.lua

    Loads only the pure-Lua pieces of the model (not src.Dependencies, which
    pulls in LÖVE) so this runs under a plain `lua` interpreter, per PRD 1 §8.
]]

Class = require 'lib.class'
require 'src.card_defs'
require 'src.Card'

T('Card', function(t)
    t('trick-tier resolution (PRD §4)', function(t)
        local espadas1 = Card('espadas', 1)
        local bastos1 = Card('bastos', 1)
        local oros1 = Card('oros', 1)
        local copas1 = Card('copas', 1)

        t:assert(espadas1.trickTier == 1, 'espadas-1 is tier 1')
        t:assert(bastos1.trickTier == 2, 'bastos-1 is tier 2')
        t:assert(oros1.trickTier == 7, 'oros-1 is tier 7')
        t:assert(copas1.trickTier == 7, 'copas-1 is tier 7')

        local espadas7 = Card('espadas', 7)
        local oros7 = Card('oros', 7)
        local bastos7 = Card('bastos', 7)
        local copas7 = Card('copas', 7)

        t:assert(espadas7.trickTier == 3, 'espadas-7 is tier 3')
        t:assert(oros7.trickTier == 4, 'oros-7 is tier 4')
        t:assert(bastos7.trickTier == 11, 'bastos-7 is tier 11')
        t:assert(copas7.trickTier == 11, 'copas-7 is tier 11')

        -- suit-independent ranks, spot-checked against the §4 table
        t:assert(Card('bastos', 3).trickTier == 5, 'rank 3 is tier 5')
        t:assert(Card('oros', 2).trickTier == 6, 'rank 2 is tier 6')
        t:assert(Card('copas', 12).trickTier == 8, 'rank 12 is tier 8')
        t:assert(Card('espadas', 11).trickTier == 9, 'rank 11 is tier 9')
        t:assert(Card('bastos', 10).trickTier == 10, 'rank 10 is tier 10')
        t:assert(Card('oros', 6).trickTier == 12, 'rank 6 is tier 12')
        t:assert(Card('copas', 5).trickTier == 13, 'rank 5 is tier 13')
        t:assert(Card('espadas', 4).trickTier == 14, 'rank 4 is tier 14')
    end)

    t('compareTrick: espadas-1 beats every other card', function(t)
        local espadas1 = Card('espadas', 1)

        for _, suit in ipairs(CARD_SUITS) do
            for _, rank in ipairs(CARD_RANKS) do
                if not (suit == 'espadas' and rank == 1) then
                    local other = Card(suit, rank)
                    t:assert(Card.compareTrick(espadas1, other) == -1,
                        'espadas-1 beats ' .. other.id)
                    t:assert(Card.compareTrick(other, espadas1) == 1,
                        other.id .. ' loses to espadas-1')
                end
            end
        end
    end)

    t('compareTrick: bastos-1 beats everything except espadas-1', function(t)
        local bastos1 = Card('bastos', 1)
        local espadas1 = Card('espadas', 1)

        t:assert(Card.compareTrick(bastos1, espadas1) == 1, 'bastos-1 loses to espadas-1')

        for _, suit in ipairs(CARD_SUITS) do
            for _, rank in ipairs(CARD_RANKS) do
                local isBastos1 = suit == 'bastos' and rank == 1
                local isEspadas1 = suit == 'espadas' and rank == 1
                if not isBastos1 and not isEspadas1 then
                    local other = Card(suit, rank)
                    t:assert(Card.compareTrick(bastos1, other) == -1,
                        'bastos-1 beats ' .. other.id)
                end
            end
        end
    end)

    t('compareTrick: same-tier cards are a parda', function(t)
        local bastos3 = Card('bastos', 3)
        local oros3 = Card('oros', 3)

        t:assert(Card.compareTrick(bastos3, oros3) == 0, 'bastos-3 vs oros-3 is a parda')
        t:assert(Card.compareTrick(oros3, bastos3) == 0, 'parda is symmetric')
    end)

    t('envido value (PRD §5): rank 1-7 return themselves, 10/11/12 return 0', function(t)
        for rank = 1, 7 do
            t:assert(Card('oros', rank).envidoValue == rank,
                'rank ' .. rank .. ' is worth ' .. rank .. ' envido points')
        end

        t:assert(Card('oros', 10).envidoValue == 0, 'rank 10 is worth 0 envido points')
        t:assert(Card('oros', 11).envidoValue == 0, 'rank 11 is worth 0 envido points')
        t:assert(Card('oros', 12).envidoValue == 0, 'rank 12 is worth 0 envido points')
    end)
end)
