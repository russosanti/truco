-- Run via: luajit lib/knife/test.lua src/truco_rules_test.lua

require 'src.truco_rules'

T('truco_rules', function(t)
    t('trucoRaiseCall: answering with the next level, capped at Vale cuatro', function(t)
        t:assert(trucoRaiseCall({ level = 2 }) == 3, 'Truco can be answered with Retruco')
        t:assert(trucoRaiseCall({ level = 3 }) == 4, 'Retruco with Vale cuatro')
        t:assert(trucoRaiseCall({ level = 4 }) == nil, 'nothing is above Vale cuatro')
        t:assert(trucoRaiseCall(nil) == nil, 'nothing pending, nothing to raise')
    end)

    t('reject value = previous level (§7)', function(t)
        t:assert(trucoRejectValue(2) == 1, 'Truco rejected -> 1')
        t:assert(trucoRejectValue(3) == 2, 'Retruco rejected -> 2')
        t:assert(trucoRejectValue(4) == 3, 'Vale cuatro rejected -> 3')
    end)

    t('fold value = current level, or 1 if never called', function(t)
        t:assert(trucoFoldValue(0) == 1, 'never called -> 1')
        t:assert(trucoFoldValue(2) == 2, 'at Truco -> 2')
        t:assert(trucoFoldValue(4) == 4, 'at Vale cuatro -> 4')
    end)

    t('availableTrucoCall: opening is either side while nothing is accepted', function(t)
        t:assert(availableTrucoCall(0, nil, 'human', nil) == 2, 'human may open Truco')
        t:assert(availableTrucoCall(0, nil, 'ai', nil) == 2, 'ai may open Truco')
    end)

    t('availableTrucoCall: only trucoLeader may raise, one step at a time', function(t)
        -- level 2 accepted, ai is leader
        t:assert(availableTrucoCall(2, 'ai', 'ai', nil) == 3, 'leader raises to Retruco')
        t:assert(availableTrucoCall(2, 'ai', 'human', nil) == nil, 'non-leader may not raise')
        -- level 3 accepted, human leader
        t:assert(availableTrucoCall(3, 'human', 'human', nil) == 4, 'leader raises to Vale cuatro')
        t:assert(availableTrucoCall(3, 'human', 'ai', nil) == nil, 'non-leader may not raise')
    end)

    t('availableTrucoCall: nothing past Vale cuatro, nothing while pending', function(t)
        t:assert(availableTrucoCall(4, 'ai', 'ai', nil) == nil, 'no raise past Vale cuatro')
        t:assert(availableTrucoCall(0, nil, 'human', { level = 2 }) == nil, 'no call while one is pending')
        t:assert(availableTrucoCall(2, 'ai', 'ai', { level = 3 }) == nil, 'leader cannot raise mid-pending')
    end)
end)
