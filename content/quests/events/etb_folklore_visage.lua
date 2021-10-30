local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = EscapeTheBogUtil.ETBActFilter,
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}
:AddCast{
    cast_id = "killed_person",
    cast_fn = function(quest, t)
        for k, agent in pairs( TheGame:GetGameState().removed_agents or {} ) do
            if agent:IsSentient() and agent:IsDead() and agent:GetFactionID() ~= "BOGGERS" then
                table.insert(t, agent)
            end
        end
    end,
    no_validation = true,
    on_assign = function(quest, agent)
        quest.param.other_dead = {}
        for k, check_agent in pairs( TheGame:GetGameState().removed_agents or {} ) do
            if check_agent ~= agent and check_agent:IsSentient() and check_agent:IsDead() and check_agent:GetFaction() == agent:GetFaction() then
                table.insert(quest.param.other_dead, check_agent)
            end
        end
    end,
}
:AddOpinionEvents{
    dead_person =
    {
        delta = OPINION_DELTAS.NEUTRALIZING,
        txt = "Dead people don't have relationships",
    },

}

QDEF:AddConvo()
    :ConfrontState("STATE_CONF")
        :Quips{
            {
                tags = "story_intro",
                [[
                    * You've heard many stories.
                    * Stories of people getting killed in the Bog are never truly gone.
                ]],
                [[
                    * You don't remember much in your current state, but you do remember the strange stories told by the laborers.
                    * How people appear in the bog even though they are long gone.
                ]],
                [[
                    * You are never the one into rumors, but even then, you have heard many things.
                    * About people seeing faces of dead people.
                ]],
            },
            {
                tags = "story_intro_ii",
                [[
                    * It's hard to believe, but here it is.
                    * You are sure that you've seen this face somewhere before, and you are pretty sure that {killed_person.heshe} is dead.
                ]],
                [[
                    * You would normally dismiss this as mere rumors, except there is one right in front of you.
                    * You've killed a lot of people in the past, and this person's face resembles one you've killed before.
                ]],
            },
            {
                tags = "dialog_confront",
                [[
                    You did this to me. It is time for you to pay for your crimes.
                ]],
                [[
                    This is your fault. There is no running away this time.
                ]],
                [[
                    There is no use hiding. You will pay for what you have done.
                ]],
            },
        }
        :Loc{
            DIALOG_INTRO = [[
                * <b>Folklore</>
                %story_intro
                player:
                    !left
                    !scared
                    killed_person:
                    !right
                    !angry
                %story_intro_ii
                killed_person:
                    %dialog_confront
                {have_backup?
                    * There seems to be other people here as well.
                    * People who died because of you.
                    * And they all want revenge!
                }
                {not have_backup?
                    * {killed_person.HeShe} wants revenge!
                }
            ]],
            OPT_DISPEL = "Dispel the apparition",
            DIALOG_DISPEL = [[
                player:
                    No! You are dead! I'm sure of it!
                    This can't be real!
            ]],
            DIALOG_DISPEL_SUCCESS = [[
                killed_person:
                    !exit
                * It seems like whatever is tormenting you is gone.
                player:
                    !thought
                * Still, this strange encounter is plaguing your mind.
                * You thought about what you have done, and what you could have done differently.
                player:
                    !shrug
                * Nah, who am I kidding. You are a grifter. You wouldn't be if you cared enough about your actions.
            ]],
            DIALOG_DISPEL_FAILURE = [[
                player:
                    !scared
                    Just leave me alone!
                * But it's no use. The visage of the dead has consumed your thoughts.
                * You feel as though you are cursed by the dead!
            ]],

            SIT_MOD = "Dead people's opinion of you matters a lot less.",
        }
        :Fn(function(cxt)
            cxt.quest.param.temp_death_data = cxt:GetCastMember("killed_person").death_data
            cxt:GetCastMember("killed_person").death_data = nil
            -- Can't talk to dead person directly.
            cxt:Dialog("DIALOG_INTRO")

            local hinder_people = table.multipick(cxt.quest.param.other_dead, math.ceil(#cxt.quest.param.other_dead / 2))

            local sit_mods = {

            }
            if cxt:GetCastMember("killed_person"):GetRelationship() ~= RELATIONSHIP.NEUTRAL then
                table.insert(sit_mods, { value = 10 * (cxt:GetCastMember("killed_person"):GetRelationship() - RELATIONSHIP.NEUTRAL), text = cxt:GetLocString("SIT_MOD") })
            end

            cxt:BasicNegotiation("DISPEL", {
                target_agent = cxt:GetCastMember("killed_person"),
                hinders = hinder_people,
                situation_modifiers = sit_mods,
            })
                :OnSuccess()
                    :Fn(function(cxt)
                        cxt:GetCastMember("killed_person").death_data = cxt.quest.param.temp_death_data
                        cxt.quest.param.temp_death_data = nil
                    end)
                    :CompleteQuest()
                    :DoneConvo()
                :OnFailure()
                    :Fn(function(cxt)
                        cxt:GetCastMember("killed_person").death_data = cxt.quest.param.temp_death_data
                        cxt.quest.param.temp_death_data = nil

                        local function InstallGraft(agent)
                            local bane = agent:GetSocialGraft(RELATIONSHIP.HATED)
                            if not bane or bane == "" then
                                bane = "shakey"
                            end
                            ConvoUtil.GiveGraft(cxt, GraftInstance(bane, {agents = {agent}}))
                        end

                        InstallGraft(cxt:GetCastMember("killed_person"))

                        for i, agent in ipairs(hinder_people) do
                            InstallGraft(agent)
                        end
                    end)
                    :CompleteQuest()
                    :DoneConvo()
        end)
