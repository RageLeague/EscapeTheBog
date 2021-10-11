local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = EscapeTheBogUtil.IsETBCampaign,
}

QDEF:AddConvo(nil, nil, "SLEEP_WAKE")
    :State("START")
        :Quips{
            {
                tags = "uneventful",
                [[
                    * You wake up, feeling slightly better about your current situation.
                ]],
                [[
                    * You wake up. Seems like you aren't dead yet.
                    * At least that's good.
                ]],
                [[
                    * You hope that this was all just a bad dream, and you will wake up all cozy in your room.
                    * Then the reality of your current situation kicks in.
                ]],
            },
            {
                tags = "uneventful,night",
                [[
                    * You wake up in the middle of the night. Perhaps you aren't as drowsy as you thought you were.
                    * At least that means you are doing good in terms your sleep schedule. Probably.
                ]],
                [[
                    * You wake up in the middle of the night. Not a good time to wake up, you would think.
                    * Still, it beats not waking up at all.
                ]],
            },
        }
        :Fn(function(cxt)
            cxt:FadeIn()
            cxt:Quip( cxt.player, "uneventful", TheGame:GetGameState():GetDayPhase() == DAY_PHASE.NIGHT and "night" or "day")
            cxt.quest:Complete()
            StateGraphUtil.AddEndOption(cxt)
        end)
