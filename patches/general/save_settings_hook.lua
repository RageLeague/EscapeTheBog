local patch_id = "SAVE_SETTINGS_HOOK"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = UserSettings.SaveSettings
function UserSettings:SaveSettings(...)
    local skip_save = not self.dirty or self.fatal_error
    local res = old_fn(self, ...)
    if not skip_save then
        Content.InvokeModAPI( "OnSettingsSaved")
    end
    return res
end
