local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local PlayerVariant     = require("scripts.revelations.common.enums.PlayerVariant")

return function()
---------------------
-- REVEL CALLBACKS --
---------------------
--[[
Rev callbacks list, also found in scripts/revelations/common/enums/callbacks.lua 
Some callbacks are related to other mod features and 
are not defined in this file, this file mostly includes
the more generic one

Remember to update both this file and scripts/revelations/common/enums/callbacks.lua 
if you add new ones

in this file:
    REV_EARLY_POST_NEW_ROOM()
        used to work aroud the different room callback
        order in repentance
    REV_POST_ROOM_CLEAR(room)
    REV_POST_GREED_CLEAR(room, wave)

    REV_ON_TEAR(tear, data, sprite, player): TearVariant
        can take TearVariant as value, triggered after revel initializes a tear

    REV_POST_TEAR_POOF_INIT(poof, data, spr, parent, grandparent)
    REV_POST_PROJ_POOF_INIT(poof, data, spr, parent, grandparent)

    REV_POST_PICKUP_COLLECT(pickup, player, isPocket): PickupVariant
        can specify pickup variant, applies to all pickups
        that can be collected

    REV_TEAR_UPDATE_INIT(tear)
    REV_FAMILIAR_UPDATE_INIT(familiar): Variant
    REV_BOMB_UPDATE_INIT(bomb): Variant
    REV_PICKUP_UPDATE_INIT(pickup): Variant
    REV_LASER_UPDATE_INIT(laser): Variant
    REV_KNIFE_UPDATE_INIT(knife): KnifeSubType
    REV_PROJECTILE_UPDATE_INIT(projectile): Variant
    REV_NPC_UPDATE_INIT(npc): Type
        All of these are triggered on the first update frame of
        the entities, to allow things like TearFlags to be set
        unlike in init callbacks

    REV_POST_SPAWN_CLEAR_AWARD(spawnPos, pickup)

    REV_POST_ROCK_BREAK(grid)

    REV_POST_ENTITY_TAKE_DMG(entity, damage, flag, source, invulnFrames)
        Runs after all post entity take damage callbacks, cannot 
        cancel it from here.

    REV_POST_BASE_PEFFECT_UPDATE*(player)
    REV_POST_BASE_PLAYER_INIT*(player)
        Like base callbacks, but automatically excludes coop babies
        and Found Soul

in root/main.lua:
    REV_POST_INGAME_RELOAD(isReload) 
        isReload is always true, use it for functions used both in NEW_ROOM and this for example to distinguish the cases. 
        Make sure your callback functions are revel:Function rather than revel.Function if you are mixing, so that revel is not the first argument.

in inventory.lua:
    REV_POST_ITEM_PICKUP(player, playerID, itemID, isD4Effect)

in basiccore.lua:
    REV_ITEM_CHECK(item id, item table): ItemId -> boolean
        called when checking if player can use item
        can specify item id in callback args, 
        return false to block item

in reflections.lua:
    REV_PRE_RENDER_ENTITY_REFLECTION(entity, sprite, offset): Type -> boolean
        specify type optionally, 
        return false to not render (still calls POST)
    REV_POST_RENDER_ENTITY_REFLECTION(entity, sprite, offset): Type
        specify type optionally

in airmovement.lua: 
    REV_PRE_ENTITY_ZPOS_UPDATE*(entity, airMovementData)
    REV_PRE_ENTITY_ZPOS_LAND*(entity, airMovementData, landFromGrid)
    REV_POST_ENTITY_ZPOS_UPDATE*(entity, airMovementData, landFromGrid)
    REV_POST_ENTITY_ZPOS_LAND*(entity, airMovementData, landFromGrid)

in revelcommon/entities/machines/basic.lua:
    REV_POST_MACHINE_UPDATE(machine)
    REV_POST_MACHINE_EXPLODE(machine)
        return false to prevent the machine exploding in a vanilla way,
        nil/true to allow explosion

    REV_POST_MACHINE_RESPAWN(machine, newMachine)
        can specify variant
        called when a machine is respawned to work around vanilla explosion
        behavior

in revel2/tomb/boulder.lua: 
    REV_POST_BOULDER_IMPACT(boulder, ent, isGrid)
        return true to break boulder

in revelcommon/bosses/init.lua:
    REV_PRE_ESTIMATE_DPS(player)

in tear_sounds.lua:
    REV_PRE_TEARS_FIRE_SOUND(tear, data, sprite) -> boolean
        return false to not play sounds
        return a number to use that as the volume
    REV_PRE_TEARIMPACTS_SOUND(tear, data, sprite) -> boolean
        return false to not play sounds
        return a number to use that as the volume
    REV_PRE_PROJIMPACTS_SOUND(projectile, data, sprite) -> boolean
        return false to not play sounds
        return a number to use multiply the volume by that

*: uses the Repentance callback system

deprecated as of Repentance:
    REV_POST_ITEM_USE(player, itemID, itemRNG, isCarBatteryUse): ItemID
    REV_POST_PILL_USE(player, pillColor, pillEffect, pillEffectRNG): PillEffect
    REV_POST_CARD_USE(player, cardID, cardRNG, isTarotClothUse): CardID
    REVEL.AddInitCallback(callback, func, id),
]]

