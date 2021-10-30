local patch_id = "FIX_NEGOTIATION_CHARGES_BUG"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local negotiation_defs = require "negotiation/negotiation_defs"
local EVENT = negotiation_defs.EVENT

local old_fn = Negotiation.MiniGame.BroadcastEvent

function Negotiation.MiniGame:BroadcastEvent(id, ...)
    if id == EVENT.END_RESOLVE then
        local engine, resolve_card = ...
        if resolve_card and resolve_card.userdata.charges == 0 then
            resolve_card:TransferCard( self.trash_deck )
            resolve_card:Consume()
        end
    end
    if old_fn then
        return old_fn(self, id, ...)
    else
        return Negotiation.MiniGame._base.BroadcastEvent(self, id, ...)
    end
end
