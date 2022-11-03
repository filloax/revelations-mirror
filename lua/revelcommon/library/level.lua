local Dimension = require "lua.revelcommon.enums.Dimension"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()


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

end

REVEL.PcallWorkaroundBreakFunction()