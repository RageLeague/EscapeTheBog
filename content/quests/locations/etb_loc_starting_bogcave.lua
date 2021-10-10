local QDEF = EscapeTheBogUtil.AddBogLocationQuest(
    {
        is_unique = true,
        entry_encounter = {
            ETB_STARTING_OUT = 1,
        },
        repeat_encounter = EscapeTheBogUtil.GenericRepeatEncounterTable,
    },
    {
        name = "Bog Cave",
        desc = "A cave in the middle of the bog. There does not appear to be any immediate danger, although there is not much here. If you want to survive, you should start moving.",
        plax = "INT_Bog_Cave_01",
        show_agents = true,
        tags = {"cave", "bog"},
        indoors = true,
    },
    {"deepbog", "deepbog"}
)
