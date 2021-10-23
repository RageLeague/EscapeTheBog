local EscapeTheBogUtil = class("EscapeTheBogUtil")

function EscapeTheBogUtil.TryMainQuestFn(id, ...)
    local arguments = {...}
    local ok, result = xpcall(function(...) return TheGame:GetGameState():GetMainQuest():DefFn(id, ...) end, generic_error, ...)
        -- print(loc.format("Call main quest fn: {1} (params: {2#listing})", id, arguments))
    -- print(ok, id, ...)
    -- print(result)
    if not ok then
        print(result)
    end
    return result
end

function EscapeTheBogUtil.AddBogExits(qdef, exit_defs)
    if type(exit_defs) == "number" then
        local res = {}
        for i = 1, exit_defs do
            table.insert(res, "bog")
        end
        exit_defs = res
    end
    qdef.exit_defs = shallowcopy(exit_defs)
end

EscapeTheBogUtil.BOG_LOCATION_QUESTS = {}

function EscapeTheBogUtil.AddBogLocationQuest(quest_def, location_def, exit_defs)
    quest_def = quest_def or {}
    if not quest_def.events then
        quest_def.events = {}
    end
    quest_def.events.caravan_move_location = function(quest, location)
        if location == quest:GetCastMember("main_location") then
            if quest.param.current_event and quest.param.current_event:IsActive() then
                -- Currently has an associated event. You probably need to deal with it first.
                return
            end
            local encounter_table = (not quest.param.visited_location) and quest:GetQuestDef().entry_encounter or quest:GetQuestDef().repeat_encounter
            if type(encounter_table) == "function" then
                encounter_table = encounter_table(TheGame:GetGameState():GetCurrentBaseDifficulty(), quest, location)
            elseif not encounter_table then
                encounter_table = {}
            else
                encounter_table = shallowcopy(encounter_table)
            end
            local q
            while not q and next(encounter_table) do
                local chosen_event = weightedpick(encounter_table)
                q = QuestUtil.SpawnQuest(chosen_event, {parameters = {location = location}})
                encounter_table[chosen_event] = nil
            end
            if not q then
                q = QuestUtil.SpawnQuest("ETB_NO_EVENT", {parameters = {location = location}})
            end
            quest.param.current_event = q
            quest.param.visited_location = true
        end
    end

    local t = debug.getinfo( 2 )
    print(t.short_src)
    local QDEF = QuestDef.Define
    {
        qtype = QTYPE.STORY,
        id = quest_def.id or t.short_src:match( "/?([%w_]+)[.]lua$" ):upper(),
        is_bog_location = true,

        SetupLocationData = function(quest)
            if not quest.param.available_exits then
                quest.param.available_exits = shallowcopy(quest:GetQuestDef().exit_defs)
            end
            if not quest.param.exits then
                quest.param.exits = {}
            end
        end,

        CanAttachLocation = function(quest, other_quest)
            if not other_quest:GetQuestDef().is_bog_location then
                return false, "Not a bog location"
            end
            quest:DefFn("SetupLocationData")
            other_quest:DefFn("SetupLocationData")
            local selftag
            for i, tag in ipairs(quest.param.available_exits) do
                if tag == "any" or other_quest:GetCastMember("main_location"):HasTag(tag) then
                    selftag = tag
                    break
                end
            end
            if not selftag then
                return false, "No matching tag"
            end
            local othertag
            for i, tag in ipairs(other_quest.param.available_exits) do
                if tag == "any" or quest:GetCastMember("main_location"):HasTag(tag) then
                    othertag = tag
                    break
                end
            end
            if not othertag then
                return false, "No matching tag"
            end
            return true, selftag, othertag
        end,
        ForceAttachLocation = function(quest, other_quest)
            assert(quest.param.exits, "No exits params")
            assert(other_quest.param.exits, "No exits params")
            table.insert(quest.param.exits, other_quest)
            table.insert(other_quest.param.exits, quest)
        end,
        AttachLocation = function(quest, other_quest)
            if not other_quest:GetQuestDef().is_bog_location then
                return false, "Not a bog location"
            end
            quest:DefFn("SetupLocationData")
            other_quest:DefFn("SetupLocationData")
            table.shuffle(quest.param.available_exits)
            table.shuffle(other_quest.param.available_exits)
            local ok, selftag, othertag = quest:DefFn("CanAttachLocation", other_quest)
            if not ok then
                return false, selftag
            end

            -- table.insert(quest.param.exits, other_quest)
            -- table.insert(other_quest.param.exits, quest)
            quest:DefFn("ForceAttachLocation", other_quest)
            table.arrayremove(quest.param.available_exits, selftag)
            table.arrayremove(other_quest.param.available_exits, othertag)
            return true
        end,
    }
    for id, data in pairs(quest_def or {}) do
        QDEF[id] = data
    end

    QDEF:AddQuestLocation(table.extend{
        cast_id = "main_location",
        show_player = true,
    }(location_def))

    table.insert(EscapeTheBogUtil.BOG_LOCATION_QUESTS, QDEF.id)

    EscapeTheBogUtil.AddBogExits(QDEF, exit_defs)

    QDEF:AddObjective{
        id = "start",
        state = QSTATUS.ACTIVE,
    }
    if not QDEF.no_default_leave then
        QDEF:AddConvo()
            :Hub_Location( function( cxt, who )
                if cxt.location ~= cxt:GetCastMember("main_location") then
                    return
                end

                -- cxt:Opt("OPT_SLEEP_ETB")
                --     :ReqCondition(not cxt.player.etb_fatigue or cxt.player.etb_fatigue:CanSleep(), "REQ_CAN_SLEEP_ETB")
                --     :Fn( function(cxt)
                --         UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_SLEEP" , nil, nil, cxt.quest)
                --     end )

                cxt:Opt("OPT_TRAVEL_ETB")
                    :MakeUnder()
                    :Fn( function(cxt)
                        UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_MOVE" , nil, nil, cxt.quest)
                    end )
            end )
            :State("STATE_MOVE")
                :Fn(function(cxt)
                    local function AddExitOption(exit)
                        local location = exit:GetCastMember("main_location")
                        cxt:Opt(cxt.quest.param.previous_location == exit and "OPT_RETURN_TO_ETB" or "OPT_MOVE_TO_ETB", location)
                            :PostText(exit:DefFn("GetPathDesc"))
                            :Dialog("DIALOG_MOVE_TO_ETB", location)
                            :Fn( function(cxt)
                                exit.param.previous_location = cxt.quest
                                cxt.encounter:DoLocationTransition( location )
                                EscapeTheBogUtil.TryMainQuestFn("AdvanceTime", 1, "TRAVEL")

                                -- TheGame:GetGameState():GetCaravan():MoveToLocation( location )
                                cxt:End()
                            end )
                    end
                    local exit_length = #cxt.quest.param.exits
                    local end_idx = table.arrayfind(cxt.quest.param.exits, cxt.quest.param.previous_location) or exit_length
                    for i = end_idx + 1, exit_length do
                        local exit = cxt.quest.param.exits[i]
                        AddExitOption(exit)
                    end
                    for i = 1, end_idx do
                        local exit = cxt.quest.param.exits[i]
                        AddExitOption(exit)
                    end
                    StateGraphUtil.AddBackButton(cxt)
                end)
    end
    assert(QDEF.GetPathDesc, "No GetPathDesc defined")
    return QDEF
