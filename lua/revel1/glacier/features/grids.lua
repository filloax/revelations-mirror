local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local noSoundGrids = {}
local noItemGrids = {}
local noPoofGrids = {}
    
function REVEL.PreventGridBreakSound(index)
    noSoundGrids[index] = true
end

function REVEL.PreventGridItemDrop(index)
    noItemGrids[index] = true
end

function REVEL.PreventGridNegativeEffects(index)
    noPoofGrids[index] = true
end
    
function REVEL.TintedAltBombRockChance(gridEntry, rng)
    local currentRoom = StageAPI.GetCurrentRoom()
    if not currentRoom.Metadata:Has{Index = gridEntry.Index, Name = "PreventRandomization"} then
        local altRock = StageAPI.Random(1, 100, rng)
        if REVEL.room:GetTintedRockIdx() == gridEntry.Index then
            return {
                Index = gridEntry.Index,
                Type = GridEntityType.GRID_ROCKT,
                Variant = gridEntry.Variant,
                GridX = gridEntry.GridX,
                GridY = gridEntry.GridY
            }
        elseif altRock <= 7 and altRock > 2 then
            return {
                Index = gridEntry.Index,
                Type = GridEntityType.GRID_ROCK_ALT,
                Variant = gridEntry.Variant,
                GridX = gridEntry.GridX,
                GridY = gridEntry.GridY
            }
        elseif altRock <= 2 then
            return {
                Index = gridEntry.Index,
                Type = GridEntityType.GRID_ROCK_BOMB,
                Variant = gridEntry.Variant,
                GridX = gridEntry.GridX,
                GridY = gridEntry.GridY
            }
        end
    end
end

StageAPI.AddCallback("Revelations", "PRE_SPAWN_GRID", 1, function(gridEntry, gridInformation, entitySets, rng)
    if REVEL.STAGE.Glacier:IsStage() then
        if gridEntry.Type == GridEntityType.GRID_ROCK then
            return REVEL.TintedAltBombRockChance(gridEntry, rng)
        elseif gridEntry.Type == GridEntityType.GRID_PIT and entitySets then -- Rooms with ice pits in them have actual pits below the ice pits, this is quite problematic as it shoves ice worms / enemies out of the way.
            local index = tostring(gridEntry.Index)
            local currentRoom = StageAPI.GetCurrentRoom()
            if currentRoom and currentRoom.PersistentData.IcePitFrames[index] then
                return false
            end
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    noSoundGrids = {}
    noItemGrids = {}
    noPoofGrids = {}
end)


local function IsIceRockRoom()
    return REVEL.STAGE.Glacier:IsStage()
end

---@param grid GridEntity
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_OVERRIDDEN_GRID_BREAK, 1, function(grindex, grid, shroomData)
    if IsIceRockRoom() then
        local currentRoom = StageAPI.GetCurrentRoom()

        if not noSoundGrids[grindex] then
            if grid:GetType() == GridEntityType.GRID_ROCK_ALT then
                REVEL.sfx:Stop(SoundEffect.SOUND_MUSHROOM_POOF)
                REVEL.sfx:Stop(SoundEffect.SOUND_MUSHROOM_POOF_2)
                REVEL.sfx:Play(SoundEffect.SOUND_FREEZE_SHATTER, 0.75, 0, false, 0.95)
                REVEL.sfx:Play(SoundEffect.SOUND_ROCK_CRUMBLE, 0.7, 0, false, 1.05)
                -- REVEL.sfx:Play(REVEL.SFX.MINT_GUM_BREAK, 1, 0, false, 1)
            end
        else
            noSoundGrids[grindex] = nil
        end

        local spawnedItem, spawnedFart
        if shroomData then
            for _, spawn in ipairs(shroomData) do
                if spawn.Type == EntityType.ENTITY_PICKUP and spawn.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                    spawnedItem = true
                    break
                end

                if spawn.Type == EntityType.ENTITY_EFFECT and spawn.Variant == EffectVariant.FART then
                    spawnedFart = true
                    break
                end
            end
        end

        local disableRockSpawn = currentRoom.Metadata:Has{Index = grindex, Name = "Disable Random Special Rock Spawn"}
        if StageAPI.GetCustomGrid(grindex, REVEL.GRIDENT.FROZEN_BODY.Name) then
            disableRockSpawn = true
        end

        if not disableRockSpawn then
            if spawnedItem and not noItemGrids[grindex] then
                if REVEL.IsAchievementUnlocked("ICETRAY") and math.random(1,2) == 1 then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, REVEL.ITEM.ICETRAY.id, REVEL.room:GetGridPosition(grindex), Vector.Zero, nil)
                else
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_SHARD_OF_GLASS, REVEL.room:GetGridPosition(grindex), Vector.Zero, nil)
                end
            elseif spawnedFart and not noPoofGrids[grindex] then
                REVEL.ENT.FROZEN_SPIDER:spawn(REVEL.room:GetGridPosition(grindex), Vector.Zero, nil)
            end
        end

        if noItemGrids[grindex] then
            noItemGrids[grindex] = nil
        end
        if noPoofGrids[grindex] then
            noPoofGrids[grindex] = nil
        end
    end
