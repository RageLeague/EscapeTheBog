local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS

local EVENT = negotiation_defs.EVENT

local MODIFIERS =
{
    ETB_DROWSY_NEGOTIATION =
    {
        name = "Drowsy",
        desc = "Each card you play has a {1#percent} chance of being {EXPEND|expended}. When that happens, reduce <b>Drowsy</b> by 1.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.expend_chance)
        end,
        expend_chance = 0.1,
        modifier_type = MODIFIER_TYPE.PERMANENT,

        event_handlers =
        {
            [ EVENT.END_RESOLVE ] = function( self, minigame, resolve_card )
                if resolve_card and resolve_card.owner == self.owner then
                    if resolve_card.deck == minigame:GetHandDeck() or resolve_card.deck == minigame:GetDrawDeck() or resolve_card.deck == minigame:GetDiscardDeck() then
                        if math.random() < self.expend_chance then
                            minigame:ExpendCard(resolve_card)
                            self.negotiator:DeltaModifier( self, -1, self )
                        end
                    end
                end
            end,
        },
    },
    ETB_TIRED_NEGOTIATION =
    {
        name = "Tired",
        desc = "Each card you play has a {1#percent} chance of being {DESTROY|destroyed}. When that happens, reduce <b>Tired</b> by 1.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.expend_chance)
        end,
        expend_chance = 0.91,
        modifier_type = MODIFIER_TYPE.PERMANENT,

        event_handlers =
        {
            [ EVENT.END_RESOLVE ] = function( self, minigame, resolve_card )
                if resolve_card and resolve_card.owner == self.owner then
                    if resolve_card.deck == minigame:GetHandDeck() or resolve_card.deck == minigame:GetDrawDeck() or resolve_card.deck == minigame:GetDiscardDeck() or resolve_card.deck == minigame:GetTrashDeck() then
                        if math.random() < self.expend_chance then
                            minigame:ExpendCard(resolve_card)
                            resolve_card:Consume()
                            self.negotiator:DeltaModifier( self, -1, self )
                        end
                    end
                end
            end,
        },
    },
}

for id, def in pairs( MODIFIERS ) do
    Content.AddNegotiationModifier( id, def )
end
