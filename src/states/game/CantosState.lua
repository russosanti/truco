-- Empty betting/calls window -- the hook PRD 3 (envido) and PRD 4 (truco)
-- plug into. For now it just falls straight through to the tricks.

CantosState = Class{__includes = BaseState}

function CantosState:init(loop)
    self.loop = loop
end

function CantosState:enter()
    self.loop.machine:change('trick')
end
