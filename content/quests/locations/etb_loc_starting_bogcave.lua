local QDEF = EscapeTheBogUtil.AddBogLocationQuest(
    {
        is_unique = true,
        entry_encounter = {
            ETB_STARTING_OUT = 1,
        },
        repeat_encounter = {
            ETB_NO_EVENT = 1,
        },
    },
    {
        name = "Bog Cave",
        desc = "A cave in the middle of the bog. Not a great place to be.",
        plax = "INT_Bog_Cave_01",
        show_agents = true,
        tags = {"cave", "bog"},
        indoors = true,
    },
    {"deepbog", "deepbog"}
)
