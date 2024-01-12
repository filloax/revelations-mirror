local RevCallbacks = require "lua.revelcommon.enums.RevCallbacks"

return function()
    Isaac.RunCallback(RevCallbacks.POST_LOAD)

    Isaac.DebugString("Revelations: Loaded Post Load Code!")
end