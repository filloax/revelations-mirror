local Dimension = require "lua.revelcommon.enums.Dimension"
return function()


function REVEL.IsThereCurse(curseid)
    local curses = REVEL.level:GetCurses()
    
    return HasBit(curses, curseid)
end

---@param noAlias? boolean
---@return boolean
function REVEL.IsRevelStage(noAlias)
    return StageAPI.InNewStage() and REVEL.some(REVEL.STAGE, function(s)
        return s:IsStage(noAlias)
    end)
end

---@param stage CustomStage
---@param noAlias? boolean
---@return boolean
function REVEL.StageIsRevelStage(stage, noAlias)
    return REVEL.some(REVEL.STAGE, function(s)
        return StageAPI.IsSameStage(stage, s, noAlias)
    end)
end

function REVEL.GetMatchingRoomDescs(predicate)
    local output = {}
    local rooms = REVEL.level:GetRooms()

    for i = 0, rooms.Size - 1 do
        local room = rooms:Get(i)
        if predicate(room) then
            output[#output + 1] = room
        end
    end

    return output
end

--[[
   LEFT0: left top, LEFT1: left bottom
   UP0: top left, UP1: top right
   RIGHT0: right top, RIGHT1: right bottom
   DOWN0: down left, DOWN1: down right

   roomDesc.GridIndex always gives the top-left of the room if it occupies more tiles
]]

local RoomShapeDoorSlotOffsets = {
    --credits to MinimapAPI by Taz & Wofsauge
    -- L0 		UP0		R0		D0		L1		UP1		R1		D1
    {Vector(-1, 0), Vector(0, -1), Vector(1, 0), Vector(0, 1),nil,nil,nil,nil}, -- ROOMSHAPE_1x1
    {Vector(-1, 0),nil,Vector(1, 0),nil,nil,nil,nil,nil}, -- ROOMSHAPE_IH
    {nil,Vector(0, -1),nil,Vector(0, 1),nil,nil,nil,nil}, -- ROOMSHAPE_IV
    {Vector(-1, 0), Vector(0, -1), Vector(1, 0), Vector(0, 2), Vector(-1, 1),nil, Vector(1, 1),nil}, -- ROOMSHAPE_1x2
    {nil,Vector(0, -1),nil, Vector(0, 2),nil,nil,nil,nil}, -- ROOMSHAPE_IIV
    {Vector(-1, 0),Vector(0, -1),Vector(2, 0),Vector(0, 1),Vector(-1, 0),Vector(1, -1),Vector(2, 0),Vector(1, 1)}, -- ROOMSHAPE_2x1
    {Vector(-1, 0),nil,Vector(2,0),nil,nil,nil,nil,nil}, -- ROOMSHAPE_IIH
    {Vector(-1,0),Vector(0,-1),Vector(2,0),Vector(0,2),Vector(-1,1),Vector(1,-1),Vector(2,1),Vector(1,2)}, -- ROOMSHAPE_2x2
    {Vector(-1,0),Vector(-1,0),Vector(1,0),Vector(-1,2),Vector(-2,1),Vector(0,-1),Vector(1,1),Vector(0,2)}, -- ROOMSHAPE_LTL
    {Vector(-1,0),Vector(0,-1),Vector(1,0),Vector(0,2),Vector(-1,1),Vector(1,0),Vector(2,1),Vector(1,2)}, -- ROOMSHAPE_LTR
    {Vector(-1,0),Vector(0,-1),Vector(2,0),Vector(0,1),Vector(0,1),Vector(1,-1),Vector(2,1),Vector(1,2)}, -- ROOMSHAPE_LBL
    {Vector(-1,0),Vector(0,-1),Vector(2,0),Vector(0,2),Vector(-1,1),Vector(1,-1),Vector(1,1),Vector(1,1)} -- ROOMSHAPE_LBR
}

function REVEL.GetRoomIdxRelativeToSlot(roomDesc, doorSlot)
    local shape = roomDesc.Data.Shape
    local pivotIndex = roomDesc.SafeGridIndex
    local offset = RoomShapeDoorSlotOffsets[shape][doorSlot + 1]

    if not offset then
      error("Room slot offset not found; Shape: " .. tostring(shape) .. "; Slot: " .. tostring(doorSlot) .. REVEL.TryGetTraceback(), 2)
      return
    end

    local roomPos = Vector(pivotIndex % 13, math.floor(pivotIndex / 13))
    local newPos = roomPos + offset

    if newPos.X < 0 or newPos.X >= 13 or newPos.Y < 0 then
        return nil
    end

    return newPos.X + newPos.Y * 13
end

--Returns used slots, avaiable slots (only depending on shape and position on the map, not actual layout)
function REVEL.GetRoomDescDoorSlots(roomDesc, maxForShape, ignoreMirrorRoom)
    --.Data.Doors depends on the vanilla room layout, so it can't be taken as a 100% surefire indicator
    --of whether the room needs a door in that position as it might get false positives
    --[[
        local doorFlags = roomDesc.Data.Doors
        local slots = {}

        for _, slot in pairs(DoorSlot) do
            if doorFlags & (1 << slot) > 0 then
                slots[#slots + 1] = slot
            end
        end

        return slots
    ]]
    local maxSlots, avaiable = {}, {}
    if maxForShape then
        REVEL.FillTable(maxSlots, StageAPI.RoomShapeToWidthHeight[roomDesc.Data.Shape].Slots)
    else
        maxSlots, avaiable = REVEL.GetRoomDescDoorSlots(roomDesc, true)
        for i, slot in ripairs(maxSlots) do
            local leadingTo = REVEL.GetRoomIdxRelativeToSlot(roomDesc, slot)
            if leadingTo and not REVEL.level:GetRoomByIdx(leadingTo).Data
            and not (
                revel.data.run.level.mirrorDoorRoomIndex > - 1 
                and roomDesc.GridIndex == revel.data.run.level.mirrorDoorRoomIndex 
                and slot == revel.data.run.level.mirrorDoorRoomSlot
            ) then --if room at the slot doesn't exist
                avaiable[#avaiable + 1] = slot
                table.remove(maxSlots, i)
            end
        end
    end

    return maxSlots, avaiable
end

-- Get the next stage type in case of Repentance level transition
-- Example, if the next stage will be dross or downpour, etc
function REVEL.SimulateStageTransitionStageType(levelStage, isRepPath)
	local oldStage, oldStageType = REVEL.level:GetAbsoluteStage(), REVEL.level:GetStageType()
    local seeds = REVEL.game:GetSeeds()
	local oldSeed = seeds:GetStartSeedString()
	
	local testStage = levelStage - 1
	local testStageType = isRepPath and StageType.STAGETYPE_REPENTANCE or StageType.STAGETYPE_ORIGINAL
	REVEL.level:SetStage(testStage, testStageType)
	
	REVEL.level:SetNextStage()
	local stageType = REVEL.level:GetStageType()
	
	seeds:SetStartSeed(oldSeed)
    REVEL.level:SetStage(oldStage, oldStageType)
	
    -- In case of curse of labyrinth and others it doesn't work
    if isRepPath and not (stageType == StageType.STAGETYPE_REPENTANCE or stageType == StageType.STAGETYPE_REPENTANCE_B) then
        local rng = REVEL.RNG()
        rng:SetSeed(seeds:GetStageSeed(levelStage), 127)
        if rng:RandomFloat() < 0.5 or not REVEL.HasUnlockedRepentanceAlt(levelStage) then
            stageType = StageType.STAGETYPE_REPENTANCE
        else
            stageType = StageType.STAGETYPE_REPENTANCE_B
        end
    end

	return stageType
end

local StageChapterMap = {
    [LevelStage.STAGE4_3] = 4,
    [LevelStage.STAGE5] = 5,
    [LevelStage.STAGE6] = 6,
    [LevelStage.STAGE7] = 7,
    [LevelStage.STAGE8] = 8,
}

local CustomStageChapterMap = {
    ["Glacier"] = 1,
    ["Tomb"] = 2,
}

---@param stage? LevelStage|CustomStage
---@return integer
function REVEL.GetStageChapter(stage)
    -- current stage, can only check custom stages in this case as 
    -- stage number wouldn't be enough
    if not stage then
        local currentStage = StageAPI.GetCurrentStage()
        if currentStage then
            for stageName, chapter in pairs(CustomStageChapterMap) do
                if stageName == currentStage.Name or stageName == currentStage.Alias then
                    return chapter
                end
            end
        end
    end

    stage = stage or REVEL.level:GetStage()

    if type(stage) == "table" and stage.IsStage then
        if stage == REVEL.STAGE.Glacier then
            return 1
        elseif stage == REVEL.STAGE.Tomb then
            return 2
        else
            error(("GetStageChapter: Unsupported stageAPI stage %s"):format(stage.Name), 2)
        end
    elseif stage >= LevelStage.STAGE1_1 and stage <= LevelStage.STAGE4_2 then
        return math.ceil(stage / 2)
    else
        return StageChapterMap[stage] or 0
    end
end

function REVEL.IsLastChapterStage()
    if REVEL.IsThereCurse(LevelCurse.CURSE_OF_LABYRINTH) then
        return true
    end

    local currentStage = StageAPI.GetCurrentStage()
    if currentStage then
        return currentStage.IsSecondStage
    end

    local stage = REVEL.level:GetStage()
    if stage >= LevelStage.STAGE1_1 and stage <= LevelStage.STAGE4_2 then
        return stage % 2 == 0
    end
    
    return true
end

function REVEL.GetDoorsForRoomFromDesc(roomDesc, maxFromOriginalLayout)
    if maxFromOriginalLayout then
        return StageAPI.GetDoorsForRoomFromData(roomDesc.Data)
    else
        local doorList, _ = REVEL.GetRoomDescDoorSlots(roomDesc)
        return REVEL.toSet(doorList)
    end
end

-- REVEL.rooms returns CONST room descs, this returns an editable one
function REVEL.GetRoomDescByListIdx(listIndex)
    local constDesc = REVEL.level:GetRooms():Get(listIndex)
    if not constDesc then
        error(("GetRoomDescByListIdx: bad index %d"):format(listIndex), 2)
    end
    local gridIndex = constDesc.SafeGridIndex

    -- Need to find out dimension
    for dim = 0, Dimension.NUM do
        local roomDesc = REVEL.level:GetRoomByIdx(gridIndex, dim)
        if roomDesc.ListIndex == listIndex then
            return roomDesc
        end
    end
end

---@param listIndex integer
---@return integer
function REVEL.GetRoomDimensionByListIdx(listIndex)
    local gridIndex = REVEL.level:GetRooms():Get(listIndex).GridIndex
    for dim = 0, Dimension.NUM do
        if REVEL.level:GetRoomByIdx(gridIndex, dim).ListIndex == listIndex then
            return dim
        end
    end
    return -1
end

---@param roomDesc? RoomDescriptor
function REVEL.RoomHasMinesButton(roomDesc)
    roomDesc = roomDesc or REVEL.level:GetCurrentRoomDesc()
    local stage = REVEL.level:GetStage()
    local stageType = REVEL.level:GetStageType()
    return (stage == LevelStage.STAGE2_1 or stage == LevelStage.STAGE2_2)
        and (stageType == StageType.STAGETYPE_REPENTANCE or stageType == StageType.STAGETYPE_REPENTANCE_B)
        and roomDesc.Data.Type == RoomType.ROOM_DEFAULT
        and roomDesc.Data.Subtype == 1 or roomDesc.Data.Subtype == 10
end

function REVEL.InMineshaft()
    local roomDescriptor = REVEL.level:GetCurrentRoomDesc()
    local subtype = roomDescriptor.Data.Subtype
    local levelStage = REVEL.level:GetStage()
    local stageType = REVEL.level:GetStageType()
    return (levelStage == LevelStage.STAGE2_1 or levelStage == LevelStage.STAGE2_2)
        and (stageType == StageType.STAGETYPE_REPENTANCE or stageType == StageType.STAGETYPE_REPENTANCE_B)
        and (
            subtype == 11
            or subtype == 20
            or subtype == 30
            or subtype == 31
        )
end

---@alias ListIndex integer
---@alias Rev.RoomMap table<integer, table<integer, ListIndex>>

-- returns an x and y based grid table with listindices signifying rooms
---@return Rev.RoomMap
function REVEL.MapRooms()
    local rooms = REVEL.level:GetRooms()
    local roomsMap = {}
    
    for x=0, 14 do
        roomsMap[x] = {}
    end
    
    for i = 0, rooms.Size - 1 do
        local room = rooms:Get(i)
        local shape = room.Data.Shape
        local x,y = room.GridIndex%13 + 1, math.floor(room.GridIndex/13) + 1
        
        if shape == RoomShape.ROOMSHAPE_1x2 or shape == RoomShape.ROOMSHAPE_IIV then
            roomsMap[x][y] = room.ListIndex
            roomsMap[x][y + 1] = room.ListIndex
            
        elseif shape == RoomShape.ROOMSHAPE_2x1 or shape == RoomShape.ROOMSHAPE_IIH then
            roomsMap[x][y] = room.ListIndex
            roomsMap[x + 1][y] = room.ListIndex
            
        elseif shape == RoomShape.ROOMSHAPE_2x2 then
            roomsMap[x][y] = room.ListIndex
            roomsMap[x][y + 1] = room.ListIndex
            roomsMap[x + 1][y] = room.ListIndex
            roomsMap[x + 1][y + 1] = room.ListIndex
            
        elseif shape == RoomShape.ROOMSHAPE_LTL then
            roomsMap[x][y + 1] = room.ListIndex
            roomsMap[x + 1][y] = room.ListIndex
            roomsMap[x + 1][y + 1] = room.ListIndex
            
        elseif shape == RoomShape.ROOMSHAPE_LTR then
            roomsMap[x][y] = room.ListIndex
            roomsMap[x][y + 1] = room.ListIndex
            roomsMap[x + 1][y + 1] = room.ListIndex
            
        elseif shape == RoomShape.ROOMSHAPE_LBL then
            roomsMap[x][y] = room.ListIndex
            roomsMap[x + 1][y] = room.ListIndex
            roomsMap[x + 1][y + 1] = room.ListIndex
            
        elseif shape == RoomShape.ROOMSHAPE_LBR then
            roomsMap[x][y] = room.ListIndex
            roomsMap[x][y + 1] = room.ListIndex
            roomsMap[x + 1][y] = room.ListIndex
            
        else
            roomsMap[x][y] = room.ListIndex
        end
    end
    
    return roomsMap
end

---@alias Rev.RoomConnectionsMap table<ListIndex, ListIndex[]>

-- returns a lookup table that gives a list of all list indices connected to each room by list index
---@param roomsMap Rev.RoomMap
---@return Rev.RoomConnectionsMap
function REVEL.GetRoomConnections(roomsMap)
    local roomConnections = {}
    
    for x=1, 13 do
        for y=1, 13 do
            local listIndex = roomsMap[x][y]
            
            if listIndex then
                roomConnections[listIndex] = roomConnections[listIndex] or {}
                
                local checkIndices = {{X=x-1,Y=y}, {X=x,Y=y-1}, {X=x+1,Y=y}, {X=x,Y=y+1}}
                for i=1, 4 do
                    local connectedListIndex = roomsMap[checkIndices[i].X][checkIndices[i].Y]
                    
                    if connectedListIndex and connectedListIndex ~= listIndex then
                        table.insert(roomConnections[listIndex], connectedListIndex)
                    end
                end
            end
        end
    end
    
    return roomConnections
end

-- returns a lookup table that gives a distance in rooms for each list index
---@param roomConnections Rev.RoomConnectionsMap
---@param targetListIndex ListIndex
---@param listIndicesToIgnore? ListIndex[]
---@return table<ListIndex, integer>
function REVEL.GetRoomPathingDistances(roomConnections, targetListIndex, listIndicesToIgnore)
    local roomDistances = {[targetListIndex] = 0}
    local currentCheckListIndices = {targetListIndex}
    
    local distance = 0
    while currentCheckListIndices[1] do
        distance = distance + 1
        
        local nextCheckListIndices = {}
        for _,listIndex in ipairs(currentCheckListIndices) do
            for _,connectedListIndex in ipairs(roomConnections[listIndex]) do
                
                if not roomDistances[connectedListIndex] then
                    local shouldIgnore = false
                    if listIndicesToIgnore then
                        for _,ignoredListIndex in ipairs(listIndicesToIgnore) do
                            if connectedListIndex == ignoredListIndex then
                                shouldIgnore = true
                                break
                            end
                        end
                    end
                    
                    if not shouldIgnore then
                        roomDistances[connectedListIndex] = distance
                        table.insert(nextCheckListIndices, connectedListIndex)
                    end
                end
            end
        end
        
        currentCheckListIndices = nextCheckListIndices
    end
    
    return roomDistances
end

function REVEL.SplitCustomGenRoom(levelRoom, onlyL)
    if #levelRoom.MapSegments > 1 and (not onlyL or #levelRoom.MapSegments == 3) then
        local topLeftIndex = (levelRoom.Shape == RoomShape.ROOMSHAPE_LBR) and levelRoom.SafeGridIndex - 1 or levelRoom.SafeGridIndex

        local out = {}
        for i, seg in ipairs(levelRoom.MapSegments) do
            local grIndex = StageAPI.VectorToGrid(seg.X, seg.Y, 13)
            local segRoom = {
                X = seg.X,
                Y = seg.Y,
                StartingRoom = levelRoom.StartingRoom,
                Shape = RoomShape.ROOMSHAPE_1x1,
                GridIndex = grIndex,
                SafeGridIndex = grIndex,
                ExtraRoomName = levelRoom.ExtraRoomName,
                --Doors = {}, --to be filled by StageAPI.SetLevelMapDoors
            }

            out[#out + 1] = segRoom
        end

        return out
    else
        return {levelRoom}
    end
end

function REVEL.SplitAllCustomMapRooms()
    local newLevelMap = {}
    for _, levelRoom in ipairs(StageAPI.CurrentLevelMap) do
        local split = REVEL.SplitCustomGenRoom(levelRoom, true)
        for __, splitRoom in ipairs(split) do
            --convert closets to 1x1
            if REVEL.includes({RoomShape.ROOMSHAPE_IH, RoomShape.ROOMSHAPE_IV}, splitRoom.Shape) then
                splitRoom.Shape = RoomShape.ROOMSHAPE_1x1
            end

            newLevelMap[#newLevelMap + 1] = splitRoom
        end
    end
    StageAPI.UpdateLevelMap(newLevelMap, nil, true)
end


end