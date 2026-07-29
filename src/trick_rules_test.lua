-- Run via: luajit lib/knife/test.lua src/trick_rules_test.lua

Class = require 'lib.class'
require 'src.card_defs'
require 'src.Card'
require 'src.trick_rules'

-- Convenience: a hand's outcome played out trick by trick, asserting the
-- winner isHandDecided reports after each trick (nil until settled).
local function play(t, tricks, mano, expected)
    local wins = { human = 0, ai = 0 }
    local firstTrickWinner, decided
    for i, result in ipairs(tricks) do
        if result ~= 'tie' then
            wins[result] = wins[result] + 1
        end
        if i == 1 and result ~= 'tie' then firstTrickWinner = result end
        decided = isHandDecided(wins, firstTrickWinner, i, mano)
        if i < #tricks then
            t:assert(decided == nil,
                'not decided before the final listed trick (trick ' .. i .. ')')
        end
    end
    t:assert(decided == expected,
        'winner is ' .. tostring(expected) .. ' (got ' .. tostring(decided) .. ')')
end

T('trick_rules', function(t)
    t('resolveTrick maps compareTrick to leader/other/tie', function(t)
        local espadas1 = Card('espadas', 1)  -- top card
        local oros1 = Card('oros', 1)         -- lower tier
        local bastos3 = Card('bastos', 3)
        local oros3 = Card('oros', 3)         -- same tier as bastos3

        t:assert(resolveTrick(espadas1, oros1) == 'leader', 'stronger leader wins')
        t:assert(resolveTrick(oros1, espadas1) == 'other', 'stronger responder wins')
        t:assert(resolveTrick(bastos3, oros3) == 'tie', 'same tier is a parda')
    end)

    t('nextLeader: winner leads, tie gives lead to mano', function(t)
        t:assert(nextLeader('leader', 'human', 'ai') == 'human', 'leader kept the lead')
        t:assert(nextLeader('other', 'human', 'ai') == 'ai', 'responder took the lead')
        t:assert(nextLeader('other', 'ai', 'human') == 'human', 'responder (human) took the lead')
        t:assert(nextLeader('tie', 'human', 'ai') == 'ai', 'tie hands lead to mano')
        t:assert(nextLeader('tie', 'ai', 'ai') == 'ai', 'tie -> mano even if mano already led')
    end)

    t('isHandDecided: every §5 worked example', function(t)
        -- treat "P1" as human throughout; mano = ai so mano-wins rows are visible
        play(t, { 'tie', 'human' }, 'ai', 'human')            -- decided after trick 2
        play(t, { 'human', 'tie' }, 'ai', 'human')            -- tie locks P1's lead
        play(t, { 'tie', 'tie', 'tie' }, 'ai', 'ai')          -- all parda -> mano (ai)
        play(t, { 'human', 'human' }, 'ai', 'human')          -- ordinary 2-of-3 sweep
    end)

    t('isHandDecided: ordinary 1-1 then a clean win on trick 3', function(t)
        play(t, { 'human', 'ai', 'human' }, 'ai', 'human')
        play(t, { 'ai', 'human', 'ai' }, 'human', 'ai')
    end)

    -- PRD 2 §5's table gave this row to mano; the reglamento gives it to whoever
    -- took trick 1. Both manos asserted, so mano can't be what decides it.
    t('isHandDecided: 1-1 with a parda third goes to the trick-1 winner', function(t)
        play(t, { 'human', 'ai', 'tie' }, 'ai', 'human')      -- mano is the trick-1 loser
        play(t, { 'human', 'ai', 'tie' }, 'human', 'human')   -- ...and the trick-1 winner
        play(t, { 'ai', 'human', 'tie' }, 'human', 'ai')      -- mirrored
        play(t, { 'ai', 'human', 'tie' }, 'ai', 'ai')
    end)

    t('isHandDecided: mano decides the all-parda hand, and only that one', function(t)
        play(t, { 'tie', 'tie', 'tie' }, 'human', 'human')
        play(t, { 'tie', 'tie', 'tie' }, 'ai', 'ai')
    end)

    -- Cross-check the branch order above against the rule stated declaratively:
    -- "the winner of the earliest non-parda trick, else mano". Two independent
    -- formulations agreeing on all 27 sequences x both manos -- winner AND the
    -- trick it is known on. This comparison is what caught the row above.
    t('isHandDecided: agrees with the reglamento on every possible hand', function(t)
        local function reference(seq, mano)
            local wins = { human = 0, ai = 0 }
            local earliest
            for i, r in ipairs(seq) do
                if r ~= 'tie' then
                    wins[r] = wins[r] + 1
                    earliest = earliest or r
                end
                if wins.human >= 2 then return 'human', i end
                if wins.ai >= 2 then return 'ai', i end
                local pardas = i - wins.human - wins.ai
                if pardas >= 1 and wins.human ~= wins.ai then
                    return (wins.human > wins.ai) and 'human' or 'ai', i
                end
                if i == 3 then return earliest or mano, i end
            end
        end

        local function actual(seq, mano)
            local wins = { human = 0, ai = 0 }
            local firstTrickWinner
            for i, r in ipairs(seq) do
                if r ~= 'tie' then wins[r] = wins[r] + 1 end
                if i == 1 and r ~= 'tie' then firstTrickWinner = r end
                local d = isHandDecided(wins, firstTrickWinner, i, mano)
                if d then return d, i end
            end
        end

        local results = { 'human', 'ai', 'tie' }
        local checked = 0
        for _, a in ipairs(results) do
            for _, b in ipairs(results) do
                for _, c in ipairs(results) do
                    for _, mano in ipairs({ 'human', 'ai' }) do
                        local seq = { a, b, c }
                        local gotWho, gotAt = actual(seq, mano)
                        local wantWho, wantAt = reference(seq, mano)
                        local label = a .. '/' .. b .. '/' .. c .. ' mano=' .. mano
                        t:assert(gotWho == wantWho, label .. ' -> ' .. tostring(wantWho)
                            .. ' (got ' .. tostring(gotWho) .. ')')
                        t:assert(gotAt == wantAt, label .. ' settles on trick '
                            .. tostring(wantAt) .. ' (got ' .. tostring(gotAt) .. ')')
                        checked = checked + 1
                    end
                end
            end
        end
        t:assert(checked == 54, 'covered all 27 sequences x 2 manos (got ' .. checked .. ')')
    end)
end)
