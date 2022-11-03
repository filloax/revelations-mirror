local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local Dimension         = require("lua.revelcommon.enums.Dimension")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Charon Map rework, uses MinimapAPI for various features, 
-- mainly forgetting cleared rooms without messing with them
-- too much (lead to unfixable bugs with grids in StageAPI floors)
-- and to remove minimap icons for items

local GetLevelRoomDisplayData
local ResetLevelRoomDisplayData
local SetLevelRoomDisplayData
local GetCurrentClearedRooms

local StopTrackClearedRooms = false

-- If, when playing as D&C, the other character 
-- has cleared this room
function REVEL.Dante.IsOtherRoomCleared(listIndex)
    listIndex = listIndex or StageAPI.GetCurrentRoomID()

    local player = REVEL.player
    if REVEL.IsDanteCharon(player) and not REVEL.Dante.IsMerged(player) then
        return GetCurrentClearedRooms()[tostring(listIndex)]
    end
    return false
end

---@param useData? table<string, DisplayData>
local function PrintMapDisplayData(useData)
    useData = useData or GetLevelRoomDisplayData()

    local a = "\n"
    local maxId
    for i=0, REVEL.level:GetRooms().Size-1 do
        if (not maxId) or REVEL.level:GetRooms():Get(i).GridIndex > maxId then
            maxId = REVEL.level:GetRooms():Get(i).GridIndex
        end
    end

    for y=0, maxId/13 + 1 do
        for x=0, 12 do
            local room = REVEL.level:GetRoomByIdx(x + y*13)
            if room.GridIndex == -1 then room = nil end
            local str1
            if room then
                local idx = room.ListIndex
                str1 = tostring(useData[tostring(idx)].DisplayFlags)
            else
                str1 = ""
            end
            ---@diagnostic disable-next-line: need-check-nil
            a = a..(string.rep(room and " " or "_", 1 - #str1)..str1).." "
        end
        a = a..'\n'
    end

    a = a..'\n'

    for y=0, maxId/13 + 1 do
        for x=0, 12 do
            local room = REVEL.level:GetRoomByIdx(x + y*13)
            if room.GridIndex == -1 then room = nil end
            local str1
            if room then
                local idx = room.ListIndex
                str1 = useData[tostring(idx)].Clear and "X" or "o"
            else
                str1 = ""
            end
            ---@diagnostic disable-next-line: need-check-nil
            a = a..(string.rep(room and " " or "_", 1 - #str1)..str1).." "
        end
        a = a..'\n'
    end
    Isaac.DebugString(a)
end

-- For debug
function REVEL.Dante.PrintMapDisplayData()
    PrintMapDisplayData()
end

function REVEL.Dante.SwitchMap()
    local levelData = revel.data.run.level.dante

    local thisLevelRoomDisplayData = GetLevelRoomDisplayData()
    local currentClearedRooms = levelData.RoomClearData.Current
    -- local newDisplayData
    if REVEL.isEmpty(levelData.OtherRoomDisplayData) then
        ResetLevelRoomDisplayData()
    else
        SetLevelRoomDisplayData(levelData.OtherRoomDisplayData)
    end
    levelData.OtherRoomDisplayData = thisLevelRoomDisplayData
    levelData.RoomClearData.Current = levelData.RoomClearData.Other
    levelData.RoomClearData.Other = currentClearedRooms

    REVEL.level:UpdateVisibility()
    if REVEL.DEBUG then
        REVEL.DebugToString("Dante | Old map display data:")
        PrintMapDisplayData(thisLevelRoomDisplayData)
        REVEL.DebugToString("Dante | New map display data:")
        PrintMapDisplayData()
    end

    StopTrackClearedRooms = true
end

function REVEL.Dante.MergeMap()
    SetLevelRoomDisplayData(revel.data.run.level.dante.OtherRoomDisplayData, true)
    REVEL.level:UpdateVisibility()
end

function GetCurrentClearedRooms()
    return revel.data.run.level.dante.RoomClearData.Current
end

---@class DisplayData
---@field DisplayFlags integer
---@field VisitedCount integer
---@field ItemIcons string[] # Used by MinimapAPI
---@field Clear boolean # Used for display, instead of actual clear state

---@return table<string, DisplayData>
function GetLevelRoomDisplayData()
    local rooms = REVEL.level:GetRooms()
    local out = {}
    local clearedRoomData = GetCurrentClearedRooms()

    for idx = 0, rooms.Size - 1 do
        -- doesn't need to be editable
        local constDesc = rooms:Get(idx)
        ---@type MinimapAPI.Room
        local mroom = MinimapAPI and MinimapAPI:GetRoomByIdx(constDesc.GridIndex)
        local sid = tostring(idx)

        local data = {
            DisplayFlags = constDesc.DisplayFlags,
            Clear = not not clearedRoomData[sid],
            VisitedCount = constDesc.VisitedCount,
            ItemIcons = mroom and mroom.ItemIcons
        }
        out[tostring(idx)] = data
    end

    return out
end

-- For debug
function REVEL.Dante.GetLevelRoomDisplayData()
    return GetLevelRoomDisplayData()
end

---@param desc RoomDescriptor
---@param data DisplayData
---@param merge? boolean
local function SetSingleRoomDisplayData(desc, data, merge)
    -- For some reason setting VisitedCount and then reentering the starting room as Charon
    -- in custom floors makes stageapi forget you are in a custom floor, so to say
    if merge then
        desc.DisplayFlags = BitOr(data.DisplayFlags, desc.DisplayFlags)
        -- desc.VisitedCount = data.VisitedCount + desc.VisitedCount
    else
        desc.DisplayFlags = data.DisplayFlags
        -- desc.VisitedCount = data.VisitedCount
    end

    if MinimapAPI then
        ---@type MinimapAPI.Room
        local mroom = MinimapAPI:GetRoomByIdx(desc.GridIndex)
        
        mroom:SetDisplayFlags(desc.DisplayFlags)
        mroom.Visited = desc.VisitedCount > 0

        if merge then
            for _, icon in ipairs(data.ItemIcons) do
                if not REVEL.includes(mroom.ItemIcons, icon) then
                    table.insert(mroom.ItemIcons, icon)
                end
            end
            mroom.Clear = mroom.Clear or data.Clear
        else
            mroom.ItemIcons = REVEL.CopyTable(data.ItemIcons)
            mroom.Clear = data.Clear
        end
    end
end

-- Needs to be done just before entering a room to properly update the minimap
function SetLevelRoomDisplayData(roomsData, merge)
    REVEL.DebugStringMinor("Dante | Ran SetLevelRoomDisplayData (merge: " .. tostring(not not merge) .. ")")

    for idx = 0, REVEL.level:GetRoomCount() - 1 do
        local data = roomsData[tostring(idx)]
        if data then
            local desc = REVEL.GetRoomDescByListIdx(idx)
            -- needs to be editable
            SetSingleRoomDisplayData(desc, data, merge)
        end
    end
end

---@type DisplayData
local ResetDisplayData = {
    DisplayFlags = 0,
    Clear = false,
    VisitedCount = 0,
    ItemIcons = {},
}

--- Sets all rooms to hidden, if done before entering room
-- will then set that room as visited and close ones as visible
-- as normal
function ResetLevelRoomDisplayData()
    REVEL.DebugStringMinor("Dante | Ran ResetLevelRoomDisplayData")

    local roomsSize = REVEL.level:GetRoomCount()

    for idx = 0, roomsSize - 1 do
        local desc = REVEL.GetRoomDescByListIdx(idx)
        SetSingleRoomDisplayData(desc, ResetDisplayData)
    end
end

function REVEL.Dante.Callbacks.Map_PostNewRoom()
    StopTrackClearedRooms = false
end

---@param player EntityPlayer
function REVEL.Dante.Callbacks.Map_PostUpdate(player)
    if REVEL.Dante.IsMerged(player) or StopTrackClearedRooms then
        return
    end

    local currentTable = GetCurrentClearedRooms()

    local roomId = StageAPI.GetCurrentRoomID()
    local sid = tostring(roomId)
    local wasClear = not not currentTable[sid]
    local clear = REVEL.room:IsClear()

    if wasClear ~= clear then
        currentTable[sid] = clear
        REVEL.DebugStringMinor("Dante | Set room " .. sid .. " to clear state:", clear)
    end
end


end
REVEL.PcallWorkaroundBreakFunction()