--[[
    Truco Argentino

    Placeholder start state -- just enough to boot the game and confirm the
    card sheet/quads load correctly. This is a stand-in for the real
    MenuState from PRD 7 (falling-cards title screen); replace it there,
    don't extend it here.
]]

StartState = Class{__includes = BaseState}

function StartState:init()
    -- espadas_1 = suit row 2 (0-indexed) * 10 + rank col 0 + 1 = 21
    -- see PRD 1 section 7 for the full suitRow/rankCol formula
    self.sampleCardQuad = gFrames['cards'][21]
end

function StartState:update(dt)
    -- PRD 7 replaces this with real menu navigation (and is what will pick the
    -- format per tournament round); until then these two keys are the only way
    -- to reach both match formats
    if love.keyboard.wasPressed('return') then
        gStateStack:pop()
        gStateStack:push(HandLoopState('best_of_3'))
    elseif love.keyboard.wasPressed('s') then
        gStateStack:pop()
        gStateStack:push(HandLoopState('single_chico'))
    end
end

function StartState:render()
    love.graphics.clear(24/255, 89/255, 53/255, 1)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(gFonts['large'])
    love.graphics.printf('Truco Argentino', 0, VIRTUAL_HEIGHT / 2 - 60, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(gFonts['small'])
    love.graphics.printf('Enter: partida (best of 3)     S: single chico', 0, VIRTUAL_HEIGHT / 2 - 14, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('placeholder menu, replaced in PRD 7', 0, VIRTUAL_HEIGHT / 2 - 4, VIRTUAL_WIDTH, 'center')

    love.graphics.draw(gTextures['deck-sheet'], self.sampleCardQuad,
        VIRTUAL_WIDTH / 2 - 32.5, VIRTUAL_HEIGHT / 2 + 15, 0, 0.5, 0.5)
end
