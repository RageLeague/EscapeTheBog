local QDEF
QDEF = EscapeTheBogUtil.AddBogLocationQuest(
    {
        entry_encounter = EscapeTheBogUtil.GenericInitialEncounterTable,
        repeat_encounter = EscapeTheBogUtil.NullEncounterTable,

        on_init = function(quest)
            quest.param.poi = table.arraypick{"nothing", "shrines", "ritual_platform"}
        end,

        GetPathDesc = function(quest)
            if not quest.param.desc_number then
                quest.param.desc_number = EscapeTheBogUtil.TryMainQuestFn("RequestRiffleShuffle", QDEF.id .. "_DESC", 1, 5) -- math.random(1, 5)
            end
            local desc = {}
            table.insert(desc, quest:GetLocalizedStr("DESC_" .. quest.param.desc_number))
            return table.concat(desc, "\n")
        end,

        events =
        {
            resolve_battle = function( quest, battle, primary_enemy, repercussions )
                if battle:GetScenario():GetLocation() ~= quest:GetCastMember("main_location") then
                    return
                end
                if quest.param.poi ~= "ritual_platform" then
                    return
                end
                for i, fighter in battle:AllFighters() do
                    if fighter.team == battle:GetEnemyTeam() and fighter.agent and fighter:IsDead() then
                        if fighter.agent:IsSentient() or fighter.agent:GetSpecies() == SPECIES.SNAIL or fighter.agent:GetSpecies() == SPECIES.BEAST then
                            if not fighter.agent.is_grout then
                                quest.param.sacrificed_creatures = (quest.param.sacrificed_creatures or 0) + 1
                            end
                        end
                    end
                end
            end,
        },
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

QDEF:AddConvo()
    :Loc{
        OPT_PRAY = "Pray at shrine",
        TT_PRAY = "Once per day, you can pray here for some time. Maybe you will get something good out of it.",
        OPT_OFFERING = "Make an offering",
        TT_OFFERING = "You can offer a lot of things, and you might get some reward depending on your offer.",
    }
    :Hub_Location(function(cxt)
        if cxt.location ~= cxt:GetCastMember("main_location") then
            return
        end
        if not cxt.quest.param.searched_for_poi then
            cxt:Opt("OPT_FIND_POI_ETB")
                :Fn( function(cxt)
                    UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_POI" , nil, nil, cxt.quest)
                end )
        else
            if cxt.quest.param.poi == "shrines" then
                cxt:Opt("OPT_PRAY")
                    :PostText("TT_PRAY")
                    :ReqCondition(not cxt.location:HasMemoryFromToday("PRAYED_HERE"), "ON_COOLDOWN")
                    :Fn( function(cxt)
                        cxt.location:Remember("PRAYED_HERE")
                        UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_SHRINE" , nil, nil, cxt.quest)
                    end )
            elseif cxt.quest.param.poi == "ritual_platform" then
                cxt:Opt("OPT_OFFERING")
                    :PostText("TT_OFFERING")
                    :Fn( function(cxt)
                        UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_RITUAL" , nil, nil, cxt.quest)
                    end )
            end
        end
    end)
    :State("STATE_POI")
        :Quips{
            {
                tags = "found_nothing",
                [[
                    * You find what appears to be a remnent of some sort of machine.
                    * No idea what it does, let alone how it will help you with your current situation.
                ]],
                [[
                    * You find a cool rock. It is shaped like a perfect disc.
                    * It doesn't help you, though.
                ]],
                [[
                    * You find that this is a huge waste of time.
                ]],
                [[
                    * You find an extremely tall tree.
                    * That's cool, I guess?
                ]],
            },
        }
        :Loc{
            DIALOG_SHRINE = [[
                * You find an old shrine.
                * You have no idea what it is doing in the middle of the bog.
                * Either way, if there is a time for some divine intervention, it should be now.
            ]],
            DIALOG_RITUAL_PLATFORM = [[
                * You find some sort of elevated platform.
                * It is stained with a crimson color.
                * Perhaps if you make an offering, something will happen.
                * Well not necessarily "good", but "something".
            ]],
        }
        :Fn(function(cxt)
            if cxt.quest.param.poi == "shrines" then
                cxt:Dialog("DIALOG_SHRINE")
            elseif cxt.quest.param.poi == "ritual_platform" then
                cxt:Dialog("DIALOG_RITUAL_PLATFORM")
            else
                cxt:Quip( cxt.player, "found_nothing")
            end
            cxt.quest.param.searched_for_poi = true
            EscapeTheBogUtil.TryMainQuestFn("AdvanceTime", 1, "SEARCH")
            StateGraphUtil.AddEndOption(cxt)
        end)
    :State("STATE_SHRINE")
        :Quips{
            {
                tags = "prayer",
                [[
                    Please, to whatever deity is listening, I need some help.
                ]],
                [[
                    I know I have not been the most devote person, but... Please, I need your help.
                ]],
                [[
                    I need your help. Please.
                ]],
            },
        }
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
                    !hesh_greeting
                    %prayer
            ]],
            DIALOG_NOTHING = [[
                * Perhaps your prayers aren't strong enough. Or that whatever deity you are praying to doesn't care about you.
                * Either way, nothing happens.
            ]],
            DIALOG_RESOLVE = [[
                * You feel like your mind is clearer after the prayer.
                * Was this divine intervention? Or is your mind simply clearer after the prayer?
                * Either way, it gets results.
            ]],
            DIALOG_HEALTH = [[
                * You feel like your wounds are starting to heal.
                * Was this divine intervention? Or is your body simply mending itself after some rest?
                * Either way, it gets results.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            local result = table.arraypick{"DIALOG_NOTHING", "DIALOG_RESOLVE", "DIALOG_HEALTH"}
            cxt:Dialog(result)
            if result == "DIALOG_RESOLVE" then
                ConvoUtil.DoResolveDelta(cxt, 10)
            elseif result == "DIALOG_HEALTH" then
                ConvoUtil.DoHealthDelta(cxt, 10)
            end
            StateGraphUtil.AddEndOption(cxt)
        end)
    :State("STATE_RITUAL")
        :Loc{
            OPT_OFFER_MONEY = "Offer money...",
            DIALOG_OFFER_MONEY = [[
                * You offered some money at the altar.
            ]],
            OPT_OFFER_BLOOD = "Offer blood...",
            DIALOG_OFFER_BLOOD = [[
                * You offered some of your own blood.
                * Probably not your best idea, but it will likely do the trick.
            ]],
            OPT_OFFER_FOOD = "Offer food...",

            OPT_OFFER_SMALL = "Offer a small amount",
            OPT_OFFER_MEDIUM = "Offer a medium amount",
            OPT_OFFER_LARGE = "Offer a large amount",

            DIALOG_OFFER_PST = [[
                * Suddenly!
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            cxt:Opt("OPT_OFFER_MONEY")
                :LoopingFn(function(cxt)
                    cxt:Opt("OPT_OFFER_SMALL")
                        :Dialog("DIALOG_OFFER_MONEY")
                        :DeliverMoney(100)
                        :Dialog("DIALOG_OFFER_PST")
                        :Fn(function(cxt)
                            cxt.quest.param.ritual_level = 1
                        end)
                        :GoTo("STATE_RITUAL_REWARD")
                    cxt:Opt("OPT_OFFER_MEDIUM")
                        :Dialog("DIALOG_OFFER_MONEY")
                        :DeliverMoney(200)
                        :Dialog("DIALOG_OFFER_PST")
                        :Fn(function(cxt)
                            cxt.quest.param.ritual_level = 2
                        end)
                        :GoTo("STATE_RITUAL_REWARD")
                    cxt:Opt("OPT_OFFER_LARGE")
                        :Dialog("DIALOG_OFFER_MONEY")
                        :DeliverMoney(300)
                        :Dialog("DIALOG_OFFER_PST")
                        :Fn(function(cxt)
                            cxt.quest.param.ritual_level = 4
                        end)
                        :GoTo("STATE_RITUAL_REWARD")
                    StateGraphUtil.AddBackButton(cxt)
                end)
            cxt:Opt("OPT_OFFER_BLOOD")
                :LoopingFn(function(cxt)
                    cxt:Opt("OPT_OFFER_SMALL")
                        :Dialog("DIALOG_OFFER_BLOOD")
                        :DeltaHealth(-8)
                        :Dialog("DIALOG_OFFER_PST")
                        :Fn(function(cxt)
                            cxt.quest.param.ritual_level = 1
                        end)
                        :GoTo("STATE_RITUAL_REWARD")
                    cxt:Opt("OPT_OFFER_MEDIUM")
                        :Dialog("DIALOG_OFFER_BLOOD")
                        :DeltaHealth(-16)
                        :Dialog("DIALOG_OFFER_PST")
                        :Fn(function(cxt)
                            cxt.quest.param.ritual_level = 2
                        end)
                        :GoTo("STATE_RITUAL_REWARD")
                    cxt:Opt("OPT_OFFER_LARGE")
                        :Dialog("DIALOG_OFFER_BLOOD")
                        :DeltaHealth(-24)
                        :Dialog("DIALOG_OFFER_PST")
                        :Fn(function(cxt)
                            cxt.quest.param.ritual_level = 4
                        end)
                        :GoTo("STATE_RITUAL_REWARD")
                    StateGraphUtil.AddBackButton(cxt)
                end)
            cxt:Opt("OPT_OFFER_FOOD")
            StateGraphUtil.AddBackButton(cxt)
        end)
    :State("STATE_RITUAL_REWARD")
        :Loc{

        }
        :Fn(function(cxt)
            cxt.enc:WaitOnLine()

            local grafts
            grafts = RewardUtil.GetPooledGrafts(cxt.quest.param.ritual_level or 3, TheGame:GetGameState():GetGraftDraftDetails().count, EscapeTheBogUtil.GetSocialBoonPool())
            local popup = Screen.PickGraftScreen(grafts, false, function(...) cxt.enc:ResumeEncounter(...) end)
            TheGame:FE():InsertScreen( popup )
            local chosen_graft = cxt.enc:YieldEncounter()

            cxt.quest.param.ritual_level = nil

            StateGraphUtil.AddEndOption(cxt)
        end)
