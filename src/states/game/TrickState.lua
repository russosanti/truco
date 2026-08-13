-- Plays 1-3 tricks

-- Variables to overlap hands in the moddle of the screen
local AI_HAND_Y       = 8
local AI_PLAYED_Y     = 60
local PLAYER_PLAYED_Y = 92
local PLAYER_HAND_Y   = 146
local PLAYER_HAND_RAISE = 12  -- how far the highlighted/hovered card lifts
local STACK_DX, STACK_DY = 12, 12 -- per-card offset so a side's played cards fan out
local STACK_DIR = { ai = -1, player = 1 }
local SIDE_MSG_Y = { ai = 66, player = 112 }  -- dialog box Y per side

-- envido/truco call buttons to there right-side
local BTN_W, BTN_H, BTN_GAP = 92, 16, 4
local BTN_X = VIRTUAL_WIDTH - BTN_W - 6
local BTN_Y0 = 60
local CALL_LABEL = {
    envido = 'Envido', real = 'Real envido', falta = 'Falta envido',
    contraflor = 'Contraflor', resto = 'Contraflor al resto',
}
local ENVIDO_OPENS = { 'envido', 'real', 'falta' }
local REJECT_LABEL = { envido = 'No quiero', flor = 'Me achico' }

-- Simple helper functions
local function handYFor(side) return side == 'ai' and AI_HAND_Y or PLAYER_HAND_Y end
local function playedYFor(side) return side == 'ai' and AI_PLAYED_Y or PLAYER_PLAYED_Y end
local function playedXFor(side) return cardRowX(side == 'ai' and 1 or 2, 2) end

TrickState = Class{__includes = BaseState}

-- Speaker shown in message box
function TrickState:speaker(side)
    return side == 'ai' and (self.aiName .. ': ') or 'You: '
end

function TrickState:init(loop)
    self.loop = loop
    self.wins = { player = 0, ai = 0 }
    self.mano = loop.mano
    self.leader = loop.mano  -- mano starts the first trick
    self.tricksPlayed = 0
    self.aiName = firstNameOf(loop.aiName or 'AI')  -- short name form
    self.firstTrickWinner = nil  -- decides a hand ending in a parda (tie)
    self.mouseWasDown = love.mouse.isDown(1)
    self.envidoUsed = false    -- envido call has happened
    self.canto = nil           -- active envido or flor canto
    self.cantoFamily = nil     -- 'envido' | 'flor'
    -- flor is mandatory and resolves before anything else this hand
    self.flor = {
        player = hasFlor(loop.playerHand) and florValue(loop.playerHand) or nil,
        ai = hasFlor(loop.aiHand) and florValue(loop.aiHand) or nil,
    }
    self.florHappened = self.flor.player ~= nil or self.flor.ai ~= nil
    self.florResolved = not self.florHappened
    self.dialogs = {}
    self.hoveredButton = nil
    -- cards played by both players
    self.playedStack = { player = {}, ai = {} }
    -- envido value from the 3 cards or each player
    self.envidoValue = { player = envidoValue(loop.playerHand), ai = envidoValue(loop.aiHand) }
    -- truco variables for scoring
    self.trucoLevel = 0        -- accepted value: 0 none, 2 truco, 3 retruco, 4 vale cuatro
    self.trucoLeader = nil     -- side that may raise next. nil if anyone
    self.trucoPending = nil    -- awaiting quiero/no quiero
    self:startTrick()
end

-- Dialog message box
function TrickState:makeDialog(side, text)
    return Textbox(self:speaker(side) .. text, SIDE_MSG_Y[side])
end

-- Message for AI moves. `afterFn` runs after the message clears
function TrickState:showAiMessage(label, afterFn)
    self.dialogs = { self:makeDialog('ai', label) }
    Timer.after(1.5, function()
        self.dialogs = {}
        if afterFn then afterFn() end
    end)
end

-- On enter calls flor if anyone has it
function TrickState:enter()
    if self.florResolved then return end

    local pie = otherSide(self.mano)
    local declarers = {}
    if self.flor[self.mano] then declarers[#declarers + 1] = self.mano end
    if self.flor[pie] then declarers[#declarers + 1] = pie end

    -- announce mano first, then pie
    local function announce(i)
        if i > #declarers then
            if #declarers == 2 then
                self:openCanto(self.mano, 'flor', 'flor')
            else
                local side = declarers[1]
                self.florResolved = true
                self:award(side, FLOR_BASE)
            end
            return
        end
        local side = declarers[i]
        self.dialogs = { self:makeDialog(side, 'Flor') }
        Timer.after(1.5, function()
            self.dialogs = {}
            announce(i + 1)
        end)
    end
    announce(1)
end

-- Start a new trick
function TrickState:startTrick()
    self.currentPlayer = self.leader  -- leader plays first
    self.trickCards = {}              -- cards played each trick per side
    self.anims = {}
    self.landed = 0                   -- cards that finished their tween this trick
    self.playCount = 0
    self.resolving = false
    self.aiThinking = false           -- true while the AI's move is on its timer
    self.raised = nil                 -- lifted human card index or nil
    self.prevHovered = nil            -- last frame's hovered card for enter/exit
    self.resultText = nil
end

-- Remove `card` from `hand` and tween it to the table
function TrickState:playCard(side, card, hand)
    -- capture the slot start position before the card leaves the hand
    local index
    for i, c in ipairs(hand) do
        if c == card then index = i break end
    end
    local fromX = cardRowX(index, #hand)
    table.remove(hand, index)

    self.trickCards[side] = card
    local a = { card = card, x = fromX, y = handYFor(side), rot = 0 }
    self.anims[side] = a

    -- make each card land with a slight offset si they don't overlap perceclty and can se the cards played
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
    self.currentPlayer = otherSide(side)
end

-- Resolve once both cards of this trick have landed
function TrickState:tryResolve()
    if self.landed >= 2 then self:resolve() end
end

function TrickState:resolve()
    self.resolving = true

    local follower = otherSide(self.leader)
    local result = resolveTrick(self.trickCards[self.leader], self.trickCards[follower])

    local winnerSide
    if result == 'leader' then
        winnerSide = self.leader
    elseif result == 'other' then
        winnerSide = follower
    end
    if winnerSide then
        self.wins[winnerSide] = self.wins[winnerSide] + 1
    end

    self.tricksPlayed = self.tricksPlayed + 1
    if self.tricksPlayed == 1 then
        self.firstTrickWinner = winnerSide  -- keeps nil on parda
    end
    if result == 'tie' then
        self.resultText = 'Parda!'
    else
        self.resultText = winnerSide == 'player' and 'You win the trick' or (self.aiName .. ' wins the trick')
    end

    local decided = isHandDecided(self.wins, self.firstTrickWinner, self.tricksPlayed, self.mano)

    -- pause to read message
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
    -- left-click card edge detection
    local clicked = consumeClick(self)

    if self.resolving then return end
    -- both cards are played but resolve is waiting for tween timers
    if self.playCount >= 2 then return end

    -- a message/reveal box is on screen freeze input
    if #self.dialogs > 0 then return end

    -- an active envido negotiation takes over input
    if self.canto then
        if self.canto.responder == 'player' then
            self:updateCallButtons(clicked)
        else
            self:aiRespondCanto()
        end
        return
    end

    -- flor is mandatory and settles before anything else
    if not self.florResolved then return end

    -- a truco call awaiting quiero / no quiero
    if self.trucoPending then
        if otherSide(self.trucoPending.caller) == 'player' then
            self:updateCallButtons(clicked)
        else
            self:aiRespondTruco()
        end
        return
    end

    if self.currentPlayer == 'ai' then
        self:updateAiTurn()
    else
        -- the human may call or play a card
        if self:updateCallButtons(clicked) then return end
        self:updatePlayerSelection(clicked)
    end
end

-- Envido: first trick, before this side plays its card, once per hand and before truco is accepted
function TrickState:canCallEnvido()
    return self.tricksPlayed == 0 and not self.envidoUsed and self.trucoLevel == 0
       and not self.florHappened
end

-- Envido can be called when a truco is first called
function TrickState:canInterruptEnvido()
    return self.tricksPlayed == 0 and not self.envidoUsed
       and self.playCount == 0 and self.trucoLevel == 0
       and not self.florHappened
end

-- The right side call buttons for this screen
function TrickState:callButtons()
    local list = {}

    if self.canto and self.canto.responder == 'player' then
        list = { { label = 'Quiero', act = 'accept' },
                 { label = REJECT_LABEL[self.cantoFamily], act = 'reject' } }
        for _, c in ipairs(self.canto:availableRaises()) do
            list[#list + 1] = { label = CALL_LABEL[c], act = 'call:' .. c }
        end

    elseif self.trucoPending and otherSide(self.trucoPending.caller) == 'player' then
        list = { { label = 'Quiero', act = 'accept' }, { label = 'No quiero', act = 'reject' } }
        -- raising is an answer. Quiero + raise
        local raise = trucoRaiseCall(self.trucoPending)
        if raise then
            list[#list + 1] = { label = TRUCO_NAME[raise], act = 'truco-raise' }
        end
        -- "el envido esta primero": envido variant can dismiss the truco call and open an envido negotiation
        if self:canInterruptEnvido() then
            for _, c in ipairs(ENVIDO_OPENS) do
                list[#list + 1] = { label = CALL_LABEL[c], act = 'call:' .. c }
            end
        end

    elseif not self.canto and not self.trucoPending
           and self.currentPlayer == 'player' and self.playCount < 2 then
        if self:canCallEnvido() then
            for _, c in ipairs(ENVIDO_OPENS) do
                list[#list + 1] = { label = CALL_LABEL[c], act = 'call:' .. c }
            end
        end
        local lvl = availableTrucoCall(self.trucoLevel, self.trucoLeader, 'player', self.trucoPending)
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

-- Clicked button actions
function TrickState:applyCallButton(act)
    if act == 'accept' then
        if self.canto then self.canto:accept(); self:finishCanto()
        else self:resolveTrucoAccept() end
    elseif act == 'reject' then
        if self.canto then self.canto:reject(); self:finishCanto()
        else self:resolveTrucoReject() end
    elseif act == 'truco-raise' then
        self:resolveTrucoRaise('player')
    elseif act == 'truco' then
        self:callTruco('player')
    elseif act == 'fold' then
        self:resolveFold('player')
    else
        local callType = act:match('call:(%a+)')
        if self.canto then
            self.canto:raise(callType)  -- player response raises
            self.aiThinking = false
        else
            self:openCanto('player', callType)
        end
    end
end

function TrickState:callTruco(side)
    local lvl = availableTrucoCall(self.trucoLevel, self.trucoLeader, side, self.trucoPending)
    if not lvl then return end
    self.trucoPending = { level = lvl, caller = side }
    self.aiThinking = false
    if side == 'ai' then self:showAiMessage(TRUCO_NAME[lvl]) end
end

-- Accept only sets the stake, no points awarded yet
function TrickState:resolveTrucoAccept()
    local p = self.trucoPending
    self.trucoLevel = p.level
    self.trucoLeader = otherSide(p.caller)  -- the accepter may raise next
    self.trucoPending = nil
    self.aiThinking = false
end

-- Accept and rise truco to the next level
function TrickState:resolveTrucoRaise(side)
    local lvl = trucoRaiseCall(self.trucoPending)
    if not lvl then return end
    self:resolveTrucoAccept()
    self.trucoLeader = side
    self.trucoPending = { level = lvl, caller = side }
end

-- Reject truco call and end the trick
function TrickState:resolveTrucoReject()
    local p = self.trucoPending
    self.trucoPending = nil
    self.loop:changePhase('score', { winner = p.caller, points = trucoRejectValue(p.level) })
end

-- Fold during play. Me voy al mazo
function TrickState:resolveFold(side)
    self.loop:changePhase('score', { winner = otherSide(side), points = trucoFoldValue(self.trucoLevel) })
end

-- Everything the AI need to know in order to make a decision
function TrickState:aiContext()
    return {
        against = self.trickCards.player,  -- nil unless the player has already played
        myWins = self.wins.ai,
        theirWins = self.wins.player,
        tricksPlayed = self.tricksPlayed,
        cardsPlayed = self.playCount,
        trucoLevel = self.trucoLevel,
        myScore = self.loop.aiScore,
        theirScore = self.loop.playerScore,
    }
end

function TrickState:aiRespondTruco()
    if self.aiThinking then return end
    self.aiThinking = true
    Timer.after(0.6, function()
        self.aiThinking = false
        if not self.trucoPending then return end
        local ctx = self:aiContext()
        -- "el envido esta primero" - answer first truco with envido call
        local open = self:canInterruptEnvido()
            and EnvidoAiStub.chooseOpen(self.envidoValue.ai, ctx) or 'pass'
        if open ~= 'pass' then
            self:openCanto('ai', open)
            return
        end
        local p = self.trucoPending
        local resp = TrucoAiStub.respond(self.loop.aiHand, ctx)
        local raiseTo = trucoRaiseCall(p)
        if resp == 'raise' and raiseTo then
            self:resolveTrucoRaise('ai')
            self:showAiMessage(TRUCO_NAME[raiseTo])
        elseif resp ~= 'noquiero' then
            self:resolveTrucoAccept()
            self:showAiMessage('Quiero')
        else
            self.trucoPending = nil
            -- announce first and then end the hand when the message clears
            self:showAiMessage('No quiero', function()
                self.loop:changePhase('score', { winner = p.caller, points = trucoRejectValue(p.level) })
            end)
        end
    end)
end

-- Opens a negotiation
function TrickState:openCanto(opener, callType, family)
    family = family or 'envido'
    self.cantoFamily = family
    if family == 'envido' then
        self.envidoUsed = true
        -- answering a truco with envido discards that truco
        self.trucoPending = nil
    end
    self.canto = Canto(family == 'flor' and FLOR_CANTO or ENVIDO_CANTO, opener, callType)
    self.aiThinking = false
    -- the flor declaration was already announced by enter()
    if opener == 'ai' and callType ~= 'flor' then self:showAiMessage(CALL_LABEL[callType]) end
end

function TrickState:aiRespondCanto()
    if self.aiThinking then return end
    self.aiThinking = true
    Timer.after(0.6, function()
        self.aiThinking = false
        if not self.canto then return end
        -- availableRaises keeps the AI's escalation legal
        local raises = self.canto:availableRaises()
        local resp
        if self.cantoFamily == 'flor' then
            resp = FlorAiStub.chooseResponse(self.flor.ai, raises, #self.canto.calls == 1)
        else
            resp = EnvidoAiStub.chooseResponse(self.envidoValue.ai, raises, self:aiContext())
        end
        if resp == 'quiero' then
            self.canto:accept()
            self:finishCanto()
        elseif resp == 'noquiero' or resp == 'meachico' then
            self.canto:reject()
            self:finishCanto()
        else
            self.canto:raise(resp)
            self:showAiMessage(CALL_LABEL[resp])
        end
    end)
end

-- AI's turn with no live calls. Depending on hand and context what it may call
function TrickState:updateAiTurn()
    if self.aiThinking then return end
    self.aiThinking = true
    Timer.after(0.6, function() -- To sim a human reaction time and not instant play
        self.aiThinking = false
        if self.currentPlayer ~= 'ai' or self.resolving or self.canto or self.trucoPending then return end
        local ctx = self:aiContext()
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
            self:playCard('ai', AiStub.chooseCard(self.loop.aiHand, ctx), self.loop.aiHand)
        end
    end)
end

-- Envido pays out here
function TrickState:award(side, points)
    self.loop:awardPoints(side, points)
end

-- The pair of values that is fought over
function TrickState:cantoValues(family)
    local held = family == 'flor' and self.flor or self.envidoValue
    return held[self.mano], held[otherSide(self.mano)]
end

function TrickState:awardCanto(outcome, family)
    local manoVal, pieVal = self:cantoValues(family)
    local award = family == 'flor' and florAward or envidoAward
    local side, points = award(outcome, self.mano, manoVal, pieVal,
        self.loop.playerScore, self.loop.aiScore)
    if family == 'flor' then self.florResolved = true end
    self:award(side, points)
end

-- Resolve the negotiation and do all the announcing
function TrickState:finishCanto()
    local outcome = self.canto.outcome
    local answerer = self.canto.responder  -- whoever accepted/rejected
    local family = self.cantoFamily
    self.canto = nil
    self.cantoFamily = nil
    self.aiThinking = false

    local function pay() self:awardCanto(outcome, family) end
    local function reveal(manoPrefix) self:revealShowdown(family, manoPrefix, pay) end

    if outcome.kind == 'accept' then
        if answerer == 'ai' and self.mano == 'ai' then
            -- mano declares first
            reveal('Quiero')
        elseif answerer == 'ai' then
            -- AI is pie: quiero and its number comes with its response below
            self:showAiMessage('Quiero', function() reveal() end)
        else
            reveal()  -- player said quiero
        end
    elseif answerer == 'ai' then
        self:showAiMessage(REJECT_LABEL[family], pay)
    else
        pay()
    end
end

-- Showdown scores, or son buenas if the pie won
function TrickState:revealShowdown(family, manoPrefix, onDone)
    local pie = otherSide(self.mano)
    local manoVal, pieVal = self:cantoValues(family)
    local manoText = manoPrefix and (manoPrefix .. ', ' .. manoVal) or tostring(manoVal)

    self.dialogs = { self:makeDialog(self.mano, manoText) }
    Timer.after(2, function()
        -- conceding says nothing about your own number
        local pieText = pieVal > manoVal and (pieVal .. ' son mejores') or 'son buenas'
        table.insert(self.dialogs, self:makeDialog(pie, pieText))
        Timer.after(2, function()
            self.dialogs = {}
            onDone()
        end)
    end)
end

-- Support picking a card with the mouse or keyboard. The lifted card is the selected card
function TrickState:updatePlayerSelection(clicked)
    local hand = self.loop.playerHand
    local n = #hand
    if self.raised then self.raised = math.max(1, math.min(self.raised, n)) end

    local hovered = self:cardAtMouse()
    if hovered then
        self.raised = hovered            -- over a card -> that card is up
    elseif self.prevHovered then
        self.raised = nil                -- just left a card -> put it down
    end
    self.prevHovered = hovered

    if love.keyboard.wasPressed('left') then
        self.raised = self.raised and math.max(1, self.raised - 1) or 1
    elseif love.keyboard.wasPressed('right') then
        self.raised = self.raised and math.min(n, self.raised + 1) or 1
    end

    if love.keyboard.wasPressed('return') and self.raised then
        self:playCard('player', hand[self.raised], hand)
    elseif hovered and clicked then
        self:playCard('player', hand[hovered], hand)
    end
end

-- Player card index under mouse cursor. Nil if none
function TrickState:cardAtMouse()
    local mx, my = push.toGame(love.mouse.getPosition())
    if not mx or not my then return nil end
    local n = #self.loop.playerHand
    local yTop = PLAYER_HAND_Y - PLAYER_HAND_RAISE
    local yBot = PLAYER_HAND_Y + CARD_H
    for i = 1, n do
        local x = cardRowX(i, n)
        if mx >= x and mx <= x + CARD_W and my >= yTop and my <= yBot then
            return i
        end
    end
    return nil
end

function TrickState:render()
    clearBackground()
    local loop = self.loop

    -- top area is the AI's face-down hand
    for i = 1, #loop.aiHand do
        drawCardBack(cardRowX(i, #loop.aiHand), AI_HAND_Y)
    end

    -- every card played this hand, stacked (oldest first)
    for _, side in ipairs({ 'ai', 'player' }) do
        for _, e in ipairs(self.playedStack[side]) do
            drawCardFrontRot(e.card, e.x, e.y, e.rot)
        end
        local a = self.anims[side]
        if a then
            drawCardFrontRot(a.card, a.x, a.y, a.rot)
        end
    end

    -- player cards faced up on your hand
    local myTurn = self.currentPlayer == 'player' and not self.resolving
        and self.playCount < 2 and not self.canto and not self.trucoPending and #self.dialogs == 0
    love.graphics.setColor(1, 1, 1, 1)
    for i = 1, #loop.playerHand do
        local x = cardRowX(i, #loop.playerHand)
        local y = (myTurn and i == self.raised) and (PLAYER_HAND_Y - PLAYER_HAND_RAISE) or PLAYER_HAND_Y
        drawCardFront(loop.playerHand[i], x, y)
    end

    if #self.dialogs > 0 then
        -- message boxes
        for _, d in ipairs(self.dialogs) do
            d:render()
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
        status = self.canto.responder == 'player' and 'Envido: respond' or (self.aiName .. ' is thinking...')
    elseif self.trucoPending then
        status = otherSide(self.trucoPending.caller) == 'player'
            and (TRUCO_NAME[self.trucoPending.level] .. ': respond') or (self.aiName .. ' is thinking...')
    elseif self.resolving then
        status = self.resultText
    elseif self.currentPlayer == 'player' then
        status = 'Trick ' .. (self.tricksPlayed + 1) .. ' - your turn' .. stake
    else
        status = 'Trick ' .. (self.tricksPlayed + 1) .. ' - ' .. self.aiName .. ' is thinking...' .. stake
    end
    drawHud(loop, status)
end
