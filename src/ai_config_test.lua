-- Run via: luajit lib/knife/test.lua src/ai_config_test.lua

require 'src.ai_config'

local TIERS = { 'weak', 'decent', 'strong', 'exceptional' }

T('ai_config (shared aggression / bluff plumbing)', function(t)
    t('shiftTier steps along the ladder and clamps at both ends', function(t)
        t:assert(AiConfig.shiftTier(TIERS, 'decent', 1) == 'strong', 'up one')
        t:assert(AiConfig.shiftTier(TIERS, 'decent', -1) == 'weak', 'down one')
        t:assert(AiConfig.shiftTier(TIERS, 'weak', -1) == 'weak', 'clamped at the bottom')
        t:assert(AiConfig.shiftTier(TIERS, 'exceptional', 1) == 'exceptional', 'clamped at the top')
        t:assert(AiConfig.shiftTier(TIERS, 'decent', 0) == 'decent', 'zero is a no-op')
    end)

    t('bluffDelta is silent at rate 0 and always fires at rate 1', function(t)
        local rate, rng = AiConfig.bluffRate, AiConfig.random

        AiConfig.bluffRate = 0
        for _ = 1, 50 do t:assert(AiConfig.bluffDelta() == 0, 'never bluffs at rate 0') end

        AiConfig.bluffRate = 1
        AiConfig.random = function() return 0.1 end   -- chance() passes, coin() heads
        t:assert(AiConfig.bluffDelta() == -1, 'rate 1 + low roll shifts down')
        AiConfig.random = function() return 0.9 end   -- chance() passes, coin() tails
        t:assert(AiConfig.bluffDelta() == 1, 'rate 1 + high roll shifts up')

        AiConfig.bluffRate, AiConfig.random = rate, rng
    end)

    t('at the default rate both the straight and the bluffed path occur', function(t)
        -- §7: bluffing is non-deterministic, so assert reachability, not an outcome
        local straight, shifted = 0, 0
        math.randomseed(1)
        for _ = 1, 2000 do
            if AiConfig.bluffDelta() == 0 then straight = straight + 1 else shifted = shifted + 1 end
        end
        t:assert(straight > 0, 'the tier decision is normally used as-is')
        t:assert(shifted > 0, 'and the bluff path is reachable')
        t:assert(straight > shifted, 'bluffing stays the exception at rate 0.10')
    end)
end)
