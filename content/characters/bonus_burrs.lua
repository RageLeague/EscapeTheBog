local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS

local function GroutJoin( fighter, anim_fighter )
    local x, z = anim_fighter:GetHomePosition()
    anim_fighter.entity.cmp.AnimController:SetXFlip(fighter:GetTeamID() == TEAM.RED)
    anim_fighter.entity:SetLocalPosition( x, 0, z )
    anim_fighter:PlayAnim( "emerge" )
    anim_fighter:WaitAnim()
end

local function GroutMoving( anim_fighter, x, z, move_type, fx_tags, force_run )
    -- To satisfy AnimFighter:IsMoving()
    anim_fighter.destx = x
    anim_fighter.destz = z

    anim_fighter:PlayAnim( "surrender" )
    anim_fighter:WaitAnim()
    anim_fighter.entity.cmp.Transform:SetPosRot(x,anim_fighter.height,z)
    anim_fighter:PlayAnim( "emerge" )
    anim_fighter:WaitAnim()

    anim_fighter:StopMoving()
end

local function GroutUpdateMoving( anim_fighter, dt )
end

local DEFS = {
    CharacterDef("ETB_GROUT_EYE",
    {
        base_def = "MONSTER",

        title = "Grout Eyestalk",
        build = "grout_eyes",
        combat_strength = 1,
        is_grout = true,

        fight_data =
        {
            MAX_HEALTH = 22,

            status_widget_head_dx = 1.0,
            status_widget_head_dy = 2.5,
            shadow_scale = 0.0, -- Doesn't add a shadow prefab if 0
            stationary = true,

            OnJoinBattle = GroutJoin,

            StartMoving = GroutMoving,

            UpdateMoving = GroutUpdateMoving,

            anim_mapping =
            {
                surrender = "death",
            },

            attacks =
            {

                etb_grout_eye_heal_lesser = table.extend(NPC_BUFF)
                {
                    name = "Intensify",
                    anim = "taunt",

                    flags = CARD_FLAGS.SKILL | CARD_FLAGS.BUFF | CARD_FLAGS.HEAL,

                    target_mod = TARGET_MOD.TEAM,
                    target_type = TARGET_TYPE.SELF,

                    OnPostResolve = function( self, battle, attack )
                        for i,ally in self.owner:GetTeam():Fighters() do
                            if ally ~= self.owner then
                                local health_delta = 2 + GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ABILITY_STRENGTH )
                                ally:HealHealth(health_delta, self)
                            end
                        end
                    end
                },

            },

            behaviour =
            {
                OnActivate = function( self )
                    self.moves = self:MakePicker()
                        :AddID( "etb_grout_eye_heal_lesser", 1 )
                        :AddID( "grout_eye_attack", 1)

                    self:SetPattern( self.Cycle )
                    self.fighter:AddCondition("grout_burr", 2+math.random(4))
                end,

                Cycle = function( self )
                    self.moves:ChooseCard()
                end,
            },
        },
    })
}

for _, def in ipairs(DEFS) do
    Content.AddCharacterDef( def )
    -- character_def:InheritBaseDef()
    Content.GetCharacterDef(def.id):InheritBaseDef()
end