REVEL.RoomWasClear = false
local nowClear = false
local prevWave = 0

if Isaac.GetPlayer(0) then
    REVEL.room = REVEL.game:GetRoom()
    REVEL.level = REVEL.game:GetLevel()

    nowClear = REVEL.room:IsClear()
    REVEL.RoomWasClear = nowClear
    prevWave = REVEL.level.GreedModeWave
end

-- POST_NEW_ROOM workaround
do
    REVEL.NEW_ROOM_CALLBACK_DEBUG = false

    local lastGameFramecount = -10
    local currentRoomTopLeftWallPtrHash
    local currentRoomTopRightWallPtrHash

    -- Adapted version of Isaacscript Common's implementation of the callback, 
    -- as the visitedcount+roomid way to check room changed
    -- was messed by dante&charon
    -- src: https://github.com/IsaacScript/isaacscript-common/blob/main/src/callbacks/postNewRoomEarly.ts
    local ROOM_SHAPE_TO_TOP_LEFT_WALL_GRID_INDEX_MAP = {
        [RoomShape.ROOMSHAPE_IH] = 30, -- 2
        [RoomShape.ROOMSHAPE_IV] = 4, -- 3
        [RoomShape.ROOMSHAPE_IIV] = 4, -- 5
        [RoomShape.ROOMSHAPE_IIH] = 56, -- 7
        [RoomShape.ROOMSHAPE_LTL] = 13, -- 9
    }
    local ROOM_SHAPE_TO_TOP_RIGHT_WALL_GRID_INDEX_MAP = {
        [RoomShape.ROOMSHAPE_IH] = 44, -- 2
        [RoomShape.ROOMSHAPE_IV] = 10, -- 3
        [RoomShape.ROOMSHAPE_IIV] = 10, -- 5
        [RoomShape.ROOMSHAPE_IIH] = 83, -- 7
        [RoomShape.ROOMSHAPE_LTR] = 14, -- 10
    }
      
    local DEFAULT_TOP_LEFT_WALL_GRID_INDEX = 0
    local DEFAULT_TOP_RIGHT_WALL_GRID_INDEX = 14

    local function GetTopLeftWallGridIndex(room)
        local roomShape = room:GetRoomShape()
      
        local topLeftWallGridIndex =
            ROOM_SHAPE_TO_TOP_LEFT_WALL_GRID_INDEX_MAP[roomShape]
        return topLeftWallGridIndex or
            DEFAULT_TOP_LEFT_WALL_GRID_INDEX
    end

    local function GetTopRightWallGridIndex(room)
        local roomShape = room:GetRoomShape()
      
        local topLeftWallGridIndex =
            ROOM_SHAPE_TO_TOP_RIGHT_WALL_GRID_INDEX_MAP[roomShape]
        return topLeftWallGridIndex or
            DEFAULT_TOP_RIGHT_WALL_GRID_INDEX
    end

    if Isaac.GetPlayer(0) then
        currentRoomTopLeftWallPtrHash = GetPtrHash(REVEL.room:GetGridEntity(GetTopLeftWallGridIndex(REVEL.room)))
        currentRoomTopRightWallPtrHash = GetPtrHash(REVEL.room:GetGridEntity(GetTopRightWallGridIndex(REVEL.room)))
        lastGameFramecount = REVEL.game:GetFrameCount()
    end

    --[[
        {
            linedefined=1630,
            source="@c:\program files (x86)\steam\steamapps\common\The Binding of Isaac Rebirth/mods/revelations/lua\revelcommon\library.lua",
            nups=1,
            lastlinedefined=1643,
            istailcall=false,
            isvararg=false,
            func=function: 254C1D18,
            namewhat="",
            nparams=3,
            short_src="...aac Rebirth/mods/revelations/lua\revelcommon\library.lua",
            currentline=-1,
            what="Lua"
        }
    ]]
    local function PrintFunctionInfo(func, context)
        if debug then
            local info = debug.getinfo(func)
            REVEL.DebugToString((context or "") .. "Running: '" .. info.short_src .. "' @line:" .. info.linedefined)
        end
    end

    local function runEarlyNewRoomCallbacks()
        if REVEL.DEBUG then
            local callbacks = StageAPI.GetCallbacks(RevCallbacks.EARLY_POST_NEW_ROOM)

            for _, callback in ipairs(callbacks) do
                if debug and REVEL.NEW_ROOM_CALLBACK_DEBUG then
                    PrintFunctionInfo(callback.Function, "[EARLY_NEW_ROOM]")
                    local ok, res = xpcall(callback.Function, debug.traceback)
                    if not ok then
                        error("[REV_EARLY_POST_NEW_ROOM|error] " .. tostring(res))
                    end
                    REVEL.DebugToString("done")
                else
                    StageAPI.TryCallback(callback)
                end
            end
        else
            StageAPI.CallCallbacks(RevCallbacks.EARLY_POST_NEW_ROOM)
        end
    end

    local LastDebugFrameRunStart = -1

    local function checkRoomChanged(callbackName, ignoreRunStart)
        -- Don't run early post new room if the game is starting, 
        -- unless ignoreRunStart is on
        if not ignoreRunStart 
        and (REVEL.game:GetFrameCount() < 1 or not REVEL.RanFirstUpdate())
        then
            if LastDebugFrameRunStart ~= REVEL.game:GetFrameCount() then
                REVEL.DebugStringMinor("checkRoomChanged: trying to do before load, abort")
                LastDebugFrameRunStart = REVEL.game:GetFrameCount()
            end
            return
        end

        local room = REVEL.game:GetRoom()

        if not room then
            REVEL.DebugToString("checkRoomChanged: Room not init yet, save loading? abort")
            return
        end

        -- Check both to make the rare instance of having same ptr hash rarer
        local topLeftWallGridIndex = GetTopLeftWallGridIndex(room)
        local topLeftWall = room:GetGridEntity(topLeftWallGridIndex)
        local topRightWallGridIndex = GetTopRightWallGridIndex(room)
        local topRightWall = room:GetGridEntity(topRightWallGridIndex)

        -- Sometimes, the PreEntitySpawn callback can fire before any grid entities in the room have
        -- spawned, which means that the top-left wall will not exist
        -- If ths is the case, then simply spawn the top-left wall early
        if not topLeftWall then
            local pos = room:GetGridPosition(topLeftWallGridIndex)
            topLeftWall = Isaac.GridSpawn(GridEntityType.GRID_WALL, 0, pos, true)
        end
        if not topRightWall then
            local pos = room:GetGridPosition(topRightWallGridIndex)
            topRightWall = Isaac.GridSpawn(GridEntityType.GRID_WALL, 0, pos, true)
        end
        
        if not topLeftWall or not topRightWall then -- run load fuckery, abort
            REVEL.DebugToString("checkRoomChanged: cannot get walls, save loading? abort")
            return
        end

        local topLeftWallPtrHash = GetPtrHash(topLeftWall)
        local topRightWallPtrHash = GetPtrHash(topRightWall)

        if topLeftWallPtrHash ~= currentRoomTopLeftWallPtrHash
        or topRightWallPtrHash ~= currentRoomTopRightWallPtrHash
        or lastGameFramecount > REVEL.game:GetFrameCount() then
            lastGameFramecount = REVEL.game:GetFrameCount()
            currentRoomTopLeftWallPtrHash = topLeftWallPtrHash
            currentRoomTopRightWallPtrHash = topRightWallPtrHash

            REVEL.DebugStringMinor(
                "Is new room! Callback: " .. callbackName, 
                currentRoomTopLeftWallPtrHash, 
                currentRoomTopRightWallPtrHash,
                StageAPI.GetCurrentRoomID()
            )
            runEarlyNewRoomCallbacks()
        end
    end

    --[[
    local function genCheckEarlyNewRoom(callback)
        local name = REVEL.getKeyFromValue(ModCallbacks, callback)
        return function()
            checkEarlyNewRoom(name)
        end
    end
    ]]

    -- The idea is: we need to run the early post new room
    -- callbacks BEFORE the first round of updates/inits;
    -- So check before spawning any entity
    revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function()
        checkRoomChanged("MC_PRE_ENTITY_SPAWN")
    end)

    revel:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function()
        checkRoomChanged("MC_POST_PLAYER_INIT")
    end)

    -- Reduntant with PRE_STAGEAPI_NEW_ROOM
    -- revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    --     checkEarlyNewRoom("MC_POST_NEW_ROOM", true)
    -- end)

    -- As of Rep big patch, this runs after, 
    -- used in case it mod callback order changes again
    
    StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_STAGEAPI_NEW_ROOM, 1, function()
        REVEL.DebugStringMinor("Running stageAPI new room")

        --[[
        -- Visited count on update/init of entities spawned
        -- in room layout isn't updated, so update it to avoid
        -- triggering the callback twice;
        -- not redundant with same frame check, as that would still
        -- allow it to trigger twice for entities spawned inside the
        -- room
        prevVisitedCount = GetVisitedCount()

        local ignoreMultipleCallsThisFrame = false

        if lastGameFramecount == REVEL.game:GetFrameCount() then
            newRoomRunsThisFrame = newRoomRunsThisFrame + 1
            -- Check if the frame count is different than last call, but also pass
            -- in case POST_NEW_ROOM was called multiple times (like changing room via code
            -- multiple times in a frame for some reason)
            -- So, pass with this = 0 (first call this frame) 
            -- or this > 1 (multiple NEW_ROOM this frame)
            if newRoomRunsThisFrame > 1 then
                ignoreMultipleCallsThisFrame = true
            end
        else
            newRoomRunsThisFrame = 0
        end
        ]]

        checkRoomChanged("StageAPI:PRE_STAGEAPI_NEW_ROOM", true)
    end)

    -- Crashes
    -- StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_STAGEAPI_LOAD_SAVE, 1, function()
    --     checkRoomChanged("StageAPI:PRE_STAGEAPI_LOAD_SAVE", true)
    -- end)

    -- Temporary, test callback to see all new uses of POST_STAGEAPI_NEW_ROOM
    StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_STAGEAPI_NEW_ROOM, 10, function()
        local callbacks = StageAPI.GetCallbacks(RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER)

        for _, callback in ipairs(callbacks) do
            if debug and REVEL.NEW_ROOM_CALLBACK_DEBUG then
                PrintFunctionInfo(callback.Function, "[STAGEAPI_NEW_ROOM]")
                local ok, res = xpcall(callback.Function, debug.traceback)
                if not ok then
                    error("[POST_STAGEAPI_NEW_ROOM_WRAPPER|error] " .. tostring(res))
                end
                REVEL.DebugToString("done")
            else
                StageAPI.TryCallback(callback)
            end
        end

        --just to double check load order in case of api changes
        REVEL.DebugStringMinor("Finished stageAPI new room")
    end)
