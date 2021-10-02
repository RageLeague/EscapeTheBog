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

function EscapeTheBogUtil.AddBogLocationQuest(quest_def, location_def, exit_defs)
    quest_def = quest_def or {}
    local t = debug.getinfo( 2 )
    print(t.short_src)
    local QDEF = QuestDef.Define
    {
        qtype = QTYPE.STORY,
        id = quest_def.id or t.short_src:match( "/?([%w_]+)[.]lua$" ):upper(),
        is_bog_location = true,

        SetupLocationData = function(quest)
            if not quest.param.available_exits then
                quest.param.available_exits = shallowcopy(quest:GetQuestDef().exit_defs)
            end
            if not quest.param.exits then
                quest.param.exits = {}
            end
        end,

        CanAttachLocation = function(quest, other_quest)
            if not other_quest.is_bog_location then
                return false, "Not a bog location"
            end
            quest:DefFn("SetupLocationData")
            other_quest:DefFn("SetupLocationData")
            local selftag
            for i, tag in ipairs(quest.available_exits) do
                if tag == "any" or other_quest:GetCastMember("main_location"):HasTag(tag) then
                    selftag = tag
                    break
                end
            end
            if not selftag then
                return false, "No matching tag"
            end
            local othertag
            for i, tag in ipairs(other_quest.available_exits) do
                if tag == "any" or quest:GetCastMember("main_location"):HasTag(tag) then
                    othertag = tag
                    break
                end
            end
            if not othertag then
                return false, "No matching tag"
            end
            return true
        end,
        AttachLocation = function(quest, other_quest)
            if not other_quest.is_bog_location then
                return false, "Not a bog location"
            end
            quest:DefFn("SetupLocationData")
            other_quest:DefFn("SetupLocationData")
            table.shuffle(quest.available_exits)
            table.shuffle(other_quest.available_exits)
            local selftag
            for i, tag in ipairs(quest.available_exits) do
                if tag == "any" or other_quest:GetCastMember("main_location"):HasTag(tag) then
                    selftag = tag
                    break
                end
            end
            if not selftag then
                return false, "No matching tag"
            end
            local othertag
            for i, tag in ipairs(other_quest.available_exits) do
                if tag == "any" or quest:GetCastMember("main_location"):HasTag(tag) then
                    othertag = tag
                    break
                end
            end
            if not othertag then
                return false, "No matching tag"
            end

            table.insert(quest.param.exits, other_quest)
            table.insert(other_quest.param.exits, quest)
            table.arrayremove(quest.param.available_exits, selftag)
            table.arrayremove(other_quest.param.available_exits, othertag)
            return true
        end,
    }
    for id, data in pairs(quest_def or {}) do
        QDEF[id] = data
    end

    QDEF:AddQuestLocation(table.extend{
        cast_id = "main_location",
    }(location_def))

    table.insert(EscapeTheBogUtil.BOG_LOCATION_QUESTS, QDEF.id)

    EscapeTheBogUtil.AddBogExits(QDEF, exit_defs)

    return QDEF
end
