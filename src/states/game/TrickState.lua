-- Plays 1-3 tricks, resolving each via the pure trick_rules functions.

-- Table layout (see addendum item 3): played cards pull toward their owner on
-- Y, AI up / human down, overlapping ~half a card in the middle.
local AI_HAND_Y      = 8
local AI_PLAYED_Y    = 60
local HUMAN_PLAYED_Y = 92
local HUMAN_HAND_Y   = 146
local HUMAN_HAND_RAISE = 12  -- how far the highlighted/hovered card lifts

-- envido/truco call buttons, right-side column
local BTN_W, BTN_H, BTN_GAP = 92, 16, 4
local BTN_X = VIRTUAL_WIDTH - BTN_W - 6
local BTN_Y0 = 60
local CALL_LABEL = { envido = 'Envido', real = 'Real envido', falta = 'Falta envido' }

local function handYFor(side)   return side == 'ai' and AI_HAND_Y or HUMAN_HAND_Y end
local function playedYFor(side) return side == 'ai' and AI_PLAYED_Y or HUMAN_PLAYED_Y end

TrickState = Class{__includes = BaseState}

function TrickState:init(loop)
    self.loop = loop
    self.wins = { human = 0, ai = 0 }
    self.mano = loop.mano
    self.leader = loop.mano  -- mano leads the first trick
    self.tricksPlayed = 0
    self.mouseWasDown = false  -- for left-click edge detection
    self.envidoUsed = false    -- an envido negotiation has already happened this hand
    self.canto = nil           -- active call negotiation, or nil
    self.envidoBanner = nil     -- brief post-envido result text
    self.hoveredButton = nil
    self:startTrick()
end

function TrickState:startTrick()
    self.currentPlayer = self.leader  -- leader plays first, other responds
    self.trickCards = {}              -- [side] -> card played this trick
    self.anims = {}                   -- [side] -> live {card,x,y,rot,done} tween target
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
    local a = { card = card, x = fromX, y = handYFor(side), rot = 0, done = false }
    self.anims[side] = a

    local toX = cardRowX(side == 'ai' and 1 or 2, 2)  -- same X as before; item 3 is Y-only
    local tilt = math.rad(math.random(-7, 7))         -- small toss tilt, settles there
    Timer.tween(0.2, { [a] = { x = toX, y = playedYFor(side), rot = tilt } }):finish(function()
        a.done = true
        self:tryResolve()
    end)

    self.playCount = self.playCount + 1
    self.currentPlayer = side == 'human' and 'ai' or 'human'
end

