-- Flor decisions for AI

FlorAiStub = {}

local TIERS = { 'shy', 'solid', 'huge' }

-- 28 and 34 at the default aggression
function FlorAiStub.tier(value, aggression)
    local shift = ((aggression or AiConfig.aggression) - 0.5) * 8
    if value >= 34 - shift then return 'huge' end
    if value >= 28 - shift then return 'solid' end
    return 'shy'
end

local function bluffed(value)
    return AiConfig.bluffTier(TIERS, FlorAiStub.tier(value))
end

-- `raises` is the canto's availableRaises(), so only a legal call can be made
function FlorAiStub.chooseResponse(value, raises, atBase)
    local tier = bluffed(value)

    if tier == 'huge' then
        if AiConfig.contains(raises, 'resto') then return 'resto' end
        if AiConfig.contains(raises, 'contraflor') then return 'contraflor' end
        return 'quiero'
    end
    if atBase or tier == 'solid' then return 'quiero' end
    return 'meachico'
end
