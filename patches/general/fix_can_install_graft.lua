local patch_id = "FIX_CAN_INSTALL_GRAFT"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Aspect.GraftOwner.CanInstallGraft

function Aspect.GraftOwner:CanInstallGraft(graft_id, ...)
    local ok, reason = old_fn(self, graft_id, ...)

    if not ok and reason == "too many" then
        local def = Content.GetGraft(graft_id)
        if def.type == GRAFT_TYPE.SOCIAL then
            return true
        end
    end

    return ok, reason
end
