-- 16-player single-elimination tournament. Stays on the stack underneath the
-- match it launches (the match's own clear() paints over the bracket), so the
-- draw survives and MatchEndState can hand the result straight back here.

TournamentState = Class{__includes = BaseState}

local HUMAN = 'You'

-- Four round columns across the virtual width. Round 1 has to fit all 16 rows
-- between the round labels and the callout at the bottom, which is what sets
-- ROW_H: 32 + 15*9 = 167, clear of the callout at VIRTUAL_HEIGHT - 26.
local COL_W = VIRTUAL_WIDTH / 4
local ROW_H = 9
local BRACKET_Y = 32
local CALLOUT_Y = VIRTUAL_HEIGHT - 26

function TournamentState:init()
    self.bracket = buildBracket(HUMAN, generateNames(15))
    self.phase = 'bracket'   -- 'bracket' | 'champion' | 'eliminated'
    self.mouseWasDown = false
end

function TournamentState:round()
    return self.bracket.round
end

function TournamentState:startMatch()
    local opponent = humanOpponent(self.bracket)
    if not opponent then return end
    gStateStack:push(HandLoopState {
        matchFormat = TOURNAMENT_ROUND_FORMAT[self:round()],
        aiName = opponent,
        onMatchEnd = function(humanWon) self:matchFinished(humanWon) end,
    })
end

-- Called by MatchEndState once the player dismisses the result.
function TournamentState:matchFinished(humanWon)
    if not humanWon then
        self.furthestRound = self:round()
        self.phase = 'eliminated'
    elseif self:round() >= #TOURNAMENT_ROUND_NAMES then
        self.phase = 'champion'
    else
        advanceRound(self.bracket, true)
    end
end

function TournamentState:update(dt)
    local mouseDown = love.mouse.isDown(1)
    local clicked = mouseDown and not self.mouseWasDown
    self.mouseWasDown = mouseDown

    if love.keyboard.wasPressed('return') or clicked then
        if self.phase == 'bracket' then
            self:startMatch()
        else
            gStateStack:pop()
            gStateStack:push(MenuState())
        end
    end
end

-- Where round r's match m, slot s sits. Each round's rows are spaced twice as
-- far apart as the previous one's and centred against them, so a path reads as a
-- line across the columns.
function TournamentState:slotXY(r, m, s)
    local spacing = ROW_H * 2 ^ (r - 1)
    return (r - 1) * COL_W + 4,
        BRACKET_Y + ((m - 1) * 2 + (s - 1)) * spacing + (spacing - ROW_H) / 2
end

-- One column per round, so the whole draw is visible. Entrants are shown by
-- first name -- generateNames keeps those distinct, and full names would not fit
-- four columns of 96px.
function TournamentState:renderBracket()
    love.graphics.setFont(gFonts['small'])
    for r, pairings in ipairs(self.bracket.rounds) do
        local current = r == self:round()
        love.graphics.setColor(1, 1, 1, current and 0.9 or 0.4)
        love.graphics.print(TOURNAMENT_ROUND_NAMES[r], (r - 1) * COL_W + 4, BRACKET_Y - 12)

        for m, pair in ipairs(pairings) do
            for s = 1, 2 do
                local name = pair[s]
                if name then
                    local x, y = self:slotXY(r, m, s)
                    if name == HUMAN then
                        love.graphics.setColor(1, 0.85, 0.3, 1)
                    else
                        love.graphics.setColor(1, 1, 1, current and 0.85 or 0.45)
                    end
                    love.graphics.print(firstNameOf(name), x, y)
                end
            end
        end
    end
end

function TournamentState:render()
    love.graphics.clear(24/255, 89/255, 53/255, 1)

    if self.phase == 'bracket' then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(gFonts['medium'])
        love.graphics.printf('Tournament', 0, 2, VIRTUAL_WIDTH, 'center')

        self:renderBracket()

        local opponent = humanOpponent(self.bracket)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf(TOURNAMENT_ROUND_NAMES[self:round()] .. ' vs ' .. tostring(opponent),
            0, CALLOUT_Y, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(1, 1, 1, 0.7)
        local format = TOURNAMENT_ROUND_FORMAT[self:round()] == 'best_of_3'
            and 'best of 3 chicos' or 'single chico'
        love.graphics.printf('Enter to play  (' .. format .. ')',
            0, VIRTUAL_HEIGHT - 14, VIRTUAL_WIDTH, 'center')
        return
    end

    -- champion / eliminated: MatchEndState's shape, framed as the tournament's
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(gFonts['large'])
    local title = self.phase == 'champion' and 'Tournament champion!' or 'Knocked out'
    love.graphics.printf(title, 0, VIRTUAL_HEIGHT / 2 - 55, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(gFonts['medium'])
    local detail = self.phase == 'champion'
        and 'you won all 4 rounds'
        or ('reached the ' .. TOURNAMENT_ROUND_NAMES[self.furthestRound])
    love.graphics.printf(detail, 0, VIRTUAL_HEIGHT / 2 - 10, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(gFonts['small'])
    love.graphics.printf('press Enter to return to the menu', 0, VIRTUAL_HEIGHT / 2 + 30,
        VIRTUAL_WIDTH, 'center')
end
