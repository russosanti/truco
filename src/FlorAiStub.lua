-- Flor decisions (PRD 9 §8). Declaring isn't a decision -- it's mandatory -- so
-- the only choice is whether to escalate once both sides have one.
--
-- Takes the flor VALUE, not the hand, for the same reason the envido stub does:
-- TrickState snapshots it at deal.

FlorAiStub = {}

local TIERS = { 'shy', 'solid', 'huge' }

-- 28 and 34 at the default aggression, sliding +-4 across the 0-1 range like
-- the envido bands.
function FlorAiStub.tier(value, aggression)
    local shift = ((aggression or AiConfig.aggression) - 0.5) * 8
    if value >= 34 - shift then return 'huge' end
    if value >= 28 - shift then return 'solid' end
    return 'shy'
end

local function bluffed(value)
    return AiConfig.bluffTier(TIERS, FlorAiStub.tier(value))
end

-- `raises` is the canto's availableRaises(), so only a legal rung can be named.
-- At the base level it always accepts: conceding there costs the same 3 as
-- losing the comparison, so declining is strictly worse than seeing it through.
-- The shy threshold is for refusing a Contraflor, which is what §8 specifies.
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
