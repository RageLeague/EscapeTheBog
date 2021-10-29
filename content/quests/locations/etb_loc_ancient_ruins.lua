local QDEF
QDEF = EscapeTheBogUtil.AddBogLocationQuest(
    {
        entry_encounter = EscapeTheBogUtil.GenericInitialEncounterTable,
        repeat_encounter = EscapeTheBogUtil.GenericSafeRepeatEncounterTable,
        sleep_encounter = EscapeTheBogUtil.GenericSleepEncounterTable,

        on_init = function(quest)
            quest.param.poi = table.arraypick{"artifact", "shrines"}
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
        name = "Ancient Ruins",
        desc = "A vestige of a former civilization. A shadow of a former glory.",
        plax = "EXT_Bog_HedgeGod_01",
        show_agents = true,
        tags = {"bog", "ruins", "clearing"},
    },
    {"dangerous", "dangerous"}
)

QDEF:Loc{
    DESC_1 = "There seems to be some broken buildings down this path. There might be something here.",
    DESC_2 = "There are some man-made structures down this path, although it has seen better days.",
    DESC_3 = "There used to be buildings down this path. But now, only a vestige of it remains.",
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
            DIALOG_SHRINE = [[
                * <b>Vestige</>
                * You find an old shrine. It doesn't look very Heshian.
                * You have no idea what it is doing in the middle of the bog.
                * Either way, if there is a time for some divine intervention, it should be now.
            ]],
            DIALOG_ARTIFACT = [[
                * <b>Vestige</>
                * You find a most curious looking device sitting on top of a pedestal.
                * A shadow of a bygone era.
                * You feel bad for it as it sits around, without a purpose, and you feel like this is a good idea to give it one.
            ]],
            DIALOG_AMBUSH = [[
                * But just as you start to approach the object, you heard a mechanical whirling sound.
                agent:
                    !right
                player:
                    !left
                    !scared
                * Suddenly, some robots spring to life!
                * Seems like they are guarding this location.
                * If you want to stay here, you have to defend yourself!
            ]],
            DIALOG_FIGHT_WIN = [[
                * With the last of the machine destroyed, you can now safely access this location.
            ]],
        }
        :Fn(function(cxt)
            if cxt.quest.param.poi == "shrines" then
                cxt:Dialog("DIALOG_SHRINE")
            else
                cxt:Dialog("DIALOG_ARTIFACT")
            end
            cxt.quest.param.searched_for_poi = true
            EscapeTheBogUtil.TryMainQuestFn("AdvanceTime", 1, "SEARCH")
            StateGraphUtil.AddEndOption(cxt)
        end)
