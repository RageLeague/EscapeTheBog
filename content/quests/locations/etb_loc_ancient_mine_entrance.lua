local QDEF
QDEF = EscapeTheBogUtil.AddBogLocationQuest(
    {
        is_unique = true,
        entry_encounter = EscapeTheBogUtil.GenericInitialEncounterTable,
        repeat_encounter = EscapeTheBogUtil.NullEncounterTable,
        sleep_encounter = EscapeTheBogUtil.GenericSleepEncounterTable,

        on_init = function(quest)

        end,

        GetPathDesc = function(quest)
            return quest:GetLocalizedStr("DESC_1")
        end,
    },
    {
        name = "Ancient Mine Entrance",
        desc = "An entrance to an ancient mine. A power force emits from this location. Going here without adequate preparation is not recommended.",
        plax = "INT_Bog_Cave_01",
        show_agents = true,
        tags = {"cave", "bog", "mine_entrance", "dangerous"},
        indoors = true,
    },
    {"dangerous"}
)

QDEF:Loc{
    DESC_1 = "You can sense a powerful force coming from this path. Whatever down there must have been extremely powerful. If you wish to go there, you should be prepared.",
}
