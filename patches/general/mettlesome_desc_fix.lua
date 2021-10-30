local patch_id = "METTLESOME_DESC_FIX"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

Content.GetBattleCondition("METTLESOME").desc_fn = function( self, fmt_str, battle )
    return loc.format(fmt_str, self:GetOwnerName(), self.stacks )
end
