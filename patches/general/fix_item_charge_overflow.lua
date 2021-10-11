local patch_id = "FIX_ITEM_CHARGE_OVERFLOW"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local assets = {
    glow = engine.asset.Texture( "UI/cardview_glow.tex"),
    common_outline = engine.asset.Texture( "UI/cardview_common_outline.tex" ),
    common_back = engine.asset.Texture( "UI/cardview_common_back.tex"),
    common_overlay = engine.asset.Texture( "UI/cardview_common_overlay.tex"),
    common_upgrade = engine.asset.Texture( "UI/cardview_common_upgrade.tex"),
    lock = engine.asset.Texture("UI/card_lock.tex"),
    motd_bg = engine.asset.Texture("UI/motd_info_bg.tex"),
    shine = engine.asset.Texture( "UI/cardview_shine.tex"),
    negotiation_wild =  engine.asset.Texture( "negotiation/negotiation_wild.tex" ),
    wild = engine.asset.Texture( "battle/cards_wild.tex" ),
    smoke = engine.asset.Texture( "particles/smoke.tex"),
    charges_full = engine.asset.Texture("UI/ic_charges_full.tex"),
    charges_empty = engine.asset.Texture("UI/ic_charges_empty.tex"),
    upgradebar = engine.asset.Texture("UI/cardupgrade_bar.tex")
}

local old_fn = Widget.CardWidget.RefreshCharges

function Widget.CardWidget:RefreshCharges(card, ...)
    local charges, max_charges = card:GetCharges()
    if max_charges and max_charges >= 7 then
        if self.charges_root then
            self.charges_root:Remove()
            self.charges_root = nil
        end
        return
        -- if not self.charges_root then
        --     self.charges_root = self.contents:AddChild( Widget.SegmentedBar() )
        -- end

        -- local max_pip_container_length = 168

        -- local pip_size = 28
        -- local pip_spacing = 0
        -- local pip_container_length = max_charges * pip_size + (max_charges-1) * pip_spacing
        -- if pip_container_length > max_pip_container_length then
        --     pip_spacing = (max_pip_container_length - max_charges * pip_size) / (max_charges-1)

        --     self.charges_root:Show()
        --     self.charges_root:SetSize( pip_container_length, pip_size )
        --     self.charges_root:SetOnTexture( assets.charges_full, 0, 0, 0, 0 )
        --     self.charges_root:SetOffTexture( assets.charges_empty, 0, 0, 0, 0 )
        --     self.charges_root:SetSpaceBetweenPips( pip_spacing )
        --     self.charges_root:SetProgress( max_charges, charges )

        --     local x, y = self.art:GetPos()
        --     self.charges_root:SetRotation( -90*DEGREES )
        --     self.charges_root:SetPos( x - 140 - pip_size/2, y )
        --     -- return
        -- end
    end
    old_fn(self, card, ...)
end
