-- End of the partida. Takes HandLoopState's place on the stack, so it reads the
-- final tally off the loop once at construction rather than holding onto it.
-- Enter loops back to the menu.

MatchEndState = Class{__includes = BaseState}

function MatchEndState:init(winner, loop)
    self.winner = winner
    self.matchFormat = loop.matchFormat
    self.chicosWon = { human = loop.chicosWon.human, ai = loop.chicosWon.ai }
    self.humanScore = loop.humanScore
    self.aiScore = loop.aiScore
end

function MatchEndState:update(dt)
    if love.keyboard.wasPressed('return') then
        gStateStack:pop()
        gStateStack:push(MenuState())
    end
end

function MatchEndState:render()
    love.graphics.clear(24/255, 89/255, 53/255, 1)
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setFont(gFonts['large'])
    local title = self.winner == 'human' and 'You win the partida!' or 'AI wins the partida'
    love.graphics.printf(title, 0, VIRTUAL_HEIGHT / 2 - 55, VIRTUAL_WIDTH, 'center')

    -- a best-of-3 is told by chicos; a single chico only ever had the one score
    local tally
    if self.matchFormat == 'best_of_3' then
        tally = 'chicos  ' .. self.chicosWon.human .. ' - ' .. self.chicosWon.ai
    else
        tally = 'final score  ' .. self.humanScore .. ' - ' .. self.aiScore
    end
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf(tally, 0, VIRTUAL_HEIGHT / 2 - 10, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(gFonts['small'])
    love.graphics.printf('press Enter to return to the title', 0, VIRTUAL_HEIGHT / 2 + 30,
        VIRTUAL_WIDTH, 'center')
end
