-- Trick-play decisions (PRD 6 §4). Lower trickTier is stronger (see
-- Card.compareTrick). Deterministic on purpose -- §4 defines no bluffing, and a
-- randomized card play reads as a blunder rather than as deception.
--
-- ctx = { against = card on the table or nil, myWins, theirWins, tricksPlayed }

AiStub = {}

local function weakest(cards)
    local pick
    for _, c in ipairs(cards) do
        if not pick or c.trickTier > pick.trickTier then pick = c end
    end
    return pick
end

local function strongest(cards)
    local pick
    for _, c in ipairs(cards) do
        if not pick or c.trickTier < pick.trickTier then pick = c end
    end
    return pick
end

local function matching(hand, test)
    local out = {}
    for _, c in ipairs(hand) do
        if test(c) then out[#out + 1] = c end
    end
    return out
end

-- Cover as cheaply as possible; failing that tie, which is never worse than
-- losing -- and per isHandDecided a parda while already up a trick takes the
-- hand outright. Otherwise throw away the weakest card.
local function respondTo(hand, against)
    local beats = matching(hand, function(c) return c.trickTier < against.trickTier end)
    if #beats > 0 then return weakest(beats) end

    local ties = matching(hand, function(c) return c.trickTier == against.trickTier end)
    if #ties > 0 then return weakest(ties) end

    return weakest(hand)
end

-- Lead big once the hand can be settled this trick -- either side holding a
-- trick win, or a parda already played (isHandDecided settles a parda plus any
-- single win). Before that lead small and keep the bravas for the decider.
local function lead(hand, ctx)
    local pardas = (ctx.tricksPlayed or 0) - (ctx.myWins or 0) - (ctx.theirWins or 0)
    local decisive = (ctx.myWins or 0) > 0 or (ctx.theirWins or 0) > 0 or pardas >= 1
    return decisive and strongest(hand) or weakest(hand)
end

function AiStub.chooseCard(hand, ctx)
    ctx = ctx or {}
    if ctx.against then return respondTo(hand, ctx.against) end
    return lead(hand, ctx)
end
