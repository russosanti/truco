-- Run via: luajit lib/knife/test.lua src/opponent_names_test.lua

require 'src.opponent_names'

T('opponent_names', function(t)
    t('randomName combines the two pools', function(t)
        math.randomseed(1)
        for _ = 1, 200 do
            local name = randomName({})
            local first, surname = name:match('^(%S+) (.+)$')
            local okFirst, okSurname = false, false
            for _, n in ipairs(OPPONENT_FIRST_NAMES) do if n == first then okFirst = true end end
            for _, n in ipairs(OPPONENT_SURNAMES) do if n == surname then okSurname = true end end
            t:assert(okFirst and okSurname, 'both halves come from the pools: ' .. name)
        end
    end)

    t('randomName never returns a name in its exclude set', function(t)
        math.randomseed(2)
        local exclude = generateNames(15)
        local taken = {}
        for _, n in ipairs(exclude) do taken[n] = true end
        for _ = 1, 300 do
            local name = randomName(exclude)
            t:assert(not taken[name], 'excluded name came back: ' .. name)
        end
    end)

    t('generateNames(15) is 15 distinct names, first names included', function(t)
        math.randomseed(3)
        for _ = 1, 50 do
            local names = generateNames(15)
            t:assert(#names == 15, 'got 15 names')
            local seenFull, seenFirst = {}, {}
            for _, name in ipairs(names) do
                t:assert(not seenFull[name], 'duplicate name ' .. name)
                seenFull[name] = true
                local first = firstNameOf(name)
                t:assert(not seenFirst[first], 'duplicate first name ' .. first)
                seenFirst[first] = true
            end
        end
    end)

    t('firstNameOf takes the given name only', function(t)
        t:assert(firstNameOf('Valentina Rodríguez') == 'Valentina', 'splits on the space')
        t:assert(firstNameOf('You') == 'You', 'a bare name is left alone')
    end)
end)
