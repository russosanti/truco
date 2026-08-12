-- Deals a fresh hand

DealState = Class{__includes = BaseState}

function DealState:init(loop)
    self.loop = loop
end

function DealState:enter()
    local loop = self.loop
    loop.deck:reset()
    loop.playerHand = loop.deck:deal(3)
    loop.aiHand = loop.deck:deal(3)

    -- mano is whoever is NOT dealing this hand
    loop.mano = otherSide(loop.dealer)

    Timer.after(0.5, function() loop:changePhase('trick') end)
end

function DealState:render()
    clearBackground()
    drawHud(self.loop, 'Dealing...')
end
