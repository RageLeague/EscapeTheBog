local QDEF = EscapeTheBogUtil.AddBogLocationQuest(
    {
        entry_encounter = {
            -- ETB_STARTING_OUT = 1,
            ETB_NO_EVENT = 1,
        },
        repeat_encounter = {
            ETB_NO_EVENT = 1,
        },
    },
    {
        name = "Bog Clearing",
        desc = "A clearing in the bog. A rare place of respite here.",
        plax = "EXT_Bog_HedgeGod_01",
        show_agents = true,
        tags = {"bog", "campsite", "clearing"},
    },
    {"dangerous", "dangerous"}
)
