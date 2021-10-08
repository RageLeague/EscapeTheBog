local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = EscapeTheBogUtil.IsETBCampaign,

    process_fighter = function(quest, fighter)
        if table.arraycontains(quest.param.opfor or {}, fighter.agent) and not (fighter.agent:GetContentID() == "GROUT_LOOT_CLUSTER" or fighter.agent:GetContentID() == "GROUT_BOG_CYST") then
            fighter:AddCondition("etb_grout_burr_immunity", 1)
        end
    end,
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
                    * You thought you are just walking normally, but all of a sudden, you have disturbed some bog burrs!
                ]],
                [[
                    * You accidentally stepped on some bog burrs while you are walking.
                ]],
            },
            {
                tags = "dialog_start_quip",
                [[
                    * They don't look happy, that's for sure.
                    * (How do you even tell bog burrs' emotions?)
                    * Either way, be prepared!
                ]],
                [[
                    * Looks like you will have to defend yourself!
                ]],
                [[
                    * Watch out! They look like they want to attack you!
                ]],
            },
        }
        :Loc{
            DIALOG_INTRO = [[
                %dialog_start
                player:
                    !left
                    !scared
                %dialog_start_quip
            ]],
            DIALOG_DEFEND = [[
                player:
                    !fight
                    I will not lose!
            ]],
            DIALOG_DEFEND_WIN = [[
                * You sure showed those burrs who's boss.
            ]],
        }
        :Fn(function(cxt)
            cxt.quest.param.opfor =  CreateCombatParty("BOG_BURRS_TEAM", cxt.quest:GetRank(), cxt.location)
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
                    :CompleteQuest()
                    :DoneConvo()
        end)
