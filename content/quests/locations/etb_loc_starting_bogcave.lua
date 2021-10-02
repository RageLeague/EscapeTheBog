local QDEF = EscapeTheBogUtil.AddBogLocationQuest(
    nil,
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
