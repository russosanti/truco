-- Run via: luajit lib/knife/test.lua src/tournament_bracket_test.lua

require 'src.opponent_names'
require 'src.tournament_bracket'

local function contains(pairings, name)
    local n = 0
    for _, pair in ipairs(pairings) do
        for _, slot in ipairs(pair) do
            if slot == name then n = n + 1 end
        end
    end
    return n
end

T('tournament_bracket', function(t)
    t('round table matches the design doc: 3 chicos then a partida', function(t)
        t:assert(#TOURNAMENT_ROUND_NAMES == 4, 'four rounds')
        for i = 1, 3 do
            t:assert(TOURNAMENT_ROUND_FORMAT[i] == 'single_chico',
                TOURNAMENT_ROUND_NAMES[i] .. ' is a single chico')
        end
        t:assert(TOURNAMENT_ROUND_FORMAT[4] == 'best_of_3', 'the Final is a best-of-3')
    end)

    t('buildBracket: 8 pairings over 16 distinct slots, human placed once', function(t)
        math.randomseed(1)
        for _ = 1, 100 do
            local bracket = buildBracket('You', generateNames(15))
            local pairings = bracket.rounds[1]
            t:assert(#pairings == 8, '8 first-round matches')
            t:assert(bracket.round == 1, 'starts on round 1')

            local seen, slots = {}, 0
            for _, pair in ipairs(pairings) do
                t:assert(#pair == 2, 'every match has two entrants')
                for _, name in ipairs(pair) do
                    t:assert(not seen[name], 'duplicate entrant ' .. name)
                    seen[name] = true
                    slots = slots + 1
                end
            end
            t:assert(slots == 16, '16 entrants')
            t:assert(contains(pairings, 'You') == 1, 'the human appears exactly once')
        end
    end)

    t('buildBracket puts the human in varying slots', function(t)
        math.randomseed(4)
        local positions = {}
        for _ = 1, 200 do
            local bracket = buildBracket('You', generateNames(15))
            for i, pair in ipairs(bracket.rounds[1]) do
                if pair[1] == 'You' or pair[2] == 'You' then positions[i] = true end
            end
        end
        local n = 0
        for _ in pairs(positions) do n = n + 1 end
        t:assert(n > 1, 'the draw is random, not a fixed slot (saw ' .. n .. ')')
    end)

    t('humanOpponent names whoever the human faces', function(t)
        math.randomseed(5)
        local bracket = buildBracket('You', generateNames(15))
        local opponent = humanOpponent(bracket)
        t:assert(opponent ~= nil and opponent ~= 'You', 'found a real opponent')
        for _, pair in ipairs(bracket.rounds[1]) do
            if pair[1] == 'You' then t:assert(pair[2] == opponent, 'matches the pairing') end
            if pair[2] == 'You' then t:assert(pair[1] == opponent, 'matches the pairing') end
        end
    end)

    t('resolveOtherMatch always returns one of its two inputs', function(t)
        math.randomseed(6)
        local a, b = 0, 0
        for _ = 1, 500 do
            local w = resolveOtherMatch('Uno', 'Dos')
            t:assert(w == 'Uno' or w == 'Dos', 'returned an entrant')
            if w == 'Uno' then a = a + 1 else b = b + 1 end
        end
        t:assert(a > 0 and b > 0, 'both sides win sometimes')
    end)

    t('advanceRound carries a winning human forward', function(t)
        math.randomseed(7)
        local bracket = buildBracket('You', generateNames(15))
        advanceRound(bracket, true)
        t:assert(bracket.round == 2, 'moved to round 2')
        t:assert(#bracket.rounds[2] == 4, '4 quarterfinals')
        t:assert(contains(bracket.rounds[2], 'You') == 1, 'the human advanced')
        t:assert(#bracket.rounds[1] == 8, 'round 1 is kept for drawing')
    end)

    t('advanceRound drops a losing human but keeps the bracket whole', function(t)
        math.randomseed(8)
        local bracket = buildBracket('You', generateNames(15))
        local beat = humanOpponent(bracket)
        advanceRound(bracket, false)
        t:assert(contains(bracket.rounds[2], 'You') == 0, 'the human is out')
        t:assert(contains(bracket.rounds[2], beat) == 1, 'their opponent advanced instead')
        t:assert(#bracket.rounds[2] == 4, 'still 4 quarterfinals')
        t:assert(humanOpponent(bracket) == nil, 'and there is nobody to face')
    end)

    t('the whole bracket runs 8 -> 4 -> 2 -> 1', function(t)
        math.randomseed(9)
        local bracket = buildBracket('You', generateNames(15))
        for _, expected in ipairs({ 4, 2, 1 }) do
            advanceRound(bracket, true)
            t:assert(#bracket.rounds[bracket.round] == expected,
                'round ' .. bracket.round .. ' has ' .. expected .. ' matches')
            t:assert(contains(bracket.rounds[bracket.round], 'You') == 1, 'human still in')
        end
        t:assert(bracket.round == 4, 'four rounds to the Final')
    end)

    t('advanceRound with nil resolves the human-less bracket by coin flip', function(t)
        math.randomseed(10)
        local bracket = buildBracket('You', generateNames(15))
        advanceRound(bracket, false)      -- human eliminated
        advanceRound(bracket, nil)        -- no human result to honour any more
        t:assert(#bracket.rounds[3] == 2, 'semifinals still get paired')
        t:assert(contains(bracket.rounds[3], 'You') == 0, 'and the human stays out')
    end)
end)