end

function EscapeTheBogUtil.IsETBCampaign(act_id)
    if not act_id then
        act_id = TheGame:GetGameState():GetCurrentActID()
    end
    if not act_id then
        return false
    end
    return string.find(act_id, "ESCAPE_THE_BOG")
end

function EscapeTheBogUtil.ETBActFilter(self, act_id)
    return EscapeTheBogUtil.IsETBCampaign(act_id)
end

function EscapeTheBogUtil.NullEncounterTable()
    return {
        ETB_NO_EVENT = 1,
    }
end

function EscapeTheBogUtil.GenericRepeatEncounterTable(difficulty, quest, location)
    local t = {
        ETB_NO_EVENT = 5,
    }
    if location:HasTag("bog") then
        if difficulty <= 3 and not location:IsIndoors() then
            t.ETB_BOG_BURR_ATTACK = TheGame:GetGameState():GetDayPhase() == DAY_PHASE.NIGHT and 2 or 1
        end
        t.ETB_BOGGER_SCAVENGERS = 1
        if location:HasTag("deepbog") then
            t.ETB_BOGGER_SCAVENGERS = t.ETB_BOGGER_SCAVENGERS + 1
        end
        t.ETB_BOG_MONSTERS = TheGame:GetGameState():GetDayPhase() == DAY_PHASE.NIGHT and 2 or 1
        if location:HasTag("forest") then
            t.ETB_BOG_MONSTERS = t.ETB_BOG_MONSTERS + 1
        end
        if not location:IsIndoors() then
            t.ETB_SINKING_BOG = TheGame:GetGameState():GetDayPhase() == DAY_PHASE.NIGHT and 2 or 1
            if location:HasTag("deepbog") then
                t.ETB_SINKING_BOG = t.ETB_SINKING_BOG + 1
            end
        end
    end
    return t
end

function EscapeTheBogUtil.GenericInitialEncounterTable(difficulty, quest, location)
    local t = EscapeTheBogUtil.GenericRepeatEncounterTable(difficulty, quest, location)
    t.ETB_NO_EVENT = 2
    if location:HasTag("bog") then
        t.ETB_OUTLAW_CAMP = 2
        if location:HasTag("clearing") then
            t.ETB_OUTLAW_CAMP = t.ETB_OUTLAW_CAMP + 1
        end
    end
    return t
