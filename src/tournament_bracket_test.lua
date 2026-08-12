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

    t('buildBracket: 8 pairings over 16 distinct slots, player placed once', function(t)
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
            t:assert(contains(pairings, 'You') == 1, 'the player appears exactly once')
        end
    end)

    t('buildBracket puts the player in varying slots', function(t)
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

    t('playerOpponent names whoever the player faces', function(t)
        math.randomseed(5)
        local bracket = buildBracket('You', generateNames(15))
        local opponent = playerOpponent(bracket)
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

    t('advanceRound carries a winning player forward', function(t)
        math.randomseed(7)
        local bracket = buildBracket('You', generateNames(15))
        advanceRound(bracket, true)
        t:assert(bracket.round == 2, 'moved to round 2')
        t:assert(#bracket.rounds[2] == 4, '4 quarterfinals')
        t:assert(contains(bracket.rounds[2], 'You') == 1, 'the player advanced')
        t:assert(#bracket.rounds[1] == 8, 'round 1 is kept for drawing')
    end)

    t('advanceRound drops a losing player but keeps the bracket whole', function(t)
        math.randomseed(8)
        local bracket = buildBracket('You', generateNames(15))
        local beat = playerOpponent(bracket)
        advanceRound(bracket, false)
        t:assert(contains(bracket.rounds[2], 'You') == 0, 'the player is out')
        t:assert(contains(bracket.rounds[2], beat) == 1, 'their opponent advanced instead')
        t:assert(#bracket.rounds[2] == 4, 'still 4 quarterfinals')
        t:assert(playerOpponent(bracket) == nil, 'and there is nobody to face')
    end)

    t('the whole bracket runs 8 -> 4 -> 2 -> 1', function(t)
        math.randomseed(9)
        local bracket = buildBracket('You', generateNames(15))
        for _, expected in ipairs({ 4, 2, 1 }) do
            advanceRound(bracket, true)
            t:assert(#bracket.rounds[bracket.round] == expected,
                'round ' .. bracket.round .. ' has ' .. expected .. ' matches')
            t:assert(contains(bracket.rounds[bracket.round], 'You') == 1, 'player still in')
        end
        t:assert(bracket.round == 4, 'four rounds to the Final')
    end)

    t('matchWinner reads a decided round, and nothing before it', function(t)
        math.randomseed(11)
        local bracket = buildBracket('You', generateNames(15))

        for m = 1, 8 do
            t:assert(matchWinner(bracket, 1, m) == nil, 'round 1 is undecided while it is being played')
        end

        advanceRound(bracket, true)
        for m, pair in ipairs(bracket.rounds[1]) do
            local w = matchWinner(bracket, 1, m)
            t:assert(w == pair[1] or w == pair[2], 'the winner is one of the entrants')
            t:assert(contains(bracket.rounds[2], w) == 1, 'and it is who advanced')
        end
        for m = 1, 4 do
            t:assert(matchWinner(bracket, 2, m) == nil, 'round 2 has not been played yet')
        end
    end)

    t('matchWinner agrees with the player result either way', function(t)
        math.randomseed(12)
        local won = buildBracket('You', generateNames(15))
        local wonIndex
        for m, pair in ipairs(won.rounds[1]) do
            if pair[1] == 'You' or pair[2] == 'You' then wonIndex = m end
        end
        advanceRound(won, true)
        t:assert(matchWinner(won, 1, wonIndex) == 'You', 'a won match reads as the player')

        math.randomseed(12)
        local lost = buildBracket('You', generateNames(15))
        local lostIndex, beat
        for m, pair in ipairs(lost.rounds[1]) do
            if pair[1] == 'You' then lostIndex, beat = m, pair[2] end
            if pair[2] == 'You' then lostIndex, beat = m, pair[1] end
        end
        advanceRound(lost, false)
        t:assert(matchWinner(lost, 1, lostIndex) == beat, 'a lost match reads as the opponent')
    end)

    t('advanceRound with nil resolves the player-less bracket by coin flip', function(t)
        math.randomseed(10)
        local bracket = buildBracket('You', generateNames(15))
        advanceRound(bracket, false)      -- human eliminated
        advanceRound(bracket, nil)        -- no human result to honour any more
        t:assert(#bracket.rounds[3] == 2, 'semifinals still get paired')
        t:assert(contains(bracket.rounds[3], 'You') == 0, 'and the player stays out')
    end)
end)
