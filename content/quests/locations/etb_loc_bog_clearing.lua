local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,
}
:AddQuestLocation{
    cast_id = "main_location",
    name = "Bog Clearing",
    desc = "A clearing in the bog. A rare place of respite here.",
    plax = "EXT_Bog_HedgeGod_01",
    show_agents = true,
    tags = {"bog", "campsite", "clearing"},
}

EscapeTheBogUtil.AddBogExits(QDEF, {"dangerous", "dangerous"})
