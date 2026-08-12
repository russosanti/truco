-- Opponent name base and generation

OPPONENT_FIRST_NAMES = {
    'Facundo', 'Lucas', 'Martin', 'Nicolas', 'Santiago', 'Julian', 'Tomas', 'Agustin',
    'Ramiro', 'Ignacio', 'Camila', 'Sofia', 'Valentina', 'Martina', 'Julieta', 'Catalina',
}

OPPONENT_SURNAMES = {
    'Gomez', 'Fernandez', 'Rodriguez', 'Lopez', 'Diaz', 'Martinez', 'Perez', 'Garcia',
    'Sanchez', 'Romero', 'Alvarez', 'Torres', 'Ruiz', 'Flores', 'Acosta', 'Benitez',
}

-- First name of the full name
function firstNameOf(name)
    return name:match('^(%S+)') or name
end

-- Random combination name excluding used ones (exclude list)
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

-- Generate n distinct names
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
