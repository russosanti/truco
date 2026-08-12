-- Someone reached 30. Holds the result briefly, then either ends the match or starts a fresh chico

ChicoScoreState = Class{__includes = BaseState}

function ChicoScoreState:init(loop)
    self.loop = loop
end

function ChicoScoreState:enter(params)
    self.winner = params.winner

    local partida = partidaWinner(self.loop.chicosWon, self.loop.matchFormat)

    Timer.after(2.5, function()
        if partida then
            gStateStack:pop()
            gStateStack:push(MatchEndState(partida, self.loop))
        else
            self.loop:startNextChico()
        end
    end)
end

function ChicoScoreState:render()
    clearBackground()
    drawHud(self.loop)

    -- show winner
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(gFonts['medium'])
    local who = self.winner == 'player' and 'You win the chico!'
        or (firstNameOf(self.loop.aiName or 'AI') .. ' wins the chico')
    love.graphics.printf(who, 0, VIRTUAL_HEIGHT / 2 - 8, VIRTUAL_WIDTH, 'center')
end
