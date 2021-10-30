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
                    * Seems like you are not alone in this part of the bog.
                ]],
                [[
                    * You found yourself facing a group of people.
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
                    Fine, grifter. We shall take our leave.
                ]],
                [[
                    I get you point. We will leave now.
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
                * You are not sure what to make of this situation.
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
                    * You noticed that where the corpse was is a mangled bog monster.
                    * You now feel somewhat awkward for talking to whatever lies below your feet.
                    {some_alive?
                        * The rest of the group disappeared before you can follow them.
                    }
                }
                {not dead?
                agent:
                    %battle_aftermath
                    !exit
                * Those people disappeared before you can follow them.
                }
                * That was a bit weird, but you didn't think too hard about it.
                * You have this place all for yourself.
            ]],
        }
        :Fn(function(cxt)
            -- local food = table.arraypick{"hawb_drumstick", "half_sandwich"}

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
                                on_runaway = function(cxt, battle)
                                    for i, agent in ipairs(cxt.quest.param.opfor) do
                                        if not agent:IsRetired() then
                                            agent:Retire()
                                        end
                                    end
                                    StateGraphUtil.DoRunAway( cxt, battle )
                                end,
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
                    on_runaway = function(cxt, battle)
                        for i, agent in ipairs(cxt.quest.param.opfor) do
                            if not agent:IsRetired() then
                                agent:Retire()
                            end
                        end
                        StateGraphUtil.DoRunAway( cxt, battle )
                    end,
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
