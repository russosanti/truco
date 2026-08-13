-- Minimal shared drawing for the hand-loop phases

CARD_SCALE = 0.25
CARD_W = 130 * CARD_SCALE
CARD_H = 200 * CARD_SCALE
CARD_GAP = 6

function drawCardFront(card, x, y)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['deck-sheet'], gFrames['cards'][card.spriteQuadIndex],
        x, y, 0, CARD_SCALE, CARD_SCALE)
end

-- Same as drawCardFront but rotated about the card's center
function drawCardFrontRot(card, x, y, rot, alpha)
    love.graphics.setColor(1, 1, 1, alpha or 1)
    love.graphics.draw(gTextures['deck-sheet'], gFrames['cards'][card.spriteQuadIndex],
        x + CARD_W / 2, y + CARD_H / 2, rot, CARD_SCALE, CARD_SCALE, 130 / 2, 200 / 2)
end

function drawCardBack(x, y)
    love.graphics.setColor(1, 1, 1, 1)
    -- card_back.png is a standalone image, not part of the quad
    love.graphics.draw(gTextures['card-back'], x, y, 0, CARD_SCALE, CARD_SCALE)
end

-- x of the `index`-th card so a row of `count` cards sits centered
function cardRowX(index, count)
    local total = count * CARD_W + (count - 1) * CARD_GAP
    local startX = (VIRTUAL_WIDTH - total) / 2
    return startX + (index - 1) * (CARD_W + CARD_GAP)
end

function clearBackground()
    love.graphics.clear(24/255, 89/255, 53/255, 1)
end

function consumeClick(state)
    local mouseDown = love.mouse.isDown(1)
    local clicked = mouseDown and not state.mouseWasDown
    state.mouseWasDown = mouseDown
    return clicked
end

-- For clicking on card
function pointInRect(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

-- Draw a labeled button reused
function drawButton(label, x, y, w, h, hovered)
    love.graphics.setColor(hovered and 0.30 or 0.16, hovered and 0.42 or 0.26, hovered and 0.30 or 0.20, 1)
    love.graphics.rectangle('fill', x, y, w, h, 3, 3)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', x, y, w, h, 3, 3)
    love.graphics.setFont(gFonts['small'])
    love.graphics.printf(label, x, y + h / 2 - 4, w, 'center')
end

-- Shared HUD: score, this hand's mano and status line.
function drawHud(loop, status)
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print('Hand ' .. loop.handNumber, 4, 2)
    -- only a partida has a chico tally worth showing
    if loop.matchFormat == 'best_of_3' then
        love.graphics.print('chicos ' .. loop.chicosWon.player .. ' - ' .. loop.chicosWon.ai, 4, 12)
    end
    -- short form of the opponent's name
    local them = firstNameOf(loop.aiName or 'AI')
    love.graphics.printf('You ' .. loop.playerScore .. '  -  ' .. loop.aiScore .. ' ' .. them,
        0, 2, VIRTUAL_WIDTH - 4, 'right')
    love.graphics.printf('mano: ' .. (loop.mano == 'player' and 'You' or them),
        0, 12, VIRTUAL_WIDTH - 4, 'right')
    if status then
        love.graphics.printf(status, 0, VIRTUAL_HEIGHT - 12, VIRTUAL_WIDTH, 'center')
    end
end
