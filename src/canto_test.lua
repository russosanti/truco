-- Run via: luajit lib/knife/test.lua src/canto_test.lua

Class = require 'lib.class'
require 'src.card_defs'
require 'src.Card'
require 'src.envido_rules'
require 'src.envido_canto'
require 'src.canto'

local function hand(...)
    local cards = {}
    for _, id in ipairs({ ... }) do
        local s, r = id:match('(%a+)_(%d+)')
        cards[#cards + 1] = Card(s, tonumber(r))
    end
    return cards
end

T('canto (engine + envido binding)', function(t)
    t('opening Envido: responder answers, accept pays cumulative to the winner', function(t)
        local c = Canto(ENVIDO_CANTO, 'human', 'envido')  -- human opens; AI responds
        t:assert(c.responder == 'ai', 'AI must respond to the human open')
        t:assert(c.cumulative == 2, 'envido pot = 2')
        c:accept()
        t:assert(c.resolved and c.outcome.kind == 'accept', 'resolved as accept')
        -- mano=human 33 vs pie 32 -> human wins the pot of 2
        local side, pts = envidoAward(c.outcome, 'human', 33, 32, 0, 0)
        t:assert(side == 'human' and pts == 2, 'human wins envido, +2')
    end)

    t('reject pays the pre-call pot to the caller (floored at 1)', function(t)
        local c = Canto(ENVIDO_CANTO, 'human', 'envido')
        c:reject()
        local side, pts = envidoAward(c.outcome, 'human', 0, 0, 0, 0)  -- reject ignores values
        t:assert(side == 'human' and pts == 1, 'rejected lone Envido: caller +1')
    end)

    t('raised chain Envido -> Real: pot 5, availableRaises narrows', function(t)
        local c = Canto(ENVIDO_CANTO, 'ai', 'envido')  -- AI opens, human responds
        t:assert(c.responder == 'human', 'human responds')
        local raises = c:availableRaises()
        t:assert(#raises == 3, 'after one envido: envido/real/falta available')
        c:raise('real')                       -- human raises to Real envido
        t:assert(c.cumulative == 5, 'pot now 5')
        t:assert(c.responder == 'ai', 'AI must answer the raise')
        t:assert(#c:availableRaises() == 1 and c:availableRaises()[1] == 'falta', 'only falta left after real')
        c:accept()
        -- mano = AI 33 vs pie 25 -> AI wins pot 5
        local side, pts = envidoAward(c.outcome, 'ai', 33, 25, 0, 0)
        t:assert(side == 'ai' and pts == 5, 'AI wins raised chain, +5')
    end)

    t('falta is a ceiling: no raises, accept pays faltaEnvidoValue', function(t)
        local c = Canto(ENVIDO_CANTO, 'human', 'falta')
        t:assert(c.pendingIsCeiling, 'falta is a ceiling')
        t:assert(#c:availableRaises() == 0, 'no raises past falta')
        t:assert(c.cumulative == 0, 'ceiling adds nothing to the pot')
        c:accept()
        -- malas (leader < 15), mano=human 33 vs pie 30, human wins -> 30 - human score
        local side, pts = envidoAward(c.outcome, 'human', 33, 30, 10, 5)
        t:assert(side == 'human' and pts == 20, 'falta malas: human 10 -> +20')
    end)

    t('reject a ceiling pays the pre-falta pot', function(t)
        local c = Canto(ENVIDO_CANTO, 'human', 'envido')
        c:raise('falta')                      -- AI (responder) raises to Falta... wait, responder is AI
        -- after human opens envido, responder is AI; raise() is the responder raising
        t:assert(c.responder == 'human', 'after AI raises falta, human must answer')
        c:reject()
        local side, pts = envidoAward(c.outcome, 'human', 0, 0, 0, 0)  -- reject ignores values
        t:assert(side == 'ai' and pts == 2, 'Envido->Falta rejected: falta caller (AI) wins the 2')
    end)
end)
