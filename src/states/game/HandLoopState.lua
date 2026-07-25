-- Owns everything that survives across phases and across hands; the phase
-- states below it just read/write these fields and drive the machine.

HandLoopState = Class{__includes = BaseState}

function HandLoopState:init()
    self.humanScore = 0
    self.aiScore = 0
    self.handNumber = 1
    self.deck = Deck()

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
    }
    self.machine:change('deal')
end

function HandLoopState:update(dt)
    self.machine:update(dt)
end

function HandLoopState:render()
    self.machine:render()
end
