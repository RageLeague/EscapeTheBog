local QDEF
QDEF = EscapeTheBogUtil.AddBogLocationQuest(
    {
        entry_encounter = EscapeTheBogUtil.GenericInitialEncounterTable,
        repeat_encounter = EscapeTheBogUtil.NullEncounterTable,

        GetPathDesc = function(quest)
            if not quest.param.desc_number then
                quest.param.desc_number = EscapeTheBogUtil.TryMainQuestFn("RequestRiffleShuffle", QDEF.id .. "_DESC", 1, 5) -- math.random(1, 5)
            end
            local desc = {}
            table.insert(desc, quest:GetLocalizedStr("DESC_" .. quest.param.desc_number))
            return table.concat(desc, "\n")
        end,
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

QDEF:Loc{
    DESC_1 = "This path leads to a large open area. It is a rare occurrence in the bog.",
    DESC_2 = "This path leads to a large rock tablet looking thing. The area in front of it is open.",
    DESC_3 = "This path leads to some sort of... shrine? Why would a shrine doing in the bog? Either way, there seems to be a clear area near it.",
    DESC_4 = "There is a ray of light coming down from this path. It is neither spark or lumin in nature, judging from the coloring.",
    DESC_5 = "You swear you saw some shadowy figures walking down this path. Probably just your imagination.",
}
