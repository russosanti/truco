-- Shared AI tuning (PRD 6 §3). One knob pair for all three decision files;
-- PRD 7 edits these values (or overrides them) per tournament round.
--
-- aggression (0-1) shifts every threshold: higher calls, raises and accepts on
-- weaker hands. bluffRate is the chance a decision slides one tier either way,
-- so the AI isn't perfectly readable. Both work through shiftTier below -- the
-- envido tiers and the truco positions are the same kind of ordered ladder.

AiConfig = {
    aggression = 0.5,
    bluffRate = 0.10,
    random = math.random,  -- injectable seam: tests stub it to kill the coin flips
}

function AiConfig.chance(p)
    return AiConfig.random() < p
end

function AiConfig.coin()
    return AiConfig.random() < 0.5
end

-- 0 normally; +1 or -1 with probability bluffRate.
function AiConfig.bluffDelta()
    if not AiConfig.chance(AiConfig.bluffRate) then return 0 end
    return AiConfig.coin() and -1 or 1
end

function AiConfig.contains(list, value)
    for _, v in ipairs(list or {}) do
        if v == value then return true end
    end
    return false
end

function AiConfig.bluffTier(order, tier)
    return AiConfig.shiftTier(order, tier, AiConfig.bluffDelta())
end

-- Step `tier` along the ordered list by `delta`, clamped at both ends.
function AiConfig.shiftTier(order, tier, delta)
    for i, name in ipairs(order) do
        if name == tier then
            local j = math.max(1, math.min(#order, i + delta))
            return order[j]
        end
    end
    return tier
end
