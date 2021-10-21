local patch_id = "SET_TEMP_FIGHTER_BEHAVIOUR"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Fighter.CreateFromAgent

function Agent:SetTempFighterBehaviour(data, enc)
    self.temp_fighter_behaviour = shallowcopy(data)
    -- added an encounter check so that if you exit from current encounter, the temp behaviour won't work
    self.temp_fighter_behaviour.current_encounter = enc or TheGame:GetGameState():GetCaravan():GetCurrentEncounter()
end

function Fighter.CreateFromAgent(agent, ...)
    local fighter = old_fn(agent, ...)

    if agent.temp_fighter_behaviour then
        local enc = TheGame:GetGameState():GetCaravan():GetCurrentEncounter()
        local temp_enc = agent.temp_fighter_behaviour.current_encounter
        if temp_enc == nil or enc == temp_enc then
            fighter.behaviour = FighterBehaviour( fighter, agent.temp_fighter_behaviour )
        end
        agent.temp_fighter_behaviour = nil
    end
    return fighter
end
