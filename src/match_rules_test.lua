-- Run via: luajit lib/knife/test.lua src/match_rules_test.lua

require 'src.match_rules'

T('match_rules', function(t)
    t('chicoWinner: nobody until a side reaches 30', function(t)
        t:assert(chicoWinner(0, 0) == nil, '0-0 -> no winner')
        t:assert(chicoWinner(29, 29) == nil, '29-29 -> still no winner')
        t:assert(chicoWinner(30, 12) == 'player', 'player at exactly 30 wins')
        t:assert(chicoWinner(12, 30) == 'ai', 'ai at exactly 30 wins')
    end)

    t('chicoWinner: overshooting 30 still wins (falta/truco can jump)', function(t)
        t:assert(chicoWinner(34, 20) == 'player', 'player past 30 wins')
        t:assert(chicoWinner(20, 41) == 'ai', 'ai past 30 wins')
    end)

    t('chicosNeeded per format', function(t)
        t:assert(chicosNeeded('single_chico') == 1, 'single chico -> 1')
        t:assert(chicosNeeded('best_of_3') == 2, 'best of 3 -> 2')
    end)

    t('partidaWinner (best_of_3): only at 2 chicos', function(t)
        t:assert(partidaWinner({ player = 0, ai = 0 }, 'best_of_3') == nil, '0-0 undecided')
        t:assert(partidaWinner({ player = 1, ai = 0 }, 'best_of_3') == nil, '1-0 undecided')
        t:assert(partidaWinner({ player = 1, ai = 1 }, 'best_of_3') == nil, '1-1 undecided -> 3rd chico')
        t:assert(partidaWinner({ player = 2, ai = 0 }, 'best_of_3') == 'player', '2-0 player')
        t:assert(partidaWinner({ player = 1, ai = 2 }, 'best_of_3') == 'ai', '2-1 ai (decisive 3rd)')
    end)

    t('partidaWinner (single_chico): the first chico ends it', function(t)
        t:assert(partidaWinner({ player = 0, ai = 0 }, 'single_chico') == nil, '0-0 undecided')
        t:assert(partidaWinner({ player = 1, ai = 0 }, 'single_chico') == 'player', '1-0 player')
        t:assert(partidaWinner({ player = 0, ai = 1 }, 'single_chico') == 'ai', '0-1 ai')
    end)
end)
