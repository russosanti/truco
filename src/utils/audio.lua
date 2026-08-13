-- Music, sound effects and the two call voices

Audio = {}

local MUSIC_VOLUME = 0.35
local SFX_VOLUME = 0.7
local VOICE_VOLUME = 1.0
local CROSSFADE = 0.6

local VOICE_KEYS = {
    'envido', 'real', 'falta', 'truco', 'retruco', 'vale4',
    'quiero', 'noquiero', 'flor', 'contraflor', 'resto',
    'meachico', 'mazo', 'sonbuenas', 'sonmejores',
}

local music, sfx, voices = {}, {}, { player = {}, ai = {} }
local current, currentName

local function load(path, mode)
    if not love.filesystem.getInfo(path) then return nil end
    local ok, source = pcall(love.audio.newSource, path, mode)
    return ok and source or nil
end

function Audio.load()
    music.menu = load('sound/music/menu.mp3', 'stream')
    music.match = load('sound/music/match.mp3', 'stream')
    for _, m in pairs(music) do
        m:setLooping(true)
        m:setVolume(0)
    end

    sfx.card = load('sound/sfx/card.wav', 'static')

    for side, set in pairs(voices) do
        for _, key in ipairs(VOICE_KEYS) do
            set[key] = load('sound/voices/' .. side .. '/' .. key .. '.wav', 'static')
        end
        for n = 0, 38 do
            set['n' .. n] = load('sound/voices/' .. side .. '/n' .. n .. '.wav', 'static')
        end
    end
end

local function fade(source, from, to, onDone)
    source:setVolume(from)
    local elapsed = 0
    Timer.prior(CROSSFADE, function(_, dt)
        elapsed = elapsed + dt
        local t = math.min(1, elapsed / CROSSFADE)
        source:setVolume(from + (to - from) * t)
    end):finish(function()
        source:setVolume(to)
        if onDone then onDone() end
    end)
end

-- Crossfades to `name`
function Audio.music(name)
    if currentName == name then return end
    local next = music[name]
    local previous = current
    currentName = name
    current = next

    if previous then
        fade(previous, previous:getVolume(), 0, function()
            if previous ~= current then previous:stop() end
        end)
    end
    if next then
        next:play()
        fade(next, 0, MUSIC_VOLUME)
    end
end

function Audio.stopMusic()
    if current then current:stop() end
    current, currentName = nil, nil
end

-- Pitch varies slightly so repeated cards don't sound mechanical.
function Audio.sfx(key, pitchSpread)
    local source = sfx[key]
    if not source then return end
    source:stop()
    source:setVolume(SFX_VOLUME)
    if pitchSpread then
        source:setPitch(1 + (math.random() * 2 - 1) * pitchSpread)
    end
    source:play()
end

-- Speaks `keys` in order, each clip starting when the previous one ends
function Audio.say(side, keys)
    local set = voices[side]
    if not set then return end

    local function speak(i)
        local source = set[keys[i]]
        if not source then
            if keys[i + 1] then speak(i + 1) end
            return
        end
        source:stop()
        source:setVolume(VOICE_VOLUME)
        source:play()
        if keys[i + 1] then
            Timer.after(source:getDuration(), function() speak(i + 1) end)
        end
    end

    if keys[1] then speak(1) end
end

function Audio.number(value)
    return 'n' .. math.max(0, math.min(38, math.floor(value)))
end
