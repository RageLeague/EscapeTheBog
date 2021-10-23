local patch_id = "NIL_CHECK_GRAFT_TRIGGER"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local oldfn = Widget.MainOverlayGraftsContainer.FindWidget

function Widget.MainOverlayGraftsContainer:FindWidget(graft, ...)
    if not graft then
        return
    end
    return oldfn(self, graft, ...)
end
