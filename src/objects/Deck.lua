--[[
    Truco Argentino

    -- Deck Class --
]]

Deck = Class{}

function Deck:init()
    self:reset()
end

--[[
    (Re)builds the full 40-card deck, unshuffled. The deck is always in the same order, so shuffle() must be called
]]
function Deck:build()
    self.cards = {}
    for _, suit in ipairs(CARD_SUITS) do
        for _, rank in ipairs(CARD_RANKS) do
            table.insert(self.cards, Card(suit, rank))
        end
    end
end

-- Shuffle cards in deck
function Deck:shuffle()
    local cards = self.cards
    for i = #cards, 2, -1 do
        local j = math.random(i)
        cards[i], cards[j] = cards[j], cards[i]
    end
end

-- Removes and returns n cards from the top of the deck
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

-- Remaining cards in deck
function Deck:remaining()
    return #self.cards
end

-- Rebuilds the deck and shuffles
function Deck:reset()
    self:build()
    self:shuffle()
end
