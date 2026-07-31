-- Run via: luajit lib/knife/test.lua src/flor_rules_test.lua

Class = require 'lib.class'
require 'src.card_defs'
require 'src.Card'
require 'src.flor_rules'

local function hand(...)
    local cards = {}
    for _, id in ipairs({ ... }) do
        local s, r = id:match('(%a+)_(%d+)')
        cards[#cards + 1] = Card(s, tonumber(r))
    end
    return cards
end

T('flor_rules', function(t)
    t('hasFlor: three of one suit and nothing else', function(t)
        t:assert(hasFlor(hand('copas_7', 'copas_6', 'copas_5')), 'three copas is a flor')
        t:assert(hasFlor(hand('oros_10', 'oros_11', 'oros_12')), 'three figures still count')
        t:assert(not hasFlor(hand('copas_7', 'copas_6', 'oros_5')), 'two of a suit is only envido')
        t:assert(not hasFlor(hand('copas_7', 'oros_6', 'bastos_5')), 'three suits is nothing')
        t:assert(not hasFlor(hand('copas_7', 'copas_6')), 'a short hand cannot have one')
    end)

    t('florValue: the three envido values plus 20', function(t)
        t:assert(florValue(hand('copas_7', 'copas_6', 'copas_5')) == 38, 'the maximum, 7+6+5+20')
        t:assert(florValue(hand('oros_10', 'oros_11', 'oros_12')) == 20,
            'the minimum: figures are worth 0, so just the 20')
        t:assert(florValue(hand('espadas_1', 'espadas_2', 'espadas_3')) == 26, '1+2+3+20')
        t:assert(florValue(hand('bastos_7', 'bastos_10', 'bastos_4')) == 31, '7+0+4+20')
    end)

    t('florValue never leaves the 20-38 band', function(t)
        for _, suit in ipairs(CARD_SUITS) do
            for i = 1, #CARD_RANKS do
                for j = i + 1, #CARD_RANKS do
                    for k = j + 1, #CARD_RANKS do
                        local v = florValue({
                            Card(suit, CARD_RANKS[i]),
                            Card(suit, CARD_RANKS[j]),
                            Card(suit, CARD_RANKS[k]),
                        })
                        t:assert(v >= 20 and v <= 38, 'value ' .. v .. ' inside 20..38')
                    end
                end
            end
        end
    end)

    t('florWinner: higher takes it, ties go to mano', function(t)
        t:assert(florWinner(35, 30) == 'mano', 'mano is higher')
        t:assert(florWinner(30, 35) == 'pie', 'pie is higher')
        t:assert(florWinner(31, 31) == 'mano', 'a tie goes to mano')
        t:assert(florWinner(20, 20) == 'mano', 'even at the floor')
    end)
end)
