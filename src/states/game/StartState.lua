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
    -- PRD 7 replaces this with real menu navigation; for now Enter drops
    -- straight into a playable hand loop
    if love.keyboard.wasPressed('return') then
        gStateStack:pop()
        gStateStack:push(HandLoopState())
    end
end

function StartState:render()
    love.graphics.clear(24/255, 89/255, 53/255, 1)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(gFonts['large'])
    love.graphics.printf('Truco Argentino', 0, VIRTUAL_HEIGHT / 2 - 60, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(gFonts['small'])
    love.graphics.printf('press Enter to play a hand -- placeholder menu, replaced in PRD 7', 0, VIRTUAL_HEIGHT / 2 - 10, VIRTUAL_WIDTH, 'center')

    love.graphics.draw(gTextures['deck-sheet'], self.sampleCardQuad,
        VIRTUAL_WIDTH / 2 - 32.5, VIRTUAL_HEIGHT / 2 + 15, 0, 0.5, 0.5)
end
