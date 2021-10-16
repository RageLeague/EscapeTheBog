local patch_id = "CUSTOM_ADD_SPEECH"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Screen.ConversationScreen.AddSpeech
function Screen.ConversationScreen:AddSpeech(...)
    local params = {...}
    TheGame:BroadcastEvent("on_convo_speech", self, params)
    return old_fn(self, table.unpack(params))
end