end

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    nowClear = REVEL.room:IsClear()
    REVEL.RoomWasClear = nowClear
    prevWave = REVEL.level.GreedModeWave
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if not nowClear and REVEL.room:IsClear() then
        StageAPI.CallCallbacks(RevCallbacks.POST_ROOM_CLEAR, false, REVEL.room)
        nowClear = true
    end

    if REVEL.level.GreedModeWave > prevWave then
        prevWave = REVEL.level.GreedModeWave
        StageAPI.CallCallbacks(RevCallbacks.POST_GREED_CLEAR, false, REVEL.room, prevWave)
    end
end)

function REVEL.GetPlayerUsingItem(strict)
    local player = nil

    for _, thisPlayer in pairs(REVEL.players) do
        if Input.IsActionTriggered(ButtonAction.ACTION_ITEM, thisPlayer.ControllerIndex) 
        or Input.IsActionTriggered(ButtonAction.ACTION_PILLCARD, thisPlayer.ControllerIndex) then
            player = thisPlayer
            break
        end
    end

    if not strict and player == nil then
        player = Isaac.GetPlayer(0)
    end

    return player
end

--Revel room rocks
local MAX_GRID_TYPE = GridEntityType.GRID_ROCK_GOLD

local function updateRocks()
    REVEL.roomRocks = {
        Updated = StageAPI.GetCurrentRoomID()
    }
    for i=1, REVEL.room:GetGridSize() do
        local grid = REVEL.room:GetGridEntity(i)
        if grid then
            -- Sometimes at new room, grids have a non initialized type with a random value
            -- but still have .Initialized = true, and in those cases it will lead to crashes,
            -- so check that
            if grid.Desc.Initialized and grid:GetType() <= MAX_GRID_TYPE then
                if grid:ToRock() and not REVEL.IsGridBroken(grid) then
                    table.insert(REVEL.roomRocks, grid:ToRock())
                end
            else
                -- Grids not initialized yet, to avoid crash when doing ToRock() redo later
                -- (Happens sometimes at run start)
                if REVEL.DEBUG then
                    REVEL.DebugToString("[REVEL] WARN: tried updating rock list when room wasn't properly initialized, aborting")
                end
                REVEL.roomRocks = {}
                return
            end
        end
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    updateRocks()
end)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 2, updateRocks)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE , function()
    if not REVEL.roomRocks or REVEL.roomRocks.Updated ~= StageAPI.GetCurrentRoomID() then
        updateRocks()
    end

    --ROCK BREAK
    for i, grid in ripairs(REVEL.roomRocks) do
        if REVEL.IsGridBroken(grid) then
            StageAPI.CallCallbacks(RevCallbacks.POST_ROCK_BREAK, false, grid)

            table.remove(REVEL.roomRocks, i)
        end
    end
