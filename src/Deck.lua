--[[
    Truco Argentino

    -- Deck Class --

    The 40-card Spanish deck: 4 suits x 10 ranks (no 8s or 9s). See PRD 1 §3
    for the method table.
]]

Deck = Class{}

function Deck:init()
    self:reset()
end

--[[
    (Re)builds the full 40-card deck, unshuffled, in canonical
    suit-then-rank order (matches CARD_SUITS x CARD_RANKS from card_defs).
]]
function Deck:build()
    self.cards = {}
    for _, suit in ipairs(CARD_SUITS) do
        for _, rank in ipairs(CARD_RANKS) do
            table.insert(self.cards, Card(suit, rank))
        end
    end
end

-- Fisher-Yates shuffle of self.cards, in place.
function Deck:shuffle()
    local cards = self.cards
    for i = #cards, 2, -1 do
        local j = math.random(i)
        cards[i], cards[j] = cards[j], cards[i]
    end
end

-- Removes and returns n cards from the top of the deck. Errors if fewer than
-- n cards remain.
function Deck:deal(n)
    if n > #self.cards then
        error('Deck:deal(' .. n .. ') requested more cards than remain (' .. #self.cards .. ')')
    end

    local dealt = {}
    for i = 1, n do
        table.insert(dealt, table.remove(self.cards, 1))
    end
    return dealt
end

function Deck:remaining()
    return #self.cards
end

-- Rebuilds the full 40-card deck and shuffles -- call this between hands.
function Deck:reset()
    self:build()
    self:shuffle()
end
