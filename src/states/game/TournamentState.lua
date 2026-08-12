-- 16-player single-elimination tournament

TournamentState = Class{__includes = BaseState}

local PLAYER = 'You'

-- Variables for rendering brackets
local COL_W = VIRTUAL_WIDTH / 4
local ROW_H = 9
local BRACKET_Y = 32
local NAME_W = 56          -- name budget
local TEXT_MID = 4         -- half the 8px line height for centring the connector lines

function TournamentState:init()
    self.bracket = buildBracket(PLAYER, generateNames(15))
    self.phase = 'bracket'
    self.mouseWasDown = love.mouse.isDown(1)
end

function TournamentState:round()
    return self.bracket.round
end

function TournamentState:startMatch()
    local opponent = playerOpponent(self.bracket)
    if not opponent then
        return
    end
    gStateStack:push(HandLoopState {
        matchFormat = TOURNAMENT_ROUND_FORMAT[self:round()],
        aiName = opponent,
        onMatchEnd = function(playerWon) self:matchFinished(playerWon) end,
    })
end

-- Called by MatchEndState once the player dismisses the result
function TournamentState:matchFinished(playerWon)
    if not playerWon then
        self.furthestRound = self:round()
        self.phase = 'eliminated'
    elseif self:round() >= #TOURNAMENT_ROUND_NAMES then
        self.phase = 'champion'
    else -- a win when not champion goes back to the tournament tree
        advanceRound(self.bracket, true)
        self.phase = 'bracket'
    end
end

function TournamentState:update(dt)
    local clicked = consumeClick(self)

    if love.keyboard.wasPressed('return') or clicked then
        if self.phase == 'bracket' then
            self.phase = 'matchup'
        elseif self.phase == 'matchup' then
            self:startMatch()
        else
            gStateStack:pop()
            gStateStack:push(MenuState())
        end
    end
end

-- Slot for match on round
function TournamentState:slotXY(r, m, s)
    local spacing = ROW_H * 2 ^ (r - 1)
    return (r - 1) * COL_W + 4,
        BRACKET_Y + ((m - 1) * 2 + (s - 1)) * spacing + (spacing - ROW_H) / 2
end

-- How many matches round r holds
function TournamentState:matchesIn(r)
    return 2 ^ (#TOURNAMENT_ROUND_NAMES - r)
end

-- The 3 lines for the brackets in the tournament
function TournamentState:renderConnectors(r)
    local stubX = (r - 1) * COL_W + NAME_W
    local joinX = r * COL_W - 6
    local feedX = r * COL_W + 2

    love.graphics.setColor(1, 1, 1, 0.25)
    for m = 1, self:matchesIn(r) do
        local _, y1 = self:slotXY(r, m, 1)
        local _, y2 = self:slotXY(r, m, 2)
        y1, y2 = y1 + TEXT_MID, y2 + TEXT_MID
        love.graphics.line(stubX, y1, joinX, y1)
        love.graphics.line(stubX, y2, joinX, y2)
        love.graphics.line(joinX, y1, joinX, y2)
        love.graphics.line(joinX, (y1 + y2) / 2, feedX, (y1 + y2) / 2)
    end
end

-- One column per round. Competitors are shown by first name
function TournamentState:renderBracket()
    love.graphics.setFont(gFonts['small'])

    for r = 1, #TOURNAMENT_ROUND_NAMES do
        local pairings = self.bracket.rounds[r]
        local current = r == self:round()

        love.graphics.setColor(1, 1, 1, current and 0.9 or 0.4)
        love.graphics.print(TOURNAMENT_ROUND_NAMES[r], (r - 1) * COL_W + 4, BRACKET_Y - 12)
        if r < #TOURNAMENT_ROUND_NAMES then self:renderConnectors(r) end

        for m = 1, self:matchesIn(r) do
            local pair = pairings and pairings[m]
            -- nil until the round after this one exists
            local winner = matchWinner(self.bracket, r, m)
            for s = 1, 2 do
                local x, y = self:slotXY(r, m, s)
                local name = pair and pair[s]
                if not name then
                    love.graphics.setColor(1, 1, 1, 0.2)
                    love.graphics.print('-', x, y)
                else
                    -- the loser stays on the board, greyed
                    local lost = winner ~= nil and name ~= winner
                    if name == PLAYER then
                        love.graphics.setColor(1, 0.85, 0.3, lost and 0.35 or 1)
                    else
                        love.graphics.setColor(1, 1, 1, lost and 0.3 or (current and 0.85 or 0.7))
                    end
                    love.graphics.print(firstNameOf(name), x, y)
                end
            end
        end
    end
end

function TournamentState:render()
    clearBackground()

    if self.phase == 'bracket' then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(gFonts['medium'])
        love.graphics.printf('Tournament', 0, 2, VIRTUAL_WIDTH, 'center')

        self:renderBracket()

        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf('Enter to continue', 0, VIRTUAL_HEIGHT - 14, VIRTUAL_WIDTH, 'center')
        return
    end

    if self.phase == 'matchup' then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf(TOURNAMENT_ROUND_NAMES[self:round()],
            0, VIRTUAL_HEIGHT / 2 - 55, VIRTUAL_WIDTH, 'center')

        love.graphics.setFont(gFonts['medium'])
        love.graphics.printf('You vs ' .. tostring(playerOpponent(self.bracket)),
            0, VIRTUAL_HEIGHT / 2 - 10, VIRTUAL_WIDTH, 'center')

        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.setFont(gFonts['small'])
        local format = TOURNAMENT_ROUND_FORMAT[self:round()] == 'best_of_3'
            and 'best of 3 chicos' or 'single chico'
        love.graphics.printf(format, 0, VIRTUAL_HEIGHT / 2 + 18, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('press Enter to play', 0, VIRTUAL_HEIGHT / 2 + 34,
            VIRTUAL_WIDTH, 'center')
        return
    end

    -- champion/eliminated
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