end

function EscapeTheBogUtil.GenericSleepEncounterTable(difficulty, quest, location)
    local t = {
        ETB_NO_SLEEP_EVENT = 5,
    }
    if location:HasTag("dangerous") then
        t.ETB_SLEEP_MONSTER_ATTACK = 2
    end
    return t
end


function EscapeTheBogUtil.ObfuscateWords(txt, frequency)
    local newtxt = txt:gsub("[%a']+", function(word)
            return math.random() < (frequency or 0.80) and string.rep("-", string.len(word)) or word
        end)
        :gsub("%- ", "--")
        :gsub(" %-", "--")
    return newtxt
end

-- I literally copy and paste this from the democratic race mod
function EscapeTheBogUtil.InsertSelectCardScreen(cards, title, desc, class, on_select)
    local card_selected
    local function OnSelectCard(screen, widget, card)
        if card then
            screen:ShowRemoval(widget)
            AUDIO:PlayEvent("event:/ui/select_cards/remove_card")
            card_selected = card
            -- on_select(card)
            -- cxt.enc:ResumeEncounter( card )
        else
            -- on_select()
        end
    end
    local function OnEndFn(screen)
        if on_select then
            on_select(card_selected)
        end
    end

    local screen = Screen.DeckScreen( cards, OnSelectCard, class or Widget.NegotiationCard, OnEndFn )
    screen:SetMusicEvent( TheGame:LookupPlayerMusic( "deck_music" ))
    screen:SetTitles( title, desc )
    TheGame:FE():InsertScreen( screen )
    return screen
end

function EscapeTheBogUtil.DoSleepConvo(cxt)
    local player = TheGame:GetGameState():GetPlayerAgent()
    local hp, maxhp = player:GetHealth()
    local resolve, maxresolve = TheGame:GetGameState():GetCaravan():GetResolve()
    local initial_state =
    {
        health = hp,
        max_health = maxhp,
        resolve = resolve,
        max_resolve = maxresolve
    }

    local chosen_event

    local sleep_segments = 1

    cxt:Dialog("DIALOG_SLEEP_DOTS_ETB")

    local fatigue = player.etb_fatigue
    if fatigue then
        fatigue:DeltaStat(-1)
    end
    EscapeTheBogUtil.TryMainQuestFn("AdvanceTime", 1, "SLEEP")

    local function TrySpawnSleepEvent()
        local associated_quest = EscapeTheBogUtil.GetAssociatedQuest(cxt.location)
        -- Process on sleep encounter
        local encounter_table = associated_quest and associated_quest:GetQuestDef().sleep_encounter

        if type(encounter_table) == "function" then
            encounter_table = encounter_table(TheGame:GetGameState():GetCurrentBaseDifficulty(), associated_quest, cxt.location)
        elseif not encounter_table then
            encounter_table = {}
        else
            encounter_table = shallowcopy(encounter_table)
        end

        local chosen = weightedpick(encounter_table)
        if chosen and chosen ~= "ETB_NO_SLEEP_EVENT" then
            chosen_event = QuestUtil.SpawnQuest(chosen)
        end
    end

    TrySpawnSleepEvent()

    while not chosen_event and ((fatigue and fatigue:CanContinueSleep()) or (not fatigue and TheGame:GetGameState():GetDayPhase() == DAY_PHASE.NIGHT)) do
        cxt:Dialog("DIALOG_SLEEP_DOTS_ETB")

        sleep_segments = sleep_segments + 1
        if fatigue then
            fatigue:DeltaStat(-1)
        end
        EscapeTheBogUtil.TryMainQuestFn("AdvanceTime", 1, "SLEEP")

        TrySpawnSleepEvent()
    end

    print("chosen event: ", chosen_event)

    -- Handle Health/Resolve restoring
    local HEALTH_SLEEP_HEAL_RATE = GetAdvancementModifier( ADVANCEMENT_OPTION.SLEEP_HEALTH_RESTORE ) or 1
    local RESOLVE_SLEEP_HEAL_RATE = GetAdvancementModifier( ADVANCEMENT_OPTION.SLEEP_RESOLVE_RESTORE ) or 1

    local sleep_data =
    {
        health_gain = math.round(10 * sleep_segments * HEALTH_SLEEP_HEAL_RATE),
        resolve_gain = math.round(6 * sleep_segments * RESOLVE_SLEEP_HEAL_RATE),
        cards_removed = {},
    }
    TheGame:BroadcastEvent( "do_sleep", player, sleep_data )
    ConvoUtil.DoHealthDelta(cxt, sleep_data.health_gain, false)
    ConvoUtil.DoResolveDelta(cxt, sleep_data.resolve_gain, false)
    for i, card in ipairs( sleep_data.cards_removed ) do
        -- could do some UI here.
        if is_instance( card, Battle.Card ) then
            player.battler:RemoveCard( card )
        else
            player.negotiator:RemoveCard( card )
        end
    end

    -- Show the screen
    local function OnDone( ... )
        cxt.enc:ResumeEncounter( ... )
    end
    TheGame:FE():PushScreen( Screen.DayOverScreen( initial_state, sleep_data, OnDone ))
    cxt.enc:YieldEncounter()

    -- local screen = TheGame:FE():FindScreen( Screen.LocationScreen )
    -- if screen then
    --     screen:UpdateDayPhase()
    --     screen:RefreshPlaxClickables(true)
    -- end

    -- Check if starved to death like an idiot
    if player.etb_hunger and player.etb_hunger.player_starved then
        cxt:Dialog("DIALOG_SLEEP_STARVED_TO_DEATH_ETB")
        cxt:Opt("OPT_ACCEPT_DEATH_ETB")
            :Fn(function(cxt)
                cxt.enc:PlayerDeath()
            end)
        return
    end

    -- Process sleep event
    if not chosen_event then
        chosen_event = QuestUtil.SpawnQuest("ETB_NO_SLEEP_EVENT")
    end

    assert(chosen_event, "No event spawned")

    cxt:PlayQuestConvo(chosen_event, "SLEEP_WAKE")
