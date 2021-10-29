local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = EscapeTheBogUtil.ETBActFilter,
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}

QDEF:AddConvo()
    :ConfrontState("STATE_CONF", function(cxt) return cxt.quest.param.location == cxt.location end)
        :Quips{
            {
                tags = "dialog_start",
                [[
                    * Looks like someone arrived here before you, and is now setting up camp here.
                ]],
                [[
                    * Look, you've go company: someone is here setting up a camp.
                ]],
                [[
                    * You noticed a bunch of people setting up camp here.
                ]],
            },
            {
                tags = "confront",
                [[
                    What are you doing here, grifter? You are not supposed to be here!
                ]],
                [[
                    Hey! You are not supposed to be here! Now get lost!
                ]],
                [[
                    A weird place to take a walk, wouldn't you agree, grifter?
                ]],
            },
            {
                tags = "confront_again",
                [[
                    Why are you back here? Do you have a death wish?
                ]],
                [[
                    Do you think that the beating that you have taken wasn't enough? You want some more?
                ]],
                [[
                    If you want more beating, I am more than happy to oblige.
                ]],
            },
            {
                tags = "talk_win",
                [[
                    Alright then. We will be taking our leave.
                ]],
                [[
                    I think it's time for us to leave. See you around, grifter.
                ]],
            },
            {
                tags = "talk_lose",
                [[
                    I'm afraid that I am going to force you to leave, grifter.
                ]],
                [[
                    I think that I've heard enough. Time to get your ass kicked.
                ]],
            },
            {
                tags = "battle_aftermath",
                [[
                    Fine, grifter. You can have this place for yourself.
                ]],
                [[
                    We will just leave and you can have this place all for yourself.
                    !hips
                    Bet you feel really accomplished.
                ]],
            },
        }
        :Loc{
            DIALOG_INTRO = [[
                %dialog_start
                * You confronted them.
                player:
                    !left
                agent:
                    !right
                    %confront
                player:
                    !bashful
                    Uhh...
            ]],
            DIALOG_INTRO_AGAIN = [[
                * You returned. The campers are still here.
                player:
                    !left
                agent:
                    !right
                    !crossed
                    %confront_again
                * Looks like there is no talking out of this one!
            ]],
            DIALOG_INTRO_AGAIN_NONSENTIENT = [[
                * You returned. There is no one left.
                player:
                    !left
                agent:
                    !right
                    !angry
                * But it seems like you are still not welcome here.
                * There is no talking out of this one!
            ]],
            DIALOG_INTRO_NO_GUARDIAN = [[
                * There is no one here.
                * Well, you have all this place for yourself, I guess?
            ]],
            OPT_TALK = "Talk your way out of this",
            DIALOG_TALK = [[
                player:
                    !placate
                    Look, I mean no harm okay?
            ]],
            DIALOG_TALK_SUCCESS = [[
                agent:
                    %talk_win
                    !exit
                * {agent} disappears before you can follow them.
                * Well, you have this place for yourself, I guess?
            ]],
            DIALOG_TALK_FAILURE = [[
                agent:
                    !fight
                    %talk_lose
                * Uh oh, they don't look happy.
                * Better defend yourself!
            ]],
            OPT_ATTACK = "Attack them",
            DIALOG_ATTACK = [[
                player:
                    !fight
                    Take this!
            ]],
            DIALOG_DEFEND = [[
                player:
                    !fight
                    Fine! Let's do this the hard way then!
            ]],
            DIALOG_BATTLE_WIN = [[
                player:
                    Ha! That will teach you!
                {dead?
                    * You noticed that where the corpse of the camper was is a mangled bog monster.
                    * You now feel somewhat awkward for talking to whatever lies below your feet.
                    {some_alive?
                        * The camper's friends disappeared before you can follow them.
                    }
                }
                {not dead?
                agent:
                    %battle_aftermath
                    !exit
                * The campers disappeared before you can follow them.
                }
                * That was a bit weird, but you didn't think too hard about it.
                * You have this place all for yourself.
            ]],
        }
        :Fn(function(cxt)
            -- local food = table.arraypick{"hawb_drumstick", "half_sandwich"}

            if not cxt.quest.param.encountered then
                cxt.quest.param.encountered = true

                local options = {"BOGGER_PATROL", "RISE_PATROL", "BANDIT_PATROL", "JAKES_PATROL", "CIVILIAN_PATROL", "SPARK_BARON_PATROL", "HESH_PATROL", "ADMIRALTY_PATROL"}
                cxt.quest.param.opfor =  CreateCombatParty(table.arraypick(options), cxt.quest:GetRank(), cxt.location)
                cxt:TalkTo(cxt.quest.param.opfor[1])
                cxt:Dialog("DIALOG_INTRO")

                cxt:BasicNegotiation("TALK", {})
                    :OnSuccess()
                        -- :GainCard( food )
                        :Fn(function(cxt)
                            for i, agent in ipairs(cxt.quest.param.opfor) do
                                if not agent:IsRetired() then
                                    agent:Retire()
                                end
                            end
                        end)
                        :CompleteQuest()
                        :DoneConvo()
                    :OnFailure()
                        :Fn(function(cxt)
                            cxt:Opt("OPT_DEFEND")
                                :Dialog("DIALOG_DEFEND")
                                :Battle{
                                    flags = BATTLE_FLAGS.SELF_DEFENCE | BATTLE_FLAGS.ISOLATED,
                                    on_runaway = StateGraphUtil.DoRunAwayNoFail,
                                }
                                    :OnWin()
                                        :Dialog("DIALOG_BATTLE_WIN")
                                        -- :GainCard( food )
                                        :Fn(function(cxt)
                                            for i, agent in ipairs(cxt.quest.param.opfor) do
                                                if not agent:IsRetired() then
                                                    agent:Retire()
                                                end
                                            end
                                        end)
                                        :CompleteQuest()
                                        :DoneConvo()
                        end)
                cxt:Opt("OPT_ATTACK")
                    :Dialog("DIALOG_ATTACK")
                    :Battle{
                        flags = BATTLE_FLAGS.ISOLATED,
                        on_runaway = StateGraphUtil.DoRunAwayNoFail,
                    }
                        :OnWin()
                            :Dialog("DIALOG_BATTLE_WIN")
                            -- :GainCard( food )
                            :Fn(function(cxt)
                                for i, agent in ipairs(cxt.quest.param.opfor) do
                                    if not agent:IsRetired() then
                                        agent:Retire()
                                    end
                                end
                            end)
                            :CompleteQuest()
                            :DoneConvo()
            else
                local i = 1
                while i <= #cxt.quest.param.opfor do
                    local agent = cxt.quest.param.opfor[i]
                    if agent:IsRetired() then
                        table.remove(cxt.quest.param.opfor, i)
                    else
                        i = i + 1
                    end
                end
                if #cxt.quest.param.opfor ~= 0 then
                    cxt:TalkTo(cxt.quest.param.opfor[1])
                    if cxt:GetAgent():IsSentient() then
                        cxt:Dialog("DIALOG_INTRO_AGAIN")
                    else
                        cxt:Dialog("DIALOG_INTRO_AGAIN_NONSENTIENT")
                    end

                    cxt:Opt("OPT_DEFEND")
                        :Dialog("DIALOG_DEFEND")
                        :Battle{
                            flags = BATTLE_FLAGS.SELF_DEFENCE | BATTLE_FLAGS.ISOLATED,
                            on_runaway = StateGraphUtil.DoRunAwayNoFail,
                        }
                            :OnWin()
                                :Dialog("DIALOG_BATTLE_WIN")
                                -- :GainCard( food )
                                :Fn(function(cxt)
                                    for i, agent in ipairs(cxt.quest.param.opfor) do
                                        if not agent:IsRetired() then
                                            agent:Retire()
                                        end
                                    end
                                end)
                                :CompleteQuest()
                                :DoneConvo()
                else
                    cxt:Dialog("DIALOG_INTRO_NO_GUARDIAN")
                    cxt.quest:Complete()
                    StateGraphUtil.AddEndOption(cxt)
                end
            end
        end)
