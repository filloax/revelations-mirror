local StageAPICallbacks = require "scripts.revelations.common.enums.StageAPICallbacks"
local RevCallbacks      = require "scripts.revelations.common.enums.RevCallbacks"
return function()

--[[
Makes entities that "contain" items support rerolling.
Currently supports:
- d6 / d100
- eternal d6
- spindown dice

Works but doesn't remember things across rooms while vanilla does
- glitched crown
- tainted isaac / isaac + birthright
- isaac's soul

Hard to do due to API limits:
- d infinity

To do later: add support for pickups and d20, etc
]]

local ETERNAL_D6_REMOVE_CHANCE = 0.3
local FLICKER_FREQ_TISAAC = 30
local FLICKER_FREQ_GLITCHED_CROWN = 6

local RegisteredEntities = {
    Collectibles = {

    },
}

REVEL.Rerolls = {}

---@class RevRerolls.Handler
---@field IsRerollable (fun(entity: Entity): boolean)? # Specify if the entity should be treated as this type of rerollable only under certain conditions

---@class RevRerolls.CollectibleHandler : RevRerolls.Handler
---@field GetPersistId (fun(entity: Entity): string)? # Return id (unique across level) to use when saving entity data, can avoid to specify if the entity doesn't persist across rooms
---@field GetItemId fun(entity: Entity): CollectibleType # Returns the item ID of the entity
---@field GetPool (fun(entity: Entity): ItemPoolType)? # Specify if the entity belongs to a specific item pool
---@field DoReroll fun(entity: Entity, newType: CollectibleType) # From the new rerolled item id, actually apply the reroll on the item
---@field GetRerollItem (fun(entity: Entity, currentId: CollectibleType, hasChaos: boolean): CollectibleType)?  # Specify if you want to manually handle deciding what item the reroll results in
---@field OnDelete (fun(entity: Entity))?  # Specify if you want alternate behavior on eternal d6 / spindown dice sad onion deletion than removing the entity
---@field DoDuplicate (fun(entity: Entity))? # Spawns a new pedestal of that collectible type

---Register entity to be handled like 
-- a collectible by reroll items 
---@param handler RevRerolls.CollectibleHandler
---@param etype integer
---@param variant integer
---@overload fun(handler: RevRerolls.CollectibleHandler, entDef: RevEntDef)
function REVEL.Rerolls.RegisterAsCollectible(handler, etype, variant)
    if type(etype) == "table" then
        ---@type RevEntDef
        local entDef = etype
        etype = entDef.id
        variant = entDef.variant
    end

    RegisteredEntities.Collectibles[etype] = RegisteredEntities.Collectibles[etype] or {}
    RegisteredEntities.Collectibles[etype][variant] = handler
end

local function IsValidEntity(entity, handler)
    return not handler.IsRerollable or handler.IsRerollable(entity)
end

---@class RevRerolls.Data
---@field FlickerData RevRerolls.FlickeringData?

---@param handler RevRerolls.CollectibleHandler
---@return RevRerolls.Data
local function GetData(entity, handler)
    local saveTable = revel.data.run.level.rerollsData
    local roomId = StageAPI.GetCurrentRoomID()
    -- Use InitSeed if no persist id specified, works when in same room
    local entityId = handler.GetPersistId and handler.GetPersistId(entity) or tostring(entity.InitSeed)

    if not saveTable[roomId] then saveTable[roomId] = {} end
    if not saveTable[roomId][entityId] then saveTable[roomId][entityId] = {} end
    return saveTable[roomId][entityId]
end

---@param registeredTable {[EntityType]: {[integer]: RevRerolls.CollectibleHandler}}
---@return fun(): Entity, RevRerolls.CollectibleHandler
local function EachRerollableEntity(registeredTable)
    local currentType, currentTypeTable = next(registeredTable)
    local currentVariant, currentHandler, currentEntities
    if currentTypeTable then
        currentVariant, currentHandler = next(currentTypeTable)
        currentEntities = Isaac.FindByType(currentType, currentVariant)
    end
    local currentIndex, currentEntity

    return function() 
        currentIndex, currentEntity = next(currentEntities, currentIndex)
        while not currentEntity or not IsValidEntity(currentEntity, currentHandler) do
            -- entity exists but not valid
            if currentEntity then
                currentIndex, currentEntity = next(currentEntities, currentIndex)
                -- retry with next
            else
                currentVariant, currentHandler = next(currentTypeTable, currentVariant)
                if currentVariant then
                    currentEntities = Isaac.FindByType(currentType, currentVariant)
                    currentIndex, currentEntity = next(currentEntities, currentIndex)
                    -- retry with next entity-variant set
                else
                    currentType, currentTypeTable = next(registeredTable, currentType)
                    if not currentTypeTable then
                        return nil
                    end
                end
            end
        end
        return currentEntity, currentHandler
    end
end

local function IsChaosActive()
    return REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_CHAOS)
end

---@param entity Entity
---@param handler RevRerolls.CollectibleHandler
---@param forceChaos? boolean # Forces chaos to true/false if not nil
local function ApplyBaseReroll(entity, handler, forceChaos)
    local currentId = handler.GetItemId(entity)

    local chaos
    if forceChaos ~= nil then
        chaos = forceChaos
    else
        chaos = IsChaosActive()
    end

    if handler.GetRerollItem then
        return handler.GetRerollItem(entity, currentId, chaos)
    end

    local poolType = handler.GetPool and handler.GetPool(entity) 
        or REVEL.pool:GetPoolForRoom(REVEL.room:GetType(), REVEL.room:GetSpawnSeed())
    if chaos then
        local rng = REVEL.RNG()
        rng:SetSeed(entity.InitSeed, 40)
        poolType = rng:RandomInt(ItemPoolType.NUM_ITEMPOOLS)
    end

    return REVEL.pool:GetCollectible(poolType, true)
end

---@param player EntityPlayer
---@param useFlags UseFlag
---@param activeSlot ActiveSlot
local function rerolls_rerollItem_UseItem(_, collectibleType, rng, player, useFlags, activeSlot, varData)
    REVEL.DebugStringMinor("Used D6, player is", REVEL.GetPlayerID(player))
    for entity, handler in EachRerollableEntity(RegisteredEntities.Collectibles) do
        handler.DoReroll(entity, ApplyBaseReroll(entity, handler))
    end
end

---@param player EntityPlayer
---@param useFlags UseFlag
---@param activeSlot ActiveSlot
local function rerolls_eternald6_UseItem(_, collectibleType, rng, player, useFlags, activeSlot, varData)
    for entity, handler in EachRerollableEntity(RegisteredEntities.Collectibles) do
        local rng = REVEL.RNG()
        rng:SetSeed(entity.InitSeed, 40)
        if rng:RandomFloat() < ETERNAL_D6_REMOVE_CHANCE then
            if handler.OnDelete then
                handler.OnDelete(entity)
            else
                entity:Remove()
            end
        else
            handler.DoReroll(entity, ApplyBaseReroll(entity, handler))
        end
    end
end

---@param player EntityPlayer
---@param useFlags UseFlag
---@param activeSlot ActiveSlot
local function rerolls_spindown_UseItem(_, collectibleType, rng, player, useFlags, activeSlot, varData)
    for entity, handler in EachRerollableEntity(RegisteredEntities.Collectibles) do
        local itemType = handler.GetItemId(entity)
        local configItem
        repeat
            itemType = itemType - 1
            configItem = REVEL.config:GetCollectible(itemType)
        until (configItem and not configItem.Hidden) or itemType == 0

        if itemType == 0 then
            if handler.OnDelete then
                handler.OnDelete(entity)
            else
                entity:Remove()
            end
        else
            handler.DoReroll(entity, itemType)
        end
    end
end

---@param player EntityPlayer
---@param useFlags UseFlag
---@param activeSlot ActiveSlot
local function rerolls_diplopia_UseItem(_, collectibleType, rng, player, useFlags, activeSlot, varData)
    for entity, handler in EachRerollableEntity(RegisteredEntities.Collectibles) do
        if handler.DoDuplicate then
            handler.DoDuplicate(entity)
        else
            local currentId = handler.GetItemId(entity)

            local freePos = REVEL.room:FindFreePickupSpawnPosition(entity.Position+Vector(0,16))
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, currentId, freePos, Vector.Zero, entity):ToPickup()
        end
    end
end

-- Flickering items
-- Tainted Isaac, Glitched Crown, etc

---@class RevRerolls.FlickeringData
---@field Progress integer
---@field NumItems integer
---@field Frequency integer
---@field ForceChaos boolean?
---@field Items integer[]

---@param entity Entity
---@param handler RevRerolls.CollectibleHandler
local function FlickeringItemUpdate(entity, handler)
    local data = GetData(entity, handler)
    local fdata = data.FlickerData

    if fdata then
        if entity.FrameCount % fdata.Frequency == 0
        and handler.IsRerollable(entity) -- wait for item id to be available (callbacks may run after)
        then
            fdata.Items[fdata.Progress] = handler.GetItemId(entity)

            fdata.Progress = fdata.Progress % fdata.NumItems + 1
            if not fdata.Items[fdata.Progress] then
                fdata.Items[fdata.Progress] = ApplyBaseReroll(entity, handler, fdata.ForceChaos)
            end
            handler.DoReroll(entity, fdata.Items[fdata.Progress])
        end
    end
end

---@param card Card
---@param player EntityPlayer
---@param useFlags integer
local function rerolls_isaacSoul_UseCard(_, card, player, useFlags)
    if REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_GLITCHED_CROWN) then return end

    for entity, handler in EachRerollableEntity(RegisteredEntities.Collectibles) do
        local data = GetData(entity, handler)
        if data.FlickerData then
            data.FlickerData.NumItems = data.FlickerData.NumItems + 1
        else
            ---@type RevRerolls.FlickeringData
            local fdata = {
                Progress = 1,
                Frequency = FLICKER_FREQ_TISAAC,
                Items = {
                    handler.GetItemId(entity),
                },
                NumItems = 2,
            }
            data.FlickerData = fdata
        end
    end
end

-- Entity Callbacks

local function rerolls_PostEntityInit(_, entity)
    local handler = RegisteredEntities.Collectibles[entity.Type][entity.Variant]
    local data = GetData(entity, handler)

    local hasTaintedIsaac = REVEL.some(REVEL.players, function(player)
        return player:GetPlayerType() == PlayerType.PLAYER_ISAAC_B
            or player:GetPlayerType() == PlayerType.PLAYER_ISAAC 
                and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
    end)
    local hasGlitchedCrown = REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_GLITCHED_CROWN)

    if hasGlitchedCrown then
        ---@type RevRerolls.FlickeringData
        local fdata = {
            Progress = 1,
            Frequency = FLICKER_FREQ_GLITCHED_CROWN,
            Items = {
                -- Do not immediately set, as entities likely
                -- are initialized by callbacks loaded after this
                -- handler.GetItemId(entity),
            },
            NumItems = 5,
        }
        data.FlickerData = fdata
    elseif hasTaintedIsaac then
        ---@type RevRerolls.FlickeringData
        local fdata = {
            Progress = 1,
            Frequency = FLICKER_FREQ_TISAAC,
            Items = {
                -- Do not immediately set, as entities likely
                -- are initialized by callbacks loaded after this
                -- handler.GetItemId(entity),
            },
            NumItems = 2,
        }
        data.FlickerData = fdata
    end
end

local function rerolls_PostEntityUpdate(_, entity)
    local handler = RegisteredEntities.Collectibles[entity.Type][entity.Variant]
    FlickeringItemUpdate(entity, handler)
end

local InitializedSpecificCallbacks = false

local function InitializeSpecificCallbacks()
    InitializedSpecificCallbacks = true

    for etype, variantTable in pairs(RegisteredEntities.Collectibles) do
        -- In order of most likely usecases
        local callbackInit, callbackUpdate
        local alreadyRegistered = false
        if etype == EntityType.ENTITY_EFFECT then
            callbackInit = ModCallbacks.MC_POST_EFFECT_INIT
            callbackUpdate = ModCallbacks.MC_POST_EFFECT_UPDATE
        elseif etype >= 10 then -- npcs
            alreadyRegistered = true
            local variants = REVEL.keys(variantTable)
            revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, function(_, npc)
                if REVEL.includes(variants, npc.Variant) then
                    rerolls_PostEntityInit(_, npc)
                end
            end, etype)
            revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
                if REVEL.includes(variants, npc.Variant) then
                    rerolls_PostEntityUpdate(_, npc)
                end
            end, etype)
        elseif etype == EntityType.ENTITY_FAMILIAR then
            callbackInit = ModCallbacks.MC_FAMILIAR_INIT
            callbackUpdate = ModCallbacks.MC_FAMILIAR_UPDATE
        elseif etype == EntityType.ENTITY_BOMBDROP then
            callbackInit = ModCallbacks.MC_POST_BOMB_INIT
            callbackUpdate = ModCallbacks.MC_POST_BOMB_UPDATE
        elseif etype == EntityType.ENTITY_PICKUP then
            callbackInit = ModCallbacks.MC_POST_PICKUP_INIT
            callbackUpdate = ModCallbacks.MC_POST_PICKUP_UPDATE
        -- slots not supported
        -- elseif etype == EntityType.ENTITY_SLOT then
        end

        if not alreadyRegistered then
            for variant, _ in pairs(variantTable) do
                revel:AddCallback(callbackInit, rerolls_PostEntityInit, variant)
                revel:AddCallback(callbackUpdate, rerolls_PostEntityUpdate, variant)
            end
        end
    end
end

local function rerolls_PostUpdateCheck()
    if not InitializedSpecificCallbacks then
        InitializeSpecificCallbacks()
    else
        revel:RemoveCallback(ModCallbacks.MC_POST_UPDATE, rerolls_PostUpdateCheck)
    end
end
revel:AddCallback(ModCallbacks.MC_POST_UPDATE, rerolls_PostUpdateCheck)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 1, InitializeSpecificCallbacks)

revel:AddCallback(ModCallbacks.MC_USE_ITEM, rerolls_rerollItem_UseItem, CollectibleType.COLLECTIBLE_D6)
revel:AddCallback(ModCallbacks.MC_USE_ITEM, rerolls_rerollItem_UseItem, CollectibleType.COLLECTIBLE_D100)
revel:AddCallback(ModCallbacks.MC_USE_ITEM, rerolls_eternald6_UseItem, CollectibleType.COLLECTIBLE_ETERNAL_D6)
revel:AddCallback(ModCallbacks.MC_USE_ITEM, rerolls_spindown_UseItem, CollectibleType.COLLECTIBLE_SPINDOWN_DICE)
revel:AddCallback(ModCallbacks.MC_USE_ITEM, rerolls_diplopia_UseItem, CollectibleType.COLLECTIBLE_DIPLOPIA)
revel:AddCallback(ModCallbacks.MC_USE_CARD, rerolls_isaacSoul_UseCard, Card.CARD_SOUL_ISAAC)

end