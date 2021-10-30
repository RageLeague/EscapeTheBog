local negotiation_defs = require "negotiation/negotiation_defs"
local MINIGAME_CARD_FLAGS = negotiation_defs.CARD_FLAGS
local MINIGAME_EVENT = negotiation_defs.EVENT
local battle_defs = require "battle/battle_defs"
local BATTLE_CARD_FLAGS = battle_defs.CARD_FLAGS
local BATTLE_EVENT = battle_defs.EVENT

-- I'm just using this from the arint mod.
if not Content.GetNegotiationCard("PC_ARINT_status_nagging_thought") then
    Content.AddNegotiationCard("PC_ARINT_status_nagging_thought", {
        name = "Nagging Thought",
        desc = "Gain {DOUBT {1}}.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.doubt_amt)
        end,
        flavour = "'But what if...?'",
        remove_on_rest = true,
        rarity = CARD_RARITY.UNIQUE,
        cost = 1,
        flags = MINIGAME_CARD_FLAGS.STATUS | MINIGAME_CARD_FLAGS.CONSUME | MINIGAME_CARD_FLAGS.SLEEP_IT_OFF,
        icon = "negotiation/silence.tex",

        doubt_amt = 1,

        OnPostResolve = function( self, minigame, targets )
            self.negotiator:CreateModifier("DOUBT", self.doubt_amt, self)
        end,
    })
end

local mettle_graft = {
    id = "etb_mettle_addiction",
    type = GRAFT_TYPE.STORY,
    name = "Mettle Addiction",
    desc = "You crave mettle so much that your actions in negotiations and battles maximizes your mettle gain.",
    img = "icons/items/graft_burnt_out_battle.tex",

    rarity = CARD_RARITY.UNIQUE,
    series = "GENERAL",

    negotiation_modifier =
    {
        hidden = true,
        event_handlers =
        {

        },
    },
    battle_condition =
    {
        -- hidden = true,
        desc = "During execution, you are forced execute each enemy with {METTLESOME}.",
        event_handlers =
        {
            [ BATTLE_EVENT.EXECUTES_ADDED ] = function( self )
                for i, fighter in self.battle:GetEnemyTeam():Fighters() do
                    if fighter:HasCondition("METTLESOME") then
                        local card = Battle.Card( "execute", self.battle.player_team:Primary() )
                        card.show_dealt = false
                        -- card:AssignTarget( fighter )
                        self.battle:PlayCard( card, fighter )
                    end
                end
            end,
        },
    },
}


Content.AddGraft( mettle_graft.id, mettle_graft )

local available_handlers = {"fellemo", "kalandra"}

local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = EscapeTheBogUtil.ETBActFilter,
}

QDEF:AddConvo(nil, nil, "SLEEP_WAKE")
    :State("START")
        :Loc{
            DIALOG_INTRO = [[
                * <b>Abyss</>
                * You find yourself to total darkness.
                * You feel as though time and space is meaningless here.
                * You thought that you have already perished in the Bog, when suddenly, a hand approaches you from the abyss.
                * You try to draw your weapons, but they are nowhere to be found.
                * The hand offers you three items: a medallion, a photograph, and a bottle.
            ]],
            OPT_TAKE_MEDALLION = "Take the medallion",
            DIALOG_TAKE_MEDALLION = [[
                * You take the medallion.
                * As you grab it, power surges through you.
                * You feel better than ever before, yet at the same time, you feel as though a giant burden is placed upon you.
            ]],
            OPT_TAKE_PHOTOGRAPH = "Take the photograph",
            DIALOG_TAKE_PHOTOGRAPH = [[
                * You take the photograph.
                {handler_fellemo?
                    {player_sal?
                        * You have no idea what to expect, but depicted on this photograph is a pair of eyes.
                        * Eyes, filled with dread, filled with anger, filled with betrayal.
                        * You feel as though you are looking at a mirror of yourself.
                    }
                    {player_rook?
                        * You have no idea what to expect, but depicted on this photograph is a desolate landscape.
                        * Broken flags fluttering in the wind, smoke rising in the sky, dead bodies lying around.
                        * It is not a memory that you wish to see.
                    }
                    {not player_sal and not player_rook?
                        * You have no idea what to expect, but depicted on this photograph is a shadowy figure with a glinted eye.
                        * From the shape of this figure's head, you figured it belongs to a kra'deshi.
                    }
                }
                {handler_kalandra?
                    {player_sal?
                        * You have no idea what to expect, but depicted on this photograph is a pair of eyes.
                        * Eyes, filled with hope, filled with determination, filled with sorrow.
                        * You feel as though you are looking at a mirror of yourself.
                    }
                    {not player_sal?
                        * You have no idea what to expect, but depicted on this photograph is a landscape.
                        * The sun has just risen, illuminating everything.
                        * Yet... The colors of this photograph looks dull, with very little contrast.
                    }
                }
                * You have no idea what to make of this.
            ]],
            OPT_TAKE_BOTTLE = "Take the bottle",
            DIALOG_TAKE_BOTTLE = [[
                * You take the bottle.
                * Instinctively, you drank from it.
                * You feel a surge of energy, a sense of grandness and power.
                * And you crave for more.
            ]],
        }
        :Fn(function(cxt)
            cxt:TalkTo(cxt.player)
            cxt:Dialog("DIALOG_INTRO")
            cxt:Opt("OPT_TAKE_MEDALLION")
                :Dialog("DIALOG_TAKE_MEDALLION")
                :Fn(function(cxt)
                    cxt:Wait()
                    local grafts
                    grafts = EscapeTheBogUtil.GetPooledGrafts(4, TheGame:GetGameState():GetGraftDraftDetails().count, EscapeTheBogUtil.GetSocialBoonPool())
                    local popup = Screen.PickGraftScreen(grafts, true, function(...) cxt.enc:ResumeEncounter(...) end)
                    TheGame:FE():InsertScreen( popup )
                    local chosen_graft = cxt.enc:YieldEncounter()

                    local grafts
                    grafts = EscapeTheBogUtil.GetPooledGrafts(4, TheGame:GetGameState():GetGraftDraftDetails().count, EscapeTheBogUtil.GetSocialBanePool())
                    local popup = Screen.PickGraftScreen(grafts, true, function(...) cxt.enc:ResumeEncounter(...) end)
                    TheGame:FE():InsertScreen( popup )
                    local chosen_graft = cxt.enc:YieldEncounter()
                end)
                :GoTo("STATE_WAKE_UP")
            cxt:Opt("OPT_TAKE_PHOTOGRAPH")
                :Fn(function(cxt)
                    cxt.quest.param.handler_id = TheGame:GetGameState():GetMainQuest().param.handler_id or table.arraypick(available_handlers)
                    cxt.quest.param["handler_" .. cxt.quest.param.handler_id] = true
                    TheGame:GetGameState():GetMainQuest().param.handler_id = cxt.quest.param.handler_id
                end)
                :Dialog("DIALOG_TAKE_PHOTOGRAPH")
                :GainCards{"PC_ARINT_status_nagging_thought"}
                :GoTo("STATE_WAKE_UP")
            cxt:Opt("OPT_TAKE_BOTTLE")
                :Dialog("DIALOG_TAKE_BOTTLE")
                :Fn(function(cxt)
                    local character_id = cxt.player:GetContentID()
                    TheGame:GetGameProfile():UnlockMettle( character_id )
                    TheGame:GetGameProfile():AddMettlePoints( character_id, 8, "EVENT_FIRST_METTLE" )
                    cxt.player.graft_owner:AddGraft(GraftInstance("etb_mettle_addiction"))
                end)
                :GoTo("STATE_WAKE_UP")
        end)
    :State("STATE_WAKE_UP")
        :Loc{
            DIALOG_INTRO = [[
                * After you grabbed the item, the abyss slowly fades away.
            ]],
            DIALOG_INTRO_PST = [[
                * You wake up with a start.
                * This is when you realized that it is all a dream.
                * Yet... You feel as though the consequence is far reaching.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt:Wait()
            cxt:FadeIn()
            cxt:Dialog("DIALOG_INTRO_PST")
            cxt.quest:Complete()
            StateGraphUtil.AddEndOption(cxt)
        end)
