local ngraft = {
    id = "etb_mystery_graft_negotiation",
    type = GRAFT_TYPE.NEGOTIATION,
    name = "Mystery Graft",
    desc = "You can't tell what kind of graft this is. There is only one way to find out.",

    rarity = CARD_RARITY.UNIQUE,
    series = "GENERAL",
}

Content.AddGraft( ngraft.id, ngraft )

local bgraft = {
    id = "etb_mystery_graft_battle",
    type = GRAFT_TYPE.COMBAT,
    name = "Mystery Graft",
    desc = "You can't tell what kind of graft this is. There is only one way to find out.",

    rarity = CARD_RARITY.UNIQUE,
    series = "GENERAL",
}


Content.AddGraft( bgraft.id, bgraft )


local QDEF
QDEF = EscapeTheBogUtil.AddBogLocationQuest(
    {
        entry_encounter = EscapeTheBogUtil.GenericInitialEncounterTable,
        repeat_encounter = EscapeTheBogUtil.GenericSafeRepeatEncounterTable,
        sleep_encounter = EscapeTheBogUtil.GenericSleepEncounterTable,

        on_init = function(quest)
            quest.param.poi = table.arraypick{"artifact", "shrines"}
        end,

        GetPathDesc = function(quest)
            if not quest.param.desc_number then
                quest.param.desc_number = EscapeTheBogUtil.TryMainQuestFn("RequestRiffleShuffle", QDEF.id .. "_DESC", 1, 3) -- math.random(1, 5)
            end
            local desc = {}
            table.insert(desc, quest:GetLocalizedStr("DESC_" .. quest.param.desc_number))
            return table.concat(desc, "\n")
        end,

        events =
        {

        },
    },
    {
        name = "Ancient Ruins",
        desc = "A vestige of a former civilization. A shadow of a former glory.",
        plax = "EXT_Bog_HedgeGod_01",
        show_agents = true,
        tags = {"bog", "ruins", "clearing"},
    },
    {"dangerous", "dangerous"}
)

QDEF:Loc{
    DESC_1 = "There seems to be some broken buildings down this path. There might be something here.",
    DESC_2 = "There are some man-made structures down this path, although it has seen better days.",
    DESC_3 = "There used to be buildings down this path. But now, only a vestige of it remains.",
}

QDEF:AddConvo()
    :ConfrontState("STATE_CONF", function(cxt) return cxt.quest.param.guardians and cxt.location == cxt:GetCastMember("main_location") end)
        :Loc{
            DIALOG_AMBUSH = [[
                * You returned. Looks like the robots are still here.
                agent:
                    !right
                player:
                    !left
                    !scared
                * If you want to stay here, you have to destroy them!
            ]],
            DIALOG_NO_ROBOTS = [[
                * Seems like the robots guarding this location are gone.
                * You can now safely access this location.
            ]],
            DIALOG_FIGHT_WIN = [[
                * With the last of the machine destroyed, you can now safely access this location.
            ]],
        }
        :Fn(function(cxt)
            EscapeTheBogUtil.FilterTableInPlace(cxt.quest.param.guardians, function(agent) return not agent:IsRetired() end)
            if #cxt.quest.param.guardians > 0 then
                cxt:TalkTo(cxt.quest.param.guardians[1])
                cxt:Dialog("DIALOG_AMBUSH")
                cxt:Opt("OPT_DEFEND")
                    :Battle{
                        flags = BATTLE_FLAGS.SELF_DEFENCE | BATTLE_FLAGS.ISOLATED,
                        on_runaway = StateGraphUtil.DoRunAwayNoFail,
                        enemies = cxt.quest.param.guardians,
                    }
                        :OnWin()
                            :Dialog("DIALOG_FIGHT_WIN")
                            :Fn(function(cxt)
                                cxt.quest.param.disable_event_spawn = nil
                                cxt.quest.param.guardians = nil
                                cxt.quest.param.searched_for_poi = true
                            end)
                            :DoneConvo()
            else
                cxt:Dialog("DIALOG_NO_ROBOTS")

                cxt.quest.param.disable_event_spawn = nil
                cxt.quest.param.guardians = nil
                cxt.quest.param.searched_for_poi = true

                StateGraphUtil.AddEndOption(cxt)
            end
        end)

