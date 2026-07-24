-- Awards the hand (1 point, no betting yet), then rotates dealer/mano and
-- deals the next one. No chico/partida win check -- that's PRD 5.

HandScoreState = Class{__includes = BaseState}

function HandScoreState:init(loop)
    self.loop = loop
end

function HandScoreState:enter(params)
    local loop = self.loop
    self.winner = params.winner

    if self.winner == 'human' then
        loop.humanScore = loop.humanScore + 1
    else
        loop.aiScore = loop.aiScore + 1
    end

    Timer.after(2.0, function()
        loop.dealer = loop.dealer == 'human' and 'ai' or 'human'  -- flips every hand
        loop.handNumber = loop.handNumber + 1
        loop.machine:change('deal')
    end)
end

function HandScoreState:render()
    love.graphics.clear(24/255, 89/255, 53/255, 1)
    local msg = self.winner == 'human' and 'You win the hand!  (+1)' or 'AI wins the hand  (+1)'
    drawHud(self.loop, msg)
end
