-- Envido decisions for AI

EnvidoAiStub = {}

local TIERS = { 'weak', 'decent', 'strong', 'exceptional' }

-- Boundaries at aggression 0.5: 20 / 27 / 31
function EnvidoAiStub.tier(value, aggression)
    local shift = ((aggression or AiConfig.aggression) - 0.5) * 8
    if value >= 31 - shift then return 'exceptional' end
    if value >= 27 - shift then return 'strong' end
    if value >= 20 - shift then return 'decent' end
    return 'weak'
end

local function bluffed(value)
    return AiConfig.bluffTier(TIERS, EnvidoAiStub.tier(value))
end

-- Falta is the killer call: leading and into "buenas"
local function wantsFalta(ctx)
    return (ctx.myScore or 0) > 15 and (ctx.myScore or 0) > (ctx.theirScore or 0)
end

-- Opening is nearly always a plain Envido
function EnvidoAiStub.chooseOpen(value, ctx)
    ctx = ctx or {}
    local tier = bluffed(value)
    if tier == 'weak' then return 'pass' end
    if tier == 'decent' or tier == 'strong' then return 'envido' end
    -- exceptional: falta on sight when it would close the chico
    if wantsFalta(ctx) then return 'falta' end
    return AiConfig.coin() and 'real' or 'envido'
end

-- `raises` is the canto's availableRaises(), so only a legal escalation can be made
function EnvidoAiStub.chooseResponse(value, raises, ctx)
    ctx = ctx or {}
    local tier = bluffed(value)
    if tier == 'weak' then return 'noquiero' end
    if tier == 'decent' then return 'quiero' end

    if tier == 'exceptional' and AiConfig.contains(raises, 'falta')
       and (wantsFalta(ctx) or AiConfig.coin()) then
        return 'falta'
    end
    if AiConfig.contains(raises, 'real') then return 'real' end
    if tier == 'exceptional' and AiConfig.contains(raises, 'falta') then return 'falta' end
    return 'quiero'
end
