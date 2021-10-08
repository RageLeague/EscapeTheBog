local ICON_SIZE = 50

local VitalsIcon = class( "ETBClass.Widget.VitalsIcon", Widget )

function VitalsIcon:init( size, aspect_id )
    VitalsIcon._base.init( self )
    assert(aspect_id, "Need an aspect id!")
    self.aspect_id = aspect_id
    self.hover_check = true
    self.tex = aspect_id and Content.GetAspect(aspect_id) and Content.GetAspect(aspect_id).texture or engine.asset.Texture("icons/support_icon.tex")
    size = size or 30
    self.icon = self:AddChild( Widget.Image( self.tex, size, size )):SetBloom(0.06)
end

function VitalsIcon:RefreshVitals( agent )
    local aspect = agent:GetAspect(self.aspect_id)
    if not aspect then
        self:Hide()
        return
    end
    local stage, hide = aspect:GetCurrentStage()
    if hide then
        self:Hide()
        return
    end
    print("Showing aspect icon", agent, self.aspect_id)
    self:SetToolTip(aspect:FormatDesc())
    self.tex = aspect:GetTexture()
    self.icon:SetTexture(self.tex)
    self:Show()
end

local old_refresh_fn = Widget.PlaxNameplate.RefreshNameplate

function Widget.PlaxNameplate:RefreshNameplate( agent, scale, ... )
    local i = 1
    while i <= #self.icons_left do
        local icon = self.icons_left[i]
        if is_instance(icon, VitalsIcon) then
            icon:Remove()
            table.remove(self.icons_left, i)
        else
            i = i + 1
        end
    end
    if agent.sorted_aspects then
        for i, aspect in ipairs(agent.sorted_aspects) do
            if aspect.GetCurrentStage then
                local widget = self.icons:AddChild( VitalsIcon(ICON_SIZE, aspect.id) )
                table.insert(self.icons_left, widget)
                widget:RefreshVitals( agent )
            end
        end
    end
    old_refresh_fn(self, agent, scale, ...)
end
