local old_flee = Fighter.Flee
function Fighter:Flee(...)
    if self.battle:GetCurrentTeam() ~= self:GetTeam() and EscapeTheBogUtil.IsETBCampaign() then
        if not self:HasCondition("RUNNING") then
            self:AddCondition( "RUNNING" )
        end
        return
    end
    old_flee(self, ...)
end

Content.GetBattleCondition("RUNNING").hud_fx = {"surrender"}
Content.GetBattleCondition("RUNNING").idle_state_override = IDLE_STATE.SURRENDER
