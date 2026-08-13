-- Textbox Class modified from CS50

Textbox = Class{}

local PAD_X, PAD_Y = 24, 16

function Textbox:init(text, y, font)
    self.font = font or gFonts['small']
    self.text = text
    self.y = y

    local maxWidth = VIRTUAL_WIDTH - 8
    local lines = { text }
    self.width = self.font:getWidth(text) + PAD_X
    if self.width > maxWidth then
        self.width = maxWidth
        _, lines = self.font:getWrap(text, self.width - PAD_X)
    end

    self.height = #lines * self.font:getHeight() + PAD_Y
    self.x = (VIRTUAL_WIDTH - self.width) / 2
    self.panel = Panel(self.x, self.y, self.width, self.height)
end

function Textbox:render()
    self.panel:render()
    love.graphics.setFont(self.font)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(self.text, self.x, self.y + PAD_Y / 2, self.width, 'center')
end
