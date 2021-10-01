local function GetCards(diff, collection, count, owner)

    local rng = TheGame:GetGameState() and TheGame:GetGameState():GetRNG( "CARDS" )
    if rng then
        push_random( function( n, m )
            return rng:Random( n, m )
        end )
    end


    diff = diff or 1
    local prob = CARD_DROP_RARITY[math.max(1, math.min( diff, #CARD_DROP_RARITY))]
    local xp_range = CARD_DROP_START_XP[math.max(1, math.min( diff, #CARD_DROP_START_XP))]

    local used_card_defs = {}
    local cards = {}

    local generate_card = function()
        local rarity = weighted_arraypick(prob)

        local new_cards = collection(function(cd) return rarity == cd.rarity and table.arrayfind(used_card_defs, cd) == nil end):GenerateRandom( 1, owner )
        if new_cards[1] then
            if (new_cards[1].max_xp or 0) > 0 then
                new_cards[1]:AddRandomXP( xp_range[1], xp_range[2] )
            end
            table.insert(cards, new_cards[1])
            table.insert(used_card_defs, new_cards[1].def)
        end
    end

    for k = 1, count-1 do
        generate_card()
    end

    --jcheng: always get at least an uncommon card
    local has_uncommon = table.findif( cards, function(cd) return cd.rarity == CARD_RARITY.UNCOMMON or cd.rarity == CARD_RARITY.RARE end )
    if has_uncommon then
        generate_card()
    else
        local uncommons = collection( function(cd) return cd.rarity == CARD_RARITY.UNCOMMON end ):GenerateRandom( 1, owner )
        for i, card in ipairs(uncommons) do
            table.insert(cards, card)
        end
    end

    table.shuffle(cards)

    if rng then
        pop_random()
    end

    return cards
end

function RewardUtil.ETBGetBattleItems(diff, count, owner)
    return GetCards(diff, function(fn) return BattleCardCollection.AllItems( fn, owner ) end, count, owner)
end
