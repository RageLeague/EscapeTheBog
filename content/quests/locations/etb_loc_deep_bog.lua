local QDEF = EscapeTheBogUtil.AddBogLocationQuest(
    {
        quest_weight = 3,
        entry_encounter = {
            -- ETB_STARTING_OUT = 1,
            ETB_NO_EVENT = 1,
        },
        repeat_encounter = {
            ETB_NO_EVENT = 1,
        },
    },
    {
        name = "Deep Bog",
        desc = "The Deep Bog holds many dangers. Don't stay for too long now!",
        plax = "EXT_BOG_DEEPBOG",
        show_agents = true,
        tags = {"bog", "deepbog", "dangerous"},
    },
    3
)
