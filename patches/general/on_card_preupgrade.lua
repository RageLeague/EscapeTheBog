local patch_id = "ON_CARD_PREUPGRADE"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = CardEngine.Card.UpgradeCard

function CardEngine.Card:UpgradeCard(...)
    if not self.engine then
        TheGame:BroadcastEvent("on_pre_card_upgrade", self, ...)
    end
    return old_fn(self, ...)
end
