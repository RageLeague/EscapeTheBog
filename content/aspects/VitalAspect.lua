-- Define basis for all Vital Aspects
local VitalAspect = class( "ETBClass.VitalAspect", Aspect)

function VitalAspect:init( agent )
    VitalAspect._base.init(self, agent)

    self.current_stat = self.default_stat or 0
end

function VitalAspect:GetLocStringPrefix( key )
    return self:GetLocPrefix() .. "." .. key:upper()
end

function VitalAspect:GetLocalizedString( key )
    return LOC(self:GetLocStringPrefix(key))
end

-- Returns up to two values:
-- First value is the integer representing the stage.
-- Second value is true if we need to hide this stage in the UI
function VitalAspect:GetCurrentStage()
end

function VitalAspect:GetName()
    local current_stage = self:GetCurrentStage()
    if current_stage then
        return loc.format(self:GetLocalizedString("ALT_NAME"), self:GetLocalizedString("NAME_STAGE_" .. current_stage))
    end
    return VitalAspect._base.GetName(self)
end

function VitalAspect:GetDesc(game_state, agent)
    local tt = {self:GetLocalizedString("DESC")}
    local current_stage = self:GetCurrentStage()
    if current_stage then
        table.insert(tt, self:GetLocalizedString("DESC_STAGE_" .. current_stage))
    end
    return table.concat(tt, "\n")
end

function VitalAspect:OnTimeSegmentPassETB(old_time, new_time, delta, reason)
end

function VitalAspect:HarvestStrings(t)
    VitalAspect._base.HarvestStrings(self, t)
    if self.loc_strings then
        for key, str in pairs( self.loc_strings ) do
            t[self:GetLocStringPrefix(key)] = str
        end
    end
end

function VitalAspect:DeltaStat(delta)
    local old_stat = self.current_stat

    self.current_stat = math.max(self.min_stat or 0, self.current_stat + delta)

    if self.OnDeltaStat then
        self:OnDeltaStat(old_stat, self.current_stat, delta)
    end
end

-- Define Hunger

local Hunger = class( "ETBClass.Hunger", ETBClass.VitalAspect)
Content.AddAspect( "etb_hunger", Hunger )

Hunger.DELTA_CHANCE = {0.98, 0.85, 0.75, 0.65, 0.5, 0.4, 1, 0.35}
Hunger.RESOLVE_LOSS = {0, 0, 0, 1, 1, 2, 3}
Hunger.MAX_HEALTH_DELTA = {3, 2, 0, 0, 0, -1, -2}
Hunger.DAMAGE_REDUCTION = {0, 0, 0, 0, 1, 2, 3}
Hunger.FATIGUE_DELTA = {1, 0, 0, 0, 0, 0, 0}

Hunger.default_stat = 2
Hunger.name = "Hunger"
Hunger.desc = "Every organic being needs to eat food. Eating a healthy amount of food is key to health, strength, and not dying."
Hunger.loc_strings = {
    ALT_NAME = "Hunger ({1})",
    NAME_STAGE_1 = "Bloated",
    NAME_STAGE_2 = "Full",
    NAME_STAGE_3 = "Content",
    NAME_STAGE_4 = "Peckish",
    NAME_STAGE_5 = "Hungry",
    NAME_STAGE_6 = "Very Hungry",
    NAME_STAGE_7 = "Starving",
    DESC_STAGE_1 = "<#BONUS>Bloated</>: You are quite full. Gain 1 Fatigue and 3 max health for each time segment passed.",
    DESC_STAGE_2 = "<#BONUS>Full</>: You have eaten enough. Gain 2 max health for each time segment passed.",
    DESC_STAGE_3 = "<#HILITE>Content</>: You have eaten enough food to go for a while. No special effects.",
    DESC_STAGE_4 = "<#PENALTY>Peckish</>: You are starting to crave some food. Lose 1 resolve for each time segment passed.",
    DESC_STAGE_5 = "<#PENALTY>Hungry</>: You need to eat some food. Lose 1 resolve for each time segment passed. Lose 1 power at the start of each battle.",
    DESC_STAGE_6 = "<#PENALTY>Very Hungry</>: You <i>really</> need to eat some food. Lose 2 resolve and 1 max health for each time segment passed. Lose 2 power at the start of each battle.",
    DESC_STAGE_7 = "<#PENALTY>Starving</>: You need to eat before you starve to death. Lose 3 resolve and 2 max health for each time segment passed. Lose 3 power at the start of each battle.",
}
Hunger.texture = global_images.health

function Hunger:GetCurrentStage()
    if not self.current_stat then
        return
    end
    if self.current_stat <= 0 then
        return 1
    elseif self.current_stat <= 1 then
        return 2
    elseif self.current_stat <= 3 then
        return 3, true
    elseif self.current_stat <= 5 then
        return 4
    elseif self.current_stat <= 7 then
        return 5
    elseif self.current_stat <= 9 then
        return 6
    else
        return 7
    end
end

function Hunger:OnTimeSegmentPassETB(old_time, new_time, delta, reason)
    if delta <= 0 then
        return
    end
    for i = 1, delta do
        local current_stage = self:GetCurrentStage()

        local fatigue_delta = self.FATIGUE_DELTA[current_stage]
        if fatigue_delta and fatigue_delta > 0 then
            if self.agent.etb_fatigue then
                self.agent.etb_fatigue:DeltaStat(fatigue_delta)
            end
        end

        local resolve_loss = self.RESOLVE_LOSS[current_stage]
        if resolve_loss and resolve_loss > 0 then
            if self.agent:IsPlayer() then
                TheGame:GetGameState():GetCaravan():DeltaResolve(-resolve_loss)
            end
        end

        local max_health_delta = self.MAX_HEALTH_DELTA[current_stage]
        if max_health_delta and max_health_delta ~= 0 then
            if self.agent.health then
                self.agent.health:AddStatModifier("HUNGER_DELTA", max_health_delta)
            end
        end

        -- Possibly increment hunger
        local chance = self.DELTA_CHANCE[current_stage]
        if reason == "REST" or reason == "SLEEP" then
            chance = chance / 2
        end
        if math.random() < chance then
            self:DeltaStat(1)
            print("OOPS")
        end
    end
end

function Hunger:ProcessFighter(fighter)
    local current_stage = self:GetCurrentStage()

    local damage_reduction = self.DAMAGE_REDUCTION[current_stage]
    if damage_reduction and damage_reduction > 0 then
        fighter:DeltaCondition("POWER", -damage_reduction)
    end
end

function Hunger:OnDeltaStat(old_stat, new_stat, delta)
    if new_stat >= 12 then
        if self.agent:IsPlayer() then
            self.player_starved = true
        else
            self.agent:Kill()
        end
    end
end

function Hunger:CanEatFood(card)
    if not card then
        return self:GetCurrentStage() >= 3
    end

    if not card.food_data_etb then
        return false
    end

    return self:GetCurrentStage() >= 3
end

local Fatigue = class( "ETBClass.Fatigue", ETBClass.VitalAspect)
Content.AddAspect( "etb_fatigue", Fatigue )

Fatigue.DELTA_CHANCE = {0.9, 0.75, 0.6, 0.5, 0.3}
Fatigue.MAX_RESOLVE_DELTA = {1, 0, 0, -1, -2}
Fatigue.CONDITION_DELTA = {1, 0, 1, 1, 2}
Fatigue.CONDITION_ID = {"convenience", nil, "ETB_DROWSY", "ETB_TIRED", "ETB_TIRED"}
Fatigue.MODIFIER_ID = {"convenience", nil, "ETB_DROWSY_NEGOTIATION", "ETB_TIRED_NEGOTIATION", "ETB_TIRED_NEGOTIATION"}

