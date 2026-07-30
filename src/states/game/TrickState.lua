-- Plays 1-3 tricks, resolving each via the pure trick_rules functions.

-- Table layout (see addendum item 3): played cards pull toward their owner on
-- Y, AI up / human down, overlapping ~half a card in the middle.
local AI_HAND_Y      = 8
local AI_PLAYED_Y    = 60
local HUMAN_PLAYED_Y = 92
local HUMAN_HAND_Y   = 146
local HUMAN_HAND_RAISE = 12  -- how far the highlighted/hovered card lifts
local STACK_DX, STACK_DY = 12, 12         -- per-card offset so a side's played cards fan out
-- ...and the two fans point away from each other (AI left, human right) so a
-- 3-card hand never has the AI's last card colliding with the human's first.
local STACK_DIR = { ai = -1, human = 1 }
local SIDE_MSG_Y = { ai = 66, human = 112 }  -- dialog box Y per side (AI up, human down)

-- envido/truco call buttons, right-side column
local BTN_W, BTN_H, BTN_GAP = 92, 16, 4
local BTN_X = VIRTUAL_WIDTH - BTN_W - 6
local BTN_Y0 = 60
local CALL_LABEL = { envido = 'Envido', real = 'Real envido', falta = 'Falta envido' }
local ENVIDO_OPENS = { 'envido', 'real', 'falta' }  -- what either side may open with

local function handYFor(side)   return side == 'ai' and AI_HAND_Y or HUMAN_HAND_Y end
local function playedYFor(side) return side == 'ai' and AI_PLAYED_Y or HUMAN_PLAYED_Y end
local function playedXFor(side) return cardRowX(side == 'ai' and 1 or 2, 2) end
local function other(side)      return side == 'human' and 'ai' or 'human' end

TrickState = Class{__includes = BaseState}

-- Every message box names its speaker; position alone reads as ambiguous once
-- the two sides talk in sequence (a bare number looked like the opponent's).
function TrickState:speaker(side)
    return side == 'ai' and (self.aiName .. ': ') or 'You: '
end

function TrickState:init(loop)
    self.loop = loop
    self.wins = { human = 0, ai = 0 }
    self.mano = loop.mano
    self.leader = loop.mano  -- mano leads the first trick
    self.tricksPlayed = 0
    self.aiName = firstNameOf(loop.aiName or 'AI')  -- short form: the HUD and boxes are tight
    self.firstTrickWinner = nil  -- decides a 1-1 hand ending in a parda; nil if trick 1 tied
    self.mouseWasDown = false  -- for left-click edge detection
    self.envidoUsed = false    -- an envido negotiation has already happened this hand
    self.canto = nil           -- active envido negotiation, or nil
    self.dialogs = {}          -- list of {text, panel} message boxes on screen
    self.hoveredButton = nil
    -- every card each side has played this hand, stacked (survives across tricks)
    self.playedStack = { human = {}, ai = {} }
    -- envido value snapshot from the full 3-card hands (a card may be on the
    -- table by the time the pie calls envido, so we can't read it off the hand later)
    self.envidoValue = { human = envidoValue(loop.humanHand), ai = envidoValue(loop.aiHand) }
    -- truco lives entirely here (one TrickState per hand); HandScoreState is
    -- handed the final point value, so none of this leaks onto loop
    self.trucoLevel = 0        -- accepted value: 0 none, 2 truco, 3 retruco, 4 vale cuatro
    self.trucoLeader = nil     -- side that may raise next (the last accepter)
    self.trucoPending = nil    -- { level, caller } awaiting quiero/no quiero
    self:startTrick()
end

-- A message box positioned on `side` (human low, ai up), sized to its text.
function TrickState:makeDialog(side, text)
    local font = gFonts['small']
    local w = font:getWidth(text) + 24
    local h = font:getHeight() + 16
    return { text = text, panel = Panel((VIRTUAL_WIDTH - w) / 2, SIDE_MSG_Y[side], w, h) }
end

-- Announce an AI move (only the AI's moves get a message). Blocks input for
-- 1.5s while shown, then clears and runs the optional continuation.
function TrickState:showAiMessage(label, afterFn)
    self.dialogs = { self:makeDialog('ai', self:speaker('ai') .. label) }
    Timer.after(1.5, function()
        self.dialogs = {}
        if afterFn then afterFn() end
    end)
end

function TrickState:startTrick()
    self.currentPlayer = self.leader  -- leader plays first, other responds
    self.trickCards = {}              -- [side] -> card played this trick
    self.anims = {}                   -- [side] -> live {card,x,y,rot} tween target
    self.landed = 0                   -- cards that finished their tween this trick
    self.playCount = 0
    self.resolving = false            -- true during the between-trick pause
    self.aiThinking = false           -- true while the AI's move is on its timer
    self.raised = nil                 -- lifted human card index, or nil for none
    self.prevHovered = nil            -- last frame's hovered card, for enter/exit edges
    self.resultText = nil
end

-- Remove `card` from `hand`, tween it from its hand slot onto the table, and
-- pass the turn. The trick isn't resolved until both cards finish landing.
function TrickState:playCard(side, card, hand)
    -- capture the hand-slot start position before the card leaves the hand
    local index
    for i, c in ipairs(hand) do
        if c == card then index = i break end
    end
    local fromX = cardRowX(index, #hand)
    table.remove(hand, index)

    self.trickCards[side] = card
    local a = { card = card, x = fromX, y = handYFor(side), rot = 0 }
    self.anims[side] = a

    -- stack: each card lands a step further along than this side's previous ones
    local idx = #self.playedStack[side]
    local toX = playedXFor(side) + STACK_DIR[side] * STACK_DX * idx
    local toY = playedYFor(side) + STACK_DY * idx
    local tilt = math.rad(math.random(-7, 7))  -- small toss tilt, settles there
    Timer.tween(0.2, { [a] = { x = toX, y = toY, rot = tilt } }):finish(function()
        -- park the settled card in the stack; drop the anim so it isn't drawn twice
        table.insert(self.playedStack[side], { card = card, x = toX, y = toY, rot = tilt })
        self.anims[side] = nil
        self.landed = self.landed + 1
        self:tryResolve()
    end)

    self.playCount = self.playCount + 1
    self.currentPlayer = side == 'human' and 'ai' or 'human'
end

-- Resolve once both cards of this trick have landed, so both are seen settling
-- before the winner is decided.
function TrickState:tryResolve()
    if self.landed >= 2 then self:resolve() end
end

function TrickState:resolve()
    self.resolving = true

    local otherSide = self.leader == 'human' and 'ai' or 'human'
    local result = resolveTrick(self.trickCards[self.leader], self.trickCards[otherSide])

    -- ties never bank a clean win; that's what isHandDecided counts on
    local winnerSide
    if result == 'leader' then
        winnerSide = self.leader
    elseif result == 'other' then
        winnerSide = otherSide
    end
    if winnerSide then
        self.wins[winnerSide] = self.wins[winnerSide] + 1
    end

    self.tricksPlayed = self.tricksPlayed + 1
    if self.tricksPlayed == 1 then
        self.firstTrickWinner = winnerSide  -- already nil on a parda
    end
    if result == 'tie' then
        self.resultText = 'Parda!'
    else
        self.resultText = winnerSide == 'human' and 'You win the trick' or (self.aiName .. ' wins the trick')
    end

    local decided = isHandDecided(self.wins, self.firstTrickWinner, self.tricksPlayed, self.mano)

    -- brief pause so both played cards and the outcome are readable
    Timer.after(1.0, function()
        if decided then
            -- the trick winner takes the accepted truco stake, or the 1-point base
            local points = self.trucoLevel > 0 and self.trucoLevel or 1
            self.loop:changePhase('score', { winner = decided, points = points })
        else
            self.leader = nextLeader(result, self.leader, self.mano)
            self:startTrick()
        end
    end)
end

function TrickState:update(dt)
    -- left-click edge detection (consumed by the pickers below); tracked every
    -- frame so a click can't carry across a pause
    local mouseDown = love.mouse.isDown(1)
    local clicked = mouseDown and not self.mouseWasDown
    self.mouseWasDown = mouseDown

    if self.resolving then return end
    -- both cards are down but resolve() is still waiting on the landing tweens;
    -- accept no more input until the trick resolves and startTrick() resets
    if self.playCount >= 2 then return end

    -- a message/reveal box is on screen; freeze input until it clears
    if #self.dialogs > 0 then return end

    -- an active envido negotiation takes over input (including the interrupt's,
    -- which has already discarded the truco call that provoked it)
    if self.canto then
        if self.canto.responder == 'human' then
            self:updateCallButtons(clicked)
        else
            self:aiRespondCanto()
        end
        return
    end

    -- a truco call awaiting quiero / no quiero
    if self.trucoPending then
        if other(self.trucoPending.caller) == 'human' then
            self:updateCallButtons(clicked)
        else
            self:aiRespondTruco()
        end
        return
    end

    if self.currentPlayer == 'ai' then
        self:updateAiTurn()
    else
        -- the human may open a call (buttons) or just play a card
        if self:updateCallButtons(clicked) then return end
        self:updateHumanSelection(clicked)
    end
end

-- Envido: first trick, before this side plays its card, once per hand -- and
-- NOT once truco has been accepted (accepting truco closes the envido window;
-- the interrupt below is the only way envido happens in answer to a truco).
function TrickState:canCallEnvido()
    return self.tricksPlayed == 0 and not self.envidoUsed and self.trucoLevel == 0
end

-- The envido interrupt is reachable only while a *first* truco is pending
-- (hand opened with truco, nothing played, envido unused, nothing accepted yet).
-- Taking it throws that truco away -- see openCanto.
function TrickState:canInterruptEnvido()
    return self.tricksPlayed == 0 and not self.envidoUsed
       and self.playCount == 0 and self.trucoLevel == 0
end

-- The right-side call buttons for this frame: responses to a live envido/truco
-- call, or the human's own-turn options, else none. Positions set here so
-- render and input agree on hit boxes.
function TrickState:callButtons()
    local list = {}

    if self.canto and self.canto.responder == 'human' then
        list = { { label = 'Quiero', act = 'accept' }, { label = 'No quiero', act = 'reject' } }
        for _, c in ipairs(self.canto:availableRaises()) do
            list[#list + 1] = { label = CALL_LABEL[c], act = 'call:' .. c }
        end

    elseif self.trucoPending and other(self.trucoPending.caller) == 'human' then
        list = { { label = 'Quiero', act = 'accept' }, { label = 'No quiero', act = 'reject' } }
        -- "el envido esta primero": any envido variant may answer a truco, and
        -- doing so discards the truco -- play just resumes once the envido ends
        if self:canInterruptEnvido() then
            for _, c in ipairs(ENVIDO_OPENS) do
                list[#list + 1] = { label = CALL_LABEL[c], act = 'call:' .. c }
            end
        end

    elseif not self.canto and not self.trucoPending
           and self.currentPlayer == 'human' and self.playCount < 2 then
        if self:canCallEnvido() then
            for _, c in ipairs(ENVIDO_OPENS) do
                list[#list + 1] = { label = CALL_LABEL[c], act = 'call:' .. c }
            end
        end
        local lvl = availableTrucoCall(self.trucoLevel, self.trucoLeader, 'human', self.trucoPending)
        if lvl then
            list[#list + 1] = { label = TRUCO_NAME[lvl], act = 'truco' }
        end
        list[#list + 1] = { label = 'Fold', act = 'fold' }

    else
        return {}
    end

    for i, b in ipairs(list) do
        b.key = tostring(i)
        b.x, b.y, b.w, b.h = BTN_X, BTN_Y0 + (i - 1) * (BTN_H + BTN_GAP), BTN_W, BTN_H
    end
    return list
end

function TrickState:updateCallButtons(clicked)
    self.hoveredButton = nil
    local mx, my = push.toGame(love.mouse.getPosition())
    for _, b in ipairs(self:callButtons()) do
        if mx and my and pointInRect(mx, my, b.x, b.y, b.w, b.h) then
            self.hoveredButton = b
        end
        if love.keyboard.wasPressed(b.key) or (self.hoveredButton == b and clicked) then
            self:applyCallButton(b.act)
            return true
        end
    end
    return false
end

function TrickState:applyCallButton(act)
    if act == 'accept' then
        if self.canto then self.canto:accept(); self:finishCanto()
        else self:resolveTrucoAccept() end
    elseif act == 'reject' then
        if self.canto then self.canto:reject(); self:finishCanto()
        else self:resolveTrucoReject() end
    elseif act == 'truco' then
        self:callTruco('human')
    elseif act == 'fold' then
        self:resolveFold('human')
    else
        local callType = act:match('call:(%a+)')
        if self.canto then
            self.canto:raise(callType)  -- human responder raises; the AI now answers
            self.aiThinking = false
        else
            self:openCanto('human', callType)
        end
    end
end

function TrickState:callTruco(side)
    local lvl = availableTrucoCall(self.trucoLevel, self.trucoLeader, side, self.trucoPending)
    if not lvl then return end
    self.trucoPending = { level = lvl, caller = side }
    self.aiThinking = false  -- let the responder's think re-arm
    if side == 'ai' then self:showAiMessage(TRUCO_NAME[lvl]) end
end

-- Accept only sets the stake; no points yet. currentPlayer (the caller) is
-- unchanged and resumes to play. (The AI-said-quiero message, if any, is added
-- by the caller -- a human accept is silent.)
function TrickState:resolveTrucoAccept()
    local p = self.trucoPending
    self.trucoLevel = p.level
    self.trucoLeader = other(p.caller)  -- the accepter may raise next
    self.trucoPending = nil
    self.aiThinking = false
end

function TrickState:resolveTrucoReject()
    local p = self.trucoPending
    self.trucoPending = nil
    self.loop:changePhase('score', { winner = p.caller, points = trucoRejectValue(p.level) })
end

function TrickState:resolveFold(side)
    self.loop:changePhase('score', { winner = other(side), points = trucoFoldValue(self.trucoLevel) })
end

-- Everything the AI's decisions read about the current position (PRD 6). Passed
-- as one table so later decisions can want more without reshaping call sites.
function TrickState:aiContext()
    return {
        against = self.trickCards.human,  -- nil unless the human has already played
        myWins = self.wins.ai,
        theirWins = self.wins.human,
        tricksPlayed = self.tricksPlayed,
        trucoLevel = self.trucoLevel,
        myScore = self.loop.aiScore,
        theirScore = self.loop.humanScore,
    }
end

function TrickState:aiRespondTruco()
    if self.aiThinking then return end
    self.aiThinking = true
    Timer.after(0.6, function()
        self.aiThinking = false
        if not self.trucoPending then return end
        local ctx = self:aiContext()
        -- "el envido esta primero": answer the truco with envido instead when the
        -- AI has one worth calling (which discards the truco -- see openCanto)
        local open = self:canInterruptEnvido()
            and EnvidoAiStub.chooseOpen(self.envidoValue.ai, ctx) or 'pass'
        if open ~= 'pass' then
            self:openCanto('ai', open)
            return
        end
        local p = self.trucoPending
        if TrucoAiStub.respond(self.loop.aiHand, ctx) == 'quiero' then
            self:resolveTrucoAccept()
            self:showAiMessage('Quiero')
        else
            self.trucoPending = nil
            -- announce first, then end the hand when the message clears
            self:showAiMessage('No quiero', function()
                self.loop:changePhase('score', { winner = p.caller, points = trucoRejectValue(p.level) })
            end)
        end
    end)
end

function TrickState:openCanto(opener, callType)
    self.envidoUsed = true
    -- answering a truco with envido discards that truco outright: no quiero is
    -- owed once the envido is done, and either side may call truco afresh
    self.trucoPending = nil
    self.canto = Canto(ENVIDO_CANTO, opener, callType)
    self.aiThinking = false  -- let the responder's think re-arm
    if opener == 'ai' then self:showAiMessage(CALL_LABEL[callType]) end
end

function TrickState:aiRespondCanto()
    if self.aiThinking then return end
    self.aiThinking = true
    Timer.after(0.6, function()
        self.aiThinking = false
        if not self.canto then return end
        -- availableRaises keeps the AI's escalation legal. A raise is announced
        -- here (it pays nothing, so it owns no award) and hands the answer back
        -- to the human; accept/reject go to finishCanto, which does that talking.
        local resp = EnvidoAiStub.chooseResponse(self.envidoValue.ai,
            self.canto:availableRaises(), self:aiContext())
        if resp == 'quiero' then
            self.canto:accept()
            self:finishCanto()
        elseif resp == 'noquiero' then
            self.canto:reject()
            self:finishCanto()
        else
            self.canto:raise(resp)
            self:showAiMessage(CALL_LABEL[resp])
        end
    end)
end

-- AI's turn with no live call. A Real/Falta-worthy envido goes FIRST: accepting a
-- truco closes the envido window, so trucoing on a big envido throws it away. A
-- weak envido still lets truco open the hand, which is what keeps the human's
-- "envido primero" interrupt reachable. Then truco, plain envido, fold, card.
function TrickState:updateAiTurn()
    if self.aiThinking then return end
    self.aiThinking = true
    Timer.after(0.6, function()
        self.aiThinking = false
        if self.currentPlayer ~= 'ai' or self.resolving or self.canto or self.trucoPending then return end

        local ctx = self:aiContext()
        -- asked once: a second call would roll the bluff again and could disagree
        local open = self:canCallEnvido()
            and EnvidoAiStub.chooseOpen(self.envidoValue.ai, ctx) or 'pass'
        local trucoLvl = availableTrucoCall(self.trucoLevel, self.trucoLeader, 'ai', self.trucoPending)

        if open == 'real' or open == 'falta' then
            self:openCanto('ai', open)
        elseif trucoLvl and TrucoAiStub.wantsToCall(self.loop.aiHand, ctx) then
            self:callTruco('ai')
        elseif open ~= 'pass' then
            self:openCanto('ai', open)
        elseif TrucoAiStub.wantsToFold(self.loop.aiHand, ctx) then
            -- announce before the hand ends, same rule as a truco no quiero
            self:showAiMessage('Me voy al mazo', function() self:resolveFold('ai') end)
        else
            -- decision lives in AiStub so PRD 7+ can swap it without touching this state
            self:playCard('ai', AiStub.chooseCard(self.loop.aiHand, ctx), self.loop.aiHand)
        end
    end)
end

-- Envido pays out here, possibly mid-trick-1; awardPoints is what notices a
-- chico ending on it and takes the hand away from us (PRD 5 §3).
function TrickState:award(side, points)
    self.loop:awardPoints(side, points)
end

function TrickState:awardCanto(outcome)
    local side, points = envidoAward(outcome, self.mano,
        self.envidoValue[self.mano], self.envidoValue[other(self.mano)],
        self.loop.humanScore, self.loop.aiScore)
    self:award(side, points)
end

-- Resolve the envido, and do all the announcing: the AI's answer is only ever
-- worth showing here, and it has to be shown BEFORE the payout -- an award can
-- end the chico, which tears this state down and would swallow the message.
-- Accept runs the mano-then-pie showdown; reject has none (per reglamento).
function TrickState:finishCanto()
    local outcome = self.canto.outcome
    local answerer = self.canto.responder  -- whoever accepted/rejected, raises included
    self.canto = nil
    self.aiThinking = false

    if outcome.kind == 'accept' then
        if answerer == 'ai' and self.mano == 'ai' then
            -- mano declares first, so the AI's quiero rides along on its number
            self:revealEnvido(outcome, 'Quiero')
        elseif answerer == 'ai' then
            -- AI is pie: quiero now, its number comes with its response below
            self:showAiMessage('Quiero', function() self:revealEnvido(outcome) end)
        else
            self:revealEnvido(outcome)  -- the human clicked Quiero; nothing to announce
        end
    elseif answerer == 'ai' then
        self:showAiMessage('No quiero', function() self:awardCanto(outcome) end)
    else
        self:awardCanto(outcome)
    end
end

-- Showdown: mano's number, then pie's ("son mejores" if better, else "son
-- buenas"), each held ~2s; points land after. Input is frozen while dialogs show.
-- manoPrefix (only "Quiero") prepends to the mano's declaration when the same
-- side both accepted and declares first.
function TrickState:revealEnvido(outcome, manoPrefix)
    local pie = other(self.mano)
    local manoVal, pieVal = self.envidoValue[self.mano], self.envidoValue[pie]
    local manoText = manoPrefix and (manoPrefix .. ', ' .. manoVal) or tostring(manoVal)

    self.dialogs = { self:makeDialog(self.mano, self:speaker(self.mano) .. manoText) }
    Timer.after(2, function()
        -- conceding says nothing about your own number, per reglamento
        local pieText = pieVal > manoVal and (pieVal .. ' son mejores') or 'son buenas'
        table.insert(self.dialogs, self:makeDialog(pie, self:speaker(pie) .. pieText))
        Timer.after(2, function()
            self.dialogs = {}
            self:awardCanto(outcome)
        end)
    end)
end

-- Pick a card two ways. Mouse: entering a card lifts it, leaving a card it was
-- over lowers it -- but drifting through empty space leaves a keyboard-lifted
-- card alone. Arrows: lift the first card if none is up, else move the lift.
-- Enter plays the lifted card; a click plays the card under the mouse.
function TrickState:updateHumanSelection(clicked)
    local hand = self.loop.humanHand
    local n = #hand
    if self.raised then self.raised = math.max(1, math.min(self.raised, n)) end

    local hovered = self:cardAtMouse()
    if hovered then
        self.raised = hovered            -- over a card -> that card is up
    elseif self.prevHovered then
        self.raised = nil                -- just left a card -> put it down
    end                                  -- empty->empty: leave the lift as-is
    self.prevHovered = hovered

    if love.keyboard.wasPressed('left') then
        self.raised = self.raised and math.max(1, self.raised - 1) or 1
    elseif love.keyboard.wasPressed('right') then
        self.raised = self.raised and math.min(n, self.raised + 1) or 1
    end

    if love.keyboard.wasPressed('return') and self.raised then
        self:playCard('human', hand[self.raised], hand)
    elseif hovered and clicked then
        self:playCard('human', hand[hovered], hand)
    end
end

-- Human-hand card index under the mouse, or nil. Hit region spans the raised
-- and resting Y so the lifted card stays clickable. push.toGame converts the
-- window pointer to virtual coords (false when outside the game area).
function TrickState:cardAtMouse()
    local mx, my = push.toGame(love.mouse.getPosition())
    if not mx or not my then return nil end
    local n = #self.loop.humanHand
    local yTop = HUMAN_HAND_Y - HUMAN_HAND_RAISE
    local yBot = HUMAN_HAND_Y + CARD_H
    for i = 1, n do
        local x = cardRowX(i, n)
        if mx >= x and mx <= x + CARD_W and my >= yTop and my <= yBot then
            return i
        end
    end
    return nil
end

function TrickState:render()
    love.graphics.clear(24/255, 89/255, 53/255, 1)
    local loop = self.loop

    -- top area is strictly the AI's face-down hand (item 4)
    for i = 1, #loop.aiHand do
        drawCardBack(cardRowX(i, #loop.aiHand), AI_HAND_Y)
    end

    -- every card played this hand, stacked (oldest first so newer land on top),
    -- then the still-tweening card on top; owner is read from the base position
    for _, side in ipairs({ 'ai', 'human' }) do
        for _, e in ipairs(self.playedStack[side]) do
            drawCardFrontRot(e.card, e.x, e.y, e.rot)
        end
        local a = self.anims[side]
        if a then
            drawCardFrontRot(a.card, a.x, a.y, a.rot)
        end
    end

    -- human hand, face-up; on the human's turn (and no live call/dialog) the
    -- active card lifts (the lift is the only cue -- no highlight ring)
    local myTurn = self.currentPlayer == 'human' and not self.resolving
        and self.playCount < 2 and not self.canto and not self.trucoPending and #self.dialogs == 0
    love.graphics.setColor(1, 1, 1, 1)
    for i = 1, #loop.humanHand do
        local x = cardRowX(i, #loop.humanHand)
        local y = (myTurn and i == self.raised) and (HUMAN_HAND_Y - HUMAN_HAND_RAISE) or HUMAN_HAND_Y
        drawCardFront(loop.humanHand[i], x, y)
    end

    if #self.dialogs > 0 then
        -- message/reveal boxes own the screen; they replace the call buttons
        love.graphics.setFont(gFonts['small'])
        for _, d in ipairs(self.dialogs) do
            d.panel:render()
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(d.text, d.panel.x, d.panel.y + 8, d.panel.width, 'center')
        end
    else
        for _, b in ipairs(self:callButtons()) do
            drawButton('[' .. b.key .. '] ' .. b.label, b.x, b.y, b.w, b.h, self.hoveredButton == b)
        end
    end

    local stake = self.trucoLevel > 0 and ('  [' .. TRUCO_NAME[self.trucoLevel] .. ']') or ''
    local status
    if #self.dialogs > 0 then
        status = nil
    elseif self.canto then
        status = self.canto.responder == 'human' and 'Envido: respond' or (self.aiName .. ' is thinking...')
    elseif self.trucoPending then
        status = other(self.trucoPending.caller) == 'human'
            and (TRUCO_NAME[self.trucoPending.level] .. ': respond') or (self.aiName .. ' is thinking...')
    elseif self.resolving then
        status = self.resultText
    elseif self.currentPlayer == 'human' then
        status = 'Trick ' .. (self.tricksPlayed + 1) .. ' - your turn' .. stake
    else
        status = 'Trick ' .. (self.tricksPlayed + 1) .. ' - ' .. self.aiName .. ' is thinking...' .. stake
    end
    drawHud(loop, status)
end
