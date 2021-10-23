local oldfn = Widget.GraftSlot.Triggered
function Widget.GraftSlot:Triggered()
    if not self.graft then
        DBG(self)
    else
        return oldfn(self)
    end
end