end)


-- REV_ON_TEAR
do
    function REVEL.CallTearCallbacks(e, data, spr, player, splitFlag)
        if not data.CalledTearCallbacks then
            StageAPI.CallCallbacksWithParams(RevCallbacks.ON_TEAR, false, e.Variant, 
                e, data, spr, player, splitFlag)
            data.CalledTearCallbacks = true
        end
    end
    
    --If the tear comes from a split shot
    function REVEL.IsTearSplit(e)
        local data = REVEL.GetData(e)
        return not not data.TearSplitFlags
    end
    
    function REVEL.GetSplitFlags(e)
        e = e:ToTear()
        return BitAnd(e.TearFlags, BitOr(TearFlags.TEAR_SPLIT, TearFlags.TEAR_QUADSPLIT, TearFlags.TEAR_BONE))
    end
    
    revel:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, e)
        local data = REVEL.GetData(e)
        local spr = e:GetSprite()
    
        if e.SpawnerType == 1 then
            data.__player = e.Parent:ToPlayer()
    
            -- Tears shot by incubi don't have the familiar set as parent
            -- in Repentance (as of writing this comment, at least)
            local incubi = Isaac.FindByType(3, FamiliarVariant.INCUBUS)
            if #incubi > 0 then
                local adjustedPos = e.Position-e.Velocity
                local closestIncubus = REVEL.getClosestInTable(REVEL.filter(incubi, function(incubus)
                    return REVEL.GetPlayerID(incubus:ToFamiliar().Player) == REVEL.GetPlayerID(data.__player)
                end), e)
                local distSquared = adjustedPos:DistanceSquared(closestIncubus.Position)
                if closestIncubus and distSquared < adjustedPos:DistanceSquared(data.__player.Position) then
                    data.Incubus = closestIncubus
                    e.Parent = closestIncubus
                end
            end
        end
    
        if data.__player then
            REVEL.CallTearCallbacks(e, data, spr, data.__player)
        end
    
        data.RanFireTear = true
    end)
    
    --[[
    revel:AddCallback(ModCallbacks.MC_POST_TEAR_RENDER, function(_, e)
        local data = REVEL.GetData(e)
        
        --INCUBUS FIX (easier than replacing every single thing)
        --Not working as of first rep mod patch
        if e.Parent and e.Parent.Type == EntityType.ENTITY_FAMILIAR 
        and e.Parent.Variant == FamiliarVariant.INCUBUS 
        and REVEL.IsRenderPassNormal()
        and not data.Incubus then
            local spr = e:GetSprite()
            e.SpawnerType = 1
            e.SpawnerVariant = 0
            data.Incubus = true
            data.__player = e.Parent:ToFamiliar().Player
        
            if data.__player then
                REVEL.CallTearCallbacks(e, data, spr, data.__player)
            end
        end
    end)
    ]]
    
    function REVEL.IncludesIncubusTear(e)
        return REVEL.GetData(e).Incubus
    end
    
    local RecentlyDiedQuadshotTears = {}
    local RecentlyDiedHaemoTears = {}
    
    --Cricket's body split shots don't have any particular flag or variant, so just find if the parent has quadshot
    --Also, they are spawned after the parent gets removed, so there's that additional challenge
    --The parent isn't set, on top of that, so we need to remember after removing a tear was there for a bit
    --Since the cricket tears get spawned after, apparently
    
    revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, tear)
        if BitAnd(REVEL.GetSplitFlags(tear), TearFlags.TEAR_QUADSPLIT) > 0 then
            RecentlyDiedQuadshotTears[#RecentlyDiedQuadshotTears + 1] = {
                Time = REVEL.game:GetFrameCount(),
                Position = tear.Position,
                Player = REVEL.GetData(tear).__player,
                -- Flags = REVEL.GetData(tear).TearFlags,
                -- Color = tear.Color,
            }
        elseif tear.Variant == TearVariant.BALLOON then
            RecentlyDiedHaemoTears[#RecentlyDiedHaemoTears + 1] = {
                Time = REVEL.game:GetFrameCount(),
                Position = tear.Position,
                Player = REVEL.GetData(tear).__player,
                -- Flags = REVEL.GetData(tear).TearFlags,
                -- Color = tear.Color,
            }
        end
    end, 2)
    
    revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        local frames = REVEL.game:GetFrameCount()
        for i, tearInfo in ripairs(RecentlyDiedQuadshotTears) do
            if frames - tearInfo.Time > 5 then
                table.remove(RecentlyDiedQuadshotTears, i)
            end
        end
        for i, tearInfo in ripairs(RecentlyDiedHaemoTears) do
            if frames - tearInfo.Time > 5 then
                table.remove(RecentlyDiedHaemoTears, i)
            end
        end
    end)
    
    StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
        RecentlyDiedQuadshotTears = {}
        RecentlyDiedHaemoTears = {}
    end)
    
    StageAPI.AddCallback("Revelations", RevCallbacks.TEAR_UPDATE_INIT, 1, function(tear)
        local data = REVEL.GetData(tear)
    
        -- REVEL.DebugToConsole("Init", tear.Variant, tear.TearFlags, tear.SubType)
    
        if tear:HasTearFlags(TearFlags.TEAR_LUDOVICO) then
            local data = REVEL.GetData(tear)
    
            data.__player = REVEL.getClosestInTable(REVEL.players, tear)
            data.__parent = data.__player
    
            if data.__player then
                REVEL.CallTearCallbacks(tear, data, tear:GetSprite(), data.__player)
            end
        elseif not data.RanFireTear then --tears that are shot from split shots don't trigger FIRE_TEAR
            local player
            local isCricket = false
            local isBone = false
            local isSplit = false
            local isHaemo = false
    
            --General check, use when investigating how to check for new item sources
            --[[
                REVEL.DebugToConsole(REVEL.getKeyFromValue(TearVariant, tear.Variant), REVEL.TearFlagsToString(tear.TearFlags))
                local closeTears = Isaac.FindInRadius(tear.Position, 40, EntityPartition.TEAR)
                for _, otherTear in pairs(closeTears) do
                    otherTear = otherTear:ToTear()
                    if otherTear.Index ~= tear.Index then
                        REVEL.DebugToConsole("    ", otherTear.Index, REVEL.getKeyFromValue(TearVariant, otherTear.Variant), REVEL.TearFlagsToString(otherTear.TearFlags), otherTear.Parent and otherTear.Parent.Type, otherTear.SpawnerType)
                    end
                end
                local recentlyDied = recentlyDiedHaemoTears
                for _, tearInfo in ripairs(recentlyDied) do --last is most recent
                    if tearInfo.Position:DistanceSquared(tear.Position) < 20*20 then
                        REVEL.DebugToConsole("     Found", tearInfo)
                    end
                end
            ]]
    
            --Cricket's body check
            if REVEL.GetSplitFlags(tear) == 0 then
                for _, tearInfo in ripairs(RecentlyDiedQuadshotTears) do --last is most recent
                    if tearInfo.Position:DistanceSquared(tear.Position) < 20*20 then
                        player = tearInfo.Player
                        isCricket = true
                    end
                end
                if not isCricket then
                    for _, tearInfo in ripairs(RecentlyDiedHaemoTears) do --last is most recent
                        if tearInfo.Position:DistanceSquared(tear.Position) < 40*40 then
                            player = tearInfo.Player
                            isHaemo = true
                        end
                    end
                end
            end
    
            if not isCricket then
                local closeTears = Isaac.FindInRadius(tear.Position, 20, EntityPartition.TEAR)
                local parentTear, closestDist
    
                --Compound fracture: tears have the bone variant, and source tear has the TEAR_BONE flag
                --Parasite: tears have TEAR_SPLIT flag (only difference from source is not triggering TEAR_FIRE)
                for _, ct in pairs(closeTears) do
                    ---@type EntityTear
                    ct = ct:ToTear()
                    if ct -- some things (like forgotten c section fetus' knife) pass through partition.TEAR without being tears
                    and ct.TearIndex ~= tear.TearIndex and REVEL.GetData(ct).__player
                    and (
                        (tear.Variant == TearVariant.BONE and HasBit(REVEL.GetSplitFlags(ct), TearFlags.TEAR_BONE))
                        or (
                            HasBit(REVEL.GetSplitFlags(tear), TearFlags.TEAR_SPLIT) 
                            and HasBit(REVEL.GetSplitFlags(ct), TearFlags.TEAR_SPLIT)
                        )
                    ) then
                        local sqDist = ct.Position:DistanceSquared(tear.Position)
                        if not closestDist or closestDist < sqDist then
                            closestDist = sqDist
                            parentTear = ct
                            isBone = tear.Variant == TearVariant.BONE and BitAnd(REVEL.GetSplitFlags(ct), TearFlags.TEAR_BONE) > 0
                            isSplit = BitAnd(REVEL.GetSplitFlags(tear), TearFlags.TEAR_SPLIT) > 0 and BitAnd(REVEL.GetSplitFlags(ct), TearFlags.TEAR_SPLIT) > 0
                        end
                    end
                end
                player = player or (parentTear and REVEL.GetData(parentTear).__player)
            end
    
            data.__player = player
            data.__parent = data.__player
            data.TearSplitFlags = REVEL.GetSplitFlags(tear)
            data.IsCricketSplitShot = isCricket
            data.TearSplitFlags = BitOr(data.TearSplitFlags, (isCricket and TearFlags.TEAR_QUADSPLIT or 0))
            data.TearSplitFlags = BitOr(data.TearSplitFlags, (isBone and TearFlags.TEAR_BONE or 0))
    
            if data.TearSplitFlags == 0 then data.TearSplitFlags = nil end
    
            if data.__player and (data.TearSplitFlags or isHaemo) then
                REVEL.CallTearCallbacks(tear, data, tear:GetSprite(), data.__player,
                  {
                    Cricket = isCricket,
                    Bone = isBone,
                    Split = isSplit,
                    Haemolacria = isHaemo,
                  }
                )
            end
        end
    end)
    
end

----------------------
-- CUSTOM TEAR POOF --
----------------------

do
    --[[Same as proj poofs
    Basically: poofs don't have a spawnerentity/Parent, so no way to find out which ones were spawned by who for replacement purposes.
    So, we spawn custom ones on tear death, and make em use the sprite of the closest poof they can find (so we don't have to redo "tear variant x spawns poof sprite y" code)]]
    
    local ids = {EffectVariant.TEAR_POOF_A, EffectVariant.TEAR_POOF_B, EffectVariant.TEAR_POOF_SMALL, EffectVariant.TEAR_POOF_VERYSMALL, EffectVariant.BULLET_POOF}
    
    revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, ent)
        local data = REVEL.GetData(ent)
    
        if not data.__manuallyRemoved then
            ent = ent:ToTear()
    
            local closest, dist
            dist = 5
    
            for i,v in ipairs(ids) do
                local poofs = Isaac.FindByType(1000, v, -1, false, false)
                local thisClosest, thisDist = REVEL.getClosestInTable(poofs, ent)
                if thisClosest and thisDist <= dist then
                    closest = thisClosest
                    dist = thisDist
                end
            end
    
            if closest then
                local cSpr = closest:GetSprite()
        
                closest.Parent = ent
                closest.SpawnerEntity = ent
                REVEL.GetData(closest).spawnerParent = ent.SpawnerEntity or ent.Parent
        
                StageAPI.CallCallbacks(RevCallbacks.POST_TEAR_POOF_INIT, false, closest, REVEL.GetData(closest), cSpr, ent, ent.SpawnerEntity or ent.Parent)
            elseif REVEL.DEBUG and not REVEL.GetData(ent).BurningBush then
                -- REVEL.DebugToString("Couldn't find original tear poof!")
            end
        end
    end, 2)
end
  
-----------------------------
-- CUSTOM PROJECTILE POOFS --
-----------------------------
    --[[Basically: poofs don't have a spawnerentity/Parent, so no way to find out which ones were spawned by who for replacement purposes.
    So, we spawn custom ones on tear death, and make em use the sprite of the closest poof they can find (so we don't have to redo 
    "tear variant x spawns poof sprite y" code)]]
--REV_POST_PROJ_POOF_INIT

--[[Basically: poofs don't have a spawnerentity/Parent, so no way to find out which ones were spawned by who for replacement purposes.
So, we spawn custom ones on tear death, and make em use the sprite of the closest poof they can find (so we don't have to redo "tear variant x spawns poof sprite y" code)]]

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, ent)
    local data = REVEL.GetData(ent)

    if not data.__manuallyRemoved then
        ent = ent:ToProjectile()

        local closest

        if ent.Variant == ProjectileVariant.PROJECTILE_TEAR then
            local poofs = Isaac.FindByType(1000, EffectVariant.TEAR_POOF_B, -1, true, false)
            closest = REVEL.getClosestInTable(poofs, ent, "ProcessedPoof")
        elseif ent.Variant == ProjectileVariant.PROJECTILE_FIRE then
            local poofs = Isaac.FindByType(1000, EffectVariant.POOF01, -1, true, false)
            closest = REVEL.getClosestInTable(poofs, ent, "ProcessedPoof")
        else
            local poofs = Isaac.FindByType(1000, EffectVariant.BULLET_POOF, -1, true, false)
            closest = REVEL.getClosestInTable(poofs, ent, "ProcessedPoof")

            if not closest then
                local closeEffs = Isaac.FindInRadius(ent.Position, 2, EntityPartition.EFFECT)
                closest = REVEL.getClosestInTable(closeEffs, ent, "ProcessedPoof")
            end
        end

        if closest then
            local spr = closest:GetSprite()

            closest.Parent = ent
            REVEL.GetData(closest).spawnerParent = ent.SpawnerEntity or ent.Parent
            closest.SpawnerEntity = ent

            StageAPI.CallCallbacks(RevCallbacks.POST_PROJ_POOF_INIT, false, closest, REVEL.GetData(closest), spr, ent, ent.SpawnerEntity or ent.Parent)

        elseif REVEL.DEBUG then
            REVEL.DebugToString("Couldn't find original bullet poof!")
        end
    end
end, 9)

-- REV_POST_PICKUP_COLLECT
do
    local DoDebug = false

    local function ppccallbackPostPickupUpdate(_, pickup)
        local data, sprite = REVEL.GetData(pickup), pickup:GetSprite()

        if not data.__calledPostCollect and sprite:IsPlaying("Collect") then
            local player = REVEL.getClosestInTable(REVEL.players, pickup)
            local isPocket = pickup.Variant == PickupVariant.PICKUP_PILL or pickup.Variant == PickupVariant.PICKUP_TAROTCARD


            if REVEL.DEBUG and DoDebug then
                REVEL.DebugToString("Detected pickup collect event for pickup at ", 
                    REVEL.room:GetGridIndex(pickup.Position), "| which is", 
                    pickup.Variant .. "." .. pickup.SubType..(isPocket and "(pocket)" or ""), 
                    "| by player", player)
            end

            StageAPI.CallCallbacksWithParams(RevCallbacks.POST_PICKUP_COLLECT, false, pickup.Variant, 
                pickup, player, isPocket)

            data.__calledPostCollect = true
        end
    end

    revel:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, ppccallbackPostPickupUpdate)
end
    
-- UPDATE_INIT
do 
    local CallbacksInfo = {
        REV_TEAR_UPDATE_INIT = {Callback = ModCallbacks.MC_POST_TEAR_UPDATE},
        REV_FAMILIAR_UPDATE_INIT = {Callback = ModCallbacks.MC_FAMILIAR_UPDATE},
        REV_BOMB_UPDATE_INIT = {Callback = ModCallbacks.MC_POST_BOMB_UPDATE},
        REV_PICKUP_UPDATE_INIT = {Callback = ModCallbacks.MC_POST_PICKUP_UPDATE},
        REV_LASER_UPDATE_INIT = {Callback = ModCallbacks.MC_POST_LASER_UPDATE},
        REV_KNIFE_UPDATE_INIT = {Callback = ModCallbacks.MC_POST_KNIFE_UPDATE, CheckAgainst = "SubType"},
        REV_PROJECTILE_UPDATE_INIT = {Callback = ModCallbacks.MC_POST_PROJECTILE_UPDATE},
        REV_NPC_UPDATE_INIT = {Callback = ModCallbacks.MC_NPC_UPDATE, CheckAgainst = "Type"},
        -- REV_EFFECT_UPDATE_INIT = {Callback = ModCallbacks.MC_POST_EFFECT_UPDATE}, --adds lag, avoiding
    }

    -- double check against this and data in case one gets reset
    local RanForEnt = {}

    for revCallback, info in pairs(CallbacksInfo) do
        revel:AddCallback(info.Callback, function(_, entity)
            -- For some reason, it seems that the base callback runs more than once at frame 0? at least for NPCs

            -- Some entities start at frame 0, some at frame 1, it seems
            if entity.FrameCount <= 1
            and not REVEL.GetData(entity).__ranUpdateInit
            and not RanForEnt[GetPtrHash(entity)]
            then
                REVEL.GetData(entity).__ranUpdateInit = true
                RanForEnt[GetPtrHash(entity)] = true
                local key = info.CheckAgainst or "Variant"
                StageAPI.CallCallbacksWithParams(revCallback, false, entity[key], entity)
            end
        end)
    end

    local RanForEntEff = {}

    -- To avoid lagging game by running things on each single effect's update
    -- as they are much more numerous than other ents
    ---@param func fun(effect: EntityEffect)
    ---@param variant? EffectVariant
    function REVEL.AddEffectInitCallback(func, variant)
        revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, entity)
            if entity.FrameCount <= 1
            and not (REVEL.GetData(entity).__ranUpdateInit and REVEL.GetData(entity).__ranUpdateInit[func])
            and not (RanForEntEff[func] and RanForEntEff[func][GetPtrHash(entity)])
            then
                REVEL.GetData(entity).__ranUpdateInit = REVEL.GetData(entity).__ranUpdateInit or {}
                REVEL.GetData(entity).__ranUpdateInit[func] = true
                RanForEntEff[func] = RanForEntEff[func] or {}
                RanForEntEff[func][GetPtrHash(entity)] = true
                func(entity)
            end
        end, variant)
    end

    StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, -20, function()
        RanForEnt = {}
        RanForEntEff = {}
    end)
end

do
    local function checkAwards(pos)
        for _, pickup in ipairs(REVEL.roomPickups) do
            if pickup.FrameCount <= 1 then
                REVEL.DebugStringMinor(("Detected room reward: %d.%d.%d:%d"):format(pickup.Type, pickup.Variant, pickup.SubType, pickup.InitSeed))
                StageAPI.CallCallbacks(RevCallbacks.POST_SPAWN_CLEAR_AWARD, false, pickup:ToPickup(), pos)
            end
        end
    end

    revel:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function(_, rng, spawnPos)
        REVEL.DebugStringMinor("About to spawn awards", StageAPI.GetCurrentRoomID(), spawnPos)
        REVEL.DelayFunction(function() checkAwards(spawnPos) end, 1)
    end)
end

-- POST_ENTITY_TAKE_DMG
do
    local function postEntityTakeDmg_EntityTakeDmg(_, entity, damage, flag, source, invulnFrames)
        StageAPI.CallCallbacksWithParams(
            RevCallbacks.POST_ENTITY_TAKE_DMG, 
            false, 
            {entity.Type, entity.Variant},
            entity, damage, flag, source, invulnFrames
        )
    end

    revel:AddPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CallbackPriority.LATE + 100, postEntityTakeDmg_EntityTakeDmg)
end

-- POST BASE PLAYER stuff
do
    local function basePlayer_PostPeffectUpdate(_, player)
        if player.Variant == PlayerVariant.PLAYER then
            Isaac.RunCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, player)
        end
    end
    local function basePlayer_PostPlayerInit(_, player)
        if player.Variant == PlayerVariant.PLAYER then
            Isaac.RunCallback(RevCallbacks.POST_BASE_PLAYER_INIT, player)
        end
    end
    revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, basePlayer_PostPeffectUpdate)
    revel:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, basePlayer_PostPlayerInit)
end

-- Deprecated callbacks warning

local DeprecatedCallbacks = {
    "REV_POST_ITEM_USE", 
    "REV_POST_PILL_USE",
    "REV_POST_CARD_USE",
}

revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
    for _, callbackKey in pairs(DeprecatedCallbacks) do
        local callbacks = StageAPI.GetCallbacks(callbackKey)
        if #callbacks > 0 then
            REVEL.DebugToString("Rev | Deprecated callback used: " .. tostring(callbackKey))
            if debug then
                for _, callback in ipairs(callbacks) do
                    local info = debug.getinfo(callback.Function)
                    if info then
                        local file = tostring(info.source)
                        local linedef = tostring(info.linedefined)
                        REVEL.DebugStringMinor("\t Function for callback defined in " .. file .. ":" .. linedef)
                    end
                end
            end
        end
    end
end)


---@deprecated
-- Deprecated as of Repentance API patch, since POST_x_INIT
-- callbacks now have position and other general attributes set
function REVEL.AddInitCallback(callback, func, id)
    REVEL.DebugLog("[REVEL] WARN: AddInitCallback deprecated", REVEL.TryGetTraceback(nil, true))
    revel:AddCallback(callback, func, id)
end

end