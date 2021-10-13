

local QDEF = QuestDef.Define
{
    title = "Escape The Bog",
    -- icon = engine.asset.Texture("icons/quests/sal_story_act1_huntingkashio.tex"),
    qtype = QTYPE.STORY,
    desc = "Find a way to get out of this place.",

    difficulty_ranks = {1, 2, 3, 4, 5},
    monster_meat = {
        ERCHIN = "etb_mixed_monster_meat",
        FLEAD = "etb_mixed_monster_meat",
        VROC = "etb_mixed_monster_meat",
        GRAWKIT = "etb_big_game_meat",
        LUMINTHIAN = "etb_big_game_meat",
    },
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/main_icon.png"),
    on_init = function(quest)

        TheGame:GetGameState():SetMainQuest(quest)

        quest.param.time_segment = 0

        quest:DefFn("GenerateBogMap", 10, "ETB_LOC_STARTING_BOGCAVE")

        local player = TheGame:GetGameState():GetPlayerAgent()

        player:AddAspect("etb_hunger")
        player:AddAspect("etb_fatigue")

        for i, card in ipairs(player.negotiator:GetCards()) do
            quest:DefFn("AddUsageLimitToCard", card)
        end

        for i, card in ipairs(player.battler:GetCards()) do
            quest:DefFn("AddUsageLimitToCard", card)
        end

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
        card_added = function( quest, card )
            quest:DefFn("AddUsageLimitToCard", card)
        end,
        card_upgraded = function( quest, card )
            quest:DefFn("AddUsageLimitToCard", card)
        end,
        resolve_battle = function( quest, battle, primary_enemy, repercussions )
            print("Look at me, I am adding death loots")
            for i, fighter in battle:AllFighters() do
                print(fighter)
                if fighter.team == battle:GetEnemyTeam() and fighter.agent and fighter:IsDead() then
                    print("Loot for", fighter.agent)
                    local id = fighter.agent:GetContentID()
                    if quest:GetQuestDef().monster_meat[id] then
                        print("Loot for", fighter.agent)
                        table.insert(repercussions.loot.items, quest:GetQuestDef().monster_meat[id])
                    end
                end
            end
        end,
    },

    AddUsageLimitToCard = function(quest, card)
        if is_instance(card, Negotiation.Card) then
            local negotiation_defs = require "negotiation/negotiation_defs"
            if CheckBits( card.flags, negotiation_defs.CARD_FLAGS.CONSUME ) then
                return
            end
        end
        if is_instance(card, Battle.Card) then
            local battle_defs = require "battle/battle_defs"
            if CheckBits( card.flags, battle_defs.CARD_FLAGS.CONSUME ) then
                return
            end
        end
        if (not card.userdata.charges) then
            card.userdata.max_charges = 15
            card.userdata.charges = card.userdata.charges or card.userdata.max_charges
        end
    end,

    AdvanceTime = function(quest, amt, reason)
        local old_time = {datetime = TheGame:GetGameState():GetDateTime(), segment = (quest.param.time_segment or 0)}
        quest.param.time_segment = (quest.param.time_segment or 0) + amt
        while quest.param.time_segment >= 6 do
            quest.param.time_segment = (quest.param.time_segment or 0) - 6
            TheGame:GetGameState():AdvanceTime()
            local current_day = math.floor( TheGame:GetGameState():GetDateTime() / 2 ) + 1
            local ranks = quest:GetQuestDef().difficulty_ranks

            TheGame:GetGameState():SetDifficulty(ranks[math.min(current_day, #ranks)])
        end
        local new_time = {datetime = TheGame:GetGameState():GetDateTime(), segment = (quest.param.time_segment or 0)}
        for i, agent in TheGame:GetGameState():GetCaravan():Members() do
            if agent.sorted_aspects then
                for i, aspect in ipairs(agent.sorted_aspects) do
                    if aspect.OnTimeSegmentPassETB then
                        aspect:OnTimeSegmentPassETB(old_time, new_time, amt, reason)
                    end
                end
            end
        end
        quest:NotifyChanged()
        TheGame:GetEvents():BroadcastEvent( "update_overlay" )
        local screen = TheGame:FE():FindScreen( Screen.LocationScreen )
        if screen then
            screen:UpdateDayPhase()
            screen:RefreshPlaxClickables(true)
        end
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

    RequestRiffleShuffle = function(quest, id, ...)
        local params = {...}
        local possibility_table = params[1]
        if not quest.param.RIFFLE_DATA then
            quest.param.RIFFLE_DATA = {}
        end
        if not quest.param.RIFFLE_DATA[id] or #quest.param.RIFFLE_DATA[id] == 0 then
            if #params >= 2 then
                local minbound, maxbound, delta = ...
                possibility_table = {}
                for i = minbound, maxbound, delta or 1 do
                    table.insert(possibility_table, i)
                end
            end
            quest.param.RIFFLE_DATA[id] = shallowcopy(possibility_table)
        end


        local chosen = table.arraypick(quest.param.RIFFLE_DATA[id])
        table.arrayremove(quest.param.RIFFLE_DATA[id], chosen)
        if #quest.param.RIFFLE_DATA[id] == 0 then
            quest.param.RIFFLE_DATA[id] = nil
        end
        return chosen
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
:AddCastByAlias{
    cast_id = "bog_monster",
    alias = "THE_BOG_ETB",
    no_validation = true,
}

QDEF:AddConvo()
    :Confront(function(cxt)
        if not cxt.player then return end
        if cxt.player.etb_hunger and cxt.player.etb_hunger.player_starved then
            return "STATE_STARVED"
        end
        if cxt.player.etb_fatigue and cxt.player.etb_fatigue.passed_out then
            return "STATE_PASSED_OUT"
        end
    end)
    :State("STATE_STARVED")
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
                    I can't... Go on... Anymore...
                * You passed out from starvation.
            ]],
            DIALOG_INTRO_PST = [[
                * ...
                * ...
                * ...
                * This is a sleep that you are never going to wake up.
                * The bog has claimed yet another victim.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt:FadeOut()
            cxt:Dialog("DIALOG_INTRO_PST")
            cxt:Opt("OPT_ACCEPT_DEATH_ETB")
                :Fn(function(cxt)
                    cxt.enc:PlayerDeath()
                end)
        end)
    :State("STATE_PASSED_OUT")
        :Loc{
            DIALOG_SLEEP_EXHAUSTED = [[
                player:
                    !left
                    I think I will just...
                * You passed out like a load of bricks.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_SLEEP_EXHAUSTED")
            cxt:FadeOut()

            EscapeTheBogUtil.DoSleepConvo(cxt)
        end)
