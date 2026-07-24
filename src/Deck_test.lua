--[[
    Truco Argentino

    -- Deck unit tests --

    Run via: lua lib/knife/test.lua src/Deck_test.lua

    Loads only the pure-Lua pieces of the model (not src.Dependencies, which
    pulls in LÖVE) so this runs under a plain `lua` interpreter, per PRD 1 §8.
]]

Class = require 'lib.class'
require 'src.card_defs'
require 'src.Card'
require 'src.Deck'

T('Deck', function(t)
    t('builds exactly 40 unique cards, all suits x ranks, no duplicates', function(t)
        local deck = Deck()

        t:assert(#deck.cards == 40, 'deck has 40 cards')

        local seen = {}
        for _, card in ipairs(deck.cards) do
            t:assert(not seen[card.id], card.id .. ' is not a duplicate')
            seen[card.id] = true
        end

        for _, suit in ipairs(CARD_SUITS) do
            for _, rank in ipairs(CARD_RANKS) do
                local id = suit .. '_' .. rank
                t:assert(seen[id], id .. ' is present in the deck')
            end
        end
    end)

    t('deal(n) returns n cards and shrinks remaining() by n', function(t)
        local deck = Deck()
        local before = deck:remaining()

        local dealt = deck:deal(3)

        t:assert(#dealt == 3, 'deal(3) returns 3 cards')
        t:assert(deck:remaining() == before - 3, 'remaining() shrinks by 3')
    end)

    t('deal(n) errors when asked for more cards than remain', function(t)
        local deck = Deck()

        t:error(function() deck:deal(41) end, 'deal(41) errors: only 40 cards exist')

        deck:deal(40)
        t:assert(deck:remaining() == 0, 'deck is empty after dealing all 40')
        t:error(function() deck:deal(1) end, 'deal(1) errors on an empty deck')
    end)

    t('shuffle() reorders cards while preserving the 40-card set', function(t)
        local deckA = Deck()
        local deckB = Deck()

        local sameOrder = true
        for i = 1, 40 do
            if deckA.cards[i].id ~= deckB.cards[i].id then
                sameOrder = false
                break
            end
        end
        t:assert(not sameOrder, 'two independently shuffled decks land in different orders')

        local idsA, idsB = {}, {}
        for _, card in ipairs(deckA.cards) do idsA[card.id] = true end
        for _, card in ipairs(deckB.cards) do idsB[card.id] = true end

        local countA, countB = 0, 0
        for id in pairs(idsA) do
            countA = countA + 1
            t:assert(idsB[id], id .. ' is present in both shuffles (same 40-card set)')
        end
        for _ in pairs(idsB) do countB = countB + 1 end
        t:assert(countA == 40 and countB == 40, 'both shuffles still contain all 40 unique cards')
    end)

    t('reset() rebuilds the full deck', function(t)
        local deck = Deck()
        deck:deal(40)
        t:assert(deck:remaining() == 0, 'deck emptied')

        deck:reset()
        t:assert(deck:remaining() == 40, 'reset() rebuilds all 40 cards')
    end)
end)
