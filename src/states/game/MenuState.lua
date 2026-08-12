-- Title screen: the 40-card falling backdrop plus the match menu.

MenuState = Class{__includes = BaseState}

local FALL_ALPHA = 0.6              -- backdrop alpha
local SPEED_MIN, SPEED_MAX = 20, 50 -- fall card speed range
local SPIN = math.rad(25)           -- fall card spin

local ITEM_W, ITEM_H, ITEM_GAP = 120, 18, 4
local ITEM_X = (VIRTUAL_WIDTH - ITEM_W) / 2
local ITEM_Y0 = 118

-- Title with a dark drop shadow
local function printShadowed(text, y, alpha)
    love.graphics.setColor(0, 0, 0, (alpha or 1) * 0.8)
    love.graphics.printf(text, 1, y + 1, VIRTUAL_WIDTH, 'center')
    love.graphics.setColor(1, 1, 1, alpha or 1)
    love.graphics.printf(text, 0, y, VIRTUAL_WIDTH, 'center')
end

-- Respawn a falling card at a random margin
local function respawn(p)
    p.x = math.random(-CARD_W, VIRTUAL_WIDTH)
    p.y = -CARD_H - math.random(0, VIRTUAL_HEIGHT)
    p.speed = math.random(SPEED_MIN, SPEED_MAX)
    p.rotSpeed = (math.random() * 2 - 1) * SPIN
end

function MenuState:init()
    -- one particle per unique card
    self.cards = {}
    for _, card in ipairs(Deck().cards) do
        local p = { card = card, rot = math.random() * math.pi * 2 }
        respawn(p)
        -- seed spread over a band well above the screen to avoid rendering mid screen
        p.y = math.random(-VIRTUAL_HEIGHT, VIRTUAL_HEIGHT)
        self.cards[#self.cards + 1] = p
    end

    self.items = {
        { label = 'Play Match', action = function() self:startMatch('best_of_3') end },
        { label = 'Quick Chico', action = function() self:startMatch('single_chico') end },
        { label = 'Tournament', action = function()
            transition(function()
                gStateStack:pop()
                gStateStack:push(TournamentState())
            end)
        end },
    }
    self.selected = 1
    self.mouseWasDown = love.mouse.isDown(1)
    self.note = nil
end

-- Start a match with random opponent
function MenuState:startMatch(matchFormat)
    transition(function()
        gStateStack:pop()
        gStateStack:push(HandLoopState { matchFormat = matchFormat, aiName = randomName({}) })
    end)
end

function MenuState:itemRect(i)
    return ITEM_X, ITEM_Y0 + (i - 1) * (ITEM_H + ITEM_GAP), ITEM_W, ITEM_H
end

function MenuState:activate(i)
    local item = self.items[i]
    if item.disabled then
        self.note = item.label .. ' is not available yet'
    elseif item.action then
        item.action()
    end
end

function MenuState:update(dt)
    for _, p in ipairs(self.cards) do
        p.y = p.y + p.speed * dt
        p.rot = p.rot + p.rotSpeed * dt
        -- y is the top-left, so the card is fully past the bottom edge
        if p.y > VIRTUAL_HEIGHT then respawn(p) end
    end

    local clicked = consumeClick(self)

    -- hovering moves the highlight, so mouse and keyboard share one selection
    local mx, my = push.toGame(love.mouse.getPosition())
    if mx and my then
        for i = 1, #self.items do
            if pointInRect(mx, my, self:itemRect(i)) then
                self.selected = i
                if clicked then self:activate(i) return end
            end
        end
    end

    if love.keyboard.wasPressed('up') then
        self.selected = self.selected == 1 and #self.items or self.selected - 1
        self.note = nil
    elseif love.keyboard.wasPressed('down') then
        self.selected = self.selected == #self.items and 1 or self.selected + 1
        self.note = nil
    elseif love.keyboard.wasPressed('return') then
        self:activate(self.selected)
    end
end

function MenuState:render()
    clearBackground()

    -- backdrop first, so the title and menu sit on top of it
    for _, p in ipairs(self.cards) do
        drawCardFrontRot(p.card, p.x, p.y, p.rot, FALL_ALPHA)
    end

    love.graphics.setFont(gFonts['large'])
    printShadowed('Truco Argentino', 46)

    for i, item in ipairs(self.items) do
        local x, y, w, h = self:itemRect(i)
        local on = i == self.selected

        love.graphics.setColor(0, 0, 0, on and 0.75 or 0.5)
        love.graphics.rectangle('fill', x, y, w, h, 3, 3)
        love.graphics.setColor(1, 1, 1, item.disabled and 0.35 or (on and 1 or 0.7))
        love.graphics.rectangle('line', x, y, w, h, 3, 3)

        love.graphics.setFont(gFonts['small'])
        love.graphics.printf(item.label .. (item.disabled and '  (soon)' or ''),
            x, y + h / 2 - 4, w, 'center')
    end

    love.graphics.setFont(gFonts['small'])
    printShadowed(self.note or 'arrows + Enter, or click', VIRTUAL_HEIGHT - 16, 0.8)
end
