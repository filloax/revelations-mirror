local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local SpikeState = require("lua.revelcommon.enums.SpikeState")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

---@type table<string, PathMap>
REVEL.PathMaps = {}

--[[

PathMaps

REVEL.MyPathMap = REVEL.NewPathMapFromTable("MyPathMap", {
    GetTargetSets = function, -- Function must return a table of tables {{Targets = {index, index}}, {Targets = {index}}}
                                 These are used as the center point of the pathfinding map that all values will radiate from
                                 Separate sets allow for entities targeting different indices to use the same path map

                                 This function is called constantly, and Path Maps are re-evaluated once a second or when Targets change.

    GetInverseCollisions = function, -- Function returns a table of index value pairs {[index] = true}
                                        When a path map is updated, the index is looked up in this table. If not true,
                                        it counts as a collision.

                                        When the path map is evaluated, collisions will still be pathfound through,
                                        but will have their value increased by 1000. This allows making entities
                                        get as close as possible, even when they can't fully reach the player.

    GetInverseCriticalCollisions = function, -- Function returns a table of index value pairs {[index] = true}
                                                When a path map is updated, the index is looked up in this table. If not true,
                                                it counts as a critical collision.

                                                Unlike normal collisions, critical collisions cannot be pathfound through whatsoever.
                                                If GetInverseCriticalCollisions is not specified, the path map will use GetInverseCollisions instead.

    OnPathUpdate = function, -- Function passes (PathMap).
                                PathMap.TargetMapSets is a table of tables {{Targets = {index, index}, Map = map}}
                                In this function, you should locate the associated map for each entity
                                by comparing Targets, then use the Map as the second argument in GetPathToZero.

                                PathMap also contains
                                PathMap.InverseCollisions
                                PathMap.InverseCriticalCollisions
                                PathMap.Collisions
                                equal to the return values of the above functions

})

REVEL.UsePathMap(pathMap, entity, dontUpdateNow = false)
REVEL.IsUsingPathMap(pathMap, entity)
REVEL.ForceUsePathMap(pathMap, forceUseID, dontUpdateNow = false)
    Will start updating the path map regardless of
    entities, 
REVEL.StopUsingPathMap(pathMap, entity)
REVEL.StopForceUsingPathMap(pathMap, forceUseID)

Common use path maps:
    REVEL.PathToPlayerMap
    REVEL.GenericChaserPathMap
    REVEL.GenericFlyingChaserPathMap

REVEL.GetPathToZero(startIndex, map, width, collisionMap)
-- only startIndex and map are necessary, but collisionMap allows you to clarify exactly the path you want your entity to be able to take
-- collisionMap needs to be a table with any InverseCollisions, InverseCriticalCollisions, or Collisions table
-- width is automatically obtained from the room if not given
-- returns a path table of indices you should move through, in order start to end

REVEL.FollowPath(entity, speed, path, useDirect, friction)
-- Moves entity from index to index in path (entity.Velocity = entity.Velocity * friction + (nextIndexPos - currentPos):Resized(speed))
-- If useDirect is true, then the entity will move toward the index before the first index that it can't perform a line check toward
]]

local RadiateMapGeneration
local DoesMapIndexCollide
local GetPathToZero
local UpdatePathMap

-- extends for convenience as they have same things mostly
---@class PathMap : PathMapArgs
---@field Name string
---@field Collisions table<integer, integer>
---@field InverseCollisions table<integer, boolean>
---@field InverseCriticalCollisions table<integer, boolean>
---@field SideCollisions table<integer, table<Direction, boolean>>?
---@field TargetMapSets TargetSet[]
---@field RecalcCollisions boolean

---@class PathMapArgs
---@field GetTargetSets fun(map: PathMap): TargetSet[]
---@field GetTargetIndices fun(map: PathMap): integer[], boolean?
---@field GetCollisions fun(map: PathMap): table<integer, integer>
---@field GetInverseCollisions fun(map: PathMap): table<integer, boolean>?
---@field GetInverseCriticalCollisions fun(map: PathMap): table<integer, boolean>
---@field GetSideCollisions fun(map: PathMap): (table<integer, table<Direction, boolean>>?)
---@field OnPathUpdate fun(map: PathMap)
---@field NoAutoHandle boolean
---@field Width integer
---@field GetWidth fun(map: PathMap): integer
---@field UsesDividedGridsInCollision boolean
---@field PrintUpdateDebugInfo boolean
---@field CacheCollisionsBetweenGridUpdates boolean

---@class TargetSet
---@field Targets integer[]
---@field Force boolean
---@field Map table<integer, integer>
---@field FarthestIndex integer

---@param name string
---@param tbl PathMapArgs
---@return PathMap
function REVEL.NewPathMapFromTable(name, tbl)
    local pathMap = {
        TargetMapSets = {},
        Name = name,

        GetTargetSets = tbl.GetTargetSets,
        GetTargetIndices = tbl.GetTargetIndices,
        GetCollisions = tbl.GetCollisions,
        GetInverseCollisions = tbl.GetInverseCollisions,
        GetInverseCriticalCollisions = tbl.GetInverseCriticalCollisions,
        GetSideCollisions = tbl.GetSideCollisions,
        OnPathUpdate = tbl.OnPathUpdate,
        NoAutoHandle = tbl.NoAutoHandle,
        Width = tbl.Width,
        GetWidth = tbl.GetWidth,
        UsesDividedGridsInCollision = tbl.UsesDividedGridsInCollision,
        PrintUpdateDebugInfo = tbl.PrintUpdateDebugInfo,
        CacheCollisionsBetweenGridUpdates = tbl.CacheCollisionsBetweenGridUpdates ,
    }
    REVEL.PathMaps[name] = pathMap
    return pathMap
end

