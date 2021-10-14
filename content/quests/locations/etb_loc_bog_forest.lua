local QDEF
QDEF = EscapeTheBogUtil.AddBogLocationQuest(
    {
        entry_encounter = EscapeTheBogUtil.GenericInitialEncounterTable,
        repeat_encounter = EscapeTheBogUtil.GenericRepeatEncounterTable,
        sleep_encounter = EscapeTheBogUtil.GenericSleepEncounterTable,
        on_init = function(quest)
            quest.param.poi = table.arraypick{"nothing", "bogberry_bushes"}
        end,
        GetPathDesc = function(quest)
            if not quest.param.desc_number then
                quest.param.desc_number = EscapeTheBogUtil.TryMainQuestFn("RequestRiffleShuffle", QDEF.id .. "_DESC", 1, 5) -- math.random(1, 7)
            end
            local desc = {}
            table.insert(desc, quest:GetLocalizedStr("DESC_" .. quest.param.desc_number))
            -- if quest.param.poi == "bogberry_bushes" then
            --     table.insert(desc, quest:GetLocalizedStr("DESC_BOGBERRIES"))
            -- end
            return table.concat(desc, "\n")
        end,
    },
    {
        name = "Bog Forest",
        desc = "The part of the bog with a lot of overgrown trees. A source of many dangers.",
        plax = "EXT_Bog_Forest_01",
        show_agents = true,
        tags = {"bog", "forest", "dangerous"},
    },
    3
)

QDEF:Loc{
    DESC_1 = "This path leads to an area with a lot of tall trees. It is hard to see anything beyond that.",
    DESC_2 = "You can see some animals moving about down this path. You should proceed with caution.",
    DESC_3 = "This path leads to a bunch of trees with lots of mushrooms. Eating them is almost certainly a bad idea.",
    DESC_4 = "This path leads to some pointy trees. Seems like a bad omen.",
    DESC_5 = "The trees down this path are lusher than most trees you've seen in the bog, although what is good for these trees are probably not good for you.",
}

QDEF:AddConvo()
    :Loc{
        OPT_EXAMINE_BOGBERRIES = "Examine bogberry bushes",
        TT_EXAMINE_BOGBERRIES = "This is a good source of food, as long as you don't get poisoned to death.",
    }
    :Hub_Location(function(cxt)
        if cxt.location ~= cxt:GetCastMember("main_location") then
            return
        end
        if not cxt.quest.param.searched_for_poi then
            cxt:Opt("OPT_FIND_POI_ETB")
                :Fn( function(cxt)
                    UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_POI" , nil, nil, cxt.quest)
                end )
        else
            if cxt.quest.param.poi == "bogberry_bushes" then
                cxt:Opt("OPT_EXAMINE_BOGBERRIES")
                    :PostText("TT_EXAMINE_BOGBERRIES")
                    :Fn( function(cxt)
                        UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_BOGBERRIES" , nil, nil, cxt.quest)
                    end )
            end
        end
    end)
    :State("STATE_POI")
        :Quips{
            {
                tags = "found_nothing",
                [[
                    * You find nothing of note here.
                ]],
                [[
                    * You find a cool rock. It is shaped like a perfect disc.
                    * It doesn't help you, though.
                ]],
                [[
                    * You find that this is a huge waste of time.
                ]],
                [[
                    * You find an extremely tall tree.
                    * That's cool, I guess?
                ]],
            },
        }
        :Loc{
            DIALOG_BOGBERRIES = [[
                * You find a bunch of bushes.
                * On those bushes are berries of all kinds of color.
                * Perhaps they are edible? You have no idea which ones you can safely eat.
            ]],
        }
        :Fn(function(cxt)
            if cxt.quest.param.poi == "bogberry_bushes" then
                cxt:Dialog("DIALOG_BOGBERRIES")
            else
                cxt:Quip( cxt.player, "found_nothing")
            end
            cxt.quest.param.searched_for_poi = true
            EscapeTheBogUtil.TryMainQuestFn("AdvanceTime", 1, "SEARCH")
            StateGraphUtil.AddEndOption(cxt)
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

                -- EscapeTheBogUtil.TryMainQuestFn("AdvanceTime", 1, "SEARCH")

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
