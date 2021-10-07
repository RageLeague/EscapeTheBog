local QDEF = QuestDef.Define
{
    title = "Escape The Bog",
    -- icon = engine.asset.Texture("icons/quests/sal_story_act1_huntingkashio.tex"),
    qtype = QTYPE.STORY,
    desc = "Find a way to get out of this place.",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/main_icon.png"),
    on_init = function(quest)

        TheGame:GetGameState():SetMainQuest(quest)

        quest.param.time_segment = 0

        quest:DefFn("GenerateBogMap", 10, "ETB_LOC_STARTING_BOGCAVE")

        TheGame:GetGameState():GetCaravan():MoveToLocation(quest.param.starting_location:GetCastMember("main_location"))
    end,

    get_narrative_progress = function(quest)

        local time_segment_id = "TIME_SEG_" .. (TheGame:GetGameState():GetDayPhase() == DAY_PHASE.DAY and "DAY" or "NIGHT") .. "_" .. ((quest.param.time_segment or 0) + 1)
        local current_day = math.floor( TheGame:GetGameState():GetDateTime() / 2 ) + 1

        local title = loc.format(quest:GetLocalizedStr("TIME_DISPLAY"), quest:GetLocalizedStr(time_segment_id), current_day)
        return (TheGame:GetGameState():GetDateTime() * 6 + (quest.param.time_segment or 0)) / 12, title, TheGame:GetGameState():GetPlayerAgent():GetLocation():GetName()
    end,

    events = {
        on_convo_speech = function(quest, params)
            local agent, txt = table.unpack(params)
            if not (agent:IsPlayer()) and agent:IsSentient() then
                params[2] = EscapeTheBogUtil.ObfuscateWords(txt)
            end
        end,
    },

    AdvanceTime = function(quest, amt)
        quest.param.time_segment = (quest.param.time_segment or 0) + amt
        while quest.param.time_segment >= 6 do
            quest.param.time_segment = (quest.param.time_segment or 0) - 6
            TheGame:GetGameState():AdvanceTime()
        end
        quest:NotifyChanged()
        TheGame:GetEvents():BroadcastEvent( "update_overlay" )
    end,

    GenerateBogMap = function(quest, map_count, starting_location, mandatory_locations)
        map_count = map_count or 0
        local quest_queue = {}
        table.insert(quest_queue, QuestUtil.SpawnQuest(starting_location))
        -- print(quest_queue[1]:DefFn("CanAttachLocation", quest_queue[2]))
        -- print(quest_queue[1]:DefFn("AttachLocation", quest_queue[2]))
        quest.param.starting_location = quest_queue[1]
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
                            table.insert(tag_cache[chosen_tag], (qdef.quest_weight or 1))
                        end
                    end
                end
            end
            if #tag_cache[chosen_tag] > 0 then
                local choice = weighted_arraypick(tag_cache[chosen_tag])
                local new_quest = QuestUtil.SpawnQuest(choice)
                chosen_quest:DefFn("AttachLocation", new_quest)
                quest_queue[idx] = new_quest
                if #chosen_quest.param.available_exits > 0 then
                    table.insert(quest_queue, chosen_quest)
                end
            end
        end
        -- DBG(tag_cache)
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
        while #quest_queue > 1 do
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
:Loc{
    TIME_SEG_DAY_1 = "Sunrise",
    TIME_SEG_DAY_2 = "Morning",
    TIME_SEG_DAY_3 = "Day",
    TIME_SEG_DAY_4 = "Noon",
    TIME_SEG_DAY_5 = "Afternoon",
    TIME_SEG_DAY_6 = "Sunset",
    TIME_SEG_NIGHT_1 = "Dusk",
    TIME_SEG_NIGHT_2 = "Evening",
    TIME_SEG_NIGHT_3 = "Night",
    TIME_SEG_NIGHT_4 = "Midnight",
    TIME_SEG_NIGHT_5 = "Early Morning",
    TIME_SEG_NIGHT_6 = "Dawn",
    TIME_DISPLAY = "{1} {2}",
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}
