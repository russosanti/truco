-- Deals a fresh hand, then hands off to the (empty) cantos window.

DealState = Class{__includes = BaseState}

function DealState:init(loop)
    self.loop = loop
end

function DealState:enter()
    local loop = self.loop
    loop.deck:reset()
    loop.humanHand = loop.deck:deal(3)
    loop.aiHand = loop.deck:deal(3)

    -- mano is whoever is NOT dealing this hand; leads the first trick
    loop.mano = loop.dealer == 'human' and 'ai' or 'human'

    Timer.after(0.5, function() loop.machine:change('trick') end)
end

function DealState:render()
    love.graphics.clear(24/255, 89/255, 53/255, 1)
    drawHud(self.loop, 'Dealing...')
end
