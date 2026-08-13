--
-- libraries
--

Class = require 'lib.class'
Event = require 'lib.knife.event'
push = require 'lib.push'
Timer = require 'lib.knife.timer'

require 'src.constants'
require 'src.utils.sides'
require 'src.utils.Util'
require 'src.StateMachine'

require 'src.states.BaseState'
require 'src.states.StateStack'

require 'src.states.game.FadeInState'
require 'src.states.game.FadeOutState'
require 'src.utils.transition'
require 'src.states.game.MenuState'
require 'src.states.game.TournamentState'

require 'src.gui.Panel'  -- used by TrickState for the "AI: <call>" message box
require 'src.gui.Textbox'

require 'src.card_defs'
require 'src.objects.Card'
require 'src.objects.Deck'

require 'src.rules.trick_rules'
require 'src.ai.ai_config'
require 'src.ai.AiStub'
require 'src.utils.table_render'

require 'src.rules.envido_rules'
require 'src.objects.canto'
require 'src.rules.envido_canto'
require 'src.ai.EnvidoAiStub'

require 'src.rules.flor_rules'
require 'src.rules.flor_canto'
require 'src.ai.FlorAiStub'

require 'src.utils.opponent_names'  --named opponents
require 'src.utils.tournament_bracket'
require 'src.rules.truco_rules'
require 'src.ai.TrucoAiStub'
require 'src.rules.match_rules'

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
