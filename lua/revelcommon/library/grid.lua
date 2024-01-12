local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local SpikeState     = require("lua.revelcommon.enums.SpikeState")
local GridBreakState = require("lua.revelcommon.enums.GridBreakState")

return function()


function REVEL.VectorToGrid(x, y, width)
    width = width or REVEL.room:GetGridWidth()
    return math.floor(width + 1 + (x + width * y))
end

---@param index integer
---@param width? integer
---@return number x
---@return number y
function REVEL.GridToVector(index, width)
    width = width or REVEL.room:GetGridWidth()
    return (index % width) - 1, (math.floor(index / width)) - 1
end

local LockedGridIndexes = {}

local function lockgridindexPostNewRoom()
    LockedGridIndexes = {}
end

function REVEL.IsGridIdAbove(id1, id2)
    local _, y1 = REVEL.GridToVector(id1)
    local _, y2 = REVEL.GridToVector(id2)
    return y1 < y2
end

function REVEL.IsGridIdBelow(id1, id2)
    local _, y1 = REVEL.GridToVector(id1)
    local _, y2 = REVEL.GridToVector(id2)
    return y1 > y2
end

function REVEL.IsGridIdLeft(id1, id2)
    local x1 = REVEL.GridToVector(id1)
    local x2 = REVEL.GridToVector(id2)
    return x1 < x2
end

function REVEL.IsGridIdRight(id1, id2)
    local x1 = REVEL.GridToVector(id1)
    local x2 = REVEL.GridToVector(id2)
    return x1 > x2
end

function REVEL.IsGridIdDirectlyAbove(id1, id2)
  local w = REVEL.room:GetGridWidth()
  return id1 == id2-w
end

function REVEL.IsGridIdDirectlyBelow(id1, id2)
  local w = REVEL.room:GetGridWidth()
  return id1 == id2+w
end

local NonBlockingCollisions = {
    GridCollisionClass.COLLISION_NONE
}

local NonSolidCollisions = {
  GridCollisionClass.COLLISION_NONE
}

local EntityGridCollisionToGridCollision = {
    [EntityGridCollisionClass.GRIDCOLL_BULLET] = {GridCollisionClass.COLLISION_SOLID, GridCollisionClass.COLLISION_OBJECT, GridCollisionClass.COLLISION_WALL, GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER},
    [EntityGridCollisionClass.GRIDCOLL_GROUND] = {GridCollisionClass.COLLISION_SOLID, GridCollisionClass.COLLISION_OBJECT, GridCollisionClass.COLLISION_PIT, GridCollisionClass.COLLISION_WALL, GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER},
    [EntityGridCollisionClass.GRIDCOLL_NOPITS] = {GridCollisionClass.COLLISION_SOLID, GridCollisionClass.COLLISION_OBJECT, GridCollisionClass.COLLISION_WALL, GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER},
    [EntityGridCollisionClass.GRIDCOLL_WALLS] = {GridCollisionClass.COLLISION_WALL, GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER}
}

function REVEL.IsGridIndexSolid(index, nonBlock)
    local pos = REVEL.room:GetGridPosition(index)
    return REVEL.room:IsPositionInRoom(pos, 0) and REVEL.includes(nonBlock or NonBlockingCollisions, REVEL.room:GetGridCollision(index))
  end
  
function REVEL.GridCollisionMatch(entityCollision, gridCollision)
    if entityCollision == EntityGridCollisionClass.GRIDCOLL_NONE then
        return false
    else
        if entityCollision == EntityGridCollisionClass.GRIDCOLL_WALLS_X or entityCollision == EntityGridCollisionClass.GRIDCOLL_WALLS_Y then
            entityCollision = EntityGridCollisionClass.GRIDCOLL_WALLS
        end

        if EntityGridCollisionToGridCollision[entityCollision] then
            return REVEL.includes(EntityGridCollisionToGridCollision[entityCollision], gridCollision)
        else
            return false
        end
    end
end

function REVEL.IsGridPosSolid(pos, nonSolid)
  local index = REVEL.room:GetGridIndex(pos)
  return not (REVEL.room:IsPositionInRoom(pos, 0) and REVEL.includes(nonSolid or NonSolidCollisions, REVEL.room:GetGridCollision(index)))
end

--if grid index is free from entities except whitelisted ones
function REVEL.IsGridIndexFree(index, radius, partitions, nonBlock, entWhitelist)
    local pos = REVEL.room:GetGridPosition(index)
    local grid = REVEL.room:GetGridEntity(index)
    return REVEL.room:IsPositionInRoom(pos, 0) and not LockedGridIndexes[index]
           and (#REVEL.MultiFindInRadius(pos, radius or 32, partitions or {EntityPartition.ENEMY}, entWhitelist) < 1)
           and REVEL.includes(nonBlock or NonBlockingCollisions, REVEL.room:GetGridCollision(index))
           and (
               not grid 
               or (grid.Desc.Type ~= GridEntityType.GRID_SPIKES and grid.Desc.Type ~= GridEntityType.GRID_SPIKES_ONOFF) 
               or grid.State == SpikeState.SPIKE_OFF
            )
end

function REVEL.GetNearFreeGridIndexes(index, radius, freeRadius, freePartitions, nonBlock, entWhitelist, minRadius)
    local valid = {}
    local oriX, oriY = REVEL.GridToVector(index)
    for x = -radius, radius do
        for y = -radius, radius do
            if not minRadius or ((x < -minRadius or x > minRadius) or (y < -minRadius or y > minRadius)) then
                local nx, ny = oriX + x, oriY + y
                if not (nx < 0 or ny < 0 or nx >= REVEL.room:GetGridWidth() or ny >= REVEL.room:GetGridHeight()) then
                    local i = REVEL.VectorToGrid(nx, ny)
                    if REVEL.IsGridIndexFree(i, freeRadius, freePartitions, nonBlock, entWhitelist) then
                        valid[#valid + 1] = i
                    end
                end
            end
        end
    end

    return valid
end

---@param position Vector
---@param indexes integer[]
---@return integer
function REVEL.GetClosestGridIndexToPosition(position, indexes)
    local index
    local distance
    for _, i in ipairs(indexes) do
        local pos = REVEL.room:GetGridPosition(i)
        local dist = pos:Distance(position)
        if not distance or dist < distance then
            distance = dist
            index = i
        end
    end

    return index
end

function REVEL.IsMidGridInDirection(index, position, direction, useVertical, threshold)
    threshold = threshold or 0
    local gridCenter = REVEL.room:GetGridPosition(index)
    local axis = useVertical and 'Y' or 'X'

    local d = sign(direction[axis])
    return sign(gridCenter[axis] - threshold * d - position[axis]) ~= d
end

function REVEL.LockGridIndex(index)
    LockedGridIndexes[index] = true
end

function REVEL.UnlockGridIndex(index)
    LockedGridIndexes[index] = false
end

function REVEL.IsGridIndexUnlocked(index)
    return not LockedGridIndexes[index]
end

function REVEL.GetAdjacentIndices(index, num, checkIfFree, width, height, start, left, right, up, down)
    if left == nil then left = true end
    if right == nil then right = true end
    if up == nil then up = true end
    if down == nil then down = true end
    start = start or 1

    width = width or REVEL.room:GetGridWidth()
    height = height or REVEL.room:GetGridHeight()

    local x, y = REVEL.GridToVector(index, width)

    local indices = {}
    for i = start, num do
        if right then
            local iX = x + i
            local ind = index + i
            if iX < width and (not checkIfFree or REVEL.IsGridIndexFree(ind)) then
                indices[#indices + 1] = ind
            end
        end

        if left then
            local iX = x - i
            local ind = index - i
            if iX > 0 and (not checkIfFree or REVEL.IsGridIndexFree(ind)) then
                indices[#indices + 1] = ind
            end
        end

        if down then
            local iY = y + i
            local ind = index + width * i
            if iY < height and (not checkIfFree or REVEL.IsGridIndexFree(ind)) then
                indices[#indices + 1] = ind
            end
        end

        if up then
            local iY = y - i
            local ind = index - width * i
            if iY > 0 and (not checkIfFree or REVEL.IsGridIndexFree(ind)) then
                indices[#indices + 1] = ind
            end
        end
    end

    return indices
end

function REVEL.GetLastNonCollidingIndex(startIndex, entityCollision, addX, addY, width, height)
    width, height = width or REVEL.room:GetGridWidth(), height or REVEL.room:GetGridHeight()
    local checkX, checkY = REVEL.GridToVector(startIndex, width)
    local checkIndex = startIndex
    local foundNonBlocking
    local timesChecked = 1
    while checkX <= width and checkY <= height and checkX >= 0 and checkY >= 0 do
        local newX, newY = checkX + addX, checkY + addY
        local newIndex = REVEL.VectorToGrid(newX, newY, width)
        if REVEL.room:IsPositionInRoom(REVEL.room:GetGridPosition(newIndex), 0) then
            local collision = REVEL.room:GetGridCollision(newIndex)
            if REVEL.GridCollisionMatch(entityCollision, collision) then
                if foundNonBlocking then
                    return checkIndex, timesChecked
                end
            else
                foundNonBlocking = true
            end
        else
            return checkIndex, timesChecked
        end

        checkIndex = newIndex
        checkX, checkY = newX, newY
        timesChecked = timesChecked + 1
    end
end

-- Call this function when ent:CollidesWithGrid is true
-- To use this you must track the entity's previous frame's velocity
-- Returns the grid this entity collided with, the collision normal
function REVEL.GetGridCollisionInfo(pos, vel, prevVel)
    local index = REVEL.room:GetGridIndex(pos - vel)
    local pos = REVEL.room:GetGridPosition(index)

    local normal = (vel - prevVel):Normalized() -- this does not lock to cardinals in the interest of fully accurate information
    local grid = REVEL.room:GetGridEntityFromPos(pos - normal * 40)

    return grid, index, normal
end


local TempGridData = {}

function REVEL.GetTempGridData(gridIndex)
    if gridIndex == nil then
        error("REVEL.GetTempGridData error: nil gridIndex", 2)
    end

    if not TempGridData[gridIndex] then
        TempGridData[gridIndex] = {}
    end

    return TempGridData[gridIndex]
end

if _G.revelTempGridData then --persist across luamod
    TempGridData = _G.revelTempGridData
else
    _G.revelTempGridData = TempGridData
end

local function ResetTempGridData()
    TempGridData = {}
    _G.revelTempGridData = TempGridData
end

-- Note: pathMaps are no longer automatically updated,
-- so pass the doUpdate param as true the first time you use this
-- in a frame if the map isn't being updated by other source
function REVEL.AnyPlayerCanReachIndex(gridIndex, doUpdate)
    if doUpdate then
        REVEL.UpdatePathMap(REVEL.PathToPlayerMap)
    end

    return not not REVEL.PathToPlayerMap.TargetMapSets[1].Map[gridIndex]
end

local RockTypes = {
    GridEntityType.GRID_ROCK,
    GridEntityType.GRID_ROCKT,
    GridEntityType.GRID_ROCK_BOMB,
    GridEntityType.GRID_ROCK_ALT,
    GridEntityType.GRID_ROCK_SS,
    GridEntityType.GRID_ROCK_SPIKED,
    GridEntityType.GRID_ROCK_ALT2,
    GridEntityType.GRID_ROCK_GOLD,
}
local PoopTypes = {
    GridEntityType.GRID_POOP,
}
local TNTTypes = {
    GridEntityType.GRID_TNT,
}

local DestroyableGridsState = {}
for _, gridtype in ipairs(RockTypes) do
    DestroyableGridsState[gridtype] = GridBreakState.BROKEN_ROCK
end
for _, gridtype in ipairs(PoopTypes) do
    DestroyableGridsState[gridtype] = GridBreakState.BROKEN_POOP
end
for _, gridtype in ipairs(TNTTypes) do
    DestroyableGridsState[gridtype] = GridBreakState.BROKEN_TNT
end

-- Returns true if grid can be destroyed and is not 
-- currently destroyed
function REVEL.CanGridBeDestroyed(gridEntity)
    if type(gridEntity) == "number" then gridEntity = REVEL.room:GetGridEntity(gridEntity) end
    if not gridEntity then 
        error("CanGridBeDestroyed: grid entity nil", 2)
    end

    if DestroyableGridsState[gridEntity.Desc.Type] then
        return not REVEL.IsGridBroken(gridEntity)
    end 
    return false
end

-- Check if the grid is at the broken state, which varies depending 
-- on grid type
function REVEL.IsGridBroken(gridEntity)
    if type(gridEntity) == "number" then gridEntity = REVEL.room:GetGridEntity(gridEntity) end
    if not gridEntity then 
        error("IsGridBroken: grid entity nil", 2)
    end

    local gridType = gridEntity.Desc.Type

    if DestroyableGridsState[gridType] then
        return gridEntity.State >= DestroyableGridsState[gridType]
    end
    return false
end

-- changed from 0-4 to 0-1000 in rep,
-- not trusting it to not change again
function REVEL.GetPoopDamagePct(grid)
    if not grid then error("GetPoopDamagePct: grid nil", 2) end
    if grid.Desc.Type ~= GridEntityType.GRID_POOP then error("GetPoopDamagePct: not poop", 2) end

    return grid.State / GridBreakState.BROKEN_POOP
end

---@param slot integer
---@return CustomGridEntity?
function REVEL.GetCustomDoorBySlot(slot)
    ---@type CustomGridEntity[]
    local customDoors = StageAPI.GetCustomDoors()
    local slotIndex = REVEL.room:GetGridIndex(REVEL.room:GetDoorSlotPosition(slot))

    for _, door in ipairs(customDoors) do
        if door.GridIndex == slotIndex then
            return door
        end
    end
end

function REVEL.GetGridIdxInDirection(fromIndex, direction)
    local vec = REVEL.dirToVel[direction]
    local w = REVEL.room:GetGridWidth()
    local x, y = REVEL.GridToVector(fromIndex, w)
    return REVEL.VectorToGrid(x + vec.X, y + vec.Y, w)
end

function REVEL.GetOppositeDoorSlot(slot)
    local adjSlot = slot % 4
    return (adjSlot + 2) % 4 + (slot - adjSlot)
end

-- CALLBACKS

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, lockgridindexPostNewRoom)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, ResetTempGridData)
revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, ResetTempGridData)

end