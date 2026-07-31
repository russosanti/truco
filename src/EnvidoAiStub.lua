-- Envido decisions (PRD 6 §5). Tiers on the hand's envido value (0-33), with
-- aggression sliding every boundary down and bluffRate occasionally nudging the
-- resulting tier one step either way.
--
-- Both entry points take the VALUE, not the hand: by the time the pie answers,
-- the mano may already have played a card, so re-deriving from a 2-card hand
-- would read a number the player never had. TrickState snapshots it at deal.
-- ctx = { myScore, theirScore }

EnvidoAiStub = {}

local TIERS = { 'weak', 'decent', 'strong', 'exceptional' }

-- Boundaries at aggression 0.5: 20 / 27 / 31. The shift spans +-4 across the
-- full 0-1 range, so a timid AI needs 24/31/35 and a reckless one 16/23/27.
function EnvidoAiStub.tier(value, aggression)
    local shift = ((aggression or AiConfig.aggression) - 0.5) * 8
    if value >= 31 - shift then return 'exceptional' end
    if value >= 27 - shift then return 'strong' end
    if value >= 20 - shift then return 'decent' end
    return 'weak'
end

local function bluffed(value)
    return AiConfig.shiftTier(TIERS, EnvidoAiStub.tier(value), AiConfig.bluffDelta())
end

-- Falta is the killer call: leading and into "buenas", faltaEnvidoValue pays
-- 30 - leader, so winning it closes the chico outright. Worth forcing there.
local function wantsFalta(ctx)
    return (ctx.myScore or 0) > 15 and (ctx.myScore or 0) > (ctx.theirScore or 0)
end

local function has(list, callType)
    for _, c in ipairs(list or {}) do
        if c == callType then return true end
    end
    return false
end

-- Opening is nearly always a plain Envido -- that's how the call is actually
-- made, and the escalation happens in chooseResponse when the other side answers.
-- Real envido only comes out of a genuinely big hand (or a bluffed-up one).
function EnvidoAiStub.chooseOpen(value, ctx)
    ctx = ctx or {}
    local tier = bluffed(value)
    if tier == 'weak' then return 'pass' end
    if tier == 'decent' or tier == 'strong' then return 'envido' end
    -- exceptional: falta on sight when it would close the chico, else it either
    -- opens big or hides the hand behind a plain envido
    if wantsFalta(ctx) then return 'falta' end
    return AiConfig.coin() and 'real' or 'envido'
end

-- `raises` is the canto's availableRaises(), so only a legal escalation can be
-- named. The ladder narrowing is also what bounds this: once falta is on the
-- table the list is empty and only quiero / no quiero are left.
function EnvidoAiStub.chooseResponse(value, raises, ctx)
    ctx = ctx or {}
    local tier = bluffed(value)
    if tier == 'weak' then return 'noquiero' end
    if tier == 'decent' then return 'quiero' end

    if tier == 'exceptional' and has(raises, 'falta')
       and (wantsFalta(ctx) or AiConfig.coin()) then
        return 'falta'
    end
    if has(raises, 'real') then return 'real' end
    if tier == 'exceptional' and has(raises, 'falta') then return 'falta' end
    return 'quiero'
end
