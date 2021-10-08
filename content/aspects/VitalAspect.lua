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

Hunger.DELTA_CHANCE = {1, 1, 0.75, 0.65, 0.5, 0.4, 0.35}
Hunger.RESOLVE_LOSS = {0, 0, 0, 1, 1, 2, 3}
Hunger.MAX_HEALTH_LOSS = {0, 0, 0, 0, 0, 1, 2}
Hunger.DAMAGE_REDUCTION = {0, 0, 0, 0, 1, 2, 3}

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
    DESC_STAGE_1 = "<#BONUS>Bloated</>: You are quite full. Gain 1 Fatigue for every time segment passed as long as you are Bloated. Gain 3 max health when you go from Bloated to Full.",
    DESC_STAGE_2 = "<#BONUS>Bloated</>: You have eaten enough. Gain 2 max health when you go from Full to Content.",
    DESC_STAGE_3 = "<#HILITE>Content</>: You have eaten enough food to go for a while. No special effects.",
    DESC_STAGE_4 = "<#PENALTY>Peckish</>: You are starting to crave some food. Lose 1 resolve for each time segment passed as long as you are Peckish.",
    DESC_STAGE_5 = "<#PENALTY>Hungry</>: You need to eat some food. Lose 1 resolve for each time segment passed as long as you are Hungry. Battle cards you own deal 1 less damage as long as you are Hungry.",
    DESC_STAGE_6 = "<#PENALTY>Very Hungry</>: You <i>really</> need to eat some food. Lose 2 resolve and 1 max health for each time segment passed as long as you are Hungry. Battle cards you own deal 2 less damage as long as you are Hungry.",
    DESC_STAGE_7 = "<#PENALTY>Very Hungry</>: You need to eat before you starve to death. Lose 3 resolve and 2 max health for each time segment passed as long as you are Hungry. Battle cards you own deal 3 less damage as long as you are Hungry.",
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

        local resolve_loss = self.RESOLVE_LOSS[current_stage]
        if resolve_loss and resolve_loss > 0 then
            if self.agent:IsPlayer() then
                TheGame:GetGameState():GetCaravan():DeltaResolve(-resolve_loss)
            end
        end

        local max_health_loss = self.MAX_HEALTH_LOSS[current_stage]
        if max_health_loss and max_health_loss > 0 then
            if self.agent.health then
                self.agent.health:AddStatModifier("HUNGER", -max_health_loss)
            end
        end

        -- Possibly increment hunger
        local chance = self.DELTA_CHANCE[current_stage]
        if reason == "REST" then
            chance = chance / 2
        end
        if math.random() < chance then
            self:DeltaStat(1)
        end
    end
end

local Fatigue = class( "ETBClass.Fatigue", ETBClass.VitalAspect)
Content.AddAspect( "etb_fatigue", Fatigue )

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
    DESC_STAGE_1 = "<#BONUS>Vigilant</>: Your mind is like a freshly sharpened sword. Fatigued occurs 1 turn later in both battle and negotiation. Gain 2 max resolve when you go from Vigilant to Lucid. Cannot sleep.",
    DESC_STAGE_2 = "<#HILITE>Lucid</>: You are perfectly awake. Cannot sleep.",
    DESC_STAGE_3 = "<#PENALTY>Drowsy</>: You are starting to want to go to sleep. Each card you play has a chance of getting expended, up to once per negotiation/battle.",
    DESC_STAGE_4 = "<#PENALTY>Tired</>: You really need to go to sleep. Each card you play has a chance of getting expended, up to twice per negotiation/battle. Lose one action at the start of each negotiation/battle.",
    DESC_STAGE_5 = "<#PENALTY>Exerted</>: You are seriously at your limit, and can pass out at any moment. Each card you play has a chance of getting expended, up to three times per negotiation/battle. Lose two actions at the start of each negotiation/battle.",
}
Fatigue.texture = global_images.resolve

function Fatigue:GetCurrentStage()
    if not self.current_stat then
        return
    end
    if self.current_stat <= 1 then
        return 1
    elseif self.current_stat <= 3 then
        return 2
    elseif self.current_stat <= 5 then
        return 3, true
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

        -- Possibly increment hunger
        local chance = self.DELTA_CHANCE[current_stage]
        if reason == "REST" then
            chance = chance / 2
        end
        if math.random() < chance then
            self:DeltaStat(1)
        end
    end
end
