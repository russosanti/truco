-- End of the partida. Takes HandLoopState's place on the stack, so it reads the
-- final tally off the loop once at construction rather than holding onto it.
-- Enter loops back to the menu.

MatchEndState = Class{__includes = BaseState}

function MatchEndState:init(winner, loop)
    self.winner = winner
    self.matchFormat = loop.matchFormat
    self.chicosWon = { player = loop.chicosWon.player, ai = loop.chicosWon.ai }
    self.playerScore = loop.playerScore
    self.aiScore = loop.aiScore
    self.aiName = loop.aiName or 'AI'
    -- whoever launched the match wants the result back (the tournament); with
    -- nobody waiting, a standalone match just returns to the menu
    self.onReturn = loop.onMatchEnd
end

function MatchEndState:update(dt)
    if love.keyboard.wasPressed('return') then
        transition(function()
            gStateStack:pop()
            if self.onReturn then
                self.onReturn(self.winner == 'player')
            else
                gStateStack:push(MenuState())
            end
        end)
    end
end

function MatchEndState:render()
    clearBackground()
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setFont(gFonts['large'])
    local title = self.winner == 'player' and 'You win the partida!'
        or (self.aiName .. ' wins the partida')
    love.graphics.printf(title, 0, VIRTUAL_HEIGHT / 2 - 55, VIRTUAL_WIDTH, 'center')

    -- a best-of-3 is told by chicos; a single chico only ever had the one score
    local tally
    if self.matchFormat == 'best_of_3' then
        tally = 'chicos  ' .. self.chicosWon.player .. ' - ' .. self.chicosWon.ai
    else
        tally = 'final score  ' .. self.playerScore .. ' - ' .. self.aiScore
    end
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf(tally, 0, VIRTUAL_HEIGHT / 2 - 10, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(gFonts['small'])
    love.graphics.printf('press Enter to return to the title', 0, VIRTUAL_HEIGHT / 2 + 30,
        VIRTUAL_WIDTH, 'center')
end
