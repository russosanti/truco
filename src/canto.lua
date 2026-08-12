-- Family-agnostic call/response escalation. Envido uses it now; Truco (PRD 4)
-- plugs its own config in. Pure logic (no LÖVE): the host applies the outcome.
--
-- config = {
--   value    = { <callType> = number, ... },   -- non-ceiling call values
--   isCeiling = function(callType) -> bool,     -- falta / vale cuatro
--   nextCalls = function(callsList) -> { types } -- raises available to the responder
-- }

Canto = Class{}

-- Starts already holding the opening call; the other side must respond.
function Canto:init(config, opener, openingType)
    self.config = config
    self.calls = {}
    self.cumulative = 0        -- sum of non-ceiling call values
    self.lastCallValue = 0
    self.pendingIsCeiling = false
    self.caller = nil          -- who made the pending (last) call
    self.responder = nil       -- whose turn to answer it
    self.resolved = false
    self.outcome = nil
    self:pushCall(opener, openingType)
end

function Canto:pushCall(side, callType)
    table.insert(self.calls, callType)
    self.caller = side
    self.pendingIsCeiling = self.config.isCeiling(callType)
    if not self.pendingIsCeiling then
        self.cumulative = self.cumulative + self.config.value[callType]
        self.lastCallValue = self.config.value[callType]
    end
    self.responder = otherSide(side)
end

-- What the current responder may raise to (empty once a ceiling is on the table).
function Canto:availableRaises()
    return self.config.nextCalls(self.calls)
end

function Canto:raise(callType)
    self:pushCall(self.responder, callType)  -- responder becomes the new caller
end

function Canto:accept() self:close('accept') end
function Canto:reject() self:close('reject') end

function Canto:close(kind)
    self.resolved = true
    self.outcome = {
        kind = kind,
        caller = self.caller,
        cumulative = self.cumulative,
        lastCallValue = self.lastCallValue,
        ceiling = self.pendingIsCeiling,
    }
end
