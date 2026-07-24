--[[
    CS50 2D
    Truco Argentino

    The Selection class gives us a list of textual items that link to callbacks;
    this particular implementation only has one dimension of items (vertically),
    but a more robust implementation might include columns as well for a more
    grid-like selection, as seen in many kinds of interfaces and games.
]]

Selection = Class{}

function Selection:init(def)
    self.items = def.items
    self.x = def.x
    self.y = def.y

    self.height = def.height
    self.width = def.width
    self.font = def.font or gFonts['small']

    self.gapHeight = self.height / #self.items

    self.currentSelection = 1

    self.showCursor = def.showCursor == nil and true or def.showCursor
end

function Selection:update(dt)
    if love.keyboard.wasPressed('up') then
        if self.currentSelection == 1 then
            self.currentSelection = #self.items
        else
            self.currentSelection = self.currentSelection - 1
        end
        
        gSounds['blip']:stop()
        gSounds['blip']:play()
    elseif love.keyboard.wasPressed('down') then
        if self.currentSelection == #self.items then
            self.currentSelection = 1
        else
            self.currentSelection = self.currentSelection + 1
        end
        
        gSounds['blip']:stop()
        gSounds['blip']:play()
    elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
        local selection = self.items[self.currentSelection]
        
        -- disable menu option and allow to show a message
        if selection.disabled then
            if selection.onDisabledSelect then
                selection.onDisabledSelect()
            end
        elseif selection.onSelect then
            selection.onSelect()
        end
        
        gSounds['blip']:stop()
        gSounds['blip']:play()
    end
end

function Selection:render()
    love.graphics.setFont(self.font)
    
    local currentY = self.y

    for i, item in ipairs(self.items) do
        local paddedY = currentY + (self.gapHeight / 2) - self.font:getHeight() / 2

        -- draw selection marker if we're at the right index
        love.graphics.setColor(1, 1, 1, 1)
        if self.showCursor and i == self.currentSelection then
            love.graphics.draw(gTextures['cursor'], self.x - 8, paddedY)
        end

        if item.disabled then
            love.graphics.setColor(128/255, 128/255, 128/255, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end

        love.graphics.printf(item.text, self.x, paddedY, self.width, 'center')

        currentY = currentY + self.gapHeight
    end
    -- reset to white
    love.graphics.setColor(1, 1, 1, 1)
end