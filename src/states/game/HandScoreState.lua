-- Awards the hand, then rotates dealer/mano and deals the next one. Points are
-- computed by whoever ended the hand (trick resolution, truco reject, or fold)
-- and passed in -- this state stays agnostic to how.

HandScoreState = Class{__includes = BaseState}

function HandScoreState:init(loop)
    self.loop = loop
end

function HandScoreState:enter(params)
    local loop = self.loop
    self.winner = params.winner
    self.points = params.points or 1

    -- awardPoints owns chico completion; if this hand ended the chico it has
    -- already moved the loop on, so don't queue another deal
    if loop:awardPoints(self.winner, self.points) then return end

    Timer.after(2.0, function()
        loop.dealer = loop.dealer == 'human' and 'ai' or 'human'  -- flips every hand
        loop.handNumber = loop.handNumber + 1
        loop:changePhase('deal')
    end)
end

function HandScoreState:render()
    love.graphics.clear(24/255, 89/255, 53/255, 1)
    local who = self.winner == 'human' and 'You win the hand!'
        or (firstNameOf(self.loop.aiName or 'AI') .. ' wins the hand')
    drawHud(self.loop, who .. '  (+' .. self.points .. ')')
end
