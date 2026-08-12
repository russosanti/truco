-- Run via: luajit lib/knife/test.lua src/envido_rules_test.lua

Class = require 'lib.class'
require 'src.card_defs'
require 'src.Card'
require 'src.envido_rules'

local function hand(...)
    local cards = {}
    for _, id in ipairs({ ... }) do
        local suit, rank = id:match('(%a+)_(%d+)')
        cards[#cards + 1] = Card(suit, tonumber(rank))
    end
    return cards
end

T('envido_rules', function(t)
    t('envidoValue: same-suit pair sums the two highest + 20', function(t)
        -- espadas 7 & 6 (+ off-suit) -> 7+6+20 = 33 (the max)
        t:assert(envidoValue(hand('espadas_7', 'espadas_6', 'oros_5')) == 33, '7+6 same suit = 33')
        -- espadas 5 & 4 -> 5+4+20 = 29
        t:assert(envidoValue(hand('espadas_5', 'espadas_4', 'oros_7')) == 29, '5+4 same suit = 29')
        -- figuras count as 0: espadas 10 & 12 -> 0+0+20 = 20
        t:assert(envidoValue(hand('espadas_10', 'espadas_12', 'oros_5')) == 20, 'two figuras same suit = 20')
    end)

    t('envidoValue: all different suits -> highest single card value', function(t)
        t:assert(envidoValue(hand('espadas_7', 'oros_5', 'bastos_3')) == 7, 'highest single = 7')
        -- three figuras, all different suits -> 0
        t:assert(envidoValue(hand('espadas_10', 'oros_11', 'bastos_12')) == 0, 'three figuras = 0')
    end)

    t('envidoValue: 3-same-suit (flor-shaped) uses best two + 20', function(t)
        -- copas 7,6,5 -> best two 7+6 +20 = 33
        t:assert(envidoValue(hand('copas_7', 'copas_6', 'copas_5')) == 33, 'best two of three = 33')
    end)

    t('envidoWinner: higher wins, ties go to mano', function(t)
        t:assert(envidoWinner(31, 20) == 'mano', 'mano higher')
        t:assert(envidoWinner(20, 31) == 'pie', 'pie higher')
        t:assert(envidoWinner(27, 27) == 'mano', 'tie -> mano')
    end)

    t('rejectValue: every §6 table row', function(t)
        t:assert(rejectValue(2, 2) == 1, 'Envido rejected = 1')
        t:assert(rejectValue(3, 3) == 1, 'Real envido (direct) rejected = 1')
        t:assert(rejectValue(4, 2) == 2, 'Envido->Envido rejected = 2')
        t:assert(rejectValue(5, 3) == 2, 'Envido->Real rejected = 2')
    end)

    t('faltaEnvidoValue: both branches', function(t)
        -- leader >= 15: the doc's worked example, 20 vs 10 -> 10
        t:assert(faltaEnvidoValue(20, 10, 'player') == 10, 'leader 20 -> 30-20 = 10')
        t:assert(faltaEnvidoValue(20, 10, 'ai') == 10, 'leader-branch ignores winner side')
        -- leader < 15 (malas): winner goes to 30 from its own score
        t:assert(faltaEnvidoValue(10, 5, 'player') == 20, 'malas, player wins -> 30-10 = 20')
        t:assert(faltaEnvidoValue(10, 5, 'ai') == 25, 'malas, ai wins -> 30-5 = 25')
        t:assert(faltaEnvidoValue(0, 0, 'player') == 30, 'both at 0 -> 30')
    end)
end)
