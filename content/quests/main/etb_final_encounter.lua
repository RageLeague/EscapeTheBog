local available_handlers = {"fellemo", "kalandra"}
local HANDLER_ID =
{
    fellemo = "SPARK_CONTACT",
    kalandra = "KALANDRA",
}
local ILLUSION_ID =
{
    fellemo = "BOGGER_BOSS_FELLEMO",
    kalandra = "BOGGER_BOSS_KALANDRA",
}

local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,
    on_init = function(quest)
        quest.param.handler_id = table.arraypick(available_handlers)
        quest.param["handler_" .. quest.param.handler_id] = true
        quest:AssignCastMember("handler")
        local current_day = math.floor( TheGame:GetGameState():GetDateTime() / 2 ) + 1
        quest.param.handler_dead = quest:GetCastMember("handler"):IsDead() or current_day >= 6
        if quest.param.handler_dead and not quest:GetCastMember("handler"):IsRetired() then
            quest:GetCastMember("handler"):Kill()
        end
        quest:AssignCastMember("handler")
    end,
}
:AddObjective{
    id = "starting_out",
    state = QSTATUS.ACTIVE,
}
:AddCast{
    cast_id = "illusion_boss",
    when = QWHEN.MANUAL,
    cast_fn = function(quest, t)
        local id = ILLUSION_ID[quest.param.handler_id]
        if quest.param.handler_dead then
            id = "BOGGER_BOSS"
        end
        local agent = AgentUtil.GetOrSpawnAgentbyAlias(id)
        table.insert(t, agent)
    end,
}
:AddCast{
    cast_id = "handler",
    when = QWHEN.MANUAL,
    cast_fn = function(quest, t)
        quest.param.handler_id = quest.param.handler_id or table.arraypick(available_handlers)
        local agent = AgentUtil.GetOrSpawnAgentbyAlias(HANDLER_ID[quest.param.handler_id])
        table.insert(t, agent)
    end,
    no_validation = true,
}

local function AddAttackOptions(cxt)
end

QDEF:AddConvo("starting_out")
    :ConfrontState("STATE_CONF")
        :Loc{
            DIALOG_INTRO = [[
                * As you enter the mine, you saw the most curious looking {illusion_boss.species}.
                player:
                    !left
                illusion_boss:
                    !right
                * By the looks of it, {illusion_boss.heshe} must be the leader of the Boggers, and if anyone is behind the madness you are currently in, it must be {illusion_boss.himher}.
                illusion_boss:
                {not handler_dead?
                    {handler_fellemo?
                        {player_rook?
                            !hips
                            {player.name}! You old scoundrel! I thought you were dead!
                            I must say, you looked really convincing back then.
                        }
                        {not player_rook?
                            !crossed
                            You weren't dead after all.
                            You must be tougher than you look.
                        }
                    }
                    {handler_kalandra?
                        {player_sal?
                            !hips
                            {player.name}! I knew you wouldn't be dead.
                            The influence of the Bog is growing stronger than ever before, and I thought you couldn't adapt.
                        }
                        {not player_sal?
                            !crossed
                            You weren't dead after all.
                            You shouldn't just left me alone like that. It's not very nice.
                        }
                    }
                }
                {handler_dead?
                    !crossed
                    So, you weren't dead after all.
                    I thought you would be long dead before that, but I guess I underestimated your strength.
                }
                player:
                    Oh yeah? Well jokes on you, I am here to end your reign of madness!
                illusion_boss:
                {not handler_dead?
                    What are you talking about? You don't recognize {1}?
                }
                {handler_dead?
                    Hah, you are just like the ones before. Soon, you shall join them.
                }
            ]],
        }
        :Fn(function(cxt)
            -- If you don't have madness removed, the name of the handler will never be shown.
            cxt:Dialog("DIALOG_INTRO", EscapeTheBogUtil.ObfuscateWords(cxt:GetCastMember("handler"):GetName(), 1))
            cxt:GoTo("STATE_FIGHT")
        end)
    :State("STATE_FIGHT")
        :Loc{
            OPT_ATTACK_FAITH = "Attack {illusion_boss}'s faith",
            DIALOG_ATTACK_FAITH = [[
                player:
                    $miscMocking
                    Ah, you sure the Bog is on your side?
                agent:
                    What is this? What do you know about the Bog?
            ]],
            DIALOG_ATTACK_FAITH_SUCCESS = [[
                player:
                    !cruel
                    $miscMocking
                    You think you are trying to kill me with the Bog, but I prevailed.
                    This means that the Bog is on my side, not yours.
                    The Bog has been helping me survive, blessing me, giving me strength.
                    !fight
                    And now, it shall help me end your reign of madness!
                agent:
                    !scared
                    $angryTakenAback
                {not handler_dead?
                    {handler_fellemo?
                        Is- is this one of your sick jokes?
                        !angry
                        Stop this at once!
                    }
                    {handler_kalandra?
                        You- you are scaring me with this crazy talk!
                        What have you been doing in the Bog?
                    }
                }
                {handler_dead?
                    You— you know nothing of what the Bog wants!
                }
                * It seems like you have shaken {agent}'s resolve! Now is your chance to strike!
            ]],
            DIALOG_ATTACK_FAITH_FAILURE = [[
                player:
                    !crossed
                    It seems to me you're just putting words in the Bog's mouth.
                agent:
                    !disappoint
                    $neutralResigned
                    You are clearly mad, {player.name}.
                    I suggest you drop this before I become impatient.
            ]],
            OPT_ATTACK = "Attack!",
            DIALOG_ATTACK = [[
                player:
                    !angry
                    This is the end of you!
            ]],
            DIALOG_ATTACK_WIN = [[
                player:
                    !angry_point
                    Had enough?
                    Lift my madness, or I will lift your life!
                agent:
                {not handler_dead?
                    You are mad, alright. But I have nothing to do with this.
                }
                {handler_dead?
                    The bog does not surrender. So neither will I.
                }
                player:
                    Still have some fight in you, huh?
            ]],
        }
        :Fn(function(cxt)
            local core_arg = nil
            cxt:RunLoop(function()
                cxt:Opt("OPT_ATTACK_FAITH")
                    :Dialog("DIALOG_ATTACK_FAITH")
                    :Negotiation{
                        flags = NEGOTIATION_FLAGS.NO_IMPATIENCE,
                        enemy_resolve_required = 30,
                        on_start_negotiation = function(minigame)
                            core_arg = minigame.opponent_negotiator:FindCoreArgument()
                        end,

                        on_success = function(cxt, minigame)
                            cxt.quest.param.boss_fight_cards_to_win = core_arg.cards_to_win
                            cxt.quest.param.boss_fight_modifiers_to_remove = core_arg.modifiers_to_remove
                            cxt:Dialog("DIALOG_ATTACK_FAITH_SUCCESS")
                            AddAttackOption(cxt)
                        end,

                    }
                    :OnFailure()
                        :Dialog("DIALOG_ATTACK_FAITH_FAILURE")
                AddAttackOption(cxt)
            end)
        end)
    :State("STATE_FLASHBACK")
    :State("STATE_POST_FIGHT_SPARE")
    :State("STATE_POST_FIGHT_KILL")
