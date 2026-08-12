-- Awards the hand, then rotates dealer/mano and deals the next one

HandScoreState = Class{__includes = BaseState}

function HandScoreState:init(loop)
    self.loop = loop
end

function HandScoreState:enter(params)
    self.winner = params.winner
    self.points = params.points or 1

    -- awardPoints owns chico completion
    if self.loop:awardPoints(self.winner, self.points) then return end

    Timer.after(2.0, function()
        self.loop.dealer = otherSide(self.loop.dealer)  -- flips every hand
        self.loop.handNumber = self.loop.handNumber + 1
        self.loop:changePhase('deal')
    end)
end

function HandScoreState:render()
    clearBackground()
    local who = self.winner == 'player' and 'You win the hand!'
        or (firstNameOf(self.loop.aiName or 'AI') .. ' wins the hand')
    drawHud(self.loop, who .. '  (+' .. self.points .. ')')
end
