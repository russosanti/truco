-- Owns everything that survives across phases and across hands; the phase
-- states below it just read/write these fields and drive the machine.

HandLoopState = Class{__includes = BaseState}

-- opts = { matchFormat, aiName, onMatchEnd }. All optional: a bare
-- HandLoopState() is a standalone best-of-3 against an unnamed "AI" that returns
-- to the menu when it ends.
function HandLoopState:init(opts)
    opts = opts or {}
    self.humanScore = 0
    self.aiScore = 0
    self.handNumber = 1
    self.deck = Deck()

    -- the tournament passes 'single_chico' for its early rounds; a standalone
    -- match (and the Final) is a best-of-3 partida
    self.matchFormat = opts.matchFormat or 'best_of_3'
    self.aiName = opts.aiName or 'AI'
    -- set by whoever launched this match to be handed the result; MatchEndState
    -- reads it off the loop and falls back to the menu when there's none
    self.onMatchEnd = opts.onMatchEnd
    self.chicosWon = { human = 0, ai = 0 }
    self.chicoNumber = 1
    self.handAborted = false

    -- the only coin flip; every later hand alternates the dealer deterministically
    self.dealer = math.random(2) == 1 and 'human' or 'ai'

    self.humanHand = {}
    self.aiHand = {}
    self.mano = nil  -- set by DealState each hand (whoever isn't the dealer)

    -- envido now lives inside the first trick (PRD 3), so there's no separate
    -- cantos phase -- deal hands straight to trick
    self.machine = StateMachine {
        ['deal']  = function() return DealState(self) end,
        ['trick'] = function() return TrickState(self) end,
        ['score'] = function() return HandScoreState(self) end,
        ['chico'] = function() return ChicoScoreState(self) end,
    }
    self.machine:change('deal')
end

-- The one place scores change (PRD 5 §3). Envido pays out mid-hand from
-- TrickState while trick/truco points land in HandScoreState -- both come
-- through here, so no path can cross 30 without completing the chico.
-- Returns true when the chico ended, i.e. the caller's hand is over.
function HandLoopState:awardPoints(side, points)
    if side == 'human' then
        self.humanScore = self.humanScore + points
    else
        self.aiScore = self.aiScore + points
    end

    local winner = chicoWinner(self.humanScore, self.aiScore)
    if not winner then return false end

    -- a chico can land mid-hand (envido resolves before trick-play is done);
    -- whatever the hand had in flight is abandoned, not unwound
    self.handAborted = true
    self.chicosWon[winner] = self.chicosWon[winner] + 1
    self.machine:change('chico', { winner = winner })
    return true
end

-- Phase changes go through here so the abandoned hand's still-armed timers
-- (an AI think, resolve()'s pause) can't drag a dead hand into the next chico.
-- Clearing the timers instead isn't safe: we'd be inside a Timer callback.
function HandLoopState:changePhase(name, params)
    if self.handAborted then return end
    self.machine:change(name, params)
end

-- Start the next chico of a partida: same match, scores back to zero.
function HandLoopState:startNextChico()
    self.humanScore = 0
    self.aiScore = 0
    self.chicoNumber = self.chicoNumber + 1
    self.handAborted = false
    -- rotation carries on unbroken across the chico boundary
    self.dealer = self.dealer == 'human' and 'ai' or 'human'
    self.handNumber = self.handNumber + 1
    self.machine:change('deal')
end

function HandLoopState:update(dt)
    self.machine:update(dt)
end

function HandLoopState:render()
    self.machine:render()
end
