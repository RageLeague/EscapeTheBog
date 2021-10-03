local QDEF = QuestDef.Define
{
    title = "Escape The Bog",
    -- icon = engine.asset.Texture("icons/quests/sal_story_act1_huntingkashio.tex"),
    qtype = QTYPE.STORY,
    desc = "Find a way to get out of this place.",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/main_icon.png"),
    on_init = function(quest)

        TheGame:GetGameState():SetMainQuest(quest)

        quest:DefFn("GenerateBogMap", 10, "ETB_LOC_STARTING_BOGCAVE")
    end,

    GenerateBogMap = function(quest, map_count, starting_location, mandatory_locations)
        map_count = map_count or 0
        local quest_queue = {}
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
        -- Linking mandatory locations to existing ones
        for i, id in ipairs(mandatory_locations or {}) do
            table.shuffle(quest_queue)
            local spawned_quest = QuestUtil.SpawnQuest(id)
            local ok = false
            for i, target_quest in ipairs(quest_queue) do
                if spawned_quest:DefFn("AttachLocation", target_quest) then
                    ok = true
                    break
                end
            end
            assert(ok, loc.format("No entry generated for {1}", spawned_quest))
            table.insert(quest_queue, spawned_quest)
        end
        -- At this point everything should be connected.
        -- Now let's add alternative routes, probably
        while #quest_queue > 1 then
            table.shuffle(quest_queue)
            local quest_to_connect = quest_queue[#quest_queue]
            local ok = false
            for i = #quest_queue - 1, 1, -1 do
                if quest_to_connect:DefFn("AttachLocation", quest_queue[i]) then
                    ok = true
                    break
                end
            end
            if not ok or #quest_to_connect.param.available_exits == 0 then
                quest_queue[#quest_queue] = nil
            end
        end
    end,
}
