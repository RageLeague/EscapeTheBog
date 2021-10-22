local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS

local DEFS = {
    CharacterDef("ETB_BOGGER_CLOBBER_PAMPHLETEER",
    {
        base_def = "BOGGER_CLOBBER",
        hide_in_compendium = true,
        fight_data =
	    {
	        MAX_MORALE = MAX_MORALE_LOOKUP.MEDIUM,
	        MAX_HEALTH = MAX_HEALTH_LOOKUP.LOW,

            attacks =
            {
                etb_clobber_shield_bash = table.extend(NPC_ATTACK)
                {
                    name = "Shield Bash",
                    anim = "attack2",
                    flags = battle_defs.CARD_FLAGS.DEBUFF | battle_defs.CARD_FLAGS.MELEE,

                    damage_mult = 0.5,

                    features =
                    {
                        DEFECT = 1,
                    }
                },
                etb_clobber_swing = table.extend(NPC_ATTACK)
                {
                    name = "Swing",
                    anim = "attack1",
                    damage_mult = 1,

                    flags = battle_defs.CARD_FLAGS.MELEE,
                },
                etb_clobber_incite = table.extend(NPC_BUFF)
                {
                    name = "Incite",
                    desc = "Apply 3 {POWER} to an ally with less than 50% health.",
                    anim = "taunt",
                    flags = battle_defs.CARD_FLAGS.SKILL | battle_defs.CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.FRIENDLY_OR_SELF,

                    CanPlayCard = function( self, battle, target )
                        if target then
                            return target:GetHealthPercent() < 0.5
                        else
                            return true
                        end
                    end,

                    OnPostResolve = function( self, battle, attack )
                        attack:AddCondition( "POWER", 2 + GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ABILITY_STRENGTH ))
                    end
                },
            },

            behaviour =
            {
                OnActivate = function( self, fighter )
                    self.moves = self:MakePicker()
                        :AddID( "etb_clobber_incite", 1 )
                        :AddID( "etb_clobber_swing", 2 )
                        :AddID( "etb_clobber_shield_bash", 1 + GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ABILITY_STRENGTH ))
                        :AddID( "ai_defend_med", 1 )

                    self:SetPattern( self.Cycle )

                    local base_stacks = 6 - 2 * GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ABILITY_STRENGTH )
                    if self.fighter:GetTeamID() == TEAM.RED then
                        local shield_bash = self.fighter:AddCondition("shield_bash", base_stacks , self)
                        shield_bash.base_stacks = base_stacks
                    end

                    self.fighter:AddCondition("ARMOURED", 3 + GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ABILITY_STRENGTH ), self)
                end,

                Cycle = function( self )
                    self.moves:ChooseCard(1)
                end
        },
        },

    }),
    CharacterDef("ETB_BOGGER_CULTIVATOR_RADICAL",
    {
        base_def = "BOGGER_CULTIVATOR",
        hide_in_compendium = true,
        fight_data =
	    {
	        MAX_MORALE = MAX_MORALE_LOOKUP.MEDIUM,
	        MAX_HEALTH = MAX_HEALTH_LOOKUP.LOW,
            attacks =
            {
                etb_cultivator_fire_in_the_hole = table.extend(NPC_ATTACK)
                {
                    name = "Throw",
                    anim = "throw",
                    flags = CARD_FLAGS.RANGED,

                    target_mod = TARGET_MOD.TEAM,
                },
                etb_cultivator_disrupt = table.extend(NPC_ATTACK)
                {
                    name = "Disrupt",
                    anim = "attack1",
                    flags = battle_defs.CARD_FLAGS.MELEE | battle_defs.CARD_FLAGS.DEBUFF,

                    CanPlayCard = function( self, battle, target )
                        if target then
                            if not target:IsPlayer() then
                                return false
                            end
                            if target:GetConditionStacks( "disrupt" ) >= 5 then
                                return false
                            end
                        end
                        return true
                    end,

                    OnPostResolve = function( self, battle, attack )
                        attack:AddCondition( "disrupt", 2 + GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ABILITY_STRENGTH ))
                    end,
                },
                etb_cultivator_demoralize =
                {
                    name = "Demoralize",
                    anim = "taunt",
                    flags = battle_defs.CARD_FLAGS.SKILL | battle_defs.CARD_FLAGS.DEBUFF,
                    target_mod = TARGET_MOD.TEAM,

                    OnPostResolve = function( self, battle, attack )
                        local morale = 0.2 + 0.05 * GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ABILITY_STRENGTH )
                        for i, hit in attack:Hits() do
                            if hit.target:HasMorale() then
                                hit.target:DeltaMorale( morale )
                            end
                        end
                    end,
                }
            },

            behaviour =
            {
                OnActivate = function( self, fighter )
                    print(" loaded Cultivator?")
                    self.moves = self:MakePicker()
                        :AddID( "etb_cultivator_fire_in_the_hole", 1 )
                        :AddID( "etb_cultivator_disrupt", 1 )
                        :AddID( "etb_cultivator_demoralize", 1, 1 )
                        :AddID( "ai_power_boost", 1, 2 )

                    self:SetPattern( self.Cycle )

                    self.fighter:AddCondition("leeching_blade", 1 + GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ABILITY_STRENGTH ), self)
                    print("SUccessfully loaded Cultivator?")
                end,

                Cycle = function( self )
                    self.moves:ChooseCard(1)
                end
            },
        },

    }),
    CharacterDef("ETB_BOGGER_BOSS_KALANDRA",
    {
        base_def = "BOGGER_BOSS",
        hide_in_compendium = true,
        fight_data =
        {
            MAX_MORALE = MAX_MORALE_LOOKUP.MEDIUM,
            MAX_HEALTH = 150,
            battle_scale = 1.0,
            death_fade_delay = 1,
            shadow_symbol = "hips",
            shadow_scale = 8.5,

            death_fade_delay = 1.85,
            death_fade_time = 0,

            attacks =
            {
                etb_bogger_boss_kalandra_double_shoot = table.extend(NPC_ATTACK)
                {
                    name = "Double Shoot",
                    anim = "shoot",

                    flags = CARD_FLAGS.RANGED,

                    base_damage = { 5, 6, 7, 8},
                    target_count = 2,
                },

                etb_bogger_boss_kalandra_spreadshot = table.extend(NPC_ATTACK)
                {
                    name = "Spread Shot",
                    anim = "shoot",
                    flags = CARD_FLAGS.RANGED,
                    target_mod = TARGET_MOD.TEAM,

                    base_damage = { 6, 8, 10, 12},
                },

                etb_bogger_boss_kalandra_flourish = table.extend(NPC_BUFF)
                {
                    name = "Flourish",
                    anim = "taunt",

                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,
                    OnPostResolve = function( self, battle, attack )
                        self.owner:AddCondition("DEFEND", 3 * (GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY ) or 1), self)
                        self.owner:AddCondition("POWER", GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY ) or 1, self)
                    end
                },

                etb_bogger_boss_kalandra_summon = table.extend(NPC_BUFF)
                {
                    name = "Summon Boggers",
                    anim = "taunt",

                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    OnPostResolve = function( self, battle, attack )
                        self.owner:GetTeam():AddFighter( Fighter.CreateFromAgent( Agent("ETB_BOGGER_CLOBBER_PAMPHLETEER"), 1 ) )
                        self.owner:GetTeam():AddFighter( Fighter.CreateFromAgent( Agent("ETB_BOGGER_CULTIVATOR_RADICAL"), 1 ) )
                        self.owner:GetTeam():ActivateNewFighters()
                        self.have_played = true
                    end,
                },
            },

            conditions =
            {

            },

            behaviour =
            {
                bog_buffs = {"eyes_of_the_bog_faith", "brain_of_the_bog_faith", "heart_of_the_bog_faith"},
                bog_debuffs = {"eyes_of_the_bog_doubt", "brain_of_the_bog_doubt", "heart_of_the_bog_doubt"},
                -- CUSTOM_FIGHT_FORMATIONS =
                -- {
                --     [1] = BOGGER_BOSS_FORMATION,
                --     [2] = BOGGER_BOSS_FORMATION,
                --     [3] = BOGGER_BOSS_FORMATION,
                --     [4] = BOGGER_BOSS_FORMATION,
                --     [5] = BOGGER_BOSS_FORMATION,
                --     [6] = BOGGER_BOSS_FORMATION,
                -- },

                AddBossConditions = function( self, fighter )
                    for i,con_id in ipairs(self.bog_buffs) do
                        if not (self.suppress_conditions and self.suppress_conditions[con_id]) then
                            self.fighter:AddCondition(con_id, 1, self)
                        else
                            self.fighter:AddCondition(self.bog_debuffs[i], 1, self)
                        end
                    end
                end,

                OnActivate = function( self )
                    self.attacks = self:MakePicker()
                        :AddID( "etb_bogger_boss_kalandra_double_shoot", 4 )
                        :AddID( "etb_bogger_boss_kalandra_spreadshot", 2 )
                        :AddID( "etb_bogger_boss_kalandra_flourish", 1)
                    self.summon = self:AddCard("etb_bogger_boss_kalandra_summon")
                    self:SetPattern( self.Attack )
                end,

                Attack = function( self )
                    if not self.summon.have_played then
                        self:ChooseCard(self.summon)
                    else
                        self.attacks:ChooseCards( 1 )
                    end
                end,
            },
        },
    }),
    CharacterDef("ETB_BOGGER_BOSS_FELLEMO",
    {
        base_def = "BOGGER_BOSS",
        hide_in_compendium = true,

        fight_data =
        {
            MAX_MORALE = MAX_MORALE_LOOKUP.MEDIUM,
            MAX_HEALTH = 150,
            battle_scale = 1.0,
            death_fade_delay = 1,
            shadow_symbol = "hips",
            shadow_scale = 8.5,

            death_fade_delay = 1.85,
            death_fade_time = 0,

            attacks =
            {
                etb_bogger_boss_fellemo_double_shoot = table.extend(NPC_ATTACK)
                {
                    name = "Pew! Pew!",
                    anim = "shoot",

                    flags = CARD_FLAGS.RANGED,

                    base_damage = { 5, 6, 7, 8},
                    target_count = 2,
                },

                etb_bogger_boss_fellemo_wound_shot = table.extend(NPC_ATTACK)
                {
                    name = "Pew!",
                    anim = "shoot",
                    flags = CARD_FLAGS.RANGED,

                    base_damage = { 6, 8, 10, 12},
                    features =
                    {
                        WOUND = 2,
                    },
                },

                etb_bogger_boss_fellemo_war_cry = table.extend(NPC_BUFF)
                {
                    name = "War Cry",
                    anim = "taunt",

                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,
                    target_mod = TARGET_MOD.TEAM,
                    OnPostResolve = function( self, battle, attack )
                        self.owner:AddCondition("DEFEND", 3 * (GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY ) or 1), self)
                        self.owner:AddCondition("POWER", GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY ) or 1, self)
                    end
                },

                etb_bogger_boss_fellemo_summon = table.extend(NPC_BUFF)
                {
                    name = "Summon Boggers",
                    anim = "taunt",

                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF,
                    target_type = TARGET_TYPE.SELF,

                    OnPostResolve = function( self, battle, attack )
                        self.owner:GetTeam():AddFighter( Fighter.CreateFromAgent( Agent("BOGGER_CLOBBER"), 1 ) )
                        self.owner:GetTeam():AddFighter( Fighter.CreateFromAgent( Agent("BOGGER_CULTIVATOR"), 1 ) )
                        self.owner:GetTeam():ActivateNewFighters()
                        self.have_played = true
                    end,
                },
            },

            conditions =
            {

            },

            behaviour =
            {
                bog_buffs = {"eyes_of_the_bog_faith", "brain_of_the_bog_faith", "heart_of_the_bog_faith"},
                bog_debuffs = {"eyes_of_the_bog_doubt", "brain_of_the_bog_doubt", "heart_of_the_bog_doubt"},
                -- CUSTOM_FIGHT_FORMATIONS =
                -- {
                --     [1] = BOGGER_BOSS_FORMATION,
                --     [2] = BOGGER_BOSS_FORMATION,
                --     [3] = BOGGER_BOSS_FORMATION,
                --     [4] = BOGGER_BOSS_FORMATION,
                --     [5] = BOGGER_BOSS_FORMATION,
                --     [6] = BOGGER_BOSS_FORMATION,
                -- },

                AddBossConditions = function( self, fighter )
                    for i,con_id in ipairs(self.bog_buffs) do
                        if not (self.suppress_conditions and self.suppress_conditions[con_id]) then
                            self.fighter:AddCondition(con_id, 1, self)
                        else
                            self.fighter:AddCondition(self.bog_debuffs[i], 1, self)
                        end
                    end
                end,

                OnActivate = function( self )
                    self.attacks = self:MakePicker()
                        :AddID( "etb_bogger_boss_fellemo_double_shoot", 4 )
                        :AddID( "etb_bogger_boss_fellemo_wound_shot", 2 )
                        :AddID( "etb_bogger_boss_fellemo_war_cry", 1)
                    self.summon = self:AddCard("etb_bogger_boss_fellemo_summon")
                    self:SetPattern( self.Attack )
                end,

                Attack = function( self )
                    if not self.summon.have_played then
                        self:ChooseCard(self.summon)
                    else
                        self.attacks:ChooseCards( 1 )
                    end
                end,
            },
        },
    }),
}

for _, def in ipairs(DEFS) do
    Content.AddCharacterDef( def )
    -- character_def:InheritBaseDef()
    Content.GetCharacterDef(def.id):InheritBaseDef()
end
