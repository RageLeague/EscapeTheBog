local patch_id = "NEGOTIATION_FORCE_SINGLE_TARGET"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = ExtendEnum(negotiation_defs.EVENT, {
    "CALC_DEFAULT_TARGET",
    "CALC_FORCE_AUTO_TARGET",
})

local old_fn = Negotiation.MiniGame.CollectPrimaryTarget

function Negotiation.MiniGame:CollectPrimaryTarget(source, target, ...)
    if is_instance( target, Negotiation.Negotiator ) then
        target = target:FindCoreArgument()
    end

    if not source:NeedsTarget() then
        return target
    end

    local t = {}
    self:CollectAllTargets( source, t )

    local weighted_targets = {}
    for i, v in ipairs( t ) do
        if source.EvaluateTargetWeight then
            weighted_targets[ v ] = source:EvaluateTargetWeight( v, t )
        else
            weighted_targets[ v ] = 1
        end
    end

    -- Verify the optional target argument; it takes precedence.
    if target and (not self:CanTarget( source, target ) or (weighted_targets[ target ] or 0) <= 0) then
        print( "Retargetting:", source, "from", target )
        target = nil
    end

    if target then
        return old_fn(self, source, target, ...)
    end

    if not self.default_target_accumulator then
        self.default_target_accumulator = CardEngine.ScalarAccumulator( self, EVENT.CALC_DEFAULT_TARGET )
    end

    local default_target = self.default_target_accumulator:CalculateValue( nil, source, weighted_targets, ... )
    if default_target then
        return default_target
    end
    return old_fn(self, source, target, ...)
end

local old_auto_target = Widget.NegotiationPanel.AssignAutoTarget

function Widget.NegotiationPanel:AssignAutoTarget(card, ...)
    local res = old_auto_target(self, card, ...)
    if true then
        local minigame = self.minigame
        local t = {}
        minigame:CollectAllTargets( card, t )

        local weighted_targets = {}
        for i, v in ipairs( t ) do
            if card.EvaluateTargetWeight then
                weighted_targets[ v ] = card:EvaluateTargetWeight( v, t )
            else
                weighted_targets[ v ] = 1
            end
        end

        if not minigame.force_target_accumulator then
            minigame.force_target_accumulator = CardEngine.ScalarAccumulator( minigame, EVENT.CALC_FORCE_AUTO_TARGET )
        end

        res = minigame.force_target_accumulator:CalculateValue( res, card, weighted_targets, ... )
    end
    return res
end
