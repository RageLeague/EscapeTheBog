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
                tags = "bog_intro",
                [[
                    * You must have lost more memory than you thought, because it seems like you have forgotten how to walk.
                    * You walked straight into a s
                ]],
            },
        }
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
                    !scared
                %bog_intro
                * You are about to pull out when you hear the most irrational voice.
                agent:
                    !right
                    ACCEPT THE BOG. BE ONE WITH THE BOG. DO NOT RESIST THE BOG.
                * You now feel a strong, irrational urge to give up, and let the bog consume you.
            ]],
            OPT_RESIST = "Resist the bog's command",
            DIALOG_RESIST = [[
                player:
                    I will not give in!
                    I need to get out of this!
            ]],
            DIALOG_RESIST_SUCCESS = [[
                player:
                    I will not give in to you, bog!
                * You successfully pulled yourself out of the thing.
            ]],
            DIALOG_RESIST_SUCCESS_INFECTED = [[
                * You have not gone out of this completely unscathed, though.
                * Seems like parasites have held onto you while you are in the thing.
            ]],
            DIALOG_RESIST_SUCCESS_PST = [[
                player:
                    The bog sure plays a lot of tricks on people's minds.
                    I need to be more careful.
            ]],
            DIALOG_RESIST_FAILURE = [[
                * You have lost your resolve to pull yourself up.
                player:
                    Maybe I should just... accept the embrace of the bog.
                * Soon, your vision went dark.
            ]],
        }
        :Fn(function(cxt)
            cxt:TalkTo(TheGame:GetGameState():GetMainQuest():GetCastMember("bog_monster"))

            cxt:Dialog("DIALOG_INTRO")

            cxt:BasicNegotiation("RESIST", {})
                :OnSuccess()
                    :Fn(function(cxt, minigame)
                        local parasites = {}
                        for i = 5, minigame:GetTurns(), 4 do
                            table.insert(parasites, table.arraypick{"twig", "stem"})
                        end
                        if #parasites > 0 then
                            cxt:Dialog("DIALOG_RESIST_SUCCESS_INFECTED")

                            cxt:GainCards(parasites)
                        end
                        cxt:Dialog("DIALOG_RESIST_SUCCESS_PST")
                    end)
                    :CompleteQuest()
                    :DoneConvo()
                :OnFailure()
                    :FadeOut()
                    :Fn(function(cxt)
                        cxt:Opt("OPT_ACCEPT_DEATH_ETB")
                            :Fn(function(cxt)
                                cxt.enc:PlayerDeath(cxt:GetAgent())
                            end)
                    end)
        end)
