local GENERATORS =
{
    BOG_BURRS_TEAM = function(difficulty_level)
        local offensive_burrs = {"GROUT_KNUCKLE", "ETB_GROUT_EYE"}
        local extra_burrs = {"GROUT_BOG_CYST", "GROUT_LOOT_CLUSTER"}
        local t = {}
        for i = 1, math.min(difficulty_level, 4) do
            table.insert(t, table.arraypick(offensive_burrs))
        end
        if #t < 4 then
            table.insert(t, table.arraypick(extra_burrs))
        end
        return t
    end,
    BOG_MONSTERS_ETB = function(difficulty_level)
        local monsters = {}
        if (difficulty_level >= 3 and math.random() < 0.5) or difficulty_level >= 6 then
            table.insert(monsters, table.arraypick{"GRAWKIT", "LUMINTHIAN"})
            difficulty_level = difficulty_level - 3
        end
        local normal_monster = table.arraypick{{"FLEAD"}, {"ERCHIN"}, {"VROC"}}
        for i = 1, math.min(difficulty_level, 4 - #monsters) do
            table.insert(monsters, table.arraypick(normal_monster))
        end
        return monsters
    end,
}

for id, data in pairs(GENERATORS) do
    AddCombatPartyDef(id, data)
end
