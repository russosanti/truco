-- Run via: luajit lib/knife/test.lua src/EnvidoAiStub_test.lua

require 'src.ai_config'
require 'src.EnvidoAiStub'

AiConfig.bluffRate = 0  -- tier tables are what's under test; bluffing has its own file

-- AiConfig.coin() is true below 0.5. What the coin decides differs per call site
-- (opening big vs. hiding behind a plain Envido; raising to Falta vs. to Real),
-- so this just pins the flip itself rather than naming an outcome.
local function setCoin(heads)
    AiConfig.random = function() return heads and 0.1 or 0.9 end
end

T('EnvidoAiStub (envido, PRD 6 §5)', function(t)
    t('tier boundaries at the default aggression 0.5', function(t)
        local cases = {
            { 0, 'weak' }, { 19, 'weak' },
            { 20, 'decent' }, { 26, 'decent' },
            { 27, 'strong' }, { 30, 'strong' },
            { 31, 'exceptional' }, { 33, 'exceptional' },
        }
        for _, c in ipairs(cases) do
            t:assert(EnvidoAiStub.tier(c[1], 0.5) == c[2], c[1] .. ' -> ' .. c[2])
        end
    end)

    t('aggression slides every boundary down (+-4 across the range)', function(t)
        -- timid: 24/31/35, so 20 is weak and 33 is only strong
        t:assert(EnvidoAiStub.tier(20, 0) == 'weak', 'timid: 20 is not worth calling')
        t:assert(EnvidoAiStub.tier(24, 0) == 'decent', 'timid: decent starts at 24')
        t:assert(EnvidoAiStub.tier(33, 0) == 'strong', 'timid: 35+ needed for exceptional')
        -- reckless: 16/23/27
        t:assert(EnvidoAiStub.tier(16, 1) == 'decent', 'reckless: 16 already calls')
        t:assert(EnvidoAiStub.tier(23, 1) == 'strong', 'reckless: strong from 23')
        t:assert(EnvidoAiStub.tier(27, 1) == 'exceptional', 'reckless: exceptional from 27')
    end)

    -- opening is a plain Envido almost always; escalation is chooseResponse's job
    t('chooseOpen maps the tiers', function(t)
        setCoin(true)
        t:assert(EnvidoAiStub.chooseOpen(19, {}) == 'pass', 'weak never calls')
        t:assert(EnvidoAiStub.chooseOpen(24, {}) == 'envido', 'decent -> Envido')
        t:assert(EnvidoAiStub.chooseOpen(28, {}) == 'envido', 'strong opens plain too')
        t:assert(EnvidoAiStub.chooseOpen(32, {}) == 'real', 'exceptional -> coin says Real')
        setCoin(false)
        t:assert(EnvidoAiStub.chooseOpen(32, {}) == 'envido',
            'exceptional -> coin hides it behind a plain Envido')
    end)

    t('Real envido never comes out below the top tier', function(t)
        AiConfig.random = math.random
        local opens = {}
        math.randomseed(1)
        for value = 20, 30 do                       -- decent and strong only
            for _ = 1, 200 do opens[EnvidoAiStub.chooseOpen(value, {})] = true end
        end
        t:assert(opens['envido'], 'they do open')
        t:assert(not opens['real'], 'but never with Real envido')
        t:assert(not opens['falta'], 'nor with Falta')
    end)

    t('exceptional always calls Falta when it would close the chico', function(t)
        setCoin(false)  -- coin would hide it behind a plain Envido; the score rule wins
        t:assert(EnvidoAiStub.chooseOpen(32, { myScore = 20, theirScore = 10 }) == 'falta',
            'ahead and past 15 -> Falta on sight')
        t:assert(EnvidoAiStub.chooseOpen(32, { myScore = 20, theirScore = 25 }) ~= 'falta',
            'past 15 but behind -> no forced Falta')
        t:assert(EnvidoAiStub.chooseOpen(32, { myScore = 12, theirScore = 5 }) ~= 'falta',
            'ahead but still in malas -> no forced Falta')
    end)

    t('chooseResponse maps the tiers and only names legal raises', function(t)
        local all = { 'envido', 'real', 'falta' }
        setCoin(false)
        t:assert(EnvidoAiStub.chooseResponse(19, all, {}) == 'noquiero', 'weak declines')
        t:assert(EnvidoAiStub.chooseResponse(24, all, {}) == 'quiero', 'decent just accepts')
        t:assert(EnvidoAiStub.chooseResponse(28, all, {}) == 'real', 'strong raises once')
        t:assert(EnvidoAiStub.chooseResponse(28, {}, {}) == 'quiero',
            'strong with nothing to raise to -> quiero')
        t:assert(EnvidoAiStub.chooseResponse(28, { 'falta' }, {}) == 'quiero',
            'strong will not jump straight to Falta')

        setCoin(true)
        t:assert(EnvidoAiStub.chooseResponse(32, all, {}) == 'falta', 'exceptional -> Falta')
        t:assert(EnvidoAiStub.chooseResponse(32, {}, {}) == 'quiero',
            'exceptional with the ladder closed -> quiero, no illegal raise')
        t:assert(EnvidoAiStub.chooseResponse(32, { 'real' }, {}) == 'real',
            'exceptional takes what is available')
    end)

    t('exceptional forced to Falta by the score, when it is available', function(t)
        setCoin(false)
        local ctx = { myScore = 20, theirScore = 10 }
        t:assert(EnvidoAiStub.chooseResponse(32, { 'real', 'falta' }, ctx) == 'falta',
            'raises to Falta to close the chico')
    end)
end)
