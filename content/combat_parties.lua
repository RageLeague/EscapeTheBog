local GENERATORS =
{
    BOG_BURRS_TEAM = function(difficulty_level)
        local offensive_burrs = {"GROUT_KNUCKLE", "ETB_GROUT_EYE"}
        local extra_burrs = {"GROUT_BOG_CYST", "GROUT_KNUCKLE", "ETB_GROUT_EYE", "GROUT_LOOT_CLUSTER"}
        local t = {}
        for i = 1, math.min(difficulty_level, 4) do
            table.insert(t, table.arraypick(offensive_burrs))
        end
        if #t < 4 then
            table.insert(t, table.arraypick(extra_burrs))
        end
        return t
    end,
}

for id, data in pairs(GENERATORS) do
    AddCombatPartyDef(id, data)
end
