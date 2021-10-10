Convo("ETB_CAMP_ACTIONS")
    :Loc{
        OPT_CAMP_ACTIONS = "Camp Actions...",
    }
    :Hub_Location(function(cxt)
        if not EscapeTheBogUtil.IsETBCampaign() then
            return
        end
        cxt:Opt("OPT_CAMP_ACTIONS")
            :Fn(function(cxt)
                UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_CAMP" , nil, nil, cxt.quest)
            end)
    end)
    :State("STATE_CAMP")
        :Loc{
            DIALOG_CAMP_ACTIONS = [[
                player:
                    !left
                    While we are here, we should do something...
            ]],

            OPT_EAT_FOOD = "Eat something...",
            REQ_HAVE_FOOD = "You don't have any food you can eat on you right now.",
            REQ_FULL = "You can't eat anymore.",

            SELECT_TITLE = "Select A Food",
            SELECT_DESC = "Select a food item to eat, consuming 1 use on it.",

            DIALOG_EAT_FOOD = [[
                * You ate some {1#card}.
            ]],

            OPT_REST_ETB = "Rest",
            DIALOG_REST_ETB = [[
                player:
                    !left
                    I think I will just rest here.
                * You decide to take a short rest here.
            ]],

            OPT_SLEEP_ETB = "Sleep here",
            DIALOG_SLEEP_ETB = [[
                player:
                    !left
                    Time for me to go to sleep.
                * You decide to sleep here until you wake up.
            ]],
            DIALOG_SLEEP_DOTS_ETB = [[
                * ...
            ]],

            REQ_CAN_SLEEP_ETB = "You are too awake to sleep right now.",
            DIALOG_SLEEP_STARVED_TO_DEATH_ETB = [[
                * This is a sleep that you are never waking up from.
                * You have starved to death in your sleep.
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt:Dialog("DIALOG_CAMP_ACTIONS")
            end

            if cxt.player and cxt.player.etb_hunger then
                local cards = {}
                for i, card in ipairs(cxt.player.battler.cards.cards) do
                    print(card.id)
                    if cxt.player.etb_hunger:CanEatFood(card) then
                        table.insert(cards, card)
                    end
                end

                cxt:Opt("OPT_EAT_FOOD")
                    :ReqCondition(#cards > 0, cxt.player.etb_hunger:CanEatFood() and "REQ_HAVE_FOOD" or "REQ_FULL")
                    :Fn(function(cxt)
                        cxt:Wait()
                        EscapeTheBogUtil.InsertSelectCardScreen(
                            cards,
                            cxt:GetLocString("SELECT_TITLE"),
                            cxt:GetLocString("SELECT_DESC"),
                            Widget.BattleCard,
                            function(card)
                                cxt.enc:ResumeEncounter( card )
                            end
                        )
                        local card = cxt.enc:YieldEncounter()
                        if card then
                            local food_data = deepcopy(card.food_data_etb)
                            TheGame:BroadcastEvent("calculate_food_value_etb", food_data, card)

                            card:ConsumeCharge()

                            local charges, max_charges = card:GetCharges()
                            if charges == 0 or charges == nil then
                                cxt.player.battler:RemoveCard( card )
                            end

                            cxt:Dialog("DIALOG_EAT_FOOD", card)

                            if food_data.hunger_restoration and food_data.hunger_restoration ~= 0 then
                                cxt.player.etb_hunger:DeltaStat(-food_data.hunger_restoration)
                            end

                            if food_data.health_delta and food_data.health_delta ~= 0 then
                                ConvoUtil.DoHealthDelta(cxt, food_data.health_delta)
                            end

                            if food_data.resolve_delta and food_data.resolve_delta ~= 0 then
                                ConvoUtil.DoResolveDelta(cxt, food_data.resolve_delta)
                            end
                        end
                    end)
            end

            cxt:Opt("OPT_SLEEP_ETB")
                :ReqCondition(not cxt.player.etb_fatigue or cxt.player.etb_fatigue:CanSleep(), "REQ_CAN_SLEEP_ETB")
                :Fn( function(cxt)
                    cxt:Dialog("DIALOG_SLEEP_ETB")
                    cxt:FadeOut()

                    EscapeTheBogUtil.DoSleepConvo(cxt)
                end )

            StateGraphUtil.AddBackButton(cxt)
        end)
