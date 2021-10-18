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
local PARASITE_VALUES =
{
    [CARD_RARITY.BASIC] = 3,
    [CARD_RARITY.COMMON] = 6,
    [CARD_RARITY.UNCOMMON] = 9,
    [CARD_RARITY.RARE] = 12,
    [CARD_RARITY.UNIQUE] = 15,
    [CARD_RARITY.BOSS] = 15,
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
            -- quest:GetCastMember("handler"):Kill()
        end
        quest:AssignCastMember("illusion_boss")
    end,
}
:AddObjective{
    id = "starting_out",
    state = QSTATUS.ACTIVE,
}
:AddObjective{
    id = "escape_bog",
}
:AddObjective{
    id = "investigate_further",
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
    no_validation = true,
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
:AddCast{
    cast_id = "bog_monster",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetMainQuest():GetCastMember("bog_monster"))
    end,
    no_validation = true,
}
:AddQuestLocation{
    cast_id = "exit_1",
    show_player = true,
    name = "Ancient Mine Entrance",
    desc = "An entrance to an ancient mine. The exit of your current location, and a path to civilization.",
    plax = "INT_Bog_Cave_01",
    show_agents = true,
    tags = {"cave", "bog", "mine_entrance"},
    indoors = true,
}
:AddQuestLocation{
    cast_id = "exit_2",
    show_player = true,
    name = "Bog Road",
    desc = "A path to civilization. You remember it clearly.",
    plax = "EXT_Bog_Road_01",
    show_agents = true,
    tags = {"bog", "deepbog", "road"},
}
:AddQuestLocation{
    cast_id = "exit_3",
    show_player = true,
    name = "Bog Gate",
    desc = "Your destination. Civilization.",
    plax = "EXT_TerritoryGate_Entrance",
    show_agents = true,
    tags = {"bog", "gate"},
    indoors = true,
}

local function AddAttackOptions(cxt)
    cxt:Opt("OPT_ATTACK")
        :Dialog("DIALOG_ATTACK")
        :Battle{
                flags = BATTLE_FLAGS.BOSS_FIGHT | BATTLE_FLAGS.ISOLATED | BATTLE_FLAGS.NO_BYSTANDERS | BATTLE_FLAGS.NO_REWARDS | BATTLE_FLAGS.NO_FLEE | BATTLE_FLAGS.NO_BURRS,

                on_start_battle = function(battle)
                    local fighter = battle:GetFighterForAgent(cxt.quest:GetCastMember("illusion_boss"))
                    if fighter then
                        fighter.behaviour.suppress_conditions = {}

                        if cxt.quest.param.boss_fight_modifiers_to_remove then
                            for _,condition_id in ipairs(cxt.quest.param.boss_fight_modifiers_to_remove) do
                                fighter.behaviour.suppress_conditions[condition_id] = true
                            end
                        end

                        if fighter.behaviour.AddBossConditions then
                            fighter.behaviour:AddBossConditions(fighter)
                        end

                        if cxt.quest.param.boss_fight_cards_to_win then
                            for _,won_card in ipairs( cxt.quest.param.boss_fight_cards_to_win ) do
                                local card = Battle.Card( won_card, battle.player_team:Primary() )
                                card.show_dealt = true
                                battle:DealCard( card, battle:GetDrawDeck() )
                            end
                        end
                    end
                end

            }
            :OnWin()
                :Fn(function()
                    if cxt:GetAgent():IsDead() then
                        cxt:Dialog("DIALOG_ATTACK_KILLED")
                        cxt:GoTo("STATE_POST_FIGHT_KILL")
                    else
                        -- cxt:Dialog("DIALOG_ATTACK_WIN")
                        cxt:GoTo("STATE_POST_FIGHT_SPARE")
                    end
                end)
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
            cxt:TalkTo(cxt:GetCastMember("illusion_boss"))
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
            DIALOG_ATTACK_KILLED = [[
                * You have killed the Bogger leader in battle.
            ]],
            -- DIALOG_ATTACK_WIN = [[
            --     player:
            --         !angry_point
            --         Had enough?
            --         Lift my madness, or I will lift your life!
            --     agent:
            --     {not handler_dead?
            --         You are mad, alright. But I have nothing to do with this.
            --     }
            --     {handler_dead?
            --         The bog does not surrender. So neither will I.
            --     }
            --     player:
            --         Still have some fight in you, huh?
            -- ]],
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
                            AddAttackOptions(cxt)
                        end,

                    }
                    :OnFailure()
                        :Dialog("DIALOG_ATTACK_FAITH_FAILURE")
                AddAttackOptions(cxt)
            end)
        end)
    :State("STATE_FLASHBACK")
        :Loc{
            DIALOG_INTRO = [[
                left:
                    !exit
                right:
                    !exit
                * Memories are flowing through you.
                * Memories of who you are, and why you are here.
                * It all started, {1} {1*day|days} ago...
                *** Okay, if you are skipping the dialog, you are clearly not interested.
                *** Yeah just skip the flashback, why don't you. You clearly don't want lore.
                *** So why waste your time?
            ]],
            OPT_SKIP = "Skip dialog",
            DIALOG_SKIP = [[
                * Alright, then, I guess you remembered everything.
                * Good.
            ]],
            OPT_FLASHBACK = "Continue Flashback",

            DIALOG_FLASH_INTRO = [[
                {handler_fellemo?
                    {player_rook?
                        agent:
                            It's good that we are working together again, even for just one more time.
                            We have made such a good team in the past before.
                            Remember in the Roaloch? Rentoria? The-
                        player:
                            Are you getting senile, old slug? You mentioned this every time we work together for the past few days.
                        agent:
                            !hips
                            Hah! I am just reminiscing the good old days.
                            Anyway, we need to find the ancient artifact. It should be here somewhere.
                        player:
                            You don't say.
                    }
                    {player_sal?
                        player:
                            Remind me why I am working with you again?
                        agent:
                            You want Kashio gone, don't you? I can help you with that.
                            But first, you need to do one more task for me: finding the ancient artifact.
                        player:
                            I swear, if-
                        * You realized that mentioning Prindo in front of {agent} in this crucial moment might not be the wisest idea.
                        * You both have a task ahead.
                    }
                    {player_arint?
                        player:
                            What are we trying to find here?
                        agent:
                            Ah, I supposed I never mentioned it to you, {player}.
                            There is supposed to be an ancient artifact somewhere around here, according to my intel.
                            We need to find it.
                        player:
                            Let me guess, your intel comes from a man whose name starts with an "R" and ends with a "K".
                        agent:
                            ...
                        player:
                            Look, you should know better than anyone that this man could not be trusted.
                            What if this intel is a ruse? What if-
                    }
                    {not player_rook and not player_sal and not player_arint?
                        player:
                            What are we trying to find here?
                        agent:
                            Ah, I supposed I never mentioned it to you, {player}.
                            There is supposed to be an ancient artifact somewhere around here, according to my intel.
                            We need to find it.
                        player:
                            What does it look like.
                        agent:
                            ...
                            We will know when we see it.
                        player:
                            Uh huh.
                    }
                }
                {handler_kalandra?
                    {player_sal?
                        player:
                            !bashful
                            I know that we haven't talked for a very long time, but I just want to say...
                            I'm glad that we are back together.
                        agent:
                            !happy
                            I feel the same way.
                        player:
                            So, uh... What are we looking for, exactly?
                        agent:
                            An ancient artifact, guarded heavily in an ancient mine.
                            From what I have gathered, it can very easily turn the tide of the revolution.
                    }
                    {not player_sal?
                        player:
                            So, uh... What are we looking for, exactly?
                        agent:
                            An ancient artifact, guarded heavily in an ancient mine.
                            From what I have gathered, it can very easily turn the tide of the revolution.
                        player:
                            I guess this means that we really need to find it, then.
                        agent:
                            Exactly.
                    }
                }
                * Suddenly, you are attacked by a group of Boggers!
                bogger:
                    !right
                    Another one who seeks the treasure of the bog.
                    You, like your predecessors, shall fertilize the bog with your blood!
                *** You and {agent} is looking for an ancient artifact, but were attacked by boggers.
            ]],
            DIALOG_FLASH_DEFEND = [[
                bogger:
                    !exit
                * You dispatched the boggers with no difficulty at all.
                agent:
                    !right
                    Are you alright?
                player:
                    Yeah. I'm good. It is no big deal.
                * But soon, you realized that it is, in fact, a big deal.
                player:
                    !injured
                * You feel like you energy is draining out of your body.
                agent:
                    Seriously, {player}, you don't look so good.
                    Do you want to-----------rest?
                player:
                    I- I'm fine.
                * You know this is a complete lie.
                * You feel your energy, your sanity, is twisted and drained from your mind.
                * Whatever happened during the fight with the boggers must have caused this.
                * Soon, you completely fainted.
            ]],
            DIALOG_FLASH_DEFEND_PST = [[
                agent:
                    !scared
                    {player},---------alright?
                    {player}?
                    {1}!!!
                * You don't remember much after that.
            ]],
        }
        :Fn(function(cxt)
            local current_day = math.floor( TheGame:GetGameState():GetDateTime() / 2 ) + 1
            cxt:Dialog("DIALOG_INTRO", current_day)
            if cxt.enc:GetScreen():IsAutoSkip() then
                cxt:RunLoop(function(cxt)
                    cxt:Opt("OPT_SKIP")
                        :Dialog("DIALOG_SKIP")
                        :Fn(function(cxt)
                            cxt.quest.param.skipped_flashback = true
                        end)
                        :Pop()
                    cxt:Opt("OPT_FLASHBACK")
                        :Pop()
                end)
            end
            if not cxt.quest.param.skipped_flashback then
                cxt:TalkTo(cxt:GetCastMember("handler"))
                cxt.enc:PresentAgent(cxt.player, SIDE.LEFT)
                cxt.enc:PresentAgent(cxt:GetAgent(), SIDE.RIGHT)
                cxt.enc.scratch.opfor = CreateCombatParty("BOGGER_PATROL", cxt.quest:GetRank(), cxt.location)
                cxt.enc.ignore_obfuscation = true
                cxt:ReassignCastMember("bogger", cxt.enc.scratch.opfor[1])
                cxt:FadeIn()
                cxt:Dialog("DIALOG_FLASH_INTRO")
                local opt = cxt:Opt("OPT_DEFEND")
                    :Fn(function(cxt)
                        for i, agent in ipairs(cxt.enc.scratch.opfor) do
                            if not agent:IsRetired() then
                                agent:Retire()
                            end
                        end
                    end)
                    :Dialog("DIALOG_FLASH_DEFEND")
                    :FadeOut()
                    :Dialog("DIALOG_FLASH_DEFEND_PST", EscapeTheBogUtil.ObfuscateWords(cxt.player:GetName(), 1))
                    :Fn(function(cxt)
                        cxt.enc.ignore_obfuscation = nil
                        cxt:GoTo("STATE_POST_FLASHBACK")
                    end)
            else
                cxt:GoTo("STATE_POST_FLASHBACK")
            end
        end)
    :State("STATE_POST_FIGHT_SPARE")
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !angry_point
                    Had enough?
                    Lift my madness, or I will lift your life.
                agent:
                {not handler_dead?
                    You are mad, alright, and I have nothing to do with it.
                }
                {handler_dead?
                    The Bog does not surrender, grifter, and neither will I.
                }
                player:
                    Seems like you are unwilling to cooperate.
                    Perhaps I should end you, right here, right now.
            ]],
            OPT_EXECUTE = "Execute the High Priest",
            OPT_EXECUTE_STRONG = "<#PENALTY>Execute {agent.himher}</>",
            DIALOG_EXECUTE = [[
                agent:
                    !right
                    !scared
                * You swiftly executed the High Priest.
                agent:
                    !exit
            ]],
            OPT_QUESTION_1 = "Ask the High Priest why you shouldn't just kill {agent.himher} right now",
            DIALOG_QUESTION_1 = [[
                player:
                    Give me a reason I shouldn't just kill you right now.
                agent:
                {not handler_dead?
                    {1}
                }
                {handler_dead?
                    You cannot kill me. I am one with the Bog.
                }
                player:
                {heard_handler_name?
                    {handler}? Why are you bringing up that name?
                    Is that your pathetic attempt to upset me?
                }
                {not heard_handler_name?
                    Terrible reasoning. I'm afraid this can only end one way.
                }
            ]],
            DIALOG_QUESTION_1_PT1 = "The Bog must have corrupted your mind.",
            DIALOG_QUESTION_1_PT2 = "You don't even seem to recognize me, {handler.name}.",
            OPT_QUESTION_2 = "Ask about {handler}",
            DIALOG_QUESTION_2 = [[
                player:
                    What do you know about {handler}?
                agent:
                {handler_fellemo?
                    Don't--------, {player.name}.---am {handler.name}.
                }
                {handler_kalandra?
                    ----serious? You-----------------me, {handler.name}?
                }
                player:
                    You mean, you are {handler}?
                    I don't believe you!
            ]],
            DIALOG_SPARE = [[
                * You couldn't do it. There are so many doubts in your mind that you just couldn't do it.
                * You dropped your weapons.
                agent:
                    Looks like you finally come to your senses.
                * Suddenly, you heard a strange voice, a most <b><i>TERRIFYING</></> voice.
                bog_monster:
                    !right
                    <#PENALTY>KILL {agent.gender:HIM|HER|THEM}!</>
                    <#PENALTY>THE BOG DEMANDS SACRIFICE!</>
            ]],
            OPT_BREAK_FREE = "Break free of the bog's influence",
            DIALOG_BREAK_FREE = [[
                player:
                    No! I will not follow your command!
            ]],
            DIALOG_BREAK_FREE_SUCCESS = [[
                player:
                    I will not listen to you!
                    So just leave me alone!
                * Your resolve has overcome the Bog's influence.
                * It has taken a lot of toll on you though, and you passed out shortly.
            ]],
            DIALOG_BREAK_FREE_SUCCESS_PST = [[
                agent:
                    !right
                    !scared
                    {1}, you--------?
                    {1}?
                    {player.name}!!!
            ]],
            DIALOG_BREAK_FREE_FAILURE = [[
                bog_monster:
                    <#PENALTY>DO IT!</>
                player:
                    No! I-
                agent:
                    !right
                    !scared
                player:
                    I'LL DO IT!
                    !cruel
                    <#PENALTY>EXCELLENT!</>
                agent:
                    !exit
                * The execution is over in a blink of an eye.
                * The leader of the boggers drops dead at your feet.
            ]],

            SIT_MOD = "The Bog's influence is very strong",
            SIT_MOD_PARASITE = "You have bog parasites on you",
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt:Dialog("DIALOG_INTRO")
            end
            if (cxt.enc.scratch.question_state or 0) == 0 then
                cxt:Opt("OPT_QUESTION_1")
                    :Fn(function(cxt)
                        if not cxt.quest.param.handler_dead then
                            cxt.enc.ignore_obfuscation = true
                            local str = {
                                EscapeTheBogUtil.TryMainQuestFn("DoObfuscateText", cxt:GetLocString( "DIALOG_QUESTION_1_PT1" )),
                                EscapeTheBogUtil.TryMainQuestFn("DoObfuscateText", cxt:GetLocString( "DIALOG_QUESTION_1_PT2" ))
                            }
                            local handler_name = cxt:GetCastMember("handler"):GetName()
                            local display_str = table.concat( str, "\n" )
                            if display_str:find(handler_name) then
                                cxt.quest.param.heard_handler_name = true
                            end
                            cxt:Dialog("DIALOG_QUESTION_1", display_str)
                            cxt.enc.ignore_obfuscation = nil
                        else
                            cxt:Dialog("DIALOG_QUESTION_1")
                        end
                        cxt.enc.scratch.question_state = 1
                    end)
            elseif (cxt.enc.scratch.question_state or 0) == 1 and cxt.quest.param.heard_handler_name then
                cxt:Opt("OPT_QUESTION_2")
                    :Fn(function(cxt)
                        cxt.enc.ignore_obfuscation = true
                        cxt:Dialog("DIALOG_QUESTION_2")
                        cxt.enc.ignore_obfuscation = nil
                        cxt.enc.scratch.question_state = 2
                    end)
            elseif (cxt.enc.scratch.question_state or 0) == 3 then
                local sit_mods = {
                    { value = 20, text = cxt:GetLocString("SIT_MOD") }
                }
                -- Calculate parasites
                local parasite_values = 0

                local battle_defs = require "battle/battle_defs"
                for i, card in ipairs(cxt.player.battler.cards.cards) do
                    if card:IsFlagged( battle_defs.CARD_FLAGS.PARASITE ) then
                        parasite_values = parasite_values + (PARASITE_VALUES[card.rarity] or 15)
                    end
                end

                local negotiation_defs = require "negotiation/negotiation_defs"
                for i, card in ipairs(cxt.player.negotiator.cards.cards) do
                    if card:IsFlagged( negotiation_defs.CARD_FLAGS.PARASITE ) then
                        parasite_values = parasite_values + (PARASITE_VALUES[card.rarity] or 15)
                    end
                end

                if parasite_values then
                    table.insert(sit_mods, { valule = parasite_values, text = cxt:GetLocString("SIT_MOD_PARASITE")})
                end

                -- Actual option
                cxt:BasicNegotiation("BREAK_FREE", {
                    target_agent = cxt:GetCastMember("bog_monster"),
                    situation_modifiers = sit_mods,
                })
                    :OnSuccess()
                        :FadeOut()
                        :Fn(function(cxt)
                            cxt.enc.ignore_obfuscation = true
                            cxt:Dialog("DIALOG_BREAK_FREE_SUCCESS_PST", EscapeTheBogUtil.TryMainQuestFn("DoObfuscateText", cxt.player:GetName()))
                            cxt.enc.ignore_obfuscation = nil
                        end)
                        :GoTo("STATE_FLASHBACK")
                    :OnFailure()
                        :Fn(function(cxt)
                            cxt:GetAgent():Kill()
                        end)
                        :GoTo("STATE_POST_FIGHT_KILL")
            end
            cxt:Opt(cxt.enc.scratch.question_state and "OPT_EXECUTE_STRONG" or "OPT_EXECUTE")
                :Dialog("DIALOG_EXECUTE")
                :Fn(function(cxt)
                    cxt:GetAgent():Kill()
                end)
                :GoTo("STATE_POST_FIGHT_KILL")
            if (cxt.enc.scratch.question_state or 0) == 2 then
                cxt:Opt("OPT_BACK_BUTTON")
                    :MakeUnder()
                    :Dialog("DIALOG_SPARE")
                    :Fn(function(cxt)
                        cxt.enc.scratch.question_state = 3
                    end)
            end
        end)
    :State("STATE_POST_FIGHT_KILL")
        :Loc{
            DIALOG_INTRO = [[
                player:
                    I did it! I killed the leader of the bog!
                    I-
                * Suddenly, you passed out.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt:FadeOut()
            cxt:GoTo("STATE_FLASHBACK")
        end)
    :State("STATE_POST_FLASHBACK")
        :Loc{
            DIALOG_INTRO_ESCAPE = [[
                * You feel like a curse has been lifted from you.
                * All your misfortunes in the past few days have ended, because you have defeated the source of it all.
                {is_hungry?
                    * Strangely, you don't feel as hungry as you were before.
                }
                * With that out of your way, it is time for you to leave.
            ]],
            DIALOG_INTRO_FRIEND = [[
                * You wake up to find {handler} by your side.
                handler:
                    Feeling better?
                player:
                    Yeah.
                    In fact, I feel a huge weight just got lifted from my sholders.
                handler:
                    I gotta say, you are out for a long time.
                    I thought you are dead. Again.
                {handler_fellemo?
                    {player_rook?
                        But I knew you wouldn't die so easily.
                    player:
                        You don't say.
                    }
                    {player_arint?
                        But I knew I could count on you, {player}.
                    player:
                        Thanks, I guess.
                    }
                    {not player_rook and not player_arint?
                        You took a lot of time to slack off, don't you.
                    player:
                        Hey. In my defense, I couldn't help it.
                    handler:
                        Sure, that's what they all say.
                    }
                    Anyway, we should focus on our task ahead.
                    We have a job to do.
                }
                {handler_kalandra?
                    {player_sal?
                        But I just can't believe it, you know.
                        You've been through so much, {player}, and I can't imagine you would just die now.
                    player:
                        !bashful
                        Can we just go back to finding the artifact now? You are making me blush.
                    handler:
                        !agree
                        Yeah, of course.
                    }
                    {not player_sal?
                        I'm glad you are okay in the end, though.
                    player:
                        Thanks.
                    handler:
                        Anyway, we should focus on our task ahead.
                        We have a job to do.
                    }
                }
                {is_hungry?
                handler:
                    !give
                    But before we do anything, eat this.
                    We can't do this on an empty stomach.
                player:
                    !take
                    Thanks.
                    Actually, it's really weird, but I don't feel as hungry as before.
                handler:
                    Good for you, then.
                }
            ]],
        }
        :Fn(function(cxt)
            TheGame:GetGameState():GetMainQuest().param.madness_cured = true
            cxt.player:RemoveAspect("etb_fatigue")
            cxt.player:RemoveAspect("etb_hunger")
            cxt.enc:PresentAgent(cxt.player, SIDE.LEFT)
            if cxt.quest.param.handler_dead or cxt:GetCastMember("illusion_boss"):IsDead() then
                -- The default ending
                cxt:FadeIn()
                cxt:Dialog("DIALOG_INTRO_ESCAPE")
                cxt.quest:Complete("starting_out")
                cxt.quest:Activate("escape_bog")

                StateGraphUtil.AddEndOption(cxt)
            else
                cxt.enc:PresentAgent(cxt:GetCastMember("handler"), SIDE.RIGHT)
                -- The better ending
                cxt:FadeIn()
                cxt:Dialog("DIALOG_INTRO_FRIEND")
                cxt.quest:Complete("starting_out")
                cxt.quest:Activate("investigate_further")

                StateGraphUtil.AddEndOption(cxt)
            end
        end)

QDEF:AddConvo("escape_bog")
    :Hub_Location(function(cxt)
        if cxt.location == cxt.quest.param.location then
            if not cxt.quest.param.searched_for_poi then
                cxt:Opt("OPT_FIND_POI_ETB")
                    :Fn( function(cxt)
                        UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_POI" , nil, nil, cxt.quest)
                    end )
            end
            cxt:Opt("OPT_TRAVEL_ETB")
                :Fn( function(cxt)
                    UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_LEAVE_1" , nil, nil, cxt.quest)
                end )
        end
    end)
    :State("STATE_POI")
        :Loc{
            DIALOG_INTRO = [[
                * While you searched around the mine, you found {handler}'s body lying on the ground.
                * The Bogger priest must have killed {handler.himher} before you arrived.
                {heard_handler_name?
                    * <i>That must have been what happened</>, you keep telling yourself.
                    * <i>The priest must have killed {handler.himher}</>, you believe.
                }
                {not heard_handler_name?
                    * If only you have arrived sooner. If only you could stop {illusion_boss.himher}.
                    * Maybe things could turn out differently.
                    * Maybe {handler} would still be alive, searching for the ancient artifact with you.
                }
                {handler_fellemo?
                    {player_sal?
                        * While your alliance with {handler} was found on shaky grounds, you still feel a bit sad seeing {handler.himher} like this.
                    }
                    {player_rook?
                        * {handler} was the closest thing that you could consider a friend.
                        * You have fought many battles alongside {handler.himher}, but the moment you weren't fighting alongside {handler.himher}, {handler.heshe} perished.
                    }
                    {player_arint?
                        * While you don't agree with {handler} a lot of times, {handler.heshe} was still your boss.
                        * And {handler.heshe} thinks very highly of your skills.
                        * Seeing {handler} like this fills you with melancholy.
                    }
                    {not player_sal and not player_rook and not player_arint?
                        * Your relationship with {handler} was purely contractual, yet you still feel a bit sad seeing {handler.himher} like this.
                    }
                }
                {handler_kalandra?
                    {player_sal?
                        * You haven't seen Prindo in years, yet when you are finally reunited, {handler.heshe} died.
                        * Unable to protect {handler.himher}, you feel like a failure.
                    }
                    {not player_sal?
                        * Your relationship with {handler} was purely contractual, yet you still feel a bit sad seeing {handler.himher} like this.
                    }
                }
                * At least you revenged {handler} by killing {handler.hisher} killer.
                {heard_handler_name?
                    * Then... <b><i>Why do you feel a chill down your spine, as if something is wrong?</></>
                }
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest.param.searched_for_poi = true
            EscapeTheBogUtil.TryMainQuestFn("AdvanceTime", 1, "SEARCH")
            StateGraphUtil.AddEndOption(cxt)
        end)
    :State("STATE_LEAVE_1")
        :Loc{
            DIALOG_INTRO = [[
                {searched_for_poi?
                    * With {handler} dead, there is no point in finding the artifact anymore.
                }
                {not searched_for_poi?
                    * With {handler} nowhere to be found, there is no point in finding the artifact anymore.
                }
                * You leave the mine.
            ]],
            DIALOG_INTRO_PST = [[
                * Thinking back now, a lot has happened in the past few days.
                * You started in the middle of the Bog.
                {bog_influence?
                    * No faith, no purpose, no knowledge, nothing.
                    * Yet, you manage to find faith in the Bog.
                    {kill_many?
                        * And as the Bog provide you with blessings, you too, provide the Bog many tributes.
                        * The Bog grows strong, just as you grow strong.
                    }
                    {not kill_many and good_survival?
                        * You have believed in the Bog, depended on the Bog.
                        * And now, you carry the strength of the Bog.
                    }
                    {not good_survival?
                        * And despite the many hardship you face in the Bog, you nevertheless believed in it and depended on it.
                        * And now, you carry its will.
                    }
                }
                {not bog_influence and kill_many?
                    * Pathetic, weak, defenseless.
                    * The Bog, and to an extension, the world, is an unforgiving place. Either you become the predator, or you become the prey.
                    {good_survival?
                        * And you? You have become the apex predator.
                    }
                    {not good_survival?
                        * And while you fight alongside the predators, you were never the strongest.
                    }
                }
                {not kill_many and not bog_influence?
                    * No knowledge, no supplies, no friends, nothing.
                    {good_survival?
                        * Yet, despite that, you adapted. You survived. You flourished.
                    }
                    {not good_survival?
                        * Yet, despite that, you adapted. You survived. Barely.
                        * That is not a luxury many can share.
                    }
                }
                * Either way, your life is changed forever.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.encounter:DoLocationTransition( cxt:GetCastMember("exit_1") )
            EscapeTheBogUtil.TryMainQuestFn("AdvanceTime", 1, "TRAVEL")
            cxt:Dialog("DIALOG_INTRO_PST")
            StateGraphUtil.AddEndOption(cxt)
        end)
    :State("STATE_LEAVE_2")
        :Loc{
            DIALOG_INTRO = [[
                * With your mind as sharp as ever, you are able to find your way around the bog easily.
                * You can finally return to civilization, and-
                * Well, you can never live too comfortably in Havaria, but it beats living in the Bog.
                {bog_influence?
                    player:
                        !cruel
                    * <i>DOES IT, THOUGH? DOES IT REALLY?</>
                }
                {searched_for_poi?
                    * It is a shame that {handler} cannot see it through.
                }
                {not searched_for_poi?
                    * {handler} is probably waiting for you somewhere comfortably. At least, you hope.
                    * <i>But you have a strange feeling that it is not going to be the case.</>
                }
                {heard_handler_name?
                    * <i>IT'S NOT MY FAULT IT'S NOT MY FAULT IT'S NOT MY FAULT IT'S NOT MY FAULT IT'S NOT MY FAULT IT'S NOT MY FAULT IT'S NOT MY FAULT IT'S NOT MY FAULT IT'S NOT MY FAULT IT'S NOT MY FAULT</>
                    * Your head hurts just thinking about it.
                }
            ]],
        }
        :Fn(function(cxt)
            cxt.encounter:DoLocationTransition( cxt:GetCastMember("exit_2") )
            EscapeTheBogUtil.TryMainQuestFn("AdvanceTime", 1, "TRAVEL")
            cxt:Dialog("DIALOG_INTRO")
            StateGraphUtil.AddEndOption(cxt)
        end)
    :State("STATE_LEAVE_3")
        :Loc{
            DIALOG_INTRO = [[
                * The front gate to the bog lies just before you.
                * Finally, after many days, you have reached your destination.
                {sunrise?
                    * A new day awaits you, and a new beginning awaits.
                }
                {midday?
                    * The sun is shining, and so is your future.
                }
                {sunset?
                    * As the sun sets on this chapter of your life, a new chapter rises.
                }
                {midnight?
                    * Darkness covers the bog, but soon, the light will arrive.
                }
            ]],
        }
        :Fn(function(cxt)
            cxt.encounter:DoLocationTransition( cxt:GetCastMember("exit_3") )
            EscapeTheBogUtil.TryMainQuestFn("AdvanceTime", 1, "TRAVEL")
            local day_phases =
            {
                "sunrise", "midday", "midday", "midday", "midday", "sunset"
            }
            local night_phases =
            {
                "sunset", "midnight", "midnight", "midnight", "midnight", "sunrise"
            }
            local phase_table = TheGame:GetGameState():GetDayPhase() == DAY_PHASE.NIGHT and night_phases or day_phases
            cxt.enc.scratch[phase_table[(TheGame:GetGameState():GetMainQuest().param.time_segment or 0) + 1]] = true
            cxt:Dialog("DIALOG_INTRO")
            StateGraphUtil.AddEndOption(cxt)
                :Fn(function() TheGame:Win() end)
        end)