Fatigue.default_stat = 2
Fatigue.name = "Fatigue"
Fatigue.desc = "High level organisms often need some time to rest. A good night sleep is good for your sanity and your memory."
Fatigue.loc_strings = {
    ALT_NAME = "Fatigue ({1})",
    NAME_STAGE_1 = "Vigilant",
    NAME_STAGE_2 = "Lucid",
    NAME_STAGE_3 = "Drowsy",
    NAME_STAGE_4 = "Tired",
    NAME_STAGE_5 = "Exerted",
    DESC_STAGE_1 = "<#BONUS>Vigilant</>: Your mind is like a freshly sharpened sword. Fatigued occurs 1 turn later in both battle and negotiation. Gain 1 max resolve for each time segment passed while you are awake. Cannot sleep.",
    DESC_STAGE_2 = "<#HILITE>Lucid</>: You are perfectly awake. Cannot sleep.",
    DESC_STAGE_3 = "<#PENALTY>Drowsy</>: You are starting to want to go to sleep. Each card you play has a chance of getting expended, up to once per negotiation/battle.",
    DESC_STAGE_4 = "<#PENALTY>Tired</>: You really need to go to sleep. Each card you play has a chance of getting destroyed, up to once per negotiation/battle. Lose 1 max resolve for each time segment passed while you are awake.",
    DESC_STAGE_5 = "<#PENALTY>Exerted</>: You are seriously at your limit, and can pass out at any moment. Each card you play has a chance of getting destroyed, up to twice per negotiation/battle. Lose 2 max resolve for each time segment passed while you are awake.",
}
Fatigue.texture = global_images.resolve

function Fatigue:GetCurrentStage()
    if not self.current_stat then
        return
    end
    if self.current_stat <= 1 then
        return 1
    elseif self.current_stat <= 3 then
        return 2, true
    elseif self.current_stat <= 5 then
        return 3
    elseif self.current_stat <= 7 then
        return 4
    else
        return 5
    end
end

function Fatigue:OnTimeSegmentPassETB(old_time, new_time, delta, reason)
    if delta <= 0 then
        return
    end
    for i = 1, delta do
        local current_stage = self:GetCurrentStage()

        if reason ~= "REST" and reason ~= "SLEEP" then
            if self.agent:IsPlayer() then
                local max_resolve_delta = self.MAX_RESOLVE_DELTA[current_stage]
                if max_resolve_delta and max_resolve_delta ~= 0 then
                    TheGame:GetGameState():GetCaravan():DeltaMaxResolve(max_resolve_delta)
                end
            end
            -- Possibly increment fatigue
            local chance = self.DELTA_CHANCE[current_stage]
            if math.random() < chance then
                self:DeltaStat(1)
            end
        end
    end
end

function Fatigue:ProcessFighter(fighter)
    local current_stage = self:GetCurrentStage()

    local condition_delta = self.CONDITION_DELTA[current_stage]
    local condition_id = self.CONDITION_ID[current_stage]
    if condition_id and condition_delta and condition_delta ~= 0 then
        fighter:DeltaCondition(condition_id, condition_delta)
    end
end

function Fatigue:OnStartNegotiation(minigame)
    local current_stage = self:GetCurrentStage()

    local negotiator = minigame:GetNegotiator(self.agent)
    if negotiator then
        local condition_delta = self.CONDITION_DELTA[current_stage]
        local condition_id = self.MODIFIER_ID[current_stage]
        if condition_id and condition_delta and condition_delta ~= 0 then
            negotiator:DeltaModifier( condition_id, condition_delta )
        end
    end
end

function Fatigue:CanSleep()
    local can_sleep_threshold = 2
    if self.agent.etb_hunger and self.agent.etb_hunger:GetCurrentStage() > 3 then
        can_sleep_threshold = can_sleep_threshold + math.ceil((self.agent.etb_hunger:GetCurrentStage() - 3) / 2)
    end
    return self:GetCurrentStage() >= can_sleep_threshold
end

function Fatigue:CanContinueSleep()
    local awake_threshold = TheGame:GetGameState():GetDayPhase() == DAY_PHASE.NIGHT and 0 or 2
    if self.agent.etb_hunger and self.agent.etb_hunger:GetCurrentStage() > 3 then
        awake_threshold = awake_threshold + self.agent.etb_hunger:GetCurrentStage() - 3
    end
    return self.current_stat > awake_threshold
end

function Fatigue:OnDeltaStat(old_stat, new_stat, delta)
    if new_stat >= 10 then
        self.passed_out = true
    else
        self.passed_out = nil
    end
end
