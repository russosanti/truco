-- Shared basic AI tuning

AiConfig = {
    aggression = 0.5,
    bluffRate = 0.10,
    random = math.random,  -- injectable sead
}

function AiConfig.chance(p)
    return AiConfig.random() < p
end

function AiConfig.coin()
    return AiConfig.random() < 0.5
end

-- probability of bluffing
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

-- Used for scaling or calling either envido or truco
function AiConfig.shiftTier(order, tier, delta)
    for i, name in ipairs(order) do
        if name == tier then
            local j = math.max(1, math.min(#order, i + delta))
            return order[j]
        end
    end
    return tier
end
