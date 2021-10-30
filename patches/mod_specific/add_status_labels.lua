local old_preview_fn = Widget.NegotiationPreviewPanel.init
local DETAILS_TILE_W = 340
function Widget.NegotiationPreviewPanel:init(card_type, ...)
    old_preview_fn(self, card_type, ...)
    self.etb_is_hungry = self.handicaps:AddChild( Widget.PreviewDetailsTile( DETAILS_TILE_W, engine.asset.Texture("ui/ic_handicaps_no_surrender.tex"), UICOLOURS.PENALTY, LOC"ASPECT.ETB_HUNGER.NAME", LOC"ETB.STATUS_PANEL.HUNGER_WARNING" ) )
    self.etb_is_tired = self.handicaps:AddChild( Widget.PreviewDetailsTile( DETAILS_TILE_W, engine.asset.Texture("ui/ic_handicaps_noresolve.tex"), UICOLOURS.PENALTY, LOC"ASPECT.ETB_FATIGUE.NAME", LOC"ETB.STATUS_PANEL.FATIGUE_WARNING" ) )
end

local old_refresh_fn = Widget.NegotiationPreviewPanel.Refresh
function Widget.NegotiationPreviewPanel:Refresh(scenario, ...)
    if self.card_type == QCARD_TYPE.BATTLE then
        local hunger = TheGame:GetGameState():GetPlayerAgent().etb_hunger
        if hunger and hunger:GetCurrentStage() >= 4 then
            self.etb_is_hungry:SetText(hunger:GetStageName(), loc.format(LOC"ETB.STATUS_PANEL.HUNGER_WARNING", hunger:GetStageName()))
            self.etb_is_hungry:SetShown(true)
        else
            self.etb_is_hungry:SetShown(false)
        end
    else
        self.etb_is_hungry:SetShown(false)
    end
    local fatigue = TheGame:GetGameState():GetPlayerAgent().etb_fatigue
    if fatigue and fatigue:GetCurrentStage() >= 3 then
        self.etb_is_tired:SetText(fatigue:GetStageName(), loc.format(LOC"ETB.STATUS_PANEL.FATIGUE_WARNING", fatigue:GetStageName()))
        self.etb_is_tired:SetShown(true)
    else
        self.etb_is_tired:SetShown(false)
    end
    return old_refresh_fn(self, scenario, ...)
end