function REVEL.NewPathMap(name, getTargetIndices, getCollisions, onPathUpdate, getInverseCollisions, noAutoHandle, width, getTargetSets, getInverseCriticalCollisions, getWidth, getSideCollisions)
    return REVEL.NewPathMapFromTable(name, {
        GetTargetSets = getTargetSets,
        GetTargetIndices = getTargetIndices,
        GetCollisions = getCollisions,
        GetInverseCollisions = getInverseCollisions,
        GetInverseCriticalCollisions = getInverseCriticalCollisions,
        GetSideCollisions = getSideCollisions,
        OnPathUpdate = onPathUpdate,
        NoAutoHandle = noAutoHandle,
        Width = width,
        GetWidth = getWidth,
    })
end
    
local PathMapsToUpdate = {}

---@param pathMap PathMap
---@param entity Entity
---@param dontUpdateNow? boolean
function REVEL.UsePathMap(pathMap, entity, dontUpdateNow)
    local name = pathMap.Name
    local data = entity:GetData()

    if not data.UsingPathMaps then
        data.UsingPathMaps = {}
    end

    if not data.UsingPathMaps[name] then
        local entry = PathMapsToUpdate[name]
        if not entry then
            entry = {
                PathMap = pathMap,
                ForceUsers = {},
                Entities = {},
            }
            PathMapsToUpdate[name] = entry
        end

        entry.Entities[GetPtrHash(entity)] = EntityPtr(entity)

        data.UsingPathMaps[name] = entry

        REVEL.DebugStringMinor(("Entity %d.%d is using path map %s"):format(entity.Type, entity.Variant, name))

        if not dontUpdateNow then
            UpdatePathMap(pathMap)
        end
    end
end

---@param pathMap PathMap
---@param entity Entity
---@return boolean
function REVEL.IsUsingPathMap(pathMap, entity)
    local name = pathMap.Name
    local data = entity:GetData()

    return data.UsingPathMaps and data.UsingPathMaps[name]
end

---@param pathMap PathMap
---@param forceUseID any
---@param dontUpdateNow? boolean
function REVEL.ForceUsePathMap(pathMap, forceUseID, dontUpdateNow)
    local name = pathMap.Name
    local entry = PathMapsToUpdate[name]

    if not entry then
        entry = {
            PathMap = pathMap,
            ForceUsers = {},
            Entities = {},
        }
        PathMapsToUpdate[name] = entry
    end

    if not entry.ForceUsers[forceUseID] then
        entry.ForceUsers[forceUseID] = true
        
        if not dontUpdateNow then
            UpdatePathMap(pathMap)
        end
    end
end

-- Side effect: clears path map from update list if not
-- used anymore
local function CheckPathMapUpdateEntryUsed(entry)
    local toRemove = {}
    local has = false
    for hash, ptr in pairs(entry.Entities) do
        local entity = ptr.Ref
        if entity and not entity:IsDead() then
            has = true
        else
            toRemove[#toRemove+1] = hash
        end
    end
    for _, hash in ipairs(toRemove) do
        entry.Entities[hash] = nil
    end

    local beingUsed = has or not REVEL.isEmpty(entry.ForceUsers)

    if not beingUsed then
        PathMapsToUpdate[entry.PathMap.Name] = nil
    end

    return beingUsed
end

---@param pathMap PathMap
---@param entity Entity
function REVEL.StopUsingPathMap(pathMap, entity)
    local name = pathMap.Name
    local data = entity:GetData()

    if data.UsingPathMaps and data.UsingPathMaps[name] then
        local hash = GetPtrHash(entity)

        data.UsingPathMaps[name].Entities[hash] = nil
        CheckPathMapUpdateEntryUsed(data.UsingPathMaps[name])

        REVEL.DebugStringMinor(("Entity %d.%d is no longer using path map %s"):format(entity.Type, entity.Variant, name))

        data.UsingPathMaps[name] = nil
    end
end

---@param pathMap PathMap
---@param forceUseID any
function REVEL.StopForceUsingPathMap(pathMap, forceUseID)
    local name = pathMap.Name
    if PathMapsToUpdate[name] then
        PathMapsToUpdate[name].ForceUsers[forceUseID] = nil
        CheckPathMapUpdateEntryUsed(PathMapsToUpdate[name])
    end
end

---@param map PathMap
---@param force? boolean
function UpdatePathMap(map, force)
    if not map then
        error("UpdatePathMap: map nil", 2)
    end

    local timeBefore = Isaac.GetTime()

    local oldTargetSets = map.TargetMapSets

    local targetSets

    if map.GetTargetSets then
        targetSets = map:GetTargetSets()
    else
        targetSets = {}
    end

    if map.GetTargetIndices then
        local targets, forceUpdate = map:GetTargetIndices()
        targetSets[#targetSets + 1] = {Targets = targets, Force = forceUpdate}
    end

    if #targetSets < 1 then
        map.TargetMapSets = {}
        return
    end

    local setsNeedingUpdating = {}
    if not force then
        local verifiedA, verifiedB = {}, {}
        local matchingTables = 0
        for i, table in ipairs(targetSets) do
            if not verifiedA[i] then
                for i2, table2 in ipairs(oldTargetSets) do
                    if not verifiedB[i2] then
                        -- Will stay true if at least one target index
                        -- is shared between the new target set [i] and
                        -- old target set [i2]
                        local matches = true
                        for _, v in ipairs(table.Targets) do
                            local hasV
                            for _, v2 in ipairs(table2.Targets) do
                                if v == v2 then
                                    hasV = true
                                    break
                                end
                            end

                            if not hasV then
                                matches = false
                                break
                            end
                        end

                        -- New target set matches old target set
                        if matches then
                            verifiedA[i] = i2
                            verifiedB[i2] = i

                            matchingTables = matchingTables + 1
                        end
                    end
                end
            end

            -- If found a set that matches at least one index
            -- among the old sets
            if verifiedA[i] and table.Force then
                setsNeedingUpdating[#setsNeedingUpdating + 1] = table
            elseif verifiedA[i] then
                table.Map = oldTargetSets[verifiedA[i]].Map
            end
        end

        if matchingTables ~= #targetSets then
            for i, table in ipairs(targetSets) do
                if not verifiedA[i] then
                    setsNeedingUpdating[#setsNeedingUpdating + 1] = table
                end
            end
        end
    else
        setsNeedingUpdating = targetSets
    end

    if #setsNeedingUpdating > 0 or force then
        -- REVEL.DebugStringMinor("Updating map:", map.Name)

        local width = (map.GetWidth and map:GetWidth()) or map.Width or REVEL.room:GetGridWidth()

        local collisions
        if map.GetCollisions then
            if map.Collisions and map.CacheCollisionsBetweenGridUpdates and not map.RecalcCollisions then
                collisions = map.Collisions
            else
                collisions = map:GetCollisions()
            end
        end

        local inverseCollisions
        if map.GetInverseCollisions then
            if map.InverseCollisions and map.CacheCollisionsBetweenGridUpdates and not map.RecalcCollisions then
                inverseCollisions = map.InverseCollisions
            else
                inverseCollisions = map:GetInverseCollisions()
            end
        end

        local inverseCriticalCollisions
        if map.GetInverseCriticalCollisions then
            if map.InverseCriticalCollisions and map.CacheCollisionsBetweenGridUpdates and not map.RecalcCollisions then
                inverseCriticalCollisions = map.InverseCriticalCollisions
            else
                inverseCriticalCollisions = map:GetInverseCriticalCollisions()
            end
        end

        local sideCollisions
        if map.GetSideCollisions then
            if map.SideCollisions and map.CacheCollisionsBetweenGridUpdates and not map.RecalcCollisions then
                sideCollisions = map.SideCollisions
            else
                sideCollisions = map:GetSideCollisions()
            end
        end

        for _, set in ipairs(setsNeedingUpdating) do
            set.Map, set.FarthestIndex = RadiateMapGeneration(set.Targets, collisions, inverseCollisions, width, inverseCriticalCollisions, map.Name, sideCollisions)
        end

        map.Collisions = collisions
        map.InverseCollisions = inverseCollisions
        map.InverseCriticalCollisions = inverseCriticalCollisions
        map.SideCollisions = sideCollisions
        map.TargetMapSets = targetSets
        map.RecalcCollisions = nil

        if map.OnPathUpdate then
            if map.GetTargetIndices and not map.GetTargetSets then
                map:OnPathUpdate()
            else
                map:OnPathUpdate()
            end
        end

        if map.PrintUpdateDebugInfo then
            local time = Isaac.GetTime() - timeBefore
            REVEL.DebugLog(map.Name .. ": Path map update took " .. time .. "ms")
        end
    end
end

---@param targets integer[]
---@param collisions table<integer, integer>
---@param inverseCollisions table<integer, boolean>
---@param width integer
---@param inverseCriticalCollisions table<integer, boolean>
---@param name string
---@param sideCollisions table<integer, table<Direction, boolean>>
---@return table<integer, integer> map
---@return integer farthestIndex
function RadiateMapGeneration(targets, collisions, inverseCollisions, width, inverseCriticalCollisions, name, sideCollisions)
    local map = {}
    local checkIndices = {}

    if inverseCollisions and not inverseCriticalCollisions then
        inverseCriticalCollisions = inverseCollisions
    end

    local farthestIndex = targets[1]
    for _, index in ipairs(targets) do
        if (not collisions or not collisions[index] or collisions[index] == 0) 
        and (not inverseCollisions or inverseCollisions[index]) 
        and (not inverseCriticalCollisions or inverseCriticalCollisions[index]) then
            map[index] = 0
            checkIndices[#checkIndices + 1] = index
        end
    end

    while #checkIndices > 0 do
        for i = #checkIndices, 1, -1 do
            local index = checkIndices[i]
            table.remove(checkIndices, i)
            local adjacentIndices = {
                index - 1,
                index - width,
                index + 1,
                index + width,
            }

            for dir1, adjacent in ipairs(adjacentIndices) do
                local criticalValid = not inverseCriticalCollisions or inverseCriticalCollisions[adjacent]
                if criticalValid then
                    local dir = dir1 - 1
                    local oppDir = (dir + 2) % 4

                    local isSideBlocked = sideCollisions and (sideCollisions[adjacent] and sideCollisions[adjacent][oppDir]
                        or sideCollisions[index] and sideCollisions[index][dir])

                    -- REVEL.DebugLog(index, adjacent, "side blocked:", isSideBlocked)

                    local noCollision = (not collisions or not collisions[adjacent] or collisions[adjacent] == 0) 
                        and (not inverseCollisions or inverseCollisions[adjacent])
                        and not isSideBlocked

                    local moveCost = 1000
                    if noCollision then
                        moveCost = 1
                    end

                    if (not map[adjacent] or map[adjacent] > map[index] + moveCost) then
                        map[adjacent] = map[index] + moveCost

                        -- REVEL.DebugLog(index, "assigned cost", map[adjacent], "to", adjacent)

                        if not map[adjacent] then
                            error((
                                "pathfinding error on map '%s', nil map indices: map[%s]=%s ; map[%s]=%s")
                                :format(tostring(name), adjacent, map[adjacent], farthestIndex, map[farthestIndex]),
                                2
                            )
                        end

                        if not map[farthestIndex] or map[adjacent] > map[farthestIndex] then
                            farthestIndex = adjacent
                        end

                        checkIndices[#checkIndices + 1] = adjacent
                    end
                end
            end
        end
    end

    return map, farthestIndex
end

function DoesMapIndexCollide(index, collisions, inverseCollisions, inverseCriticalCollisions)
    if collisions.Collisions or collisions.InverseCollisions or collisions.InverseCriticalCollisions then
        if not inverseCollisions then
            inverseCollisions = collisions.InverseCollisions
        end

        if not inverseCriticalCollisions then
            inverseCriticalCollisions = collisions.InverseCriticalCollisions
        end

        collisions = collisions.Collisions
    end

    return (collisions and collisions[index] and collisions[index] ~= 0) 
        or (inverseCollisions and not inverseCollisions[index]) 
        or (inverseCriticalCollisions and not inverseCriticalCollisions[index])
end

---@param start integer
---@param map table<integer, integer>
---@param width? integer
---@param collisionMap? table<integer, integer>
---@param blockingSides? table<integer, table<Direction, boolean>>
---@return integer[]? path
---@return boolean success
function GetPathToZero(start, map, width, collisionMap, blockingSides)
    width = width or REVEL.room:GetGridWidth()
    local checkIndices = {
        start - 1,
        start - width,
        start + 1,
        start + width,
    }

    local path = {}
    local minimum
    while #checkIndices > 0 do
        local nextIndex

        local checkValues
        if blockingSides then --increase weight of blocked sides, needs to be done on path finding due to it depending on p os
            checkValues = {}
            for dir1, ind in ipairs(checkIndices) do
                local dir = dir1 - 1
                local oppDir = (dir + 2) % 4

                local isSideBlocked = blockingSides[ind] and blockingSides[ind][oppDir]
                    or blockingSides[path[#path]] and blockingSides[path[#path]][dir]

                if isSideBlocked then
                    checkValues[dir1] = map[ind] and map[ind] + width * 10000
                else
                    checkValues[dir1] = map[ind]
                end
            end
        end

        for dir1, ind in ipairs(checkIndices) do
            local val = (checkValues and checkValues[dir1]) or map[ind]
            if val and (not minimum or val < minimum) 
            and (not collisionMap or not DoesMapIndexCollide(ind, collisionMap)) then
                minimum = val
                nextIndex = ind
            end
        end

        if nextIndex then
            path[#path + 1] = nextIndex
            if minimum == 0 then
                return path, true
            end

            checkIndices = {
                nextIndex - 1,
                nextIndex - width,
                nextIndex + 1,
                nextIndex + width,
            }
        else
            if #path == 0 then
                return nil, false
            else
                return path, false
            end
        end
    end

    error("GetPathToZero | shouldn't reach this", 2)
end

REVEL.UpdatePathMap = UpdatePathMap
REVEL.DoesMapIndexCollide = DoesMapIndexCollide
REVEL.GetPathToZero = GetPathToZero

function REVEL.GetUpdatingPathMaps()
    return PathMapsToUpdate
end

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, -15, function()
    -- Invalidate all map target sets, so that they get recalculated next time necessarily
    for name, pathMap in pairs(REVEL.PathMaps) do
        if not pathMap.NoAutoHandle then
            pathMap.TargetMapSets = {}
        end
    end
end)

-- This is currently the biggest lag inducing callback in the mod,
-- ought to optimize by not always updating all maps
-- Update: did just that, now to see if that improved things
revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    for name, v in pairs(PathMapsToUpdate) do
        local pathMap = v.PathMap
        local isSecond = REVEL.game:GetFrameCount() % 30 == 0
        local stillUsed = CheckPathMapUpdateEntryUsed(v)
        if stillUsed then
            UpdatePathMap(pathMap, isSecond)
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 1, function()
    for i, e in ipairs(REVEL.roomEntities) do
        local data = e:GetData()
        if data.UsingPathMaps then
            for name, entry in pairs(data.UsingPathMaps) do
                PathMapsToUpdate[name] = entry
                entry.PathMap = REVEL.PathMaps[name]
            end
        end
    end
end)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_GRID_UPDATE, 5, function()
    for name, map in pairs(REVEL.PathMaps) do
        if map.CacheCollisionsBetweenGridUpdates then
            map.RecalcCollisions = true
        end
    end
end)

-- Various common use path maps
do

-- Can be used on POST_NEW_ROOM to check if a non-flying player can reach a point
REVEL.PathToPlayerMap = REVEL.NewPathMapFromTable("PathToPlayerMap", {
    GetTargetIndices = function(map)
        local indices = {}
        local obtainedIndices = {}
        for _, player in ipairs(REVEL.players) do
            local index = REVEL.room:GetGridIndex(player.Position)
            if not obtainedIndices[index] then
                indices[#indices + 1] = index
                obtainedIndices[index] = true
            end
        end

        return indices
    end,
    GetInverseCollisions = function(map)
        local inverseCollisions = {}
        for i = 0, REVEL.room:GetGridSize() do
            if REVEL.room:IsPositionInRoom(REVEL.room:GetGridPosition(i), 0) then
                local grid = REVEL.room:GetGridEntity(i)
                inverseCollisions[i] = REVEL.room:GetGridCollision(i) == 0 
                    and (
                        not grid 
                        or (grid.Desc.Type ~= GridEntityType.GRID_SPIKES and grid.Desc.Type ~= GridEntityType.GRID_SPIKES_ONOFF) 
                        or grid.State == SpikeState.SPIKE_OFF
                    )
            end
        end

        return inverseCollisions
    end
})

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, -5, function()
    UpdatePathMap(REVEL.PathToPlayerMap, true)
end)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, -5, function()
    UpdatePathMap(REVEL.PathToPlayerMap, true)
end)

function REVEL.GetMinimumTargetSets(entities)
    local sets = {}
    local individualTargets = {}
    for _, ent in ipairs(entities) do
        local data = ent:GetData()
        if data.TargetIndices then
            local shouldAdd = true
            for _, set in ipairs(sets) do
                if #set.Targets == #data.TargetIndices then
                    local matching = 0
                    for _, index in ipairs(data.TargetIndices) do
                        for _, index2 in ipairs(set.Targets) do
                            if index == index2 then
                                matching = matching + 1
                                break
                            end
                        end
                    end

                    if matching == #data.TargetIndices then
                        shouldAdd = false
                        break
                    end
                end
            end

            if shouldAdd then
                sets[#sets + 1] = {Targets = data.TargetIndices}
            end
        else
            local targetIndex = data.TargetIndex or REVEL.room:GetGridIndex(ent:ToNPC():GetPlayerTarget().Position)
            if not individualTargets[targetIndex] then
                sets[#sets + 1] = {Targets = {targetIndex}}
                individualTargets[targetIndex] = true
            end
        end
    end

    return sets
end

function REVEL.GetTargetSetMatchingEntity(entity, sets, data)
    data = data or entity:GetData()

    local targetSet = data.TargetIndices
    if not targetSet then
        targetSet = {data.TargetIndex or REVEL.room:GetGridIndex(entity:ToNPC():GetPlayerTarget().Position)}
    end

    local matchingSet
    for _, set in ipairs(sets) do
        if #set.Targets == #targetSet then
            local matching = 0
            for _, index in ipairs(set.Targets) do
                for _, index2 in ipairs(targetSet) do
                    if index == index2 then
                        matching = matching + 1
                        break
                    end
                end
            end

            if matching == #targetSet then
                matchingSet = set
                break
            end
        end
    end

    if matchingSet then
        return matchingSet
    end
end

function REVEL.IsGridPassable(i, ground, general, ignorePits, fireIndices, room) -- fireIndices doubles as ignoreFires if set to true
    room = room or REVEL.room
    local collision = room:GetGridCollision(i)
    if ground then
        if collision ~= 0 and (not ignorePits or collision ~= GridEntityType.GRID_PIT) then
            return false
        elseif not ignorePits then
            local grid = room:GetGridEntity(i)
            if grid 
            and (grid.Desc.Type == GridEntityType.GRID_SPIKES or grid.Desc.Type == GridEntityType.GRID_SPIKES_ONOFF) 
            and grid.State ~= SpikeState.SPIKE_OFF then
                return false
            end
        end
    end

    if general then
        if collision == GridCollisionClass.COLLISION_WALL or collision == GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER then
            return false
        end

        if fireIndices ~= true then
            if not fireIndices then
                for _, fire in ipairs(REVEL.roomFires) do
                    if fire.HitPoints > 1 and room:GetGridIndex(fire.Position) == i then
                        return false
                    end
                end
            elseif fireIndices[i] then
                return false
            end
        end
    end

    return true
end

function REVEL.GetPassableGrids(ground, general, ignorePits, ignoreFires) -- Ground: All colliding grids (like Rock, Poop) + Active Spikes, General: Fires, Spike Rocks, Tall Rocks (repentance)
    local hazardFree = {}
    local fireIndices
    if general and not ignoreFires then
        fireIndices = {}
        for _, fire in ipairs(REVEL.roomFires) do
            if fire.HitPoints > 1 then
                fireIndices[REVEL.room:GetGridIndex(fire.Position)] = true
            end
        end
    end

    for i = 0, REVEL.room:GetGridSize() do
        local pos = REVEL.room:GetGridPosition(i)
        if REVEL.room:IsPositionInRoom(pos, 0) then
            hazardFree[i] = REVEL.IsGridPassable(i, ground, general, ignorePits, ignoreFires or fireIndices, REVEL.room)
        end
    end

    return hazardFree
end

function REVEL.GetInsideGrids()
    local insideGrids = {}
    for i = 0, REVEL.room:GetGridSize() do
        if REVEL.room:IsPositionInRoom(REVEL.room:GetGridPosition(i), 0) then
            insideGrids[i] = true
        end
    end

    return insideGrids
end
    
local function GetMinimumTargetSetsFromMatch(pred, entityTable)
    local chaserEnemies = {}
    for _, ent in ipairs(entityTable or REVEL.roomEntities) do
        local data = ent:GetData()
        if not pred or pred(ent) then
            chaserEnemies[#chaserEnemies + 1] = ent
        end
    end

    return REVEL.GetMinimumTargetSets(chaserEnemies)
end


function REVEL.GetMinimumTargetSetsFromMap(map, entityTable)
    return GetMinimumTargetSetsFromMatch(function(ent) return REVEL.IsUsingPathMap(map, ent) end, entityTable)
end

function REVEL.GetMinimumTargetSetsFromData(dataKey, entityTable)
    return GetMinimumTargetSetsFromMatch(dataKey and function(ent) return ent:GetData()[dataKey] end, entityTable)
end

---@param pred fun(ent: Entity): boolean
---@param entityTable Entity[]
---@param map PathMap
---@param sets? TargetSet[]
local function SetPathOnMatchingEnts(pred, entityTable, map, sets)
    sets = sets or map.TargetMapSets
    for _, ent in ipairs(entityTable or REVEL.roomEntities) do
        local data = ent:GetData()
        if not pred or pred(ent) then
            local matchingSet = REVEL.GetTargetSetMatchingEntity(ent, sets, data)
            if matchingSet then
                if data.OnPathUpdate then
                    data.OnPathUpdate(matchingSet, ent, map)
                else
                    data.Path = nil
                    data.PathIndex = nil
                    local path, isComplete = GetPathToZero(
                        REVEL.room:GetGridIndex(ent.Position), 
                        matchingSet.Map, 
                        nil, 
                        map, 
                        map.SideCollisions
                    )
                    if isComplete or data.UseIncompleteMap then
                        data.Path = path
                    end
                end
            end
        end
    end
end

---@param dataKey any
---@param entityTable Entity[]
---@param map PathMap
---@param sets? TargetSet[]
function REVEL.SetPathOnMatchingEntsWithData(dataKey, entityTable, map, sets)
    return SetPathOnMatchingEnts(
        dataKey and function(ent) return ent:GetData()[dataKey] end, 
        entityTable, map, sets
    )
end

---@param entityTable Entity[]
---@param map PathMap
---@param sets? TargetSet[]
function REVEL.SetPathOnMatchingEntsUsingPathmap(entityTable, map, sets)
    return SetPathOnMatchingEnts(
        function(ent) return REVEL.IsUsingPathMap(map, ent) end, 
        entityTable, map, sets
    )
end

local BasicMapFunctions = {
    GetTargetSets = function(map)
        return REVEL.GetMinimumTargetSetsFromMap(map)
    end,
    OnPathUpdate = function(map)
        return REVEL.SetPathOnMatchingEntsUsingPathmap(nil, map)
    end,
}

REVEL.GenericChaserPathMap = REVEL.NewPathMapFromTable("GenericChaserPathMap", { -- Manages generic chaser enemy movement
    GetTargetSets = BasicMapFunctions.GetTargetSets,
    GetInverseCollisions = function(map)
        return REVEL.GetPassableGrids(true, true)
    end,
    GetInverseCriticalCollisions = function(map)
        return REVEL.GetInsideGrids()
    end,
    OnPathUpdate = BasicMapFunctions.OnPathUpdate,
})

REVEL.GenericFlyingChaserPathMap = REVEL.NewPathMapFromTable("GenericFlyingChaserPathMap", { -- Flying chasers collide with walls, fires, spike rocks, and tall rocks, so they still need pathfinding
    GetTargetSets = BasicMapFunctions.GetTargetSets,
    GetInverseCollisions = function(map)
        return REVEL.GetPassableGrids(false, true)
    end,
    GetInverseCriticalCollisions = function(map)
        return REVEL.GetInsideGrids()
    end,
    OnPathUpdate = BasicMapFunctions.OnPathUpdate,
})

end


local function GridDistanceSquared(indexA, indexB)
    if not (indexA and indexB) then 
        error("got nil values:" .. tostring(indexA) .. " and " .. tostring(indexB) .. REVEL.TryGetTraceback(), 2) 
    end
	return REVEL.room:GetGridPosition(indexA):DistanceSquared(REVEL.room:GetGridPosition(indexB))
end
REVEL.GridDistanceSquared = GridDistanceSquared

---Generate path using A* algorithm between two grid indices
---@param startIndex integer
---@param targetIndex integer
---@param validCollisions? table
---@return table|boolean path
---@return integer? pathLength
function REVEL.GeneratePathAStar(startIndex, targetIndex, validCollisions)
	local gridCollisions = {}
	local lengthScores = {} -- How many steps from Start to Index
	local combinedScores = {} -- Estimated distance from Index to Target + lengthScore
    validCollisions = validCollisions or {GridCollisionClass.COLLISION_NONE}
	for i = 0, REVEL.room:GetGridSize() - 1 do
        local coll = REVEL.room:GetGridCollision(i)
        if REVEL.includes(validCollisions, coll) then
    		gridCollisions[i] = 0
        else
            gridCollisions[i] = 1
        end

		lengthScores[i] = 999999999
		combinedScores[i] = 999999999
	end

	local width = REVEL.room:GetGridWidth()

	lengthScores[startIndex] = 0 -- 0 steps between startIndex and startIndex
	combinedScores[startIndex] = GridDistanceSquared(startIndex, targetIndex)

	local processedIndices = {}
	local indicesToCheck = {startIndex}

	local path = {}

	local foundPath, pathLength
	while #indicesToCheck > 0 do
		local checkIndex -- Grid index whose neighbors will be checked, try to select the one closest to the target
		local indexOfCheckIndex -- index in the indicesToCheck table of checkIndex
		local bestCombinedScore = 999999999
		for i, ind in ipairs(indicesToCheck) do
			if combinedScores[ind] < bestCombinedScore then
				checkIndex = ind
				indexOfCheckIndex = i
				bestCombinedScore = combinedScores[ind]
			end
		end

		if checkIndex == targetIndex then
			foundPath = true
            pathLength = bestCombinedScore
			break
		end

		table.remove(indicesToCheck, indexOfCheckIndex)
		processedIndices[checkIndex] = true

		local adjacentIndices = {
			checkIndex - 1,
			checkIndex + 1,
			checkIndex - width,
			checkIndex + width
		}

		for _, index in ipairs(adjacentIndices) do
			if not processedIndices[index] and gridCollisions[index] == 0 then
				local lengthScore = lengthScores[checkIndex] + 1
				local alreadyFound
				for _, ind in ipairs(indicesToCheck) do
					if ind == index then
						alreadyFound = true
						break
					end
				end

				if not alreadyFound or lengthScore < lengthScores[index] then
					indicesToCheck[#indicesToCheck + 1] = index
					path[index] = checkIndex
					lengthScores[index] = lengthScore
					combinedScores[index] = lengthScore + GridDistanceSquared(index, targetIndex)
				end
			end
		end
	end

	if foundPath then
		local pathReturn = {}
        local backwardPath = {}
		local current = targetIndex
		while path[current] do
            backwardPath[#backwardPath + 1] = current
            current = path[current]
		end

        for i = #backwardPath, 1, -1 do
            pathReturn[#pathReturn + 1] = backwardPath[i]
        end

		return pathReturn, pathLength
	else
		return false
	end
end


function REVEL.GetGridIndicesInRadius(pos, radius, room)
    room = room or REVEL.room
    local width = room:GetGridWidth()
    local topLeft = room:GetGridIndex(room:GetClampedPosition(pos + Vector(-radius, -radius), 0))
    local bottomRight = room:GetGridIndex(room:GetClampedPosition(pos + Vector(radius, radius), 0))
    local minX, minY = REVEL.GridToVector(topLeft, width)
    local maxX, maxY = REVEL.GridToVector(bottomRight, width)

    local indices = {}

    for x = minX, maxX do
        for y = minY, maxY do
            local index = REVEL.VectorToGrid(x, y, width)
            if x ~= minX and x ~= maxX and y ~= minY and y ~= maxY then
                indices[#indices + 1] = index
            else
                local gridPos = room:GetGridPosition(index)
                if gridPos:DistanceSquared(pos) < (20 + radius) ^ 2 then
                    indices[#indices + 1] = index
                end
            end
        end
    end

    return indices
end

function REVEL.CheckLine(posA, posB, radius, ground, general, ignorePits, ignoreFires)
    local room = REVEL.room
    local diff = posB - posA
    local distance = diff:Length()
    local normal = diff / distance
    local numChecks = math.ceil(distance / radius)
    local checkedIndices = {}

    local fireIndices
    if general and not ignoreFires then
        fireIndices = {}
        for _, fire in ipairs(REVEL.roomFires) do
            if fire.HitPoints > 1 then
                fireIndices[REVEL.room:GetGridIndex(fire.Position)] = true
            end
        end
    end

    for i = 1, numChecks do
        local check = posA + (normal * radius * i)
        if not room:IsPositionInRoom(check, 0) then
            return false, check
        end

        local indices = REVEL.GetGridIndicesInRadius(check, radius, room)
        local collides = false
        for _, index in ipairs(indices) do
            if not checkedIndices[index] then
                checkedIndices[index] = true
                if not REVEL.IsGridPassable(index, ground, general, ignorePits, ignoreFires or fireIndices, room) then
                    collides = true
                    break
                end
            end
        end

        if collides then
            return false, check
        end
    end

    return true
end

---Makes entity follow the path, adding velocity/friction accordingly
---@param entity Entity
---@param speed number
---@param path table<integer, integer>
---@param useDirect? boolean @If the movement should be towards the first grid with free line check
---@param friction? number @default: entity.Friction
---@param ground? boolean @default: true
---@param general? boolean @default: true
---@param ignorePits? boolean
---@param ignoreFires? boolean
---@param reset? boolean @reset state of path following
---@return boolean done
function REVEL.FollowPath(entity, speed, path, useDirect, friction, ground, general, ignorePits, ignoreFires, reset)
    if ground == nil then ground = true end
    if general == nil then general = true end

    if #path == 0 then
        error("REVEL.FollowPath error: empty path", 2)
    end

	local data = entity:GetData()
    if not data.PathIndex or reset then
        data.PathIndex = 1
    end

	if useDirect then
		local pathIndex
		for i = #path, data.PathIndex, -1 do
            local index = path[i]
            if REVEL.CheckLine(entity.Position, REVEL.room:GetGridPosition(index), 20, ground, general, ignorePits, ignoreFires) then
                pathIndex = i
                break
            end
		end

        if pathIndex then
    		data.PathIndex = pathIndex
        end
	end

	local index = path[data.PathIndex]
    local currentIndex = REVEL.room:GetGridIndex(entity.Position)

    local done = false

	if index == currentIndex then
		data.PathIndex = data.PathIndex + 1
		if data.PathIndex >= #path then
            data.PathIndex = #path
            done = true
		end

		index = path[data.PathIndex]
	end

--  REVEL.DebugToString({path, "Index", index, "Length", #path, "PathIndex", data.PathIndex})

    if not index then
        error("Tried to follow nil index in path: pathIndex = " .. tostring(data.PathIndex) .. REVEL.TryGetTraceback())
    end

    local pos = REVEL.room:GetGridPosition(index)

    friction = friction or entity.Friction
	entity.Velocity = entity.Velocity * friction + (pos - entity.Position):Resized(speed)

    return done
end

function REVEL.GetDirectPath(path, ground, general, ignorePits, ignoreFires)
    if ground == nil then ground = true end
    if general == nil then general = true end
    
    local out = {path[1]}

    local lastFree

    for i = 2, #path do
        local lastPos = REVEL.room:GetGridPosition(out[#out])
        local thisPos = REVEL.room:GetGridPosition(path[i])
        local freeToLast = REVEL.CheckLine(lastPos, thisPos, 5, ground, general, ignorePits, ignoreFires)
        if freeToLast then
            lastFree = path[i]
        else
            if lastFree then
                local lastFreePos = REVEL.room:GetGridPosition(lastFree)
                out[#out+1] = lastFree
                if REVEL.CheckLine(lastFreePos, thisPos, 10, ground, general, ignorePits, ignoreFires) then
                    lastFree = path[i]
                else
                    out[#out+1] = path[i]
                    lastFree = nil
                end
            else
                out[#out+1] = path[i]
            end
        end
    end

    if lastFree then
        out[#out+1] = lastFree
    end

    return out
end

---@param path integer[]
---@return number
function REVEL.GetPathLength(path)
    local len = 0
    for i = 2, #path do
        local posPrev = REVEL.room:GetGridPosition(path[i-1])
        local pos = REVEL.room:GetGridPosition(path[i])
        len = len + pos:Distance(posPrev)
    end
    return len
end

----------------------
-- Level pathfinder --
----------------------
do
    REVEL.LevelPathfindingIndices = {}
    REVEL.LevelPathMapNoSecret = REVEL.NewPathMapFromTable("LevelPathMapNoSecret", {
        GetTargetSets = function(map)
            local targetSets = {}
            for _, roomGrid in ipairs(REVEL.LevelPathfindingIndices) do
                targetSets[#targetSets + 1] = {Targets = {roomGrid}}
            end

            return targetSets
        end,
        GetInverseCollisions = function(map)
            local valid = {}
            local roomsList = REVEL.level:GetRooms()
            for i = 0, roomsList.Size - 1 do
                local roomDesc = roomsList:Get(i)
                if roomDesc and (roomDesc.Data.Type ~= RoomType.ROOM_SECRET and roomDesc.Data.Type ~= RoomType.ROOM_SUPERSECRET and roomDesc.GridIndex > -1) then
                    local room = roomDesc.Data
                    local ind = roomDesc.GridIndex
                    local shape = room.Shape
                    if shape == RoomShape.ROOMSHAPE_2x2 or shape == RoomShape.ROOMSHAPE_LBL or shape == RoomShape.ROOMSHAPE_LBR or shape == RoomShape.ROOMSHAPE_LTL or shape == RoomShape.ROOMSHAPE_LTR then
                        if shape ~= RoomShape.ROOMSHAPE_LTL then
                            valid[ind] = true
                        end

                        if shape ~= RoomShape.ROOMSHAPE_LTR then
                            valid[ind + 1] = true
                        end

                        if shape ~= RoomShape.ROOMSHAPE_LBL then
                            valid[ind + 13] = true
                        end

                        if shape ~= RoomShape.ROOMSHAPE_LBR then
                            valid[ind + 14] = true
                        end
                    elseif shape == RoomShape.ROOMSHAPE_1x2 or shape == RoomShape.ROOMSHAPE_IIV then
                        valid[ind] = true
                        valid[ind + 13] = true
                    elseif shape == RoomShape.ROOMSHAPE_2x1 or shape == RoomShape.ROOMSHAPE_IIH then
                        valid[ind] = true
                        valid[ind + 1] = true
                    else
                        valid[ind] = true
                    end
                end
            end

            return valid
        end,
        NoAutoHandle = true,
        Width = 13
    })

    REVEL.LevelPathMapWithSecret = REVEL.NewPathMapFromTable("LevelPathMapWithSecret", {
        GetTargetSets = function(map)
            local targetSets = {}
            for _, roomGrid in ipairs(REVEL.LevelPathfindingIndices) do
                targetSets[#targetSets + 1] = {Targets = {roomGrid}}
            end

            return targetSets
        end,
        GetInverseCollisions = function(map)
            local valid = {}
            local roomsList = REVEL.level:GetRooms()
            for i = 0, roomsList.Size - 1 do
                local roomDesc = roomsList:Get(i)
                if roomDesc and roomDesc.GridIndex > -1 then
                    local room = roomDesc.Data
                    local ind = roomDesc.GridIndex
                    local shape = room.Shape
                    if shape == RoomShape.ROOMSHAPE_2x2 or shape == RoomShape.ROOMSHAPE_LBL or shape == RoomShape.ROOMSHAPE_LBR or shape == RoomShape.ROOMSHAPE_LTL or shape == RoomShape.ROOMSHAPE_LTR then
                        if shape ~= RoomShape.ROOMSHAPE_LTL then
                            valid[ind] = true
                        end

                        if shape ~= RoomShape.ROOMSHAPE_LTR then
                            valid[ind + 1] = true
                        end

                        if shape ~= RoomShape.ROOMSHAPE_LBL then
                            valid[ind + 13] = true
                        end

                        if shape ~= RoomShape.ROOMSHAPE_LBR then
                            valid[ind + 14] = true
                        end
                    elseif shape == RoomShape.ROOMSHAPE_1x2 or shape == RoomShape.ROOMSHAPE_IIV then
                        valid[ind] = true
                        valid[ind + 13] = true
                    elseif shape == RoomShape.ROOMSHAPE_2x1 or shape == RoomShape.ROOMSHAPE_IIH then
                        valid[ind] = true
                        valid[ind + 1] = true
                    else
                        valid[ind] = true
                    end
                end
            end

            return valid
        end,
        NoAutoHandle = true,
        Width = 13
    })

    function REVEL.GetPathMapToRoomIndex(roomIndex, isGrid, includeSecret)
        local pathMap = REVEL.LevelPathMapNoSecret
        if includeSecret then
            pathMap = REVEL.LevelPathMapWithSecret
        end

        if not isGrid then
            roomIndex = REVEL.level:GetRooms():Get(roomIndex).GridIndex
        end

        local has = REVEL.includes(REVEL.LevelPathfindingIndices, roomIndex)

        local update = not pathMap.TargetMapSets
        if not has then
            REVEL.LevelPathfindingIndices[#REVEL.LevelPathfindingIndices + 1] = roomIndex
            update = true
        end

        if not update then
            for _, set in ipairs(pathMap.TargetMapSets) do
                if set.Targets[1] == roomIndex then
                    return set.Map
                end
            end
        end

        UpdatePathMap(pathMap, true)

        for _, set in ipairs(pathMap.TargetMapSets) do
            if set.Targets[1] == roomIndex then
                return set.Map
            end
        end
    end

    --Get a door slot that will eventually lead you to the target level grid id
    function REVEL.FindDoorToIdx(target, throughSecret)
        local gridIndex = REVEL.level:GetCurrentRoomDesc().GridIndex
        local map = REVEL.GetPathMapToRoomIndex(target, true, throughSecret)

        local lowestValue, lvDoorIndex, lvDoor
        for i = 0, 7 do
            local door = REVEL.room:GetDoor(i)
            if door then
                local doorRoomGrid = door.TargetRoomIndex
                if map[doorRoomGrid] and (not lowestValue or map[doorRoomGrid] < lowestValue) then
                    lowestValue = map[doorRoomGrid]
                    lvDoorIndex = i
                    lvDoor = door
                end
            end
        end

        return lvDoorIndex, lvDoor
    end

    revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
        REVEL.LevelPathfindingIndices = {}
    end)
end

Isaac.DebugString("Revelations: Loaded Pathfinding Library!")
end
