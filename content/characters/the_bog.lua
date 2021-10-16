local CAMERA_SHAKE_PARAMS = { 0.25, 55, 1.25 } -- Magnitude, speed, time

local BURR_BOSS_FORMATION =
{
    { 13.5, 1.5, FIGHTER_FORMATION.FRONT_X },  -- Burr Boss

    { 4, -5, nil },
    { 6, 5, nil },
    { 2, 1, nil },
}

local BOGGER_BOSS_FORMATION =
{
    { 7, 1.4, FIGHTER_FORMATION.FRONT_X },  -- Bogger Priest (same as burr boss but X is 7.5 less)

    { 4, -5, nil },
    { 6, 5, nil },
    { 2, 1, nil },
}


local DEFS = {
    CharacterDef("THE_BOG_ETB",
    {
        base_def = "BOG_BURR_BOSS",
        name = "The Bog",
        alt_boss_id = "BOGGER_BOSS",

        negotiation_data =
        {
            ring_offset =
            {
                x = 0,
                y = 600,
                z = 0,
            },
            behaviour =
            {
                cycle_options =
                {
                    -- Tentacle
                    function( self, turns )
                        if self.cycle_turns == 0 then
                            self.tentacle:ChooseCards(2)
                            self.boil:ChooseCards(1)
                        end
                        self:ChooseGrowingNumbers( 2, 1 )
                    end,

                    -- Blinding
                    function( self, turns )
                        if self.cycle_turns == 0 then
                            self:ChooseCard(self.spore)
                            self.fume:ChooseCards(2)
                        end
                        self:ChooseGrowingNumbers( 1, 1 )
                        self:ChooseComposure( 1, 2, 3 )
                    end,

                    -- Rash
                    function( self, turns )
                        if self.cycle_turns == 0 then
                            self.rash:ChooseCards(3)
                            self.blister:ChooseCards(2)
                        end
                        self:ChooseComposure( 2, 2, 3 )
                    end,
                },

                OnInit = function( self, difficulty )
                    -- if CheckBits(self.engine:GetFlags(), NEGOTIATION_FLAGS.WORDSMITH) then
                    self.tentacle = self:MakePicker()
                        :AddID("grout_bog_tentacle", 1)
                        :AddID("grout_bog_tentacle", 1)
                    self.boil = self:MakePicker()
                        :AddID("grout_bog_boil", 1)

                    self.spore = self:AddArgument("SPORE_CLOUD")
                    self.fume = self:MakePicker()
                        :AddID("grout_bog_fume", 1)
                        :AddID("grout_bog_fume", 1)

                    self.rash = self:MakePicker()
                        :AddID("grout_bog_rash", 1)
                        :AddID("grout_bog_rash", 1)
                        :AddID("grout_bog_rash", 1)
                    self.blister = self:MakePicker()
                        :AddID("grout_bog_blister", 1)
                        :AddID("grout_bog_blister", 1)


                    self.negotiator:AddModifier("DARK_INTELLECT")
                    self.cycle_order = shallowcopy(self.cycle_options)
                    table.shuffle(self.cycle_order)
                    self.current_cycle = table.remove(self.cycle_order)
                    self.cycle_turns = 0
                    self:SetPattern(self.BossCycle)
                    -- end
                end,

                BossCycle = function( self, turns )
                    self.current_cycle( self, turns)
                    self.cycle_turns = self.cycle_turns + 1
                    if self.cycle_turns >= 3 then
                        self.cycle_turns = 0
                        if #self.cycle_order <= 0 then
                            self.cycle_order = shallowcopy(self.cycle_options)
                            table.shuffle(self.cycle_order)
                        end
                        self.current_cycle = table.remove(self.cycle_order)
                    end

                end,
            }
        },

        fight_data =
        {
            MAX_HEALTH = 300,
            battle_scale = 1.2,

            status_widget_dx = 2.5,
            status_widget_head_dx = 4,
            status_widget_head_dy = 5,
            -- death_fade_delay = 2.5,
            shadow_scale = 0.0,
            death_fade_time = -1,
            formation = FIGHTER_FORMATION.FRONT_X,

            stationary = true,
            approach_distance = 6,
            no_despawn = true,

            ranged_riposte = true,

            OnJoinBattle = function( fighter, anim_fighter, fight_screen )
                local x, z = anim_fighter:GetHomePosition()
                anim_fighter.entity.cmp.AnimController:SetXFlip(fighter:GetTeamID() == TEAM.RED)
                anim_fighter.entity:SetLocalPosition( x, 0, z )
                anim_fighter:CoroDelay(.6)
                fight_screen:ScreenShake( CAMERA_SHAKE_PARAMS )
                anim_fighter:CoroDelay(1.2)
                anim_fighter:PlayAnim( "emerge" )
                anim_fighter:WaitAnim()
            end,

            behaviour =
            {
                CUSTOM_FIGHT_FORMATIONS =
                {
                    [1] = BURR_BOSS_FORMATION,
                    [2] = BURR_BOSS_FORMATION,
                    [3] = BURR_BOSS_FORMATION,
                    [4] = BURR_BOSS_FORMATION,
                    [5] = BURR_BOSS_FORMATION,
                    [6] = BURR_BOSS_FORMATION,
                },

                OnActivate = function( self )
                    self.fighter:GetTeam():SetCustomFormation( self.CUSTOM_FIGHT_FORMATIONS )
                    self.chosen_order = { self.EyeStalkCycle, self.TreasureCycle, self.KnuckleCycle}
                    local has_eyes = false
                    for i,ally in self.fighter:GetTeam():Fighters() do
                        if ally.agent:GetContentID() == "GROUT_EYE" then
                            has_eyes = true
                            self.fighter:AddCondition("burr_boss_eye_tracker")
                            break
                        end
                    end
                    if has_eyes then
                        table.shuffle(self.chosen_order, 2) -- always start with the eyestalk
                    else
                        table.shuffle(self.chosen_order) -- Random!
                    end

                    self.spawn_treasure = self:AddCard("burr_boss_card_steal")
                    self.spawn_eyes = self:AddCard("summon_eye_stalks")
                    self.spawn_knuckles = self:AddCard("summon_knuckles")

                    self.eye_stage_moves = self:MakePicker()
                        :AddID("burr_boss_projectile", 2)
                        :AddID("burr_boss_taunt", 1)

                    self.treasure_stage_moves = self:MakePicker()
                        :AddID("burr_boss_rage_attack", 3)
                        :AddID("burr_boss_taunt_heal", 1)

                    self.knuckle_stage_moves = self:MakePicker()
                        :AddID("burr_boss_projectile_knuckle", 2)
                        :AddID("burr_boss_taunt", 1)

                    self.stage_position = 1
                    self:SetPattern(self.chosen_order[self.stage_position])
                end,

                CheckForStageSwitch = function( self )
                    if self.battle:GetTurns() - (self.last_turn or -1) > 0 then
                        self.stage_turns = (self.stage_turns or 0) + 1
                        self.last_turn = self.battle:GetTurns()
                    end
                    if self.fighter:GetTeam():NumActiveFighters() == 1 and self.stage_turns > 1 then
                        -- Always leave the player with at least 6 cards after stealing (minimum steal is 6)
                        if #self.battle:GetCardsOwnedBy(self.battle:GetPlayerFighter()) < 12 then
                            table.arrayremove(self.chosen_order, self.TreasureCycle)
                        end
                        self.stage_turns = 1
                        self.stage_position = self.stage_position + 1
                        if self.stage_position > #self.chosen_order then
                            table.shuffle(self.chosen_order)
                            self.stage_position = 1
                        end
                        self:SetPattern(self.chosen_order[self.stage_position ])
                        return true
                    else
                        return false
                    end
                end,

                EyeStalkCycle = function( self )
                    if not self:CheckForStageSwitch() then
                        if self.stage_turns <= 1 and not self.fighter:HasCondition("burr_boss_eye_tracker") then
                            self:ChooseCard(self.spawn_eyes)
                        else
                            self.eye_stage_moves:ChooseCard()
                        end
                    else
                        self:RunBehaviour( self.battle )
                    end
                end,

                TreasureCycle = function( self )
                    if not self:CheckForStageSwitch() then
                        if self.stage_turns <= 1 then
                            self:ChooseCard(self.spawn_treasure)
                        else
                            self.treasure_stage_moves:ChooseCard()
                        end
                    else
                        self:RunBehaviour( self.battle )
                    end
                end,

                KnuckleCycle = function( self )
                    if not self:CheckForStageSwitch() then
                        if self.stage_turns <= 1 then
                            self:ChooseCard(self.spawn_knuckles)
                        else
                            self.knuckle_stage_moves:ChooseCard()
                        end
                    else
                        self:RunBehaviour( self.battle )
                    end
                end
            },

            anim_mapping =
            {
                idle = "idle2",
                hit_mid_pst_idle = "hit_mid_pst_idle2",
                defend_pst = "defend_pst2",
                stunned_pst = "stunned_pst2",
            },

            eye_closed_anim_mapping =
            {
            },
        },
    })
}

for _, def in pairs(DEFS) do
    Content.AddCharacterDef( def )
    -- character_def:InheritBaseDef()
    Content.GetCharacterDef(def.id):InheritBaseDef()
end
