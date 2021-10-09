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
            REQ_HAVE_FOOD = "You don't have any food on you right now.",

            SELECT_TITLE = "Select A Food",
            SELECT_DESC = "Select a food item to eat, consuming 1 use on it.",

            DIALOG_EAT_FOOD = [[
                * You ate some {1#card}.
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
                    if card.food_data_etb then
                        table.insert(cards, card)
                    end
                end

                cxt:Opt("OPT_EAT_FOOD")
                    :ReqCondition(#cards > 0, "REQ_HAVE_FOOD")
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

            StateGraphUtil.AddBackButton(cxt)
        end)
