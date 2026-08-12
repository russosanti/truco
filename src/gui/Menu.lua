--[[
    Truco Argentino
    A Menu is simply a Selection layered onto a Panel.
]]

Menu = Class{}

function Menu:init(def)
    self.panel = Panel(def.x, def.y, def.width, def.height)
    
    self.selection = Selection {
        items = def.items,
        x = def.x,
        y = def.y,
        width = def.width,
        height = def.height,
        showCursor = def.showCursor,
        font = def.font
    }
end

function Menu:update(dt)
    self.selection:update(dt)
end

function Menu:render()
    self.panel:render()
    self.selection:render()
end