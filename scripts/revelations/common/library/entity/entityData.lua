local RevCallbacks = require "scripts.revelations.common.enums.RevCallbacks"

return function()

-- entity data that doesn't get cleared on entity remove,
-- but on new room after entity remove
-- Still uses :GetData() for mod reload persistence

-- Early to be used in player id stuff

---@type table<integer, {ClearingSoon: boolean, Data: table}>
local EntityData = {}

if REVEL.DEBUG then
    REVEL.EntityData = EntityData
end

---@param entity Entity
---@return table data
function REVEL.GetData(entity)
    REVEL.Assert(entity, "REVEL.GetData | entity nil!", 2)

    local baseData = entity:GetData()
    local hash = GetPtrHash(entity)

    if not EntityData[hash] then
        -- data exists, was reloaded
        if baseData.__RevEntityData then
            EntityData[hash] = baseData.__RevEntityData
        else
            local dataEntry = {
                ClearingSoon = false,
                Data = {}
            }
            EntityData[hash] = dataEntry
            baseData.__RevEntityData = dataEntry
        end
    end

    return EntityData[hash].Data
end

local function edata_PostEntityRemove(_, entity)
    local hash = GetPtrHash(entity)

    if EntityData[hash] then
        EntityData[hash].ClearingSoon = true
        -- REVEL.DebugLog("Marked data", hash, "for removal, data is:", REVEL.PrettyPrint(EntityData[hash]), debug.traceback())

        REVEL.DelayFunction(function()
            -- double check to avoid sync shenanigans
            if EntityData[hash] and EntityData[hash].ClearingSoon then
                EntityData[hash] = nil
                -- REVEL.DebugLog("Removed data", hash)
            end
        end, 1)
    end
end

revel:AddPriorityCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, CallbackPriority.LATE, edata_PostEntityRemove)

end