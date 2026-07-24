--
-- libraries
--

Class = require 'lib.class'
Event = require 'lib.knife.event'
push = require 'lib.push'
Timer = require 'lib.knife.timer'

require 'src.constants'
require 'src.Util'
require 'src.StateMachine'

require 'src.states.BaseState'
require 'src.states.StateStack'

require 'src.states.game.FadeInState'
require 'src.states.game.FadeOutState'
require 'src.states.game.StartState'

-- require 'src.gui.Menu'
-- require 'src.gui.Panel'
-- require 'src.gui.ProgressBar'
-- require 'src.gui.Selection'
-- require 'src.gui.Textbox'
-- kept in src/gui, commented out until something actually uses them --
-- generic pokebowl widgets, no card-game-specific behavior yet

-- PRD 1: card & deck model. Def-then-class ordering, mirroring pokebowl's
-- pokemon_defs.lua -> Pokemon.lua. Later PRDs add their own requires here.
require 'src.card_defs'
require 'src.Card'
require 'src.Deck'

-- PRD 2: hand loop. Pure rules + throwaway AI + shared drawing, then the
-- HandLoopState and its four phase states (deal -> cantos -> trick -> score).
require 'src.trick_rules'
require 'src.AiStub'
require 'src.table_render'

require 'src.states.game.HandLoopState'
require 'src.states.game.DealState'
require 'src.states.game.CantosState'
require 'src.states.game.TrickState'
require 'src.states.game.HandScoreState'

gTextures = {
    ['deck-sheet'] = love.graphics.newImage('graphics/deck_sheet.png'),
    ['card-back'] = love.graphics.newImage('graphics/card_back.png'),
}

gFrames = {
    -- 130x200 per card, 10 cols x 4 rows -- see PRD 1 section 7 for the
    -- suit/rank -> index formula that maps onto this quad array
    ['cards'] = GenerateQuads(gTextures['deck-sheet'], 130, 200)
}

gFonts = {
    ['small'] = love.graphics.newFont('fonts/font.ttf', 8),
    ['medium'] = love.graphics.newFont('fonts/font.ttf', 16),
    ['large'] = love.graphics.newFont('fonts/font.ttf', 32)
}

gSounds = {
    -- no audio assets yet
}
