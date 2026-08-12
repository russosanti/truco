-- Variables that survives across phases and across hands
HandLoopState = Class{__includes = BaseState}

-- opts = { matchFormat, aiName, onMatchEnd }
function HandLoopState:init(opts)
    opts = opts or {}
    self.playerScore = 0
    self.aiScore = 0
    self.handNumber = 1
    self.deck = Deck()

    self.matchFormat = opts.matchFormat or 'best_of_3'
    self.aiName = opts.aiName or 'AI'
    -- callback function on match end
    self.onMatchEnd = opts.onMatchEnd
    self.chicosWon = { player = 0, ai = 0 }
    self.chicoNumber = 1
    self.handAborted = false

    -- who starts as hand coin flip
    self.dealer = math.random(2) == 1 and 'player' or 'ai'

    self.playerHand = {}
    self.aiHand = {}
    self.mano = nil  -- who is mano this hand

    self.machine = StateMachine {
        ['deal']  = function() return DealState(self) end,
        ['trick'] = function() return TrickState(self) end,
        ['score'] = function() return HandScoreState(self) end,
        ['chico'] = function() return ChicoScoreState(self) end,
    }
    self.machine:change('deal')
end

-- Updates scores and checks for a winner
function HandLoopState:awardPoints(side, points)
    if side == 'player' then
        self.playerScore = self.playerScore + points
    else
        self.aiScore = self.aiScore + points
    end

    local winner = chicoWinner(self.playerScore, self.aiScore)
    if not winner then return false end

    -- a chico can land mid-hand (with envido)
    self.handAborted = true
    self.chicosWon[winner] = self.chicosWon[winner] + 1
    self.machine:change('chico', { winner = winner })
    return true
end

-- Check for hand aborted so we don't drag timers to next state
function HandLoopState:changePhase(name, params)
    if self.handAborted then return end
    self.machine:change(name, params)
end

-- Start the next chico of a partida of a match. Scores to 0 (like a tennis set)
function HandLoopState:startNextChico()
    self.playerScore = 0
    self.aiScore = 0
    self.chicoNumber = self.chicoNumber + 1
    self.handAborted = false
    -- rotation carries
    self.dealer = otherSide(self.dealer)
    self.handNumber = self.handNumber + 1
    self.machine:change('deal')
end

function HandLoopState:update(dt)
    self.machine:update(dt)
end

function HandLoopState:render()
    self.machine:render()
end
