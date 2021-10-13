local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS

local ITEMS =
{
    etb_mixed_bogberries =
    {
        name = "Mixed Bogberries",
        desc = "Has an unknown effect each time you eat it.",

        cost = 1,
        target_type = TARGET_TYPE.FRIENDLY_OR_SELF,

        max_charges = 1,

        effects =
        {
            blue =
            {
                hunger_restoration = 2,
                health_gain = 3,
                resolve_gain = 3,
                cards = {"gassy", "bloated"},
            },
            striped =
            {
                hunger_restoration = 1,
                resolve_gain = 7,
                cards = {"drunk"},
            },
            purple =
            {
                hunger_restoration = 1,
                health_gain = 7,
                cards = {"ulcer"},
            },
            spotted =
            {
                hunger_restoration = 1,
                resolve_gain = -10,
                cards = {"sick"},
            },
            red =
            {
                hunger_restoration = 1,
                health_gain = -10,
                cards = {"numbness"},
            },
            rotten =
            {
                hunger_restoration = 1,
                health_gain = -20,
                max_health_gain = 5,
                cards = {"drunk", "drunk_player"},
            },
        },

        food_data_fn_etb = function(self)
            local chosen_effect
            if self.userdata and self.userdata.available_effects and #self.userdata.available_effects > 0 then
                chosen_effect = table.arraypick(self.userdata.available_effects)
                table.arrayremove(self.userdata.available_effects, chosen_effect)
            end
            if not chosen_effect then
                chosen_effect = table.arraypick(copykeys(self.effects))
            end
            local effect_table = self.effects[chosen_effect]
            assert(effect_table, "Invalid effect: " .. chosen_effect)
            return deepcopy(effect_table)
        end,

        OnPostResolve = function( self, battle, attack)
            local chosen_effect
            if self.userdata and self.userdata.available_effects and #self.userdata.available_effects > 0 then
                chosen_effect = table.arraypick(self.userdata.available_effects)
                table.arrayremove(self.userdata.available_effects, chosen_effect)
            end
            if not chosen_effect then
                chosen_effect = table.arraypick(copykeys(self.effects))
            end
            local effect_table = self.effects[chosen_effect]
            assert(effect_table, "Invalid effect: " .. chosen_effect)

            if (effect_table.health_gain or 0) > 0 then
                self.target:HealHealth( effect_table.health_gain, self )
            elseif (effect_table.health_gain or 0) < 0 then
                self.target:DeltaHealth( effect_table.health_gain, self )
            end

            if (effect_table.resolve_gain or 0) > 0 then
                self.target:AddCondition("CONCENTRATION", effect_table.resolve_gain, self)
            elseif (effect_table.resolve_gain or 0) < 0 then
                self.target:AddCondition("IMPAIR", math.ceil(-effect_table.resolve_gain / 2), self)
            end

            if (effect_table.max_health_gain or 0) ~= 0 then
                self.target:DeltaMaxHealth(effect_table.max_health_gain)
                self.target:GetAgent().health:AddStatModifier( "BOG_BERRIES", effect_table.max_health_gain )
            end
        end,
    },
    etb_mixed_monster_meat =
    {
        name = "Mixed Monster Meat",
        desc = "{HEAL} {1} health and gain {2} {DISEASED}.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.heal_amt, self.diseased_amt)
        end,
        flavour = "'It's food, right?'",

        cost = 1,
        target_type = TARGET_TYPE.FRIENDLY_OR_SELF,

        max_charges = 2,

        heal_amt = 5,
        diseased_amt = 2,

        food_data_etb =
        {
            hunger_restoration = 2,
        },

        OnPostResolve = function( self, battle, attack)
            self.target:HealHealth( self.heal_amt, self )
            self.target:AddCondition("DISEASED", self.heal_amt, self)
        end,
    },
}
for i, id, data in sorted_pairs( ITEMS ) do
    data.item_tags = (data.item_tags or 0) | ITEM_TAGS.COMBAT
    data.flags = (data.flags or 0) | CARD_FLAGS.ITEM
    data.rarity = data.rarity or CARD_RARITY.UNIQUE
    data.series = CARD_SERIES.GENERAL

    Content.AddBattleCard( id, data )
end

