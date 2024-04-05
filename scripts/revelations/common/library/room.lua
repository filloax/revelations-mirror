local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local GridBreakState    = require("scripts.revelations.common.enums.GridBreakState")
local SpikeState        = require("scripts.revelations.common.enums.SpikeState")

return function()

function REVEL.SafeRoomTransition(index, useChangeRoom, direction, roomAnimation)
    REVEL.level.LeaveDoor = -1
    if useChangeRoom then
        REVEL.game:ChangeRoom(index)
    else
        REVEL.game:StartRoomTransition(index, direction, roomAnimation)
    end
end

--room transition progress
--will return higher values in cases where the transition animation is different (like game start)
--mind that IsPaused returns true for some parts of it
local roomTransitionCount = -1
local stopTransition = false
local prevRoom = -1
local endRoomTransCount = 19 --obtained with testing

function REVEL.GetRoomTransitionProgress()
    if roomTransitionCount == -1 then
        return 1
    else
        return math.min(1, roomTransitionCount / endRoomTransCount) --the math.min is a temporary workaround for longer transitions, but for what this is used for its good enough
    end
end

local function roomTransitionProgressPostUpdate()
    local room = REVEL.level:GetCurrentRoomIndex()
    if room ~= prevRoom then
        stopTransition = true
        prevRoom = room
    end
end

local function roomTransitionProgressPostRender()
    if roomTransitionCount > -1 then
        roomTransitionCount = roomTransitionCount + 1
        if stopTransition then
            roomTransitionCount = -1
            stopTransition = false
        end
    end
end

local function roomTransitionProgressPostNewRoom()
    roomTransitionCount = 0
    stopTransition = false
end

-- TODO: replace with Repentance room check? mainly used by virgil
-- function REVEL.IsRevelEntrance()
--     return StageAPI.GetCurrentRoomType() == "GlacierEntrance" or StageAPI.GetCurrentRoomType() == "TombEntrance"
-- end

function REVEL.IsCrawlspace()
    return REVEL.room:GetType() == RoomType.ROOM_DUNGEON or StageAPI.GetCurrentRoomType() == "RevelationsHub"
end
  
-- Wrapper for old stageapi function that was deprecated but would
-- be more or less the same amount of code when adapted to specific cases
function REVEL.IndicesShareGroup(stageapiRoom, index1, index2, specificGroup)
    if specificGroup then
        return stageapiRoom.Metadata:IsIndexInGroup(index1, specificGroup) and stageapiRoom.Metadata:IsIndexInGroup(index2, specificGroup)
    else
        return stageapiRoom.Metadata:Has({
            Groups = stageapiRoom.Metadata:GroupsWithIndex(index1),
            Index = index2
        })
    end
end

function REVEL.WasRoomClearFromStart()
    local id = tostring(StageAPI.GetCurrentRoomID())
    return revel.data.run.level.clearFromStartRooms[id] == 1
end

local function wasRoomClearPostNewRoom()
    if REVEL.room:IsFirstVisit() then
        local id = tostring(StageAPI.GetCurrentRoomID())
        revel.data.run.level.clearFromStartRooms[id] = REVEL.room:IsClear() and 1 or 0
    end
end

function REVEL.ShutDoors()
    for i = 0, 7 do
        local door = REVEL.room:GetDoor(i)
        if door then
            door:Close()
        end
    end
end

function REVEL.OpenDoors(instant, includeLocked, includeSecret)
    for i = 0, 7 do
        local door = REVEL.room:GetDoor(i)
        if door then
            if (includeLocked or not door:IsLocked())
            and (includeSecret or not REVEL.includes({RoomType.ROOM_SECRET, RoomType.ROOM_SUPERSECRET}, door.TargetRoomType)) then
                door:Open()
                if instant then
                    door:GetSprite():Play("Opened", true)
                end
            end
        end
    end
end

