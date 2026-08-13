--
-- libraries
--

Class = require 'lib.class'
Event = require 'lib.knife.event'
push = require 'lib.push'
Timer = require 'lib.knife.timer'

require 'src.constants'
require 'src.sides'
require 'src.Util'
require 'src.StateMachine'

require 'src.states.BaseState'
require 'src.states.StateStack'

require 'src.states.game.FadeInState'
require 'src.states.game.FadeOutState'
require 'src.transition'
require 'src.states.game.MenuState'
require 'src.states.game.TournamentState'

require 'src.gui.Panel'  -- used by TrickState for the "AI: <call>" message box
require 'src.gui.Textbox'

require 'src.card_defs'
require 'src.Card'
require 'src.Deck'

require 'src.trick_rules'
require 'src.ai_config'
require 'src.AiStub'
require 'src.table_render'

require 'src.envido_rules'
require 'src.canto'
require 'src.envido_canto'
require 'src.EnvidoAiStub'

require 'src.flor_rules'
require 'src.flor_canto'
require 'src.FlorAiStub'

require 'src.opponent_names'  --named opponents
require 'src.tournament_bracket'
require 'src.truco_rules'
require 'src.TrucoAiStub'
require 'src.match_rules'

require 'src.states.game.HandLoopState'
require 'src.states.game.DealState'
require 'src.states.game.TrickState'
require 'src.states.game.HandScoreState'
require 'src.states.game.ChicoScoreState'
require 'src.states.game.MatchEndState'

gTextures = {
    ['deck-sheet'] = love.graphics.newImage('graphics/deck_sheet.png'),
    ['card-back'] = love.graphics.newImage('graphics/card_back.png'),
}

gFrames = {
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
