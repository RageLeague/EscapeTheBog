local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = EscapeTheBogUtil.IsETBCampaign,
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
            local opfor =  CreateCombatParty("BOG_BURRS_TEAM", cxt.quest:GetRank(), cxt.location)
            cxt:TalkTo(opfor[1])
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_DEFEND")
                :Battle{
                    no_oppo_limit = true,
                    flags = BATTLE_FLAGS.SELF_DEFENCE
                }
                :OnWin()
                    :Fn(function()
                        cxt.quest:Complete()
                    end)
        end)