-- Resolve only once both played cards have finished animating, so both are
-- seen landing before the winner is decided.
function TrickState:tryResolve()
    if self.playCount < 2 then return end
    if self.anims.human and self.anims.human.done
       and self.anims.ai and self.anims.ai.done then
        self:resolve()
    end
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
    if result == 'tie' then
        self.resultText = 'Parda!'
    else
        self.resultText = winnerSide == 'human' and 'You win the trick' or 'AI wins the trick'
    end

    local decided = isHandDecided(self.wins, result == 'tie', self.tricksPlayed, self.mano)

    -- brief pause so both played cards and the outcome are readable
    Timer.after(1.0, function()
        if decided then
            self.loop.machine:change('score', { winner = decided })
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

    -- an active envido negotiation takes over input until it resolves (its
    -- banner then lingers briefly before card play resumes)
    if self.canto then
        if self.canto.resolved then return end
        if self.canto.responder == 'human' then
            self:updateCallButtons(clicked)
        else
            self:aiRespondCanto()
        end
        return
    end

    if self.currentPlayer == 'ai' then
        self:updateAiTurn()
    else
        -- the human may open envido (buttons) or just play a card to skip it
        if self:updateCallButtons(clicked) then return end
        self:updateHumanSelection(clicked)
    end
end

-- Envido is callable only in the first trick, before this side plays its card,
-- and only once per hand (mano first; the pie can still call after mano's card).
function TrickState:canCallEnvido()
    return self.tricksPlayed == 0 and not self.envidoUsed
end

-- The right-side call buttons for this frame: envido opens (human's eligible
-- turn) or the responses to a live call, else none. Positions set here so
-- render and input agree on hit boxes.
function TrickState:callButtons()
    local list
    if self.canto and not self.canto.resolved and self.canto.responder == 'human' then
        list = { { label = 'Quiero', act = 'accept' }, { label = 'No quiero', act = 'reject' } }
        for _, c in ipairs(self.canto:availableRaises()) do
            list[#list + 1] = { label = CALL_LABEL[c], act = 'call:' .. c }
        end
    elseif not self.canto and self.currentPlayer == 'human'
           and self.playCount < 2 and self:canCallEnvido() then
        list = {
            { label = 'Envido', act = 'call:envido' },
            { label = 'Real envido', act = 'call:real' },
            { label = 'Falta envido', act = 'call:falta' },
        }
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
        self.canto:accept(); self:finishCanto()
    elseif act == 'reject' then
        self.canto:reject(); self:finishCanto()
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

function TrickState:openCanto(opener, callType)
    self.envidoUsed = true
    self.canto = Canto(ENVIDO_CANTO, opener, callType)
    self.aiThinking = false  -- let the responder's think re-arm
end

function TrickState:aiRespondCanto()
    if self.aiThinking then return end
    self.aiThinking = true
    Timer.after(0.6, function()
        self.aiThinking = false
        if not self.canto or self.canto.resolved then return end
        -- stub never raises: quiero / no quiero only
        if EnvidoAiStub.chooseResponse(self.loop.aiHand) == 'quiero' then
            self.canto:accept()
        else
            self.canto:reject()
        end
        self:finishCanto()
    end)
end

-- AI's turn with no live call: decide envido first (when eligible), else play.
function TrickState:updateAiTurn()
    if self.aiThinking then return end
    self.aiThinking = true
    Timer.after(0.6, function()
        self.aiThinking = false
        if self.currentPlayer ~= 'ai' or self.resolving or self.canto then return end
        if self:canCallEnvido() and EnvidoAiStub.chooseOpen(self.loop.aiHand) == 'envido' then
            self:openCanto('ai', 'envido')
        else
            -- decision lives in AiStub so PRD 6 can swap it without touching this state
            self:playCard('ai', AiStub.chooseCard(self.loop.aiHand), self.loop.aiHand)
        end
    end)
end

-- Apply the resolved envido points immediately, show a banner, then resume the
-- interrupted card play (currentPlayer is unchanged -- the opener still plays).
function TrickState:finishCanto()
    local side, points = envidoAward(self.canto.outcome, self.mano,
        self.loop.humanHand, self.loop.aiHand, self.loop.humanScore, self.loop.aiScore)
    if side == 'human' then
        self.loop.humanScore = self.loop.humanScore + points
    else
        self.loop.aiScore = self.loop.aiScore + points
    end
    self.aiThinking = false
    self.envidoBanner = (side == 'human' and 'You' or 'AI') .. ' win the envido  (+' .. points .. ')'
    Timer.after(1.5, function()
        self.canto = nil
        self.envidoBanner = nil
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

    -- cards played this trick, drawn from their live tween state; owner is
    -- conveyed by position (AI high, human low) so no labels are needed
    for _, side in ipairs({ 'ai', 'human' }) do
        local a = self.anims[side]
        if a then
            drawCardFrontRot(a.card, a.x, a.y, a.rot)
        end
    end

    -- human hand, face-up; on the human's turn (and no live call) the active
    -- card lifts (the lift is the only cue -- no highlight ring)
    local myTurn = self.currentPlayer == 'human' and not self.resolving
        and self.playCount < 2 and not self.canto
    love.graphics.setColor(1, 1, 1, 1)
    for i = 1, #loop.humanHand do
        local x = cardRowX(i, #loop.humanHand)
        local y = (myTurn and i == self.raised) and (HUMAN_HAND_Y - HUMAN_HAND_RAISE) or HUMAN_HAND_Y
        drawCardFront(loop.humanHand[i], x, y)
    end

    -- call buttons (envido open / call responses) + the brief envido banner
    for _, b in ipairs(self:callButtons()) do
        drawButton('[' .. b.key .. '] ' .. b.label, b.x, b.y, b.w, b.h, self.hoveredButton == b)
    end
    if self.envidoBanner then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf(self.envidoBanner, 0, 66, VIRTUAL_WIDTH, 'center')
    end

    local status
    if self.envidoBanner then
        status = nil
    elseif self.canto then
        status = self.canto.responder == 'human' and 'Envido: respond' or 'AI is thinking...'
    elseif self.resolving then
        status = self.resultText
    elseif self.currentPlayer == 'human' then
        status = 'Trick ' .. (self.tricksPlayed + 1) .. ' - play a card'
            .. (self:canCallEnvido() and '  (or call envido)' or '')
    else
        status = 'Trick ' .. (self.tricksPlayed + 1) .. ' - AI is thinking...'
    end
    drawHud(loop, status)
end
