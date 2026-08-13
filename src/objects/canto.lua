-- Call/response escalation. 
--
-- config = {
--   value    = { <callType> = number, ... },
--   isCeiling = function(callType) -> bool,     -- falta envido or vale cuatro
--   nextCalls = function(callsList) -> { types } -- raises available to the responder
-- }

Canto = Class{}

-- Starts already holding the opening call. Other player must response
function Canto:init(config, opener, openingType)
    self.config = config
    self.calls = {}
    self.cumulative = 0        -- sum of non ceiling call values
    self.lastCallValue = 0
    self.pendingIsCeiling = false
    self.caller = nil          -- who made the last call
    self.responder = nil       -- whose needs to answer
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

-- Available answers to last call (empty if ceiling)
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
