-- Run via: luajit lib/knife/test.lua src/trick_rules_test.lua

Class = require 'lib.class'
require 'src.card_defs'
require 'src.Card'
require 'src.trick_rules'

-- Convenience: a hand's outcome played out trick by trick, asserting the
-- winner isHandDecided reports after each trick (nil until settled).
local function play(t, tricks, mano, expected)
    local wins = { human = 0, ai = 0 }
    local decided
    for i, result in ipairs(tricks) do
        if result ~= 'tie' then
            wins[result] = wins[result] + 1
        end
        decided = isHandDecided(wins, result == 'tie', i, mano)
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
        play(t, { 'human', 'ai', 'tie' }, 'ai', 'ai')         -- 1-1, tied decider -> mano (ai)
        play(t, { 'tie', 'tie', 'tie' }, 'ai', 'ai')          -- all parda -> mano (ai)
        play(t, { 'human', 'human' }, 'ai', 'human')          -- ordinary 2-of-3 sweep
    end)

    t('isHandDecided: ordinary 1-1 then a clean win on trick 3', function(t)
        play(t, { 'human', 'ai', 'human' }, 'ai', 'human')
        play(t, { 'ai', 'human', 'ai' }, 'human', 'ai')
    end)

    t('isHandDecided: mano actually decides the tied decider', function(t)
        -- same 1-1-then-tie shape, but mano = human this time
        play(t, { 'human', 'ai', 'tie' }, 'human', 'human')
        play(t, { 'tie', 'tie', 'tie' }, 'human', 'human')
    end)
end)
