local QDEF = QuestDef.Define
{
    title = "Escape The Bog",
    -- icon = engine.asset.Texture("icons/quests/sal_story_act1_huntingkashio.tex"),
    qtype = QTYPE.STORY,
    desc = "Find a way to get out of this place.",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/main_icon.png"),
    on_init = function(quest)

        TheGame:GetGameState():SetMainQuest(quest)

        quest:DefFn("GenerateBogMap", 30, {"ETB_LOC_STARTING_BOGCAVE", "ETB_LOC_DEEP_BOG"})
    end,

    GenerateBogMap = function(quest, map_count, mandatory_locations)
        local quest_queue = {}
        for i, id in ipairs(mandatory_locations or {}) do
            table.insert(quest_queue, QuestUtil.SpawnQuest(id))
        end
        print(quest_queue[1]:DefFn("CanAttachLocation", quest_queue[2]))
        print(quest_queue[1]:DefFn("AttachLocation", quest_queue[2]))
    end,
}
