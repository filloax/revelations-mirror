local AddedCallbacks = {}
local FunctionMaps = {}

for _, callbackId in pairs(ModCallbacks) do
    AddedCallbacks[callbackId] = {}
    FunctionMaps[callbackId] = {}
end

-- Doesn't actually work on multiple mods rn, as the local variables are
-- one instance just found it cleaner to split it in a separate function
local function PatchMod_TrackAddedCallbacks(mod)
    mod._PreCallTrackAddCallback = mod.AddCallback
    mod._PreCallTrackRemoveCallback = mod.RemoveCallback

    function mod:AddCallback(callbackId, fn, entityId)
        entityId = entityId or -1 -- base game behavior

        if not fn then
            error("AddCallback | function nil", 2)
        end
        if type(fn) ~= "function" then
            error("AddCallback | function not a function: " .. tostring(fn), 2)
        end
        if not AddedCallbacks[callbackId] then
            error("AddCallback | Unknown callback " .. tostring(callbackId), 2)
        end

        if not AddedCallbacks[callbackId][entityId] then
            AddedCallbacks[callbackId][entityId] = {}
        end

        FunctionMaps[callbackId][fn] = FunctionMaps[callbackId][fn] or {}
        table.insert(FunctionMaps[callbackId][fn], entityId)

        table.insert(AddedCallbacks[callbackId][entityId], fn)
        mod:_PreCallTrackAddCallback(callbackId, fn, entityId)
    end

    function mod:RemoveCallback(callbackId, fn)
        if not fn then
            error("RemoveCallback | function nil", 2)
        end
        if type(fn) ~= "function" then
            error("RemoveCallback | function not a function: " .. tostring(fn), 2)
        end

        local entityIds = FunctionMaps[callbackId] and FunctionMaps[callbackId][fn]

        if not entityIds then
            REVEL.DebugStringMinor("RemoveCallback | WARN: callback not registered", callbackId, fn)
        else
            for _, entityId in ipairs(entityIds) do
                if not AddedCallbacks[callbackId][entityId] then
                    REVEL.DebugStringMinor("RemoveCallback | WARN: no callbacks for this entity id", callbackId, entityId)
                else
                    local item = REVEL.indexOf(AddedCallbacks[callbackId][entityId], fn)
                    if not item then
                        REVEL.DebugStringMinor("RemoveCallback | WARN: callback for entity not registered", callbackId, entityId, fn)
                    else
                        table.remove(AddedCallbacks[callbackId][entityId], item)
                    end
                end
            end
            FunctionMaps[callbackId][fn] = nil
        end

        mod:_PreCallTrackRemoveCallback(callbackId, fn)
    end

    function mod:GetRegisteredCallbacks()
        return AddedCallbacks
    end

    function mod:RemoveAllCallbacks()
        for callbackId, functionMap in pairs(FunctionMaps) do
            for fn, entityIds in pairs(functionMap) do
                mod:RemoveCallback(callbackId, fn)
            end
        end
    end

    local thisRemoveCallback = mod.RemoveCallback -- work around later hook

    -- Force to use this remove callback
    function mod:RemoveRegisteredCallbacks()
        for callbackId, functionMap in pairs(FunctionMaps) do
            for fn, entityIds in pairs(functionMap) do
                thisRemoveCallback(mod, callbackId, fn)
            end
        end
    end
end

return PatchMod_TrackAddedCallbacks