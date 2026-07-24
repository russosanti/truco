-- Throwaway opponent: picks a uniformly random card. PRD 6 replaces this
-- whole file; TrickState must keep all decision logic out here.

AiStub = {}

function AiStub.chooseCard(hand)
    return hand[math.random(#hand)]
end
