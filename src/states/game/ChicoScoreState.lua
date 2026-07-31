-- Someone reached 30. Holds the result briefly, then either ends the partida
-- (hand the match over to MatchEndState) or starts a fresh chico. The chico
-- tally was already banked by HandLoopState:awardPoints.

ChicoScoreState = Class{__includes = BaseState}

function ChicoScoreState:init(loop)
    self.loop = loop
end

function ChicoScoreState:enter(params)
    local loop = self.loop
    self.winner = params.winner

    local partida = partidaWinner(loop.chicosWon, loop.matchFormat)

    Timer.after(2.5, function()
        if partida then
            gStateStack:pop()
            gStateStack:push(MatchEndState(partida, loop))
        else
            loop:startNextChico()
        end
    end)
end

function ChicoScoreState:render()
    love.graphics.clear(24/255, 89/255, 53/255, 1)
    drawHud(self.loop)

    -- centered, not drawHud's bottom status line: this is the one beat that says
    -- who took the chico before a decided partida jumps to MatchEndState
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(gFonts['medium'])
    local who = self.winner == 'human' and 'You win the chico!'
        or (firstNameOf(self.loop.aiName or 'AI') .. ' wins the chico')
    love.graphics.printf(who, 0, VIRTUAL_HEIGHT / 2 - 8, VIRTUAL_WIDTH, 'center')
end