end)

-- Ice grid breaking with specific items

-- Burning bush done in burningbush.burningbush.lua

local AddedCallbacks = false

---@param effect EntityEffect
local function iceGrid_ghostPepperFlame_PostEffectUpdate(_, effect)
    -- defensive safe check
    if IsIceRockRoom() then
        local index = REVEL.room:GetGridIndex(effect.Position)
        local grid = REVEL.room:GetGridEntity(index)
        if grid and grid:GetType() == GridEntityType.GRID_ROCK_ALT 
        and not REVEL.IsGridBroken(grid) then
            REVEL.SpawnMeltEffect(REVEL.room:GetGridPosition(index))
            REVEL.room:DestroyGrid(index, true)
            effect.Timeout = math.max(1, effect.Timeout - 40)
        end
    end
end

---@param effect EntityEffect
local function iceGrid_redCandleFlame_PostEffectUpdate(_, effect)
    -- defensive safe check
    if IsIceRockRoom() then
        local refPos = effect.Position + effect.Velocity * 1.5

        -- Check all grids touched by the fire
        local checkIndices = {
            REVEL.room:GetGridIndex(refPos + REVEL.VEC_LEFT * effect.Size),
            REVEL.room:GetGridIndex(refPos + REVEL.VEC_UP * effect.Size),
            REVEL.room:GetGridIndex(refPos + REVEL.VEC_RIGHT * effect.Size),
            REVEL.room:GetGridIndex(refPos + REVEL.VEC_DOWN * effect.Size),
        }
        local w = REVEL.room:GetGridWidth()
        local minX, minY, maxX, maxY
        for _, idx in ipairs(checkIndices) do
            local x, y = StageAPI.GridToVector(idx, w)
            if not minX or x < minX then minX = x end
            if not minY or y < minY then minY = y end
            if not maxX or x > maxX then maxX = x end
            if not maxY or y > maxY then maxY = y end
        end

        for x = minX, maxX do
            for y = minY, maxY do
                local index = StageAPI.VectorToGrid(x, y, w)
                local grid = REVEL.room:GetGridEntity(index)
                if grid and grid:GetType() == GridEntityType.GRID_ROCK_ALT 
                and not REVEL.IsGridBroken(grid) then
                    REVEL.SpawnMeltEffect(REVEL.room:GetGridPosition(index))
                    REVEL.room:DestroyGrid(index, true)
                    effect.Timeout = math.max(1, effect.Timeout - 400)
                end
            end
        end
    end
end

---@param tear EntityTear
local function iceGrid_fireMindTear_PostTearUpdate(_, tear)
    if HasBit(tear.TearFlags, TearFlags.TEAR_BURN) 
    and not tear:GetData().BurningBush
    -- defensive safe check
    and IsIceRockRoom() then
        local index = REVEL.room:GetGridIndex(tear.Position)
        local grid = REVEL.room:GetGridEntity(index)
        if grid and grid:GetType() == GridEntityType.GRID_ROCK_ALT 
        and not REVEL.IsGridBroken(grid) then
            REVEL.SpawnMeltEffect(REVEL.room:GetGridPosition(index))
            REVEL.room:DestroyGrid(index, true)
            tear:Die()
        end
    end
end

-- optimization: avoid adding to the many generic callbacks, 
-- only use when relevant
local function iceGridChecks_PostNewRoom()
    local isIceRockRoom = IsIceRockRoom()
    if isIceRockRoom and not AddedCallbacks then
        AddedCallbacks = true
        revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, iceGrid_ghostPepperFlame_PostEffectUpdate, EffectVariant.BLUE_FLAME)
        revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, iceGrid_redCandleFlame_PostEffectUpdate, EffectVariant.RED_CANDLE_FLAME)
        revel:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, iceGrid_fireMindTear_PostTearUpdate)
    elseif not isIceRockRoom and AddedCallbacks then
        AddedCallbacks = false
        revel:RemoveCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, iceGrid_ghostPepperFlame_PostEffectUpdate)
        revel:RemoveCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, iceGrid_redCandleFlame_PostEffectUpdate)
        revel:RemoveCallback(ModCallbacks.MC_POST_TEAR_UPDATE, iceGrid_fireMindTear_PostTearUpdate)
    end
end

revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, iceGridChecks_PostNewRoom)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 0, iceGridChecks_PostNewRoom)

end

REVEL.PcallWorkaroundBreakFunction()
