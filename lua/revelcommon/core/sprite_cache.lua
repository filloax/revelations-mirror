local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Too many big mods = memory errors, black square-d sprites, etc
-- try to avoid it

-- temporary, later add way to detect many big mods at once?
-- shouldn't be too big a cache hit anyways
REVEL.DO_MEMORY_FIX = true

local function RunClearCache()
    local consoleOut = Isaac.ExecuteCommand("clearcache")
    REVEL.DebugToString("Cleared cache, console output:", consoleOut)
    -- local consoleOut = Isaac.ExecuteCommand("reloadshaders")
    -- REVEL.DebugToString("Reloaded shaders, console output:", consoleOut)
end

revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    if REVEL.DO_MEMORY_FIX
    and REVEL.game:GetFrameCount() > 10 then
        RunClearCache()
    end
end)

end
