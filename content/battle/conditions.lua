local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS

local CONDITIONS =
{
    ETB_GROUT_BURR_IMMUNITY = {
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
    ETB_DROWSY = {
        name = "Drowsy",
        desc = "Each card you play has a {1#percent} chance of being {EXPEND|expended}. When that happens, reduce <b>Drowsy</b> by 1.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.expend_chance)
        end,

        expend_chance = 0.1,
        ctype = CTYPE.DEBUFF,

        event_handlers =
        {
            [ BATTLE_EVENT.END_RESOLVE ] = function( self, battle, resolve_card )
                if resolve_card and resolve_card.owner == self.owner then
                    if resolve_card.deck == battle:GetHandDeck() or resolve_card.deck == battle:GetDrawDeck() or resolve_card.deck == battle:GetDiscardDeck() then
                        if math.random() < self.expend_chance then
                            battle:ExpendCard(resolve_card)
                            self.owner:RemoveCondition( self.id, 1, self )
                        end
                    end
                end
            end,
        },
    },
    ETB_TIRED = {
        name = "Tired",
        desc = "Each card you play has a {1#percent} chance of being {DESTROY|destroyed}. When that happens, reduce <b>Tired</b> by 1.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.expend_chance)
        end,

        expend_chance = 0.1,
        ctype = CTYPE.DEBUFF,

        event_handlers =
        {
            [ BATTLE_EVENT.END_RESOLVE ] = function( self, battle, resolve_card )
                if resolve_card and resolve_card.owner == self.owner then
                    if resolve_card.deck == battle:GetHandDeck() or resolve_card.deck == battle:GetDrawDeck() or resolve_card.deck == battle:GetDiscardDeck() then
                        if math.random() < self.expend_chance then
                            resolve_card:Consume()
                            self.owner:RemoveCondition( self.id, 1, self )
                        end
                    end
                end
            end,
        },
    },
}

for id, def in pairs( CONDITIONS ) do
    Content.AddBattleCondition( id, def )
end
