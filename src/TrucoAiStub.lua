-- Truco decisions (PRD 6 §6). Position, not a single number: unplayed bravas
-- weighed against the trick score so far. Aggression slides the position one
-- step and bluffRate occasionally nudges it again.
--
-- ctx = { myWins, theirWins, tricksPlayed, trucoLevel }

TrucoAiStub = {}

local POSITIONS = { 'weak', 'uncertain', 'strong' }

local function bravas(hand)
    local n = 0
    for _, card in ipairs(hand) do
        if card.trickTier <= 4 then n = n + 1 end  -- tier 1-4 = "brava" (PRD 1 §4)
    end
    return n
end

function TrucoAiStub.position(hand, ctx)
    ctx = ctx or {}
    if bravas(hand) >= 1 or (ctx.myWins or 0) > 0 then return 'strong' end
    -- no bravas and no wins: still anyone's hand in trick 1, plainly bad after
    if (ctx.tricksPlayed or 0) == 0 and (ctx.theirWins or 0) == 0 then return 'uncertain' end
    return 'weak'
end

-- Aggression pushes the read one step optimistic at the top of the range and
-- one step pessimistic at the bottom; the bluff then rides on top of that.
local function effective(hand, ctx)
    local pos = TrucoAiStub.position(hand, ctx)
    local delta = 0
    if AiConfig.aggression >= 0.75 then delta = 1
    elseif AiConfig.aggression <= 0.25 then delta = -1 end
    pos = AiConfig.shiftTier(POSITIONS, pos, delta)
    return AiConfig.shiftTier(POSITIONS, pos, AiConfig.bluffDelta())
end

-- Two or more bravas: strong enough to escalate rather than merely accept.
local function veryStrong(hand, ctx)
    return bravas(hand) >= 2 or (ctx or {}).myWins and ctx.myWins >= 2
end

-- Open or raise from strength only -- and not on the very first move of a hand
-- unless the cards are exceptional: normally you play one and see what the other
-- side has before betting. (Raising on a later turn needs no special case: once
-- resolveTrucoAccept makes the AI the trucoLeader, availableTrucoCall offers the
-- next level and updateAiTurn's truco branch takes it.)
function TrucoAiStub.wantsToCall(hand, ctx)
    ctx = ctx or {}
    local nothingSeen = (ctx.tricksPlayed or 0) == 0 and (ctx.cardsPlayed or 0) == 0
    if nothingSeen and not veryStrong(hand, ctx) then return false end
    return effective(hand, ctx) == 'strong'
end

-- Benefit of the doubt anywhere but a plainly lost position -- and from a very
-- strong one, answer by raising instead ('quiero, and up'). The caller checks
-- the raise is legal; at Vale cuatro this reads as a plain quiero.
function TrucoAiStub.respond(hand, ctx)
    local pos = effective(hand, ctx)
    if pos == 'weak' then return 'noquiero' end
    if pos == 'strong' and veryStrong(hand, ctx) then return 'raise' end
    return 'quiero'
end

-- Only worth folding once a stake is actually accepted -- it caps the loss at
-- the current level instead of risking the opponent escalating it further.
function TrucoAiStub.wantsToFold(hand, ctx)
    ctx = ctx or {}
    return (ctx.trucoLevel or 0) > 0 and effective(hand, ctx) == 'weak'
end
