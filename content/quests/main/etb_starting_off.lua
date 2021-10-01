local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,
}

QDEF:AddConvo()
    :Confront(function(cxt)
        if TheGame:GetLocalSettings().FAST_STARTUP then
            TheGame:GetGameState():GetMainQuest().param.debug_mode = true
            cxt.quest:Complete()
        else
            return "STATE_START"
        end
    end)
    :State("STATE_START")
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
                * You thought today is just going to be an ordinary day, and you are just going to grift another day.
                * You find out that it isn't the case when you wake up.
            ]],
            DIALOG_INTRO = [[
                player:
                    Ow, what happened?
                * You have no recollection of how you got where you are right now.
                * But you know that the bog is not a nice place to be. It is not a good place to stay for long.
                * You need to get out of here, and find civilization, you thought.
            ]],
            OPT_CHECK_INVENTORY = "Check Inventory",
            DIALOG_CHECK_INVENTORY = [[
                * Before you move on to anywhere, you checked what you have on you.
                * Luckily, you have a few things.
            ]],
        }
