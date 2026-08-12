-- Run via: luajit lib/knife/test.lua src/flor_canto_test.lua

Class = require 'lib.class'
require 'src.sides'
require 'src.card_defs'
require 'src.Card'
require 'src.envido_rules'
require 'src.flor_rules'
require 'src.canto'
require 'src.flor_canto'

-- human is mano throughout; 35 vs 30 so mano wins unless stated otherwise
local function play(steps, playerScore, aiScore, manoVal, pieVal)
    local c = Canto(FLOR_CANTO, 'player', 'flor')
    for _, step in ipairs(steps) do
        if step == 'accept' then c:accept()
        elseif step == 'reject' then c:reject()
        else c:raise(step) end
    end
    return florAward(c.outcome, 'player', manoVal or 35, pieVal or 30,
        playerScore or 0, aiScore or 0)
end

T('flor_canto', function(t)
    t('the ladder narrows flor -> contraflor -> al resto -> nothing', function(t)
        local c = Canto(FLOR_CANTO, 'player', 'flor')
        t:assert(c.responder == 'ai', 'the pie answers the declaration')
        local raises = c:availableRaises()
        t:assert(#raises == 1 and raises[1] == 'contraflor', 'only Contraflor from the base')
        c:raise('contraflor')
        t:assert(c.responder == 'player', 'and it goes back to the other side')
        raises = c:availableRaises()
        t:assert(#raises == 1 and raises[1] == 'resto', 'only al resto from Contraflor')
        c:raise('resto')
        t:assert(#c:availableRaises() == 0, 'al resto is the ceiling')
    end)

    t('base flor accepted pays 3 to the better flor', function(t)
        local side, points = play({ 'accept' })
        t:assert(side == 'player' and points == 3, 'mano 35 beats pie 30 for 3')

        side, points = play({ 'accept' }, 0, 0, 30, 35)
        t:assert(side == 'ai' and points == 3, 'the higher flor takes it either way')

        side, points = play({ 'accept' }, 0, 0, 31, 31)
        t:assert(side == 'player' and points == 3, 'a tie goes to mano')
    end)

    t('base flor refused pays the flor itself to the declarer', function(t)
        local side, points = play({ 'reject' })
        t:assert(side == 'player' and points == 3, 'me achico at the base: mano keeps the 3')
    end)

    t('Contraflor: 6 accepted, 3 to the proposer if refused', function(t)
        local side, points = play({ 'contraflor', 'accept' })
        t:assert(side == 'player' and points == 6, 'accepted Contraflor is worth 6')

        side, points = play({ 'contraflor', 'reject' })
        t:assert(side == 'ai' and points == 3,
            'refusing it pays the rung below to whoever called it')
    end)

    t('Contraflor al resto: falta plus both flores, 6 if refused', function(t)
        -- malas: leader under 15, so faltaEnvidoValue is 30 - the winner's own
        local side, points = play({ 'contraflor', 'resto', 'accept' }, 10, 5)
        t:assert(side == 'player', 'the better flor takes it')
        t:assert(points == faltaEnvidoValue(10, 5, 'player') + 6,
            'falta plus 3 per declared flor')
        t:assert(points == 20 + 6, 'which is 26 from 10-5')

        -- buenas: leader at or past 15, so it is 30 - the leader
        side, points = play({ 'contraflor', 'resto', 'accept' }, 22, 8)
        t:assert(points == faltaEnvidoValue(22, 8, 'player') + 6, 'same formula in buenas')
        t:assert(points == 8 + 6, 'which is 14 from 22-8')

        -- the ladder alternates: mano declared, pie contraflored, mano went al
        -- resto -- so refusing it pays mano, not the Contraflor's caller
        side, points = play({ 'contraflor', 'resto', 'reject' }, 10, 5)
        t:assert(side == 'player' and points == 6,
            'refusing al resto pays the Contraflor to whoever called al resto')
    end)

    t('the caller of the refused rung is who gets paid', function(t)
        -- ai opens as mano: refusing its base flor pays the ai
        local c = Canto(FLOR_CANTO, 'ai', 'flor')
        c:reject()
        local side, points = florAward(c.outcome, 'ai', 35, 30, 0, 0)
        t:assert(side == 'ai' and points == 3, 'mano ai keeps its flor')
    end)
end)
