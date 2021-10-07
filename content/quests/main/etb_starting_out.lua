local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,
}
:AddObjective{
    id = "starting_out",
    state = QSTATUS.ACTIVE,
}

QDEF:AddConvo("starting_out")
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
            DIALOG_INTRO_2 = [[
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
            DIALOG_CHECK_INVENTORY_PST = [[
                * You don't exactly remember where you got those items, or why you have those items, but it's a good thing that you aren't completely defenseless.
                * You feel slightly better about your chance of survival. It's time to move on.
            ]],
            DIALOG_CHECK_INVENTORY_PST_NO_DRAFT = [[
                * Feeling confident that you won't be needing any of your items, you toss them away like an idiot.
                * The Bog immediately absorbs the items you threw away.
                * Too late for any regrets. Time to move on.
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.enc:GetScreen():Fade(0)
                cxt:Dialog("DIALOG_INTRO")
                cxt:FadeIn()
                cxt:Dialog("DIALOG_INTRO_2")
            end
            if not cxt.quest.param.checked_inventory then
                cxt:Opt("OPT_CHECK_INVENTORY")
                    :Dialog("DIALOG_CHECK_INVENTORY")
                    :Fn(function(cxt)
                        cxt.quest.param.checked_inventory = true

                        local skip_count = TheGame:GetGameState().card_skip_count or 0

                        local function OnDone()
                            cxt.encounter:ResumeEncounter()
                        end

                        for i = 1, 2 do
                            local draft_popup = Screen.DraftChoicePopup()
                            local cards = RewardUtil.ETBGetBattleItems( 1, 3, cxt.player )
                            draft_popup:DraftCards( cxt.player, Battle.Card, cards, OnDone )
                            TheGame:FE():InsertScreen( draft_popup )
                            cxt.enc:YieldEncounter()
                        end

                        local skip_delta = (TheGame:GetGameState().card_skip_count or 0) - skip_count
                        if skip_delta >= 2 then
                            cxt:Dialog("DIALOG_CHECK_INVENTORY_PST_NO_DRAFT")
                        else
                            cxt:Dialog("DIALOG_CHECK_INVENTORY_PST")
                        end
                    end)
            end
            cxt:Opt("OPT_DONE")
                :SetSFX( SoundEvents.leave_conversation )
                :Fn(function(cxt)
                    cxt.quest:Complete()
                    cxt:End()
                end)
                :MakeUnder()
        end)
