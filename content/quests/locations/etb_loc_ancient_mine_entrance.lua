local QDEF
QDEF = EscapeTheBogUtil.AddBogLocationQuest(
    {
        no_spawn_by_default = true,
        entry_encounter = EscapeTheBogUtil.GenericInitialEncounterTable,
        repeat_encounter = EscapeTheBogUtil.GenericRepeatEncounterTable,
        sleep_encounter = EscapeTheBogUtil.GenericSleepEncounterTable,

        on_init = function(quest)

        end,

        GetPathDesc = function(quest)
            return quest:GetLocalizedStr("DESC_1")
        end,
    },
    {
        name = "Ancient Mine Entrance",
        desc = "An entrance to an ancient mine. A power force emits from this location. Going here without adequate preparation is not recommended.",
        plax = "INT_Bog_Cave_01",
        show_agents = true,
        tags = {"cave", "bog", "mine_entrance"},
        indoors = true,
    },
    {"dangerous"}
)

QDEF:Loc{
    DESC_1 = "You can sense a powerful force coming from this path. Whatever down there must have been extremely powerful. If you wish to go there, you should be prepared.",
}

QDEF:AddConvo()
    :Loc{
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
        end
    end)
    :State("STATE_POI")
        :Loc{
            DIALOG_DEEP_MINE = [[
                * You find a path that goes further into the mine.
                * An eerie green light is radiating from that direction.
                * You can sense a powerful being down there.
                * It must be the source of the madness that you are currently in.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_DEEP_MINE")
            cxt.quest.param.searched_for_poi = true
            local mine = QuestUtil.SpawnQuest("ETB_LOC_ANCIENT_MINE")
            mine:DefFn("SetupLocationData")
            cxt.quest:DefFn("ForceAttachLocation", mine)
            EscapeTheBogUtil.TryMainQuestFn("AdvanceTime", 1, "SEARCH")
            StateGraphUtil.AddEndOption(cxt)
        end)
