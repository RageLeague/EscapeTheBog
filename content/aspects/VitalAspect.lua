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

function VitalAspect:HarvestStrings(t)
    VitalAspect._base.HarvestStrings(self, t)
    if self.loc_strings then
        for key, str in pairs( self.loc_strings ) do
            t[self:GetLocStringPrefix(key)] = str
        end
    end
end
