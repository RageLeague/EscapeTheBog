local patch_id = "FIX_CAN_INSTALL_GRAFT"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS

local oldfn = Negotiation.Card.ConsumeCharge

function Negotiation.Card:ConsumeCharge()
    oldfn(self)
    if self:IsSpent() then
        self:SetFlags( CARD_FLAGS.CONSUME )
    end
end