QDEF:AddConvo()
    :Loc{
        OPT_PRAY = "Pray at shrine",
        TT_PRAY = "Once per day, you can pray here for some time. Maybe you will get something good out of it.",
        OPT_TAKE_ARTIFACT = "Take the artifact",
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
                    :ReqCondition(not cxt.location:HasMemoryFromToday("USED_LOCATION"), "ON_COOLDOWN")
                    :Fn( function(cxt)
                        cxt.location:Remember("USED_LOCATION")
                        UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_SHRINE" , nil, nil, cxt.quest)
                    end )
            elseif cxt.quest.param.poi == "artifact" then
                -- cxt:Opt("OPT_OFFERING")
                --     :PostText("TT_OFFERING")
                --     :ReqCondition(not cxt.location:HasMemoryFromToday("USED_LOCATION"), "ON_COOLDOWN")
                --     :Fn( function(cxt)
                --         UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_RITUAL" , nil, nil, cxt.quest)
                --     end )
                if not cxt.quest.param.took_artifact then
                    cxt:Opt("OPT_TAKE_ARTIFACT")
                        :Fn( function(cxt)
                            UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_ARTIFACT" , nil, nil, cxt.quest)
                        end )
                end
            end
        end
    end)
    :State("STATE_POI")
        :Loc{
            DIALOG_SHRINE = [[
                * <b>Vestige</>
                * You find an old shrine. It doesn't look very Heshian.
                * You have no idea what it is doing in the middle of the bog.
                * Either way, if there is a time for some divine intervention, it should be now.
            ]],
            DIALOG_ARTIFACT = [[
                * <b>Vestige</>
                * You find a most curious looking device sitting on top of a pedestal.
                * A shadow of a bygone era.
                * You feel bad for it as it sits around, without a purpose, and you feel like this is a good idea to give it one.
            ]],
            DIALOG_AMBUSH = [[
                * But just as you start to approach the object, you heard a mechanical whirling sound.
                agent:
                    !right
                player:
                    !left
                    !scared
                * Suddenly, some robots spring to life!
                * Seems like they are guarding this location.
                * If you want to stay here, you have to defend yourself!
            ]],
            DIALOG_FIGHT_WIN = [[
                * With the last of the machine destroyed, you can now safely access this location.
            ]],
        }
        :Fn(function(cxt)
            if cxt.quest.param.poi == "shrines" then
                cxt:Dialog("DIALOG_SHRINE")
            else
                cxt:Dialog("DIALOG_ARTIFACT")
            end
            -- cxt.quest.param.searched_for_poi = true
            cxt.quest.param.disable_event_spawn = true
            cxt.quest.param.guardians = CreateCombatParty({"SPARK_BARON_AUTOMECH", "RISE_AUTOMECH", "AUTODOG"}, cxt.quest:GetRank(), cxt.location)
            cxt:TalkTo(cxt.quest.param.guardians[1])
            cxt:Dialog("DIALOG_AMBUSH")
            cxt:Opt("OPT_DEFEND")
                :Battle{
                    flags = BATTLE_FLAGS.SELF_DEFENCE | BATTLE_FLAGS.ISOLATED,
                    on_runaway = StateGraphUtil.DoRunAwayNoFail,
                    enemies = cxt.quest.param.guardians,
                }
                    :OnWin()
                        :Dialog("DIALOG_FIGHT_WIN")
                        :Fn(function(cxt)
                            cxt.quest.param.disable_event_spawn = nil
                            cxt.quest.param.guardians = nil
                            cxt.quest.param.searched_for_poi = true
                            EscapeTheBogUtil.TryMainQuestFn("AdvanceTime", 1, "SEARCH")
                        end)
                        :DoneConvo()
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
                cxt.caravan:UpgradeResolve( 5 )
            elseif result == "DIALOG_HEALTH" then
                ConvoUtil.DoHealthDelta(cxt, 10)
                cxt.caravan:UpgradeHealth( 5, "PRAYER_BONUS" )
            end
            EscapeTheBogUtil.TryMainQuestFn("AdvanceTime", 1, "REST")
            StateGraphUtil.AddEndOption(cxt)
        end)
    :State("STATE_ARTIFACT")
        :Loc{
            DIALOG_INTRO = [[
                * It's time to take a look at this artifact.
                player:
                    !left
                    !thought
                * It looks like a powerful graft, although it has seen better days.
                * Do you want to try it out?
            ]],
            OPT_INSTALL_GRAFT = "Install the graft",
            TT_NEGOTIATION = "This will take up a negotiation graft slot.",
            TT_BATTLE = "This will take up a battle graft slot.",
            DIALOG_INSTALL_GRAFT = [[
                * Well, you are stuck with it now, whether you like it or not.
            ]],
        }
        :Fn(function(cxt)
            while not cxt.quest.param.graft_reward or (cxt.quest.param.graft_reward:GetType() ~= GRAFT_TYPE.COMBAT and cxt.quest.param.graft_reward:GetType() ~= GRAFT_TYPE.NEGOTIATION) do
                cxt.quest.param.graft_reward = cxt.quest.param.graft_reward or RewardUtil.GetGrafts(5, 1, TheGame:GetGameState():GetPlayerAgent())[1]
            end
            local is_battle = cxt.quest.param.graft_reward:GetType() == GRAFT_TYPE.COMBAT

            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_INSTALL_GRAFT")
                :PostText(is_battle and "TT_BATTLE" or "TT_NEGOTIATION")
                :Fn(function(cxt)
                    local graft = GraftInstance(is_battle and "etb_mystery_graft_battle" or "etb_mystery_graft_negotiation")
                    local installed = ConvoUtil.GiveGraft(cxt, graft)
                    if installed then
                        TheGame:GetGameState():GetPlayerAgent().graft_owner:ReplaceGraft( graft, cxt.quest.param.graft_reward )
                        cxt:Dialog("DIALOG_INSTALL_GRAFT")
                    end
                end)
            StateGraphUtil.AddBackButton(cxt)
        end)
