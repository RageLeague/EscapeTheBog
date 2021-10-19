local patch_id = "CALC_CAN_FLEE"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)


local battle_defs = require "battle/battle_defs"

local CARD_FLAGS = battle_defs.CARD_FLAGS
local BATTLE_EVENT = ExtendEnum( battle_defs.EVENT,
{
    "CALC_CAN_FLEE"
})

local old_flee = Fighter.Flee
function Fighter:Flee(...)
    if not self.battle.fighter_flee_accumulator then
        self.battle.fighter_flee_accumulator = CardEngine.ScalarAccumulator( self.battle, BATTLE_EVENT.CALC_CAN_FLEE )
    end
    local can_flee, details = self.battle.fighter_flee_accumulator:CalculateValue( true, self )
    if not can_flee then
        if not self:HasCondition("RUNNING") then
            self:AddCondition( "RUNNING" )
        end
        return
    end
    old_flee(self, ...)
end

Content.GetBattleCondition("RUNNING").hud_fx = {"surrender"}
Content.GetBattleCondition("RUNNING").idle_state_override = IDLE_STATE.SURRENDER
