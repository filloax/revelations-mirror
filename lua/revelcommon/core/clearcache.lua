local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()

-- Too many big mods = memory errors, black square-d sprites, etc
-- try to avoid it

-- temporary? later add way to detect many big mods at once?
-- shouldn't be too big a performance hit anyways
REVEL.DO_MEMORY_FIX = true

local ClearCacheModes = {
    OFF = 0,
    EVERY_LEVEL = 1,
    EVERY_ROOM = 2,
}

local LEVEL_MODE_MINS_FORCE_CLEAR = 1.5

local LastClearCacheTime = -1

local function RunClearCache()
    local consoleOut = Isaac.ExecuteCommand("clearcache")
    REVEL.DebugToString("Cleared cache, console output:", consoleOut)
    -- local consoleOut = Isaac.ExecuteCommand("reloadshaders")
    -- REVEL.DebugToString("Reloaded shaders, console output:", consoleOut)
    LastClearCacheTime = Isaac.GetTime()
end

function REVEL.ClearCache()
    RunClearCache()
end

revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    if REVEL.DO_MEMORY_FIX
    and revel.data.clearCacheMode == ClearCacheModes.EVERY_ROOM
    or (
        revel.data.clearCacheMode == ClearCacheModes.EVERY_LEVEL
        and Isaac.GetTime() - LastClearCacheTime >= LEVEL_MODE_MINS_FORCE_CLEAR * 60000
    )
    and REVEL.game:GetFrameCount() > 10 then
        RunClearCache()
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
    if REVEL.DO_MEMORY_FIX
    and revel.data.clearCacheMode == ClearCacheModes.EVERY_LEVEL
    and REVEL.game:GetFrameCount() > 10 then
        RunClearCache()
    end
end)

end
