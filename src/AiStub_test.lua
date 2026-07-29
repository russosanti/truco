-- Run via: luajit lib/knife/test.lua src/AiStub_test.lua

Class = require 'lib.class'
require 'src.card_defs'
require 'src.Card'
require 'src.ai_config'
require 'src.AiStub'

local function hand(...)
    local cards = {}
    for _, id in ipairs({ ... }) do
        local s, r = id:match('(%a+)_(%d+)')
        cards[#cards + 1] = Card(s, tonumber(r))
    end
    return cards
end
local function card(id) return hand(id)[1] end

T('AiStub (trick play, PRD 6 §4)', function(t)
    t('responding: covers with the weakest card that still wins', function(t)
        -- vs oros_3 (tier 5): espadas_1 (1) and copas_3 (5)... only the 1 beats it,
        -- but with two winners it must spend the cheaper one
        local h = hand('espadas_1', 'copas_12', 'bastos_4')  -- tiers 1, 8, 14
        local pick = AiStub.chooseCard(h, { against = card('copas_10') })  -- tier 10
        t:assert(pick.id == 'copas_12', 'plays the 12 (tier 8), saving the ancho')
    end)

    t('responding: takes a tie rather than an outright loss', function(t)
        -- vs bastos_11 (tier 9): copas_11 ties it, everything else loses
        local h = hand('copas_11', 'oros_5', 'bastos_4')  -- tiers 9, 13, 14
        local pick = AiStub.chooseCard(h, { against = card('bastos_11') })
        t:assert(pick.id == 'copas_11', 'ties instead of throwing away')
    end)

    t('responding: sacrifices the weakest when nothing can win or tie', function(t)
        local h = hand('copas_12', 'oros_5', 'bastos_4')  -- tiers 8, 13, 14
        local pick = AiStub.chooseCard(h, { against = card('espadas_1') })  -- tier 1
        t:assert(pick.id == 'bastos_4', 'throws the 4 away, keeps the 12')
    end)

    t('leading: holds the bravas back while nothing is decided', function(t)
        local h = hand('espadas_1', 'copas_12', 'bastos_4')
        local pick = AiStub.chooseCard(h, { myWins = 0, theirWins = 0, tricksPlayed = 0 })
        t:assert(pick.id == 'bastos_4', 'leads the weakest at 0-0')
    end)

    t('leading: goes big once a trick win can close the hand', function(t)
        local h = hand('espadas_1', 'copas_12', 'bastos_4')
        local mine = AiStub.chooseCard(h, { myWins = 1, theirWins = 0, tricksPlayed = 1 })
        t:assert(mine.id == 'espadas_1', 'up a trick -> strongest')
        local theirs = AiStub.chooseCard(h, { myWins = 0, theirWins = 1, tricksPlayed = 1 })
        t:assert(theirs.id == 'espadas_1', 'down a trick, must win -> strongest')
    end)

    t('leading: a parda also makes this trick the decider', function(t)
        -- 1 trick played, no clean wins -> it was a parda, so isHandDecided will
        -- settle the hand on whoever takes this one
        local h = hand('espadas_1', 'copas_12', 'bastos_4')
        local pick = AiStub.chooseCard(h, { myWins = 0, theirWins = 0, tricksPlayed = 1 })
        t:assert(pick.id == 'espadas_1', 'after a parda -> strongest')
    end)

    t('always returns a card from the hand', function(t)
        local h = hand('oros_7', 'copas_2')
        for _, ctx in ipairs({ {}, { against = card('espadas_1') }, { myWins = 2 } }) do
            local pick = AiStub.chooseCard(h, ctx)
            t:assert(pick == h[1] or pick == h[2], 'picked one of the held cards')
        end
    end)
end)
