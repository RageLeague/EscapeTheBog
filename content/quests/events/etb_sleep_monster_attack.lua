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
                    * You wake up to a bunch of animals wanting to eat you!
                ]],
                [[
                    * As you wake up, you realized that sleeping in the middle of the bog with no protection whatsoever is a bad idea.
                    * Because now wild animals are looking to bite your face off.
                ]],
            },
            {
                tags = "dialog_start_quip",
                [[
                    * Good luck!
                ]],
                [[
                    * Your movement is a bit slow as you suddenly wake up, and the beasts got a jump on you first!
                ]],
            },
        }
        :Loc{
            DIALOG_INTRO = [[
                %dialog_start
                player:
                    !left
                %dialog_start_quip
            ]],
            DIALOG_DEFEND = [[
                player:
                    !fight
                    I will not lose!
            ]],
            DIALOG_DEFEND_WIN = [[
                * Looks like you made it out alive.
            ]],
        }
        :Fn(function(cxt)
            cxt.quest.param.opfor =  CreateCombatParty("BOG_MONSTERS_ETB", cxt.quest:GetRank(), cxt.location)
            cxt:TalkTo(cxt.quest.param.opfor[1])

            cxt:FadeIn()
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_DEFEND")
                :Dialog("DIALOG_DEFEND")
                :Battle{
                    no_oppo_limit = true,
                    advantage = TEAM.RED,
                    flags = BATTLE_FLAGS.SELF_DEFENCE,
                    on_start_battle = function(battle)
                        -- for i, agent in ipairs(opfor) do
                        --     local fighter = battle:GetFighterForAgent(agent)
                        --     if fighter then
                        --         fighter:RemoveCondition("grout_burr")
                        --     end
                        -- end
                    end
                }
                :OnWin()
                    :Dialog("DIALOG_DEFEND_WIN")
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
