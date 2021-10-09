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
                ]],
                [[
                    * You wake up in the middle of the night. Not a good time to wake up, you would think.
                ]],
            },
        }
        :Fn(function(cxt)
            cxt:FadeIn()
            cxt:Quip( nil, "uneventful", TheGame:GetGameState():GetDayPhase() == DAY_PHASE.NIGHT and "night" or "day")
            cxt.quest:Complete()
            StateGraphUtil.AddEndOption(cxt)
        end)