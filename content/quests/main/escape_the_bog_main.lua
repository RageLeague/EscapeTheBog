local QDEF = QuestDef.Define
{
    title = "Escape The Bog",
    -- icon = engine.asset.Texture("icons/quests/sal_story_act1_huntingkashio.tex"),
    qtype = QTYPE.STORY,
    desc = "Find a way to get out of this place.",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/main_icon.png"),
    on_init = function(quest)

        TheGame:GetGameState():SetMainQuest(quest)

        quest:DefFn("GenerateBogMap", 30, "ETB_LOC_STARTING_BOGCAVE")
    end,

    GenerateBogMap = function(quest, map_count, starting_location, mandatory_locations)
        map_count = map_count or 0
        local quest_queue = {}
        -- for i, id in ipairs(mandatory_locations or {}) do
        --     table.insert(quest_queue, QuestUtil.SpawnQuest(id))
        -- end
        table.insert(quest_queue, QuestUtil.SpawnQuest(starting_location))
        -- print(quest_queue[1]:DefFn("CanAttachLocation", quest_queue[2]))
        -- print(quest_queue[1]:DefFn("AttachLocation", quest_queue[2]))
        quest.param.current_location = quest_queue[1]
        local tag_cache = {}
        while map_count > 0 do
            map_count = map_count - 1
            local idx = math.random(1, #quest_queue)
            local chosen_quest = quest_queue[idx]
            chosen_quest:DefFn("SetupLocationData")
            local chosen_tag = table.arraypick(chosen_quest.param.available_exits)
            if not tag_cache[chosen_tag] then
                tag_cache[chosen_tag] = {}
                for i, id in ipairs(EscapeTheBogUtil.BOG_LOCATION_QUESTS) do
                    local qdef = Content.GetQuestDef( id )
                    if not qdef.is_unique then
                        local loc_id = string.format( "%s_main_location", qdef.id)
                        if chosen_tag == "any" or table.arraycontains(Content.GetLocationContent(loc_id).tags or {}, chosen_tag) then
                            table.insert(tag_cache[chosen_tag], id)
                        end
                    end
                end
            end
            if #tag_cache[chosen_tag] > 0 then
                local new_quest = QuestUtil.SpawnQuest(starting_location)
                chosen_quest:DefFn("AttachLocation", new_quest)
                quest_queue[idx] = new_quest
                if #chosen_quest.param.available_exits > 0 then
                    table.insert(quest_queue, chosen_quest)
                end
            end
        end
    end,
}
