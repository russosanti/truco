-- Run via: luajit lib/knife/test.lua src/TrucoAiStub_test.lua

Class = require 'lib.class'
require 'src.card_defs'
require 'src.Card'
require 'src.ai_config'
require 'src.TrucoAiStub'

AiConfig.bluffRate = 0  -- position table under test; bluffing has its own file

local function hand(...)
    local cards = {}
    for _, id in ipairs({ ... }) do
        local s, r = id:match('(%a+)_(%d+)')
        cards[#cards + 1] = Card(s, tonumber(r))
    end
    return cards
end

local BRAVA  = hand('espadas_1', 'copas_5', 'bastos_4')   -- espadas_1 = tier 1
local BRAVAS = hand('espadas_1', 'bastos_1', 'copas_5')   -- tiers 1 and 2: two bravas
local NOTHING = hand('copas_5', 'oros_6', 'bastos_4')     -- tiers 13, 12, 14

-- "something has been played" -- a lone brava won't open before that
local SEEN = { tricksPlayed = 0, cardsPlayed = 1 }

T('TrucoAiStub (truco, PRD 6 §6)', function(t)
    t('position: strong on an unplayed brava or a banked trick', function(t)
        t:assert(TrucoAiStub.position(BRAVA, { tricksPlayed = 0 }) == 'strong', 'holds a brava')
        t:assert(TrucoAiStub.position(NOTHING, { myWins = 1, tricksPlayed = 1 }) == 'strong',
            'no brava but already up a trick')
    end)

    t('position: uncertain only in trick 1 with nothing decided', function(t)
        t:assert(TrucoAiStub.position(NOTHING, { tricksPlayed = 0 }) == 'uncertain',
            'no bravas, nothing played yet')
    end)

    t('position: weak once a trick is gone and nothing was won', function(t)
        t:assert(TrucoAiStub.position(NOTHING, { myWins = 0, theirWins = 1, tricksPlayed = 1 }) == 'weak',
            'lost trick 1 with no bravas left')
        t:assert(TrucoAiStub.position(NOTHING, { myWins = 0, theirWins = 1, tricksPlayed = 2 }) == 'weak',
            'still weak in trick 3')
    end)

    t('calls from strength only', function(t)
        t:assert(TrucoAiStub.wantsToCall(BRAVA, SEEN) == true, 'brava calls')
        t:assert(TrucoAiStub.wantsToCall(NOTHING, SEEN) == false, 'uncertain does not call')
        t:assert(TrucoAiStub.wantsToCall(NOTHING, { theirWins = 1, tricksPlayed = 1 }) == false,
            'weak does not call')
    end)

    -- betting before a single card is down reads as trigger-happy; play one and
    -- see what the other side has first, unless the hand is exceptional
    t('holds off on the very first move of a hand', function(t)
        local opening = { tricksPlayed = 0, cardsPlayed = 0 }
        t:assert(TrucoAiStub.wantsToCall(BRAVA, opening) == false,
            'one brava is not enough to open before anything is played')
        t:assert(TrucoAiStub.wantsToCall(BRAVAS, opening) == true,
            'two bravas will still open the hand with truco')
        t:assert(TrucoAiStub.wantsToCall(BRAVA, SEEN) == true,
            'and after a card is down, one brava is enough')
        t:assert(TrucoAiStub.wantsToCall(BRAVA, { tricksPlayed = 1 }) == true,
            'likewise from trick 2 on')
    end)

    t('responds quiero anywhere but a lost position', function(t)
        t:assert(TrucoAiStub.respond(BRAVA, { tricksPlayed = 0 }) == 'quiero', 'strong accepts')
        t:assert(TrucoAiStub.respond(NOTHING, { tricksPlayed = 0 }) == 'quiero',
            'uncertain accepts -- benefit of the doubt this early')
        t:assert(TrucoAiStub.respond(NOTHING, { theirWins = 1, tricksPlayed = 1 }) == 'noquiero',
            'weak declines')
    end)

    t('answers a call by raising it when very strong', function(t)
        t:assert(TrucoAiStub.respond(BRAVAS, { tricksPlayed = 0 }) == 'raise',
            'two bravas: quiero and up, in one move')
        t:assert(TrucoAiStub.respond(BRAVA, { tricksPlayed = 0 }) == 'quiero',
            'one brava just accepts')
    end)

    t('folds only from a weak position with a stake already accepted', function(t)
        t:assert(TrucoAiStub.wantsToFold(NOTHING, { theirWins = 1, tricksPlayed = 1, trucoLevel = 2 }) == true,
            'weak with truco accepted -> caps the loss')
        t:assert(TrucoAiStub.wantsToFold(NOTHING, { theirWins = 1, tricksPlayed = 1 }) == false,
            'weak but nothing staked -> play it out, it is only 1 point')
        t:assert(TrucoAiStub.wantsToFold(BRAVA, { trucoLevel = 4, tricksPlayed = 0 }) == false,
            'never folds from strength, however big the stake')
    end)

    t('aggression shifts the read one position either way', function(t)
        local base = AiConfig.aggression
        local lost = { theirWins = 1, tricksPlayed = 1, trucoLevel = 2 }

        -- SEEN throughout, so this measures the aggression shift and not the
        -- separate "don't bet before a card is down" rule
        AiConfig.aggression = 1.0
        t:assert(TrucoAiStub.wantsToCall(NOTHING, SEEN) == true,
            'reckless: calls from uncertain')
        t:assert(TrucoAiStub.wantsToFold(NOTHING, lost) == false,
            'reckless: rides out a weak position instead of folding')

        AiConfig.aggression = 0.0
        t:assert(TrucoAiStub.wantsToCall(BRAVA, SEEN) == false,
            'timid: a single brava is not enough to call')
        t:assert(TrucoAiStub.respond(NOTHING, { tricksPlayed = 0 }) == 'noquiero',
            'timid: declines from uncertain')

        AiConfig.aggression = base
    end)
end)