-- GetCornerPositions
do 
    -- Grab all edge and corner indices --
    local adjacentWallsToRotation = {
        {
            Adjacent = {
                -1, -- -1 is left, 1 is right
                -2  -- width is capped, so -2 is up, 2 is down
            },
            Rotation = -45
        },
        {
            Adjacent = {
                1,
                -2
            },
            Rotation = 45
        },
        {
            Adjacent = {
                1,
                2
            },
            Rotation = 135
        },
        {
            Adjacent = {
                -1,
                2
            },
            Rotation = 225
        }
    }
  
    local cornerPositions = {}
    local edgePositions = {}
    local lPosition = nil
    local lastUpdatedIndex
    function REVEL.GetCornerPositions(reset) -- Calculate Corner Positions. Any index connecting to two walls that is not itself a wall must be a corner.
        local currentRoomIndex = REVEL.level:GetCurrentRoomIndex()
        if reset or #cornerPositions == 0 or currentRoomIndex ~= lastUpdatedIndex then
            lastUpdatedIndex = currentRoomIndex
            cornerPositions = {}
            edgePositions = {}
            lPosition = nil
    
            local firstInteriorIndex
            local log = ""
            for i = 0, REVEL.room:GetGridSize() do
                local pos = REVEL.room:GetGridPosition(i)
                if REVEL.DEBUG then
                    log = log .. REVEL.ToStringMulti(pos, REVEL.room:IsPositionInRoom(pos, 0)) .. "\n"
                end
                if REVEL.room:IsPositionInRoom(pos, 0) then
                    firstInteriorIndex = i
                    break
                end
            end
    
            if not firstInteriorIndex then
                if REVEL.DEBUG then
                    error("GetCornerPositions: firstInteriorIndex nil, Positions:" .. log, 2)
                else
                    error("GetCornerPositions: firstInteriorIndex nil", 2)
                end
            end
    
            local width = REVEL.room:GetGridWidth()
            local checkIndices = {firstInteriorIndex}
            local checkedIndices = {[firstInteriorIndex] = true}
            local done
    
            while #checkIndices > 0 do
                local checkIndex = checkIndices[#checkIndices]
                checkIndices[#checkIndices] = nil
                local adjacent = {1, width, -1, -width}
                local adjwalls = {}
                local adjfree = {}
                for _, ind in ipairs(adjacent) do
                    local checkind = checkIndex + ind
                    local adjgrid = REVEL.room:GetGridEntity(checkind)
                    if adjgrid and (adjgrid.Desc.Type == GridEntityType.GRID_WALL or adjgrid.Desc.Type == GridEntityType.GRID_DOOR) then
                        if ind > 2 then
                            ind = 2
                        elseif ind < -2 then
                            ind = -2
                        end
    
                        adjwalls[#adjwalls + 1] = ind
                    else
                        adjfree[#adjfree + 1] = ind
                    end
                end
    
                local isL
                if #adjwalls == 0 then
                    local potentialL = {1 + width, -1 + width, 1 - width, -1 - width}
                    for i, ind in ipairs(potentialL) do
                        local adjgrid = REVEL.room:GetGridEntity(checkIndex + ind)
                        if adjgrid and (adjgrid.Desc.Type == GridEntityType.GRID_WALL or adjgrid.Desc.Type == GridEntityType.GRID_DOOR) then
                            if i == 1 then
                                isL = -45
                            elseif i == 2 then
                                isL = 45
                            elseif i == 3 then
                                isL = 225
                            else
                                isL = 135
                            end
    
                            break
                        end
                    end
                end
    
                if #adjwalls > 0 or isL then
                    local pos = REVEL.room:GetGridPosition(checkIndex)
                    if #adjwalls == 2 then
                        local rotation
                        for _, potentialRotation in ipairs(adjacentWallsToRotation) do
                            local matching = 0
                            for _, wall in ipairs(adjwalls) do
                                for _, wall2 in ipairs(potentialRotation.Adjacent) do
                                    if wall == wall2 then
                                        matching = matching + 1
                                    end
                                end
                            end
    
                            if matching == 2 then
                                rotation = potentialRotation.Rotation
                                break
                            end
                        end
    
                        cornerPositions[#cornerPositions + 1] = {
                            Position = pos,
                            Grid = REVEL.room:GetGridEntity(checkIndex),
                            Index = checkIndex,
                            Rotation = rotation,
                            AdjacentWalls = adjwalls
                        }
                    elseif isL then
                        lPosition = {
                            Position = pos,
                            Grid = REVEL.room:GetGridEntity(checkIndex),
                            Index = checkIndex,
                            Rotation = isL,
                            AdjacentWalls = adjwalls
                        }
                    end
    
                    edgePositions[#edgePositions + 1] = {
                        Position = pos,
                        Grid = REVEL.room:GetGridEntity(checkIndex),
                        Index = checkIndex,
                        AdjacentWalls = adjwalls
                    }
    
                    for _, indAdd in ipairs(adjfree) do
                        if not checkedIndices[checkIndex + indAdd] then
                            checkedIndices[checkIndex + indAdd] = true
                            local position = REVEL.room:GetGridPosition(checkIndex + indAdd)
                            if not REVEL.room:IsPositionInRoom(position, 32) then
                                checkIndices[#checkIndices + 1] = checkIndex + indAdd
                                break
                            end
                        end
                    end
                end
            end
        end
    
        return cornerPositions, edgePositions, lPosition
    end
end

-- Returns false if there is any potential danger in the current room
function REVEL.RoomIsSafe()
    if REVEL.room:IsClear() then
        local roomHasDanger = false
        for _, entity in pairs(REVEL.roomNPCs) do
            if (entity:IsActiveEnemy() and not entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)) then
                roomHasDanger = true
                break
            end
        end
        roomHasDanger = roomHasDanger or
            Isaac.CountEntities(nil, EntityType.ENTITY_PROJECTILE)
                + Isaac.CountEntities(nil, EntityType.ENTITY_BOMBDROP)
                > 0
    
        return not roomHasDanger
    end
    return false
end

-- returns wall direction
-- doesn't really work in L rooms (for now)
function REVEL.GetClosestWall(position) 
    local c = REVEL.room:GetCenterPos()
    local tl, br = REVEL.GetRoomCorners()
     --y = mx + q, the usual line thing
    local mTlC = (c.Y - tl.Y) / (c.X - tl.X)
    local qTlC = c.Y - c.X * mTlC
    local isOnUpperLeftHalf = position.Y < position.X * mTlC + qTlC

    local mCTr = (tl.Y - c.Y) / (br.X - c.X)
    local qCTr = c.Y - c.X * mCTr
    local isOnUpperRightHalf = position.Y < position.X * mCTr + qCTr

    if isOnUpperLeftHalf and isOnUpperRightHalf then
        return Direction.UP
    elseif isOnUpperLeftHalf and not isOnUpperRightHalf then
        return Direction.LEFT
    elseif not isOnUpperLeftHalf and isOnUpperRightHalf then
        return Direction.RIGHT
    else
        return Direction.DOWN
    end
end

local doRoomUpdateNext = false

-- Calling Room:Update() updates each entity, causing infinite 
-- recursion if done inside an POST_x_UPDATE callback
function REVEL.UpdateRoomASAP()
    doRoomUpdateNext = true
end

local function updateRoomASAPUpdate()
    if doRoomUpdateNext then
        doRoomUpdateNext = false
        REVEL.room:Update()
    end
end


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


---TODO: document and replace return with table instead of nil
function REVEL.TryGetRandomNonAdjacentIndexes(numToGet, totalIndexNum, blockedEdgeWidth)
    local matching

    if totalIndexNum == 0 then
        matching = nil
    elseif totalIndexNum == 1 then
        matching = {1}
    elseif numToGet >= totalIndexNum - blockedEdgeWidth then
        matching = REVEL.Range(1, totalIndexNum)
        table.remove(matching, math.random(1, totalIndexNum))
    elseif numToGet == totalIndexNum - blockedEdgeWidth * 2 then
        matching = REVEL.Range(1 + blockedEdgeWidth, totalIndexNum - blockedEdgeWidth)
    else
        matching = {}

        local avaiableSlots = REVEL.KeyRange(1 + blockedEdgeWidth, totalIndexNum - blockedEdgeWidth)
        local nonAdjacentSlots = REVEL.KeyRange(1 + blockedEdgeWidth, totalIndexNum - blockedEdgeWidth)
        local numAvaiableSlots = totalIndexNum - 2
        local numNonAdjacentSlots = numAvaiableSlots

        repeat
            local slot = REVEL.RandomFromSet(nonAdjacentSlots, numNonAdjacentSlots)
            if not slot then
                -- REVEL.DebugToConsole(nonAdjacentSlots, numToGet, totalIndexNum, blockedEdgeWidth, avaiableSlots)
            end
            matching[#matching + 1] = slot
            avaiableSlots[slot] = nil
            numAvaiableSlots = numAvaiableSlots - 1
            nonAdjacentSlots[slot] = nil
            numNonAdjacentSlots = numNonAdjacentSlots - 1
            for i = -1, 1, 2 do
                if nonAdjacentSlots[slot + 1] then
                    nonAdjacentSlots[slot + 1] = nil
                    numNonAdjacentSlots = numNonAdjacentSlots - 1
                end
            end
        until numNonAdjacentSlots <= 0 or #matching >= numToGet

        if #matching < numToGet and numAvaiableSlots > 0 then
            repeat
                local slot = REVEL.RandomFromSet(avaiableSlots, numAvaiableSlots)
                matching[#matching + 1] = slot
                avaiableSlots[slot] = nil
                numAvaiableSlots = numAvaiableSlots - 1
            until numAvaiableSlots <= 0
        end
    end

    return matching
end

-- CALLBACKS

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, lockgridindexPostNewRoom)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, ResetTempGridData)
revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, ResetTempGridData)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, wasRoomClearPostNewRoom)
revel:AddCallback(ModCallbacks.MC_POST_UPDATE, roomTransitionProgressPostUpdate)
revel:AddCallback(ModCallbacks.MC_POST_RENDER, roomTransitionProgressPostRender)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, roomTransitionProgressPostNewRoom)
revel:AddCallback(ModCallbacks.MC_POST_UPDATE, updateRoomASAPUpdate)

end