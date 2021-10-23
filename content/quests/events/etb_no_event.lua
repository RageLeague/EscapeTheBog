local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = EscapeTheBogUtil.ETBActFilter,

    on_init = function(quest)

    end,
}

QDEF:AddConvo()
    :ConfrontState("STATE_CONF")
        :Quips{
            {
                tags = "uneventful_start",
                [[
                    * You kept waiting for some sort of ambush, but it never arrived.
                ]],
                [[
                    * There is nothing for you here.
                ]],
                [[
                    * You found nothing at this location.
                ]],
            },
            {
                tags = "uneventful_start_quip",
                [[
                    * But perhaps, this is for the best.
                ]],
                [[
                    * A moment of respite is rare in the bog. Cherish it dearly.
                ]],
                [[
                    * Were you hoping for something else?
                ]],
            },
        }
        :Loc{
            DIALOG_INTRO = [[
                %uneventful_start
                %uneventful_start_quip
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Complete()
            StateGraphUtil.AddEndOption(cxt)
        end)
