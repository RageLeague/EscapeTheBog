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
                    * Looks like someone arrived here before you, and is now setting up camp here.
                ]],
                [[
                    * Look, you've go company: someone is here setting up a camp.
                ]],
                [[
                    * You noticed a bunch of people setting up camp here.
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
                * Well, you have this place for yourself, I guess?
            ]],
            DIALOG_TALK_FAILURE = [[
                agent:
                    !fight
                    %talk_lose
                * Uh oh, they don't look happy.
                * Better defend yourself!
            ]],
        }
