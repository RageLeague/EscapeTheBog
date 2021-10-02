local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,
}
:AddQuestLocation{
    cast_id = "main_location",
    name = "Deep Bog",
    desc = "The Deep Bog holds many dangers. Don't stay for too long now!",
    plax = "EXT_BOG_DEEPBOG",
    show_agents = true,
    tags = {"bog", "deepbog", "dangerous"},
}

EscapeTheBogUtil.AddBogExits(QDEF, 3)
