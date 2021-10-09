local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = EscapeTheBogUtil.IsETBCampaign,
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}

QDEF:AddConvo()
    :ConfrontState("STATE_CONF")
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
                    Uhh...
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
            ]],
        }
        :Fn(function(cxt)
            local options = {"BOGGER_PATROL", "RISE_PATROL", "BANDIT_PATROL", "JAKES_PATROL"}
            cxt.quest.param.opfor =  CreateCombatParty(table.arraypick(options), cxt.quest:GetRank(), cxt.location)
            cxt:TalkTo(cxt.quest.param.opfor[1])
            cxt:Dialog("DIALOG_INTRO")

            cxt:BasicNegotiation("TALK", {})
                :OnSuccess()
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
                            }
                                :OnWin()
                                    :Dialog("DIALOG_BATTLE_WIN")
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
                }
                    :OnWin()
                        :Dialog("DIALOG_BATTLE_WIN")
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