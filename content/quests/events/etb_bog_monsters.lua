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
                    * A bunch of wild animals decided that you look tasty, and now they wants to eat you.
                ]],
                [[
                    * You stumbled across a bunch of wild animals, and they don't seem to like you.
                ]],
            },
            {
                tags = "dialog_start_quip",
                [[
                    * Good luck!
                ]],
                [[
                    * Time to defend yourself!
                ]],
                [[
                    * It's an eat or be eaten world, and you sure as Hesh don't plan to be eaten.
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
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_DEFEND")
                :Dialog("DIALOG_DEFEND")
                :Battle{
                    no_oppo_limit = true,
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
