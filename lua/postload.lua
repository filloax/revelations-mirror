local RevCallbacks = require "lua.revelcommon.enums.RevCallbacks"

REVEL.LoadFunctions[#REVEL.LoadFunctions+1] = function()
    Isaac.RunCallback(RevCallbacks.POST_LOAD)

    Isaac.DebugString("Revelations: Loaded Post Load Code!")
end