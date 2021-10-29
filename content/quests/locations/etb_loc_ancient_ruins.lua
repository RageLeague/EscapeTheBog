local QDEF
QDEF = EscapeTheBogUtil.AddBogLocationQuest(
    {
        entry_encounter = EscapeTheBogUtil.GenericInitialEncounterTable,
        repeat_encounter = EscapeTheBogUtil.GenericRepeatEncounterTable,
        sleep_encounter = EscapeTheBogUtil.GenericSleepEncounterTable,

        on_init = function(quest)
            -- quest.param.poi = table.arraypick{"nothing", "shrines", "ritual_platform"}
        end,

        GetPathDesc = function(quest)
            if not quest.param.desc_number then
                quest.param.desc_number = EscapeTheBogUtil.TryMainQuestFn("RequestRiffleShuffle", QDEF.id .. "_DESC", 1, 3) -- math.random(1, 5)
            end
            local desc = {}
            table.insert(desc, quest:GetLocalizedStr("DESC_" .. quest.param.desc_number))
            return table.concat(desc, "\n")
        end,

        events =
        {

        },
    },
    {
        name = "Bog Camp",
        desc = "Someone must have set up camp here. It might be risky to go here.",
        plax = "EXT_BOGGER_HIDEOUT_01",
        show_agents = true,
        tags = {"bog", "campsite", "clearing"},
    },
    {"dangerous", "dangerous"}
)

QDEF:Loc{
    DESC_1 = "You can see tents and campfires down this path. Someone must have been here.",
    DESC_2 = "You can see smoke coming from this path. If you are going to find anyone, this path is your best bet.",
    DESC_3 = "There seems to be people down this path, and they don't look very friendly. Expect confrontation down this path.",
}

QDEF:AddConvo()
    :Loc{
        OPT_SEARCH_CAMPFIRE = "Search the campfire",
        OPT_SEARCH_TENTS = "Search the tents",
    }
    :Hub_Location(function(cxt)
        if cxt.location ~= cxt:GetCastMember("main_location") then
            return
        end

        if not cxt.quest.param.searched_campfires then
            cxt:Opt("OPT_SEARCH_CAMPFIRE")
                :Fn( function(cxt)
                    cxt.quest.param.searched_campfires = true
                    UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_CAMPFIRE" , nil, nil, cxt.quest)
                end )
        end
        if not cxt.quest.param.searched_tents then
            cxt:Opt("OPT_SEARCH_TENTS")
                :Fn( function(cxt)
                    cxt.quest.param.searched_tents = true
                    UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_TENT" , nil, nil, cxt.quest)
                end )
        end
    end)
