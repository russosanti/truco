-- Opponent names (PRD 8 §3). Generic, common Argentine given names and
-- surnames, combined for variety; nothing tied to an identifiable person.
-- Written without accents (Tomas, not Tomás): the name widths the bracket and
-- the dialog boxes are budgeted against are byte counts, and an accented
-- character is two bytes in UTF-8.

OPPONENT_FIRST_NAMES = {
    'Facundo', 'Lucas', 'Martin', 'Nicolas', 'Santiago', 'Julian', 'Tomas', 'Agustin',
    'Ramiro', 'Ignacio', 'Camila', 'Sofia', 'Valentina', 'Martina', 'Julieta', 'Catalina',
}

OPPONENT_SURNAMES = {
    'Gomez', 'Fernandez', 'Rodriguez', 'Lopez', 'Diaz', 'Martinez', 'Perez', 'Garcia',
    'Sanchez', 'Romero', 'Alvarez', 'Torres', 'Ruiz', 'Flores', 'Acosta', 'Benitez',
}

-- The short label used in-match: names are generated with distinct first names,
-- so this is unambiguous and fits the HUD and the dialog boxes.
function firstNameOf(name)
    return name:match('^(%S+)') or name
end

-- One name, avoiding anything already in `exclude` (a list). 256 combinations
-- against at most 15 taken, so the retry practically never runs twice.
function randomName(exclude)
    local taken = {}
    for _, name in ipairs(exclude or {}) do
        taken[name] = true
        taken[firstNameOf(name)] = true
    end

    for _ = 1, 200 do
        local first = OPPONENT_FIRST_NAMES[math.random(#OPPONENT_FIRST_NAMES)]
        local surname = OPPONENT_SURNAMES[math.random(#OPPONENT_SURNAMES)]
        if not taken[first] and not taken[first .. ' ' .. surname] then
            return first .. ' ' .. surname
        end
    end
    error('randomName: could not find an unused name')
end

-- `n` names, all distinct. Drawn by shuffling the first-name pool rather than
-- calling randomName n times: that guarantees distinct FIRST names too (which
-- is what the bracket displays, and 16 of them covers the 15 opponents a
-- tournament needs) with no retry loop.
function generateNames(n)
    local firsts = {}
    for i, name in ipairs(OPPONENT_FIRST_NAMES) do firsts[i] = name end
    for i = #firsts, 2, -1 do
        local j = math.random(i)
        firsts[i], firsts[j] = firsts[j], firsts[i]
    end

    if n > #firsts then
        error('generateNames(' .. n .. ') wants more names than there are first names')
    end

    local names = {}
    for i = 1, n do
        names[i] = firsts[i] .. ' ' .. OPPONENT_SURNAMES[math.random(#OPPONENT_SURNAMES)]
    end
    return names
end
