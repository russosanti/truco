-- Minimal shared drawing for the hand-loop phases (PRD 2 — functional, not
-- final art; PRD 7 owns real presentation).

CARD_SCALE = 0.25
CARD_W = 130 * CARD_SCALE
CARD_H = 200 * CARD_SCALE
CARD_GAP = 6

function drawCardFront(card, x, y)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['deck-sheet'], gFrames['cards'][card.spriteQuadIndex],
        x, y, 0, CARD_SCALE, CARD_SCALE)
end

-- Same as drawCardFront but rotated about the card's center; (x,y) stays the
-- top-left anchor. Origin is in unscaled image space, so at rot=0 this is
-- pixel-identical to drawCardFront.
function drawCardFrontRot(card, x, y, rot)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['deck-sheet'], gFrames['cards'][card.spriteQuadIndex],
        x + CARD_W / 2, y + CARD_H / 2, rot, CARD_SCALE, CARD_SCALE, 130 / 2, 200 / 2)
end

function drawCardBack(x, y)
    love.graphics.setColor(1, 1, 1, 1)
    -- card_back.png is a standalone image, not part of the quad sheet
    love.graphics.draw(gTextures['card-back'], x, y, 0, CARD_SCALE, CARD_SCALE)
end

-- x of the `index`-th card so a row of `count` cards sits centered
function cardRowX(index, count)
    local total = count * CARD_W + (count - 1) * CARD_GAP
    local startX = (VIRTUAL_WIDTH - total) / 2
    return startX + (index - 1) * (CARD_W + CARD_GAP)
end

-- Is (px,py) inside the rect? Shared by the click-driven call UIs.
function pointInRect(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

-- A labeled button; brighter fill when hovered. Generic, reused by call UIs.
function drawButton(label, x, y, w, h, hovered)
    love.graphics.setColor(hovered and 0.30 or 0.16, hovered and 0.42 or 0.26, hovered and 0.30 or 0.20, 1)
    love.graphics.rectangle('fill', x, y, w, h, 3, 3)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', x, y, w, h, 3, 3)
    love.graphics.setFont(gFonts['small'])
    love.graphics.printf(label, x, y + h / 2 - 4, w, 'center')
end

-- Shared HUD: score, this hand's mano, and a per-phase status line.
function drawHud(loop, status)
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print('Hand ' .. loop.handNumber, 4, 2)
    -- only a partida has a chico tally worth showing
    if loop.matchFormat == 'best_of_3' then
        love.graphics.print('chicos ' .. loop.chicosWon.human .. ' - ' .. loop.chicosWon.ai, 4, 12)
    end
    love.graphics.printf('You ' .. loop.humanScore .. '  -  ' .. loop.aiScore .. ' AI',
        0, 2, VIRTUAL_WIDTH - 4, 'right')
    love.graphics.printf('mano: ' .. tostring(loop.mano), 0, 12, VIRTUAL_WIDTH - 4, 'right')
    if status then
        love.graphics.printf(status, 0, VIRTUAL_HEIGHT - 12, VIRTUAL_WIDTH, 'center')
    end
end
