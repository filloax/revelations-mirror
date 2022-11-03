local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

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

function REVEL.GetRoomsListNames()
    local out = {}
    for listName, _ in pairs(StageAPI.RoomsLists) do
        out[#out + 1] = listName
    end
    return out
end

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


StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, wasRoomClearPostNewRoom)
revel:AddCallback(ModCallbacks.MC_POST_UPDATE, roomTransitionProgressPostUpdate)
revel:AddCallback(ModCallbacks.MC_POST_RENDER, roomTransitionProgressPostRender)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, roomTransitionProgressPostNewRoom)
revel:AddCallback(ModCallbacks.MC_POST_UPDATE, updateRoomASAPUpdate)

end

REVEL.PcallWorkaroundBreakFunction()