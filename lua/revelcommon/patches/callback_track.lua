local AddedCallbacks = {}

-- Doesn't actually work on multiple mods rn, as the local variables are
-- one instance just found it cleaner to split it in a separate function
local function PatchMod_TrackAddedCallbacks(mod)
    mod._PreCallTrackAddCallback = mod.AddCallback

    function mod:AddCallback(callbackId, fn, entityId)
        if not callbackId then
            error("AddCallback track override | callbackId is nil!", 2)
        end

        if not AddedCallbacks[callbackId] then
            AddedCallbacks[callbackId] = true
        end

        mod:_PreCallTrackAddCallback(callbackId, fn, entityId)
    end

    function mod:GetUsedCallbackIDs()
        return AddedCallbacks
    end

    ---@return table<CallbackID, CallbackEntry[]>
    function mod:GetRegisteredCallbacks()
        local callbacks = {}
        for callbackId, _ in pairs(AddedCallbacks) do
            callbacks[callbackId] = {}
            local thisCallbacks = Isaac.GetCallbacks(callbackId)
            for _, callback in ipairs(thisCallbacks) do
                if callback.Mod == mod then
                    table.insert(callbacks[callbackId], callback)
                end
            end
        end
        return callbacks
    end

    function mod:RemoveAllCallbacks()
        for callbackId, callbacks in pairs(self:GetRegisteredCallbacks()) do
            for _, callback in ipairs(callbacks) do
                mod:RemoveCallback(callbackId, callback.Function)
            end
        end
    end
end

return PatchMod_TrackAddedCallbacks