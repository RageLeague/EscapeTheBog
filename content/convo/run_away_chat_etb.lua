Convo("RUN_AWAY_CHAT_ETB")
    :State("STATE_RAN")
        :Loc{
            DIALOG_RUNAWAY = [[
                player:
                    !exit
                agent:
                    !exit
                * You run from battle, and you keep running.
                * You outrun your pursuers, but you can't outrun your reputation.
            ]],
            DIALOG_RUNAWAY_SECRET = [[
                player:
                    !exit
                agent:
                    !exit
                * You run from battle, and you keep running.
                * At least no-one knows of your shame.
            ]],
            OPT_KEEP_RUNNING = "Keep Running",
        }
        :Fn(function(cxt, params)

            local battle, no_fail, secret = params.battle, params.no_fail, params.secret

            cxt:Dialog(secret and "DIALOG_RUNAWAY_SECRET" or "DIALOG_RUNAWAY")

            if not no_fail and cxt.quest and cxt.quest:IsActive() then
                cxt.quest:Fail()
            end

            -- If the player fled, allies don't like them.
            for i, fighter in battle:GetPlayerTeam():Fighters() do
                if fighter:GetStatus() ~= FIGHT_STATUS.DEAD and fighter:GetStatus() ~= FIGHT_STATUS.FLED then
                    local agent = fighter.agent
                    if not agent:IsPlayer() then
                        fighter.agent:OpinionEvent( OPINION.ABANDONED )
                        agent:Dismiss()
                    end
                end
            end

            -- You might be a coward, if someone saw.
            local no_one_knows = secret
            if not no_one_knows then
                cxt:GainCards{"coward"}
            end

            cxt:Opt("OPT_KEEP_RUNNING")
                :MakeUnder()
                :Fn(function(cxt)
                    local loc_quest = EscapeTheBogUtil.GetAssociatedQuest(cxt.location)
                    assert(loc_quest, "Not in a valid location")
                    local runaway_quest = loc_quest.param.previous_location or table.arraypick(loc_quest.param.exits)
                    local runaway_loc = runaway_quest:GetCastMember("main_location")
                    runaway_quest.param.previous_location = loc_quest
                    cxt.encounter:DoLocationTransition( runaway_loc )
                    EscapeTheBogUtil.TryMainQuestFn("AdvanceTime", 1, "TRAVEL")

                    -- StateGraphUtil.AddEndOption(cxt)
                    cxt:End()
                end)
        end)

    -- :State("STATE_RAN_SECRET")
    --     :Loc{

    --     }
    --     :Fn(function(cxt, params)

    --         cxt:GoTo("STATE_RAN")
    --     end)
