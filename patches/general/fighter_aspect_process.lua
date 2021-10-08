local patch_id = "FIGHTER_ASPECT_PROCESS"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Fighter.CreateFromAgent

function Fighter.CreateFromAgent(agent, ...)
    local fighter = old_fn(agent, ...)
    if agent.aspects then
        for i, aspect in ipairs(agent.sorted_aspects) do
            if aspect.ProcessFighter then
                aspect:ProcessFighter(fighter)
            end
        end
    end
    return fighter
end
