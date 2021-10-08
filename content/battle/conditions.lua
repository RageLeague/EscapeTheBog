local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS

local CONDITIONS =
{
    etb_grout_burr_immunity = {
        hidden = true,

        event_priorities =
        {
            [ BATTLE_EVENT.CALC_MODIFY_STACKS ] = EVENT_PRIORITY_SETTOR,
        },

        event_handlers =
        {
            [ BATTLE_EVENT.CALC_MODIFY_STACKS ] = function( self, acc, condition_id, fighter, source )
                if condition_id == "grout_burr" and fighter == self.owner then
                    if acc.value > 0 then
                        acc:ModifyValue( 0, self )
                    end
                end
            end,
        },
    },
}

for id, def in pairs( CONDITIONS ) do
    Content.AddBattleCondition( id, def )
end
