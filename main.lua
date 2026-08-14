--[[
    Truco Argentino

    Carried over from the pokebowl project (itself built on the CS50 2D Pokemon distro by Colton Ogden)

    Card art: Spanish playing card artwork by Basquetteur (Wikimedia Commons),
    CC BY-SA 3.0 -- see graphics/ and the project README for full attribution.
]]

love.graphics.setDefaultFilter('nearest', 'nearest')
require 'src.Dependencies'

function love.load()
    love.window.setTitle('Truco Argentino')
    math.randomseed(os.time())

    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable = true
    })

    push.setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, { upscale = 'normal' })

    -- same stack pattern as pokebowl: states push/pop and render bottom-to-top
    gStateStack = StateStack()
    gStateStack:push(MenuState())

    love.keyboard.keysPressed = {}
end

function love.resize(w, h)
    push.resize(w, h)
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

    love.keyboard.keysPressed[key] = true
end

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

function love.update(dt)
    Timer.update(dt)
    gStateStack:update(dt)

    love.keyboard.keysPressed = {}
end

function love.draw()
    push.start()
    gStateStack:render()
    push.finish()
end
