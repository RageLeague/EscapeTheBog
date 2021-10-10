local BOGBERRY_ID = "etb_mixed_bogberries"

local QDEF = EscapeTheBogUtil.AddBogLocationQuest(
    {
        quest_weight = 3,
        entry_encounter = EscapeTheBogUtil.GenericInitialEncounterTable,
        repeat_encounter = EscapeTheBogUtil.GenericRepeatEncounterTable,
        on_init = function(quest)
            quest.param.poi = "bogberry_bushes"-- table.arraypick{"nothing", "bogberry_bushes"}
        end,
    },
    {
        name = "Deep Bog",
        desc = "The Deep Bog holds many dangers. Don't stay for too long now!",
        plax = "EXT_BOG_DEEPBOG",
        show_agents = true,
        tags = {"bog", "deepbog", "dangerous"},
    },
    3
)

QDEF:AddConvo()
    :Loc{
        OPT_EXAMINE_BOGBERRIES = "Examine bogberry bushes",
    }
    :Hub_Location(function(cxt)
        if cxt.location ~= cxt:GetCastMember("main_location") then
            return
        end
        print("Helo?")
        if cxt.quest.param.poi == "bogberry_bushes" then
            cxt:Opt("OPT_EXAMINE_BOGBERRIES")
                :Fn( function(cxt)
                    UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_BOGBERRIES" , nil, nil, cxt.quest)
                end )
        end
    end)
    :State("STATE_BOGBERRIES")
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
                    Look at all these berries!
                * You found some bogberry bushes.
                * There are a bunch of berries that you can pick.
                * It could be a good food source... Or it could be your undoing if you eat the wrong one.
            ]],
            DIALOG_INTRO_DID_TODAY = [[
                * You picked all the bogberries you need for today.
            ]],
            OPT_BLUE = "Pick the blue ones",
            OPT_STRIPED = "Pick the striped ones",
            OPT_PURPLE = "Pick the purple ones",
            OPT_SPOTTED = "Pick the spotted ones",
            OPT_RED = "Pick the red ones",
            OPT_ROTTEN = "Pick the rotten ones",

            DIALOG_PICK = [[
                * You picked the berries of the bushes.
            ]],

            DIALOG_PICKED_ALL = [[
                * You picked all the berries available. If you want more, you will have to come back tomorrow.
            ]],

            DIALOG_PICKED_SOME = [[
                * You picked all the berries you wanted. If you want different ones, you will have to come back tomorrow.
            ]],

            DIALOG_PICKED_NONE = [[
                * You decide to not pick any berries.
            ]],
        }
        :Fn(function(cxt)
            if cxt.location:HasMemoryFromToday("BOGBERRY_PICKED") then
                cxt:Dialog("DIALOG_INTRO_DID_TODAY")
                StateGraphUtil.AddEndOption(cxt)
                return
            end
            cxt:Dialog("DIALOG_INTRO")
            local bogberry_card = Content.GetBattleCard(BOGBERRY_ID)
            if not cxt.location:HasMemoryFromToday("BOGBERRY_GENERATED") then
                cxt.location:Remember("BOGBERRY_GENERATED", table.multipick(copykeys(bogberry_card.effects), 3))
            end
            local available_berries = cxt.location:HasMemoryFromToday("BOGBERRY_GENERATED")
            local selected_berries = {}
            local function GiveBerryCard()
                cxt.enc:GetScreen():ForceWaitOnLine()

                local card = Battle.Card(BOGBERRY_ID, cxt.player, {available_effects = selected_berries, max_charges = #selected_berries})
                cxt.player.battler:AddCard(card)

                cxt.enc:GetScreen():ShowGainCards({card}, function() cxt.enc:ResumeEncounter() end)
                cxt.enc:YieldEncounter()

                cxt:Dialog( "DIALOG_GET_CARD_PRES_BATTLE", card.id)

                cxt.location:Remember("BOGBERRY_PICKED")

                StateGraphUtil.AddEndOption(cxt)
            end
            cxt:RunLoopingFn( function()
                if #available_berries == 0 then
                    cxt:Dialog("DIALOG_PICKED_ALL")
                    GiveBerryCard()
                    return
                end
                for i, id in ipairs(available_berries) do
                    cxt:Opt("OPT_" .. id:upper())
                        :Dialog("DIALOG_PICK")
                        :Fn(function(cxt)
                            table.insert(selected_berries, id)
                            table.arrayremove(available_berries, id)
                        end)
                end
                cxt:Opt("OPT_DONE")
                    :SetSFX( SoundEvents.leave_conversation )
                    :Fn(function(cxt)
                        if #selected_berries == 0 then
                            cxt:Dialog("DIALOG_PICKED_NONE")
                            StateGraphUtil.AddEndOption(cxt)
                        else
                            cxt:Dialog("DIALOG_PICKED_SOME")
                            GiveBerryCard()
                        end
                    end)
                    :MakeUnder()
            end)
        end)
