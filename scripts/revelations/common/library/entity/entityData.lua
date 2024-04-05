local RevCallbacks = require "scripts.revelations.common.enums.RevCallbacks"

return function()

-- entity data that doesn't get cleared on entity remove,
-- but on new room after entity remove
-- Still uses :GetData() for mod reload persistence

-- Early to be used in player id stuff

---@type table<integer, {ClearOnRoom: boolean, Data: table}>
local EntityData = {}

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
                ClearOnRoom = false,
                Data = {}
            }
            EntityData[hash] = dataEntry
            baseData.__RevEntityData = dataEntry
        end
    end

    return EntityData[hash].Data
end

local function edata_PostEntityRemove(_, entity)
    local baseData = entity:GetData()
    local hash = GetPtrHash(entity)

    if EntityData[hash] then
        EntityData[hash].ClearOnRoom = true
    end
end

local function edata_PostNewRoom()
    local toRemove = {}
    for hash, dataEntry in pairs(EntityData) do
        if dataEntry.ClearOnRoom then
            toRemove[#toRemove+1] = hash
        end
    end
    for _, hash in ipairs(toRemove) do
        EntityData[hash] = nil
    end
end

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, edata_PostEntityRemove)
revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, edata_PostNewRoom)

end