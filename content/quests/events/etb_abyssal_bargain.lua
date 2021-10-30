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
                    }
                }
            ]],
            OPT_TAKE_BOTTLE = "Take the bottle",
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt:Opt("OPT_TAKE_MEDALLION")
                :Dialog("DIALOG_TAKE_MEDALLION")
                :Fn(function(cxt)

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
                    cxt:Dialog("DIALOG_TAKE_PHOTOGRAPH")
                end)
        end)
    :State("STATE_WAKE_UP")
        :Loc{
            DIALOG_INTRO = [[
                * As you grabbed the item, the abyss slowly fades away.
            ]],
            DIALOG_INTRO_PST = [[
                * This is when you realized that it is all a dream.
                * Yet... You feel as though the consequence is far reaching.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt:FadeIn()
            cxt:Dialog("DIALOG_INTRO_PST")
            cxt.quest:Complete()
            StateGraphUtil.AddEndOption(cxt)
        end)
