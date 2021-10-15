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
                    * When you arrive at this location, you are confronted by strange figures!
                ]],
                [[
                    * Look, you've go company.
                ]],
            },
            {
                tags = "bogger_quip",
                [[
                    Who are you? Are you here to desecrate the bog?
                ]],
                [[
                    You do not belong here, grifter! Do you wish to perish at the hands of the bog?
                ]],
            },
            {
                tags = "bogger_quip,night",
                [[
                    Halt! What are you doing here so late in the bog? Are you looking for trouble?
                ]],
            },
            {
                tags = "bogger_yes_response",
                [[
                    !fight
                    Tresspasser! May your blood spill on the soil of the bog!
                ]],
            },
            {
                tags = "bogger_battle_aftermath",
                [[
                    You might defeat me, but you can never defeat the bog!
                ]],
                [[
                    The bog will remember this transgression!
                ]],
            },
            {
                tags = "bogger_no_response",
                [[
                    !point
                    If that's the case, then prove it!
                ]],
                [[
                    !hips
                    Oh yeah? Let's hear what this grifter has to say!
                ]],
            },
            {
                tags = "bogger_negotiation_aftermath",
                [[
                    Very well. We shall take our leave.
                ]],
            },
        }
        :Loc{
            DIALOG_INTRO = [[
                %dialog_start
                player:
                    !left
                agent:
                    !right
                    !angry
                    %bogger_quip
                * You can barely understand what they are saying, which is unnatural.
                * They do not look friendly. Better answer their question!
            ]],
            OPT_YES = "Yes?",
            DIALOG_YES = [[
                player:
                    !bashful
                    Uhh... Yes?
                agent:
                    %bogger_yes_response
                player:
                    !placate
                    Wait, hold on!
            ]],
            DIALOG_BATTLE_WIN = [[
                player:
                    Ha! That will teach you!
                {dead?
                    * You noticed that where the corpse of the bogger was is a mangled bog monster.
                    * You now feel somewhat awkward for talking to whatever lies below your feet.
                    {some_alive?
                        * The rest of the boggers disappeared before you can follow them.
                    }
                }
                {not dead?
                agent:
                    %bogger_battle_aftermath
                    !exit
                * The boggers disappeared before you can follow them.
                }
                * That was a bit weird, but you didn't think too hard about it.
            ]],
            OPT_NO = "No?",
            DIALOG_NO = [[
                player:
                    !bashful
                    Uhh... No?
                agent:
                    %bogger_no_response
                player:
                    !bashful
                    Uhh... okay?
            ]],
            DIALOG_NEGOTIATION_WIN = [[
                agent:
                    %bogger_negotiation_aftermath
                    !exit
                * The boggers left before you can follow them.
            ]],
            DIALOG_NEGOTIATION_LOSE = [[
                agent:
                    %bogger_yes_response
                player:
                    !placate
                    Wait, hold on!
            ]],
        }
        :Fn(function(cxt)
            cxt.quest.param.opfor =  CreateCombatParty("BOGGER_PATROL", cxt.quest:GetRank(), cxt.location)
            cxt:TalkTo(cxt.quest.param.opfor[1])
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_YES")
                :Dialog("DIALOG_YES")
                :HiddenBattle{
                    flags = BATTLE_FLAGS.SELF_DEFENCE | BATTLE_FLAGS.ISOLATED,

                    on_runaway = function(cxt, battle, no_fail)
                        for i, agent in ipairs(cxt.quest.param.opfor) do
                            if not agent:IsRetired() then
                                agent:Retire()
                            end
                        end
                        StateGraphUtil.DoRunAway( cxt, battle, no_fail )
                    end,
                }
                    :OnWin()
                        :Fn(function(cxt)
                            for i, agent in ipairs(cxt.quest.param.opfor) do
                                if agent:IsAlive() then
                                    cxt.quest.param.some_alive = true
                                    break
                                end
                            end
                        end)
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

            cxt:Opt("OPT_NO")
                :Dialog("DIALOG_NO")
                :HiddensNegotiation{
                }
                    :OnSuccess()
                        :Dialog("DIALOG_NEGOTIATION_WIN")
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
                        :Dialog("DIALOG_NEGOTIATION_LOSE")
                        :Fn(function(cxt)
                            cxt:Opt("OPT_DEFEND")
                                :Battle{
                                    flags = BATTLE_FLAGS.SELF_DEFENCE | BATTLE_FLAGS.ISOLATED,
                                    on_runaway = function(cxt, battle, no_fail)
                                        for i, agent in ipairs(cxt.quest.param.opfor) do
                                            if not agent:IsRetired() then
                                                agent:Retire()
                                            end
                                        end
                                        StateGraphUtil.DoRunAway( cxt, battle, no_fail )
                                    end,
                                }
                                    :OnWin()
                                        :Fn(function(cxt)
                                            for i, agent in ipairs(cxt.quest.param.opfor) do
                                                if agent:IsAlive() then
                                                    cxt.quest.param.some_alive = true
                                                    break
                                                end
                                            end
                                        end)
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
        end)
