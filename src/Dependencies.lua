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
require 'src.states.game.MenuState'
require 'src.states.game.TournamentState'

require 'src.gui.Panel'  -- used by TrickState for the "AI: <call>" message box
-- require 'src.gui.Menu'
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
require 'src.ai_config'  -- PRD 6: shared aggression/bluff knobs, before the AI files
require 'src.AiStub'
require 'src.table_render'

-- PRD 3: envido. Pure valuation math + the family-agnostic call engine and its
-- envido binding + a throwaway decision stub. Envido runs inside the first
-- trick (TrickState hosts the call window), so there's no CantosState anymore.
require 'src.envido_rules'
require 'src.canto'
require 'src.envido_canto'
require 'src.EnvidoAiStub'

-- PRD 9: flor. Mandatory, cancels envido, and rides the same Canto engine.
require 'src.flor_rules'
require 'src.flor_canto'
require 'src.FlorAiStub'

-- PRD 4: truco. Pure point/gating math + a throwaway decision stub. Truco lives
-- entirely inside TrickState (state-local), so nothing else changes.
require 'src.opponent_names'  -- PRD 8: named opponents + the bracket, both pure
require 'src.tournament_bracket'
require 'src.truco_rules'
require 'src.TrucoAiStub'

-- PRD 5: match structure. Every score change funnels through
-- HandLoopState:awardPoints, which is what completes a chico.
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
