local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = EscapeTheBogUtil.ETBActFilter,
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}
:AddCastByAlias{
    cast_id = "sampler",
    alias = "BILEBROKER_SAMPLER"
}

QDEF:AddConvo()
    :ConfrontState("STATE_CONF")
        :Quips{
            {
                tags = "meet_stranger",
                [[
                    * You see a mysterious stranger wandering around looking for something.
                    * When {sampler.heshe} sees you, {sampler.heshe} immediately turns {sampler.hisher} attention to you.
                ]],
                [[
                    * You saw another stranger wandering about.
                    * {sampler.HeShe} noticed you, and confronts you.
                ]],
            },
            {
                tags = "meet_stranger,met",
                [[
                    * You saw {sampler} again, wandering around looking for something.
                    * {sampler.HeShe} is looking for you, probably. Because {sampler.hisher} immediately turns {sampler.hisher} attention to you.
                ]],
            },
        }
        :Loc{
            DIALOG_INTRO = [[
                * <b>Stranger</>
                %meet_stranger
                player:
                    !left
                agent:
                    !right
                {not met?
                    Greetings, {player.honorific}.
                    You look like you have a lot of bog parasites.
                    Would you like me to take a sample? I promise it would only hurt a little.
                }
                {met?
                    It's you again.
                    Would you like me to take another sample? I promise it would only hurt a little.
                }
            ]],
            OPT_ATTACK = "Attack {agent}",
            DIALOG_ATTACK = [[
                player:
                    !fight
                * You ready your weapon.
                agent:
                    !angry
                    Hey, where is this coming from?
            ]],
            DIALOG_ATTACK_WIN = [[
                {dead?
                    * Well, you killed the stranger.
                    * You have no idea why you did what you just did.
                    player:
                        !happy
                    * But that's what makes it so fun!
                    player:
                        !neutral
                    * ...except when you look down, there is no stranger.
                    * There is just a piled of mangled bog monster corpse.
                    * Weird.
                }
                {not dead?
                    agent:
                        !injured
                        I get it! You don't want me to take a sample.
                        No need to be rude about it, you know?
                        !exit
                    * Then, {agent} disappears.
                    * That is certainly strange.
                }
            ]],
            OPT_YES = "Yes?",
            DIALOG_YES = [[
                player:
                    !bashful
                    Uh... Yes?
                agent:
                    Excellent. Which parasite do you want me to pick?
            ]],
            OPT_SELECT_PARASITE = "Choose {1#card}",
            DIALOG_YES_PST = [[
                * The process was extremely painful.
                player:
                    !injured
                    Ow, that hurts!
                agent:
                    Don't worry, the pain is temporary.
                    Thank you for this sample. I will be seeing you later.
                    !exit
                * Then, {agent} disappears.
                * That is certainly strange.
            ]],
            DIALOG_YES_NO_PICK = [[
                agent:
                    Hmm... There is nothing you want me to take.
                    That's strange, because you clearly have parasites on you.
                    Are you aware of this parasite.
            ]],
            DIALOG_YES_NO_PICK_ALREADY_CURED = [[
                agent:
                    !crossed
                    Well, if you don't want me to take any samples, then suit yourself.
                    Maybe you will change your mind when we next meet.
                    !exit
                * Then, {agent} disappears.
                * That is certainly strange.
            ]],
            DIALOG_YES_TO_AWARE = [[
                player:
                    !bashful
                    Uh... Yes?
                agent:
                    !shrug
                    Well, if you are unwilling to let me take it, then suit yourself.
                    Maybe you will change your mind when we next meet.
                    !exit
                * Then, {agent} disappears.
                * That is certainly strange.
            ]],
            DIALOG_NO_TO_AWARE = [[
                player:
                    !bashful
                    Uh... No?
                agent:
                    !hips
                    In that case, now you know! You learned something today about yourself!
                    Now, do you want me to take a sample of that?
            ]],
            DIALOG_YES_TO_SAMPLE = [[
                player:
                    !bashful
                    Uh... Yes?
                agent:
                    !shrug
                    Alright, here goes nothing.
            ]],
            DIALOG_YES_TO_SAMPLE_PST = [[
                * The process was extremely painful.
                player:
                    !injured
                    Ow, that hurts!
                agent:
                    Don't worry, the pain is temporary.
                player:
                    !placate
                    Wait, wait. Hold on.
                    Did you just say words that I understood?
                agent:
                    !dubious
                    Yes...? Maybe...? Is that not... normal, somehow?
                player:
                    You have no idea. I haven't been able to understand what people are saying for the past few days.
                    I was only able to catch pieces of what people are saying.
                agent:
                    !thought
                    Hmm... That is certainly interesting.
                    There have been numerous reports of auditory and visual hallucination in the bog, and we haven't been able to trace the pathogen that caused this.
                    But seeing that extracting this parasite from you cause you to understand what people are saying, I hypothesize that this parasite is the root cause of these hallucination reports.
                player:
                    Alright, now you've lost me.
                agent:
                    Come on, it's not even that complicated.
                    Anyway, as I was saying, I was unable to extract the entire parasite. Just the surface parts, where I can safely extract it from you.
                player:
                    So... I am not cured just yet?
                agent:
                    !shrug
                    Probably not. It's not something that external forces can remove without seriously damaging the host.
                    Anyway, thank you for this sample. I will take a good look at it.
                    I will be seeing you later.
                    !exit
                * Then, {agent} disappears.
                * That is certainly strange.
            ]],
            OPT_NO = "No?",
            DIALOG_NO = [[
                player:
                    !crossed
                    Uh... No.
                agent:
                    What a shame.
                    Maybe you will change your mind when we next meet.
                    !exit
                * Then, {agent} disappears.
                * That is certainly strange.
            ]],
        }
        :Fn(function(cxt)
            cxt:TalkTo(cxt:GetCastMember("sampler"))
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_YES")
                :Dialog("DIALOG_YES")
                :Fn(function(cxt)
                    local battle_defs = require "battle/battle_defs"
                    for i, card in ipairs(cxt.player.battler.cards.cards) do
                        if card:IsFlagged( battle_defs.CARD_FLAGS.PARASITE ) then
                            cxt:Opt("OPT_SELECT_PARASITE", card)
                                :Fn(function(cxt)
                                    cxt.player.battler:RemoveCard(card)
                                end)
                                :Dialog("DIALOG_YES_PST")
                                :Fn(function(cxt)
                                    cxt:GetAgent():MoveToLimbo()
                                end)
                                :CompleteQuest()
                                :DoneConvo()
                        end
                    end

                    local negotiation_defs = require "negotiation/negotiation_defs"
                    for i, card in ipairs(cxt.player.negotiator.cards.cards) do
                        if card:IsFlagged( negotiation_defs.CARD_FLAGS.PARASITE ) then
                            cxt:Opt("OPT_SELECT_PARASITE", card)
                                :Fn(function(cxt)
                                    cxt.player.negotiator:RemoveCard(card)
                                end)
                                :Dialog("DIALOG_YES_PST")
                                :Fn(function(cxt)
                                    cxt:GetAgent():MoveToLimbo()
                                end)
                                :CompleteQuest()
                                :DoneConvo()
                        end
                    end

                    cxt:Opt("OPT_BACK_BUTTON")
                        :MakeUnder()
                        :Fn(function(cxt)
                            if TheGame:GetGameState():GetMainQuest().param.madness_cured then
                                cxt:Dialog("DIALOG_YES_NO_PICK_ALREADY_CURED")
                                cxt:GetAgent():MoveToLimbo()
                                cxt.quest:Complete()
                                StateGraphUtil.AddEndOption(cxt)
                            else
                                cxt:Dialog("DIALOG_YES_NO_PICK")

                                cxt:Opt("OPT_YES")
                                    :Dialog("DIALOG_YES_TO_AWARE")
                                    :Fn(function(cxt)
                                        cxt:GetAgent():MoveToLimbo()
                                    end)
                                    :CompleteQuest()
                                    :DoneConvo()

                                cxt:Opt("OPT_NO")
                                    :Dialog("DIALOG_NO_TO_AWARE")
                                    :Fn(function(cxt)
                                        cxt:Opt("OPT_YES")
                                            :Dialog("DIALOG_YES_TO_SAMPLE")
                                            :Fn(function(cxt)
                                                cxt.player.health:AddStatModifier( "PARASITE_REMOVAL", -PARASITE_HEALTH_LOSS )
                                                TheGame:GetGameState():GetMainQuest().param.madness_cured = true
                                            end)
                                            :Dialog("DIALOG_YES_TO_SAMPLE_PST")
                                            :Fn(function(cxt)
                                                cxt:GetAgent():MoveToLimbo()
                                            end)
                                            :CompleteQuest()
                                            :DoneConvo()

                                        cxt:Opt("OPT_NO")
                                            :Dialog("DIALOG_NO")
                                            :Fn(function(cxt)
                                                cxt:GetAgent():MoveToLimbo()
                                            end)
                                            :CompleteQuest()
                                            :DoneConvo()
                                    end)
                            end
                        end)
                end)

            cxt:Opt("OPT_NO")
                :Dialog("DIALOG_NO")
                :Fn(function(cxt)
                    cxt:GetAgent():MoveToLimbo()
                end)
                :CompleteQuest()
                :DoneConvo()

            cxt:Opt("OPT_ATTACK")
                :Dialog("DIALOG_ATTACK")
                :Battle{
                    flags = BATTLE_FLAGS.ISOLATED,

                    on_runaway = function(cxt, battle, no_fail)
                        cxt:GetAgent():MoveToLimbo()
                        StateGraphUtil.DoRunAway( cxt, battle, no_fail )
                    end,
                }
                    :OnWin()
                        :Dialog("DIALOG_ATTACK_WIN")
                        :Fn(function(cxt)
                            cxt:GetAgent():MoveToLimbo()
                        end)
                        :CompleteQuest()
                        :DoneConvo()
        end)