end

function EscapeTheBogUtil.GetAssociatedQuest(location)
    if location.quest_membership then
        for i, quest in ipairs(location.quest_membership) do
            if quest:GetQuestDef().is_bog_location then
                return quest
            end
        end
    end
end

local SOCIAL_BOON_CACHE

function EscapeTheBogUtil.GetSocialBoonPool()
    if SOCIAL_BOON_CACHE then
        return deepcopy(SOCIAL_BOON_CACHE)
    end
    SOCIAL_BOON_CACHE = {
        [ CARD_RARITY.COMMON ] = {},
        [ CARD_RARITY.UNCOMMON ] = {},
        [ CARD_RARITY.RARE ] = {},
    }
    local existing_ids = {}
    for i, def in pairs(Content.GetAllCharacterDefs()) do
        if def.loved_graft and def.loved_graft ~= "" and not existing_ids[def.loved_graft] then
            local gift_cost_idx = math.max(def.renown or 1, def.combat_strength or 1)
            if def.boss then
                -- Boon of bosses are always rare
                table.insert(SOCIAL_BOON_CACHE[CARD_RARITY.RARE], def.loved_graft)
            elseif gift_cost_idx <= 2 then
                table.insert(SOCIAL_BOON_CACHE[CARD_RARITY.COMMON], def.loved_graft)
            elseif gift_cost_idx <= 4 then
                table.insert(SOCIAL_BOON_CACHE[CARD_RARITY.UNCOMMON], def.loved_graft)
            else
                table.insert(SOCIAL_BOON_CACHE[CARD_RARITY.RARE], def.loved_graft)
            end
            existing_ids[def.loved_graft] = true
        end
    end
    -- Just because
    if not existing_ids.bolstered_health then
        table.insert(SOCIAL_BOON_CACHE[CARD_RARITY.COMMON], "bolstered_health")
    end
    if not existing_ids.bolstered_resolve then
        table.insert(SOCIAL_BOON_CACHE[CARD_RARITY.COMMON], "bolstered_resolve")
    end
    return SOCIAL_BOON_CACHE
end

function EscapeTheBogUtil.DraftItemCardScreen(cxt)
    local draft_popup = Screen.DraftChoicePopup()
    local cards = RewardUtil.ETBGetBattleItems( 1, 3, cxt.player )
    draft_popup:DraftCards( cxt.player, Battle.Card, cards, function(cxt) cxt.encounter:ResumeEncounter() end )
    TheGame:FE():InsertScreen( draft_popup )
    cxt.enc:YieldEncounter()
end

function EscapeTheBogUtil.GetPooledGrafts(difficulty, num, graft_pool)
    local grafts = {}
    local prob = GRAFT_DROP_RARITY[math.max(1, math.min( difficulty, #GRAFT_DROP_RARITY))]
    local owner = TheGame:GetGameState():GetPlayerAgent()

    for k = 1, num do
        local rarity = weighted_arraypick(prob)
        local pool = graft_pool[ rarity ]
        local idx = math.random(1, #pool)
        local graft_id = pool[idx]
        pool[idx] = table.remove(pool)
        if graft_id then
            local graft = GraftInstance( graft_id )
            table.insert(grafts, graft)
        end
    end
    return grafts
end
