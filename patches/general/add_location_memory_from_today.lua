local patch_id = "ADD_LOCATION_MEMORY_FROM_TODAY"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local memtokens = require "memtokens"

function Location:HasMemoryFromToday(token)
    local phase = TheGame:GetGameState():GetDayPhase()
    local duration = (phase == DAY_PHASE.DAY) and 1 or 2
    return memtokens.HasMemory( self.memory, token, duration)
end
