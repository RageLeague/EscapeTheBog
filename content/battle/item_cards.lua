local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS

local ITEMS =
{
    etb_blue_bogberry =
    {

    },
}
for i, id, data in sorted_pairs( ITEMS ) do
    data.item_tags = (data.item_tags or 0) | ITEM_TAGS.COMBAT
    data.flags = (data.flags or 0) | CARD_FLAGS.ITEM
    data.rarity = data.rarity or CARD_RARITY.UNIQUE
    data.series = CARD_SERIES.GENERAL

    Content.AddBattleCard( id, data )
end

