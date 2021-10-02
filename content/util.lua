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
