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
local NAME_W = 56          -- name budget; the tree lines live to the right of it
local TEXT_MID = 4         -- half the 8px line height, for centring the connectors

function TournamentState:init()
    self.bracket = buildBracket(HUMAN, generateNames(15))
    -- 'bracket' (the tree) -> 'matchup' (round + versus) -> the match itself
    self.phase = 'bracket'   -- | 'matchup' | 'champion' | 'eliminated'
    -- seeded from the live button, not false: this state is reached BY a click on
    -- the menu, and that button is still held for several frames afterwards -- a
    -- false start here reads it as a fresh click and skips straight past the tree
    self.mouseWasDown = love.mouse.isDown(1)
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

-- Called by MatchEndState once the player dismisses the result. A win drops back
-- to the tree rather than to the next matchup, so the round just decided is seen
-- filled in before the next one is set up.
function TournamentState:matchFinished(humanWon)
    if not humanWon then
        self.furthestRound = self:round()
        self.phase = 'eliminated'
    elseif self:round() >= #TOURNAMENT_ROUND_NAMES then
        self.phase = 'champion'
    else
        advanceRound(self.bracket, true)
        self.phase = 'bracket'
    end
end

function TournamentState:update(dt)
    local mouseDown = love.mouse.isDown(1)
    local clicked = mouseDown and not self.mouseWasDown
    self.mouseWasDown = mouseDown

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

-- Where round r's match m, slot s sits. Each round's rows are spaced twice as
-- far apart as the previous one's and centred against them, so a path reads as a
-- line across the columns.
function TournamentState:slotXY(r, m, s)
    local spacing = ROW_H * 2 ^ (r - 1)
    return (r - 1) * COL_W + 4,
        BRACKET_Y + ((m - 1) * 2 + (s - 1)) * spacing + (spacing - ROW_H) / 2
end

-- How many matches round r holds, whether or not it's been drawn yet -- 8/4/2/1.
function TournamentState:matchesIn(r)
    return 2 ^ (#TOURNAMENT_ROUND_NAMES - r)
end

-- The tree lines feeding round r's pairs into round r+1: a stub off each name,
-- a vertical joining the pair, then a stub from the midpoint into the next
-- column. slotXY's doubling spacing already puts that midpoint exactly on the
-- next round's row, so this needs no layout of its own.
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

-- One column per round. Entrants are shown by first name -- generateNames keeps
-- those distinct, and full names would not fit four columns of 96px. A round
-- that hasn't been reached has no pairings yet, so its slots are placeholders:
-- nothing is shown before advanceRound has actually decided it.
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
            -- nil until the round after this one exists; then it's who went through
            local winner = matchWinner(self.bracket, r, m)
            for s = 1, 2 do
                local x, y = self:slotXY(r, m, s)
                local name = pair and pair[s]
                if not name then
                    love.graphics.setColor(1, 1, 1, 0.2)
                    love.graphics.print('-', x, y)
                else
                    -- the loser stays on the board, dimmed: who didn't make it is
                    -- half of what a bracket is for
                    local lost = winner ~= nil and name ~= winner
                    if name == HUMAN then
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
    love.graphics.clear(24/255, 89/255, 53/255, 1)

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

        -- the full name here; the bracket columns only have room for first names
        love.graphics.setFont(gFonts['medium'])
        love.graphics.printf('You vs ' .. tostring(humanOpponent(self.bracket)),
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
