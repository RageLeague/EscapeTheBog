local BATTLE_FOOD_DEFS =
{
    half_sandwich =
    {
        hunger_restoration = 2,
        health_gain = 4,
    },
    bog_brew =
    {
        hunger_restoration = 1,
        health_gain = 8,
    },
    hawb_drumstick =
    {
        hunger_restoration = 2,
        health_gain = 8,
    },
    pickled_floater =
    {
        hunger_restoration = 1,
        resolve_gain = 5,
    },
}

for id, data in pairs(BATTLE_FOOD_DEFS) do
    local battle_def = Content.GetBattleCard( id )
    if battle_def then
        battle_def.food_data_etb = data
    end
end
