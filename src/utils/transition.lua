local FADE_COLOR = { r = 0, g = 0, b = 0 }
local FADE_TIME = 0.2

function transition(fn)
    gStateStack:push(FadeInState(FADE_COLOR, FADE_TIME, function()
        fn()
        gStateStack:push(FadeOutState(FADE_COLOR, FADE_TIME, function() end))
    end))
end
