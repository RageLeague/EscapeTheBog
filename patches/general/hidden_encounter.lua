local patch_id = "HIDDEN_ENCOUNTER"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local negotiation_defs = require "negotiation/negotiation_defs"

function ConvoOption:HiddensNegotiation( params )
    params = params or {}
    params.is_negotiation = true
    -- if self.hub.caravan:GetResolve() <= 0 then
    --     if params.flags and CheckBits( params.flags, NEGOTIATION_FLAGS.NO_AUTOFAIL ) then
    --         self:ReqCondition( false, "NO_RESOLVE_DISABLED" )
    --         self.last_param = params
    --         return self
    --     end
    -- end

    local agent = params.target_agent or self.hub:GetAgent()
    if agent == nil then
        self:ReqCondition( false )
        self.last_param = params
        return self
    end

    params.reason = self.hub:GetLocString(params.reason or (params.flags and CheckBits( params.flags, NEGOTIATION_FLAGS.INTIMIDATION ) and "DEFAULT_NEGOTIATION_REASON_INTIMIDATE" or "DEFAULT_NEGOTIATION_REASON"), agent)

    -- Negotiation difficulty, unless overridden, is determined by quest rank.
    if params and params.difficulty == nil then
        if self.hub.quest then
            params.difficulty = self.hub.quest:GetRank()
        else
            params.difficulty = TheGame:GetGameState():GetCurrentBaseDifficulty()
        end
    end

    -- self.negotiation_params = Negotiation.MiniGame.ParamsFromParty( self.hub.caravan, agent, params, self.hub.encounter )

    -- if self.hub.caravan:GetResolve() <= 0 then
    --     self:PostText( "NO_RESOLVE" )
    --     self:PreIcon( global_images.warning, UICOLOURS.NEGOTIATION )
    -- else
    --     self:PreIcon( global_images.negotiation, UICOLOURS.NEGOTIATION )
    -- end
    -- self.data = self.data or {}
    -- self.data.sfx = "event:/ui/main/gen/pre_negotiation_click"
    -- self.data.preclick_fn = function( option )
    --     local screen = self.hub.encounter:GetScreen()
    --     if not screen:IsNegotiationPreviewPanelShowing() then
    --         screen:PresentNegotiationPreviewPanel( self.negotiation_params )
    --         return false
    --     end
    --     return true
    -- end

    -- local timer_name = self.hub:GetStateID()..(params.timer_id or self.loc_id or self.text or "")
    -- local cooldown = params.cooldown or 1
    -- if cooldown > 0 then
    --     local mem, duration = agent:HasMemoryOfNegotiation(timer_name, cooldown)
    --     self:ReqCondition( not mem, "ON_COOLDOWN", cooldown )
    -- end

    --DBG(params.resolve_modifiers)
    -- if self.negotiation_params.resolve_modifiers then
    --     for _, modifier in ipairs(self.negotiation_params.resolve_modifiers) do
    --         if modifier.value then
    --             local txt = self.hub.encounter:LocFormat( modifier.text )
    --             if modifier.value > 0 then

    --                 self:PostText( "SITUATION_MODIFIER_POSITIVE", modifier.value, txt )
    --             else
    --                 self:PostText( "SITUATION_MODIFIER_NEGATIVE", modifier.value, txt )
    --             end
    --         end
    --     end
    -- end

    self:Fn(function(cxt)
        local result = cxt:DoNegotiation( params )
        if result ~= negotiation_defs.RESULT.CANCELLED then
            agent:RememberNegotiation( timer_name )
        end
    end )

    -- if self.negotiation_params.flags & NEGOTIATION_FLAGS.INTIMIDATION ~= 0 then
    --     -- NOTE: only_show because the actual opinion event needs to happen in Encounter:RunNegotiation,
    --     -- to ensure it occurs before any subsequence option handlers are run.
    --    self:ReceiveOpinion(OPINION.ATTEMPT_INTIMIDATION, { only_show = true }, agent)
    -- end

    self.last_param = params
    return self
end

function ConvoOption:HiddenBattle(params)
    params = params or {}
    params.is_battle = true

    if params.on_runaway == nil then
        if self.hub.quest and ( self.hub.quest:GetType() ~= QTYPE.STORY ) then
            params.on_runaway = StateGraphUtil.DoRunAway
        end
    end

    -- self.battle_scenario = self.hub.encounter:CreateScenario( params, self.hub.quest )

    -- if params.on_runaway == nil then
    --     self.battle_scenario:SetFlags( BATTLE_FLAGS.NO_FLEE )
    -- end


    -- self:PreIcon( global_images.combat, UICOLOURS.FIGHT )
    -- if not self.battle_scenario:IsSelfDefence() then
    --     local primary = self.battle_scenario:GetPrimary( TEAM.RED )
    --     if primary and primary:IsSentient() and primary:GetSocialConnections() then
    --         self:ReceiveOpinion( OPINION.ATTACKED, nil, primary )
    --     end
    -- end

    -- self.data = self.data or {}
    -- self.data.sfx = "event:/ui/main/gen/pre_battle_click"
    -- self.data.preclick_fn = function( option )
    --     local screen = self.hub.encounter:GetScreen()
    --     if not screen:IsBattlePreviewPanelShowing() then
    --         screen:PresentBattlePreviewPanel( self.battle_scenario )
    --         return false
    --     end
    --     return true
    -- end

    self:Fn(function()
        self.hub:DoBattle(params)
    end)

    self.last_param = params
    return self
end
