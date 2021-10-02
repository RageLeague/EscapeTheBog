local EscapeTheBogUtil = class("EscapeTheBogUtil")

function EscapeTheBogUtil.AddBogExits(qdef, exit_defs)
    if type(exit_defs) == "number" then
        local res = {}
        for i = 1, exit_defs do
            table.insert(res, "any")
        end
        exit_defs = res
    end
    qdef.exit_defs = shallowcopy(exit_defs)
end

EscapeTheBogUtil.BOG_LOCATION_QUESTS = {}

function EscapeTheBogUtil.AddBogLocationQuest(id, quest_def, location_def, exit_defs)
    local QDEF = QuestDef.Define
    {
        qtype = QTYPE.STORY,
        id = id,
    }
    for id, data in pairs(quest_def) do
        QDEF[id] = data
    end

    QDEF:AddQuestLocation(table.extend{
        cast_id = "main_location",
    }(location_def))

    table.insert(EscapeTheBogUtil.BOG_LOCATION_QUESTS, id)

    return QDEF
end
