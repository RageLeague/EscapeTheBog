local QDEF
QDEF = EscapeTheBogUtil.AddBogLocationQuest(
    {
        is_unique = true,
        entry_encounter = {
            ETB_FINAL_ENCOUNTER = 1,
        },
        repeat_encounter = EscapeTheBogUtil.NullEncounterTable,
        sleep_encounter = EscapeTheBogUtil.NullEncounterTable,

        on_init = function(quest)

        end,

        GetPathDesc = function(quest)
            return quest:GetLocalizedStr("DESC_1")
        end,
    },
    {
        name = "Ancient Mine",
        desc = "Home to an ancient and powerful being, and the source of your current madness. Going here without adequate preparation is not recommended.",
        plax = "INT_BOG_MINE",
        show_agents = true,
        tags = {"cave", "bog", "ancient_mine"},
        indoors = true,
    },
    {}
)

QDEF:Loc{
    DESC_1 = "You can sense a powerful force coming from this path. Whatever down there must have been extremely powerful. If you wish to go there, you should be prepared.",
}
