-- Minimap persistence and switching, adapted from
-- Dante & Charon code to separately track cleared rooms
local Minimap = {}

---@class MapRoomDisplayData
---@field DisplayFlags integer
---@field Visited boolean # Only used with MinimapAPI as vanilla can have weird interactions with other mods
---@field ItemIcons string[] # Used by MinimapAPI
---@field Clear boolean # Used for display, instead of actual clear state

function Minimap.LoadFunction()

---Stores minimap data to be later loaded with [Minimap.LoadMinimapData]
---@param id string
---@return table<integer, MapRoomDisplayData> savedData
function Minimap.StoreMinimapData(id)
    local data = Minimap.GetCurrentLevelRoomsDisplayData()
    revel.data.run.level.minimapData[id] = data
    REVEL.DebugStringMinor("Stored minimap data:", id)
    return data
end

---Load saved minimap data with an id.
--
-- Needs to be done just before entering a room to properly update the minimap.
-- Will affect room descriptors, specifically DisplayFlags.
---@param id string
---@param updateVisibility? boolean If true (default), update level visibility after (set to false if you do it later for some reason)
---@param merge? boolean If true, OR the visited, clear and display flags
---@param blankIfEmpty? boolean If true (default), will reset the map data if no data for that ID is saved
function Minimap.LoadMinimapData(id, updateVisibility, merge, blankIfEmpty)
    local data = revel.data.run.level.minimapData[id]

    if data then
        REVEL.DebugStringMinor("Loading minimap data:", id)
        Minimap.SetLevelRoomsDisplayData(data, merge)
    elseif blankIfEmpty ~= false then
        REVEL.DebugStringMinor("Loading minimap data:", id, "| blank, resetting")
        Minimap.ResetLevelRoomsDisplayData()
    end

    if updateVisibility ~= false then
        REVEL.level:UpdateVisibility()
    end
end

---Loads Minimap data previously stored with [Minimap.StoreMinimapData]
---@param id string
---@return table<integer, MapRoomDisplayData>?
function Minimap.GetMinimapData(id)
    return revel.data.run.level.minimapData[id]
end

---Get the a table with MapRoomDisplayData for each level room descriptor,
-- containing in each the information that affects minimap room rendering.
--
-- Make sure serialization can handle integer IDs as this table is indexed
-- by integers.
---@return table<integer, MapRoomDisplayData>
function Minimap.GetCurrentLevelRoomsDisplayData()
    local rooms = REVEL.level:GetRooms()
    local out = {}

    for idx = 0, rooms.Size - 1 do
        -- doesn't need to be editable
        local constDesc = rooms:Get(idx)
        ---@type MinimapAPI.Room
        local mroom = MinimapAPI and MinimapAPI:GetRoomByIdx(constDesc.GridIndex)

        local data = {
            DisplayFlags = constDesc.DisplayFlags,
            -- Original dante code did the following
            -- Clear = not not revel.data.run.level.dante.RoomClearData.Current[idx],
            -- Likely because directly using room is clear lead to 
            -- weird interactions when switching? Check later if this is the case, 
            -- use is clear for now
            Clear = constDesc.Clear,
            VisitedCount = mroom and mroom.Visited,
            ItemIcons = mroom and mroom.ItemIcons
        }
        out[idx] = data
    end

    return out
end

---Modify the display data of a single room (as indicated by its RoomDescriptor), 
-- changing how it looks in the Minimap.
---@param desc RoomDescriptor
---@param data MapRoomDisplayData
---@param merge? boolean If true, icons and clear status will be OR-ed, and visit counts will be summed, instead of replacing values
local function SetSingleRoomDisplayData(desc, data, merge)
    -- For some reason setting VisitedCount and then reentering the starting room as Charon
    -- in custom floors makes stageapi forget you are in a custom floor, so to say
    if not desc then return end
    
    if merge then
        desc.DisplayFlags = BitOr(data.DisplayFlags, desc.DisplayFlags)
    else
        desc.DisplayFlags = data.DisplayFlags
    end

    if MinimapAPI then
        ---@type MinimapAPI.Room
        local mroom = MinimapAPI:GetRoomByIdx(desc.GridIndex)

        if mroom then
            mroom:SetDisplayFlags(desc.DisplayFlags)

            if merge then
                for _, icon in ipairs(data.ItemIcons) do
                    if not REVEL.includes(mroom.ItemIcons, icon) then
                        table.insert(mroom.ItemIcons, icon)
                    end
                end
                mroom.Clear = mroom.Clear or data.Clear
                mroom.Visited = data.Visited or mroom.Visited
            else
                mroom.ItemIcons = REVEL.CopyTable(data.ItemIcons)
                mroom.Clear = data.Clear
                mroom.Visited = data.Visited
            end
        end
    end
end

--
-- revelations/scripts/revelations/**,revelations/main.lua
--

---Update the display data for all rooms in the level with the passed roomsData table,
-- which will affect the minimap rendering for all the affected room list indices.
--
-- Needs to be done just before entering a room to properly update the minimap.
-- Will affect room descriptors, specifically DisplayFlags.
---@param roomsData table<integer, MapRoomDisplayData> Indexed by level roomdescriptor ListIndex
---@param merge? boolean If true, icons and clear status will be OR-ed, and visit counts will be summed, instead of replacing values
function Minimap.SetLevelRoomsDisplayData(roomsData, merge)
    REVEL.DebugStringMinor("Dante | Ran SetLevelRoomDisplayData (merge: " .. tostring(not not merge) .. ")")

    for idx = 0, REVEL.level:GetRoomCount() - 1 do
        local data = roomsData[idx]
        if data then
            local desc = REVEL.GetRoomDescByListIdx(idx)
            -- needs to be editable
            SetSingleRoomDisplayData(desc, data, merge)
        end
    end
end

---@type MapRoomDisplayData
local ResetDisplayData = REVEL.ImmutableTable {
    DisplayFlags = 0,
    Clear = false,
    Visited = false,
    ItemIcons = {},
}

---@return MapRoomDisplayData
function Minimap.CreateBlankDisplayData()
    return REVEL.CopyTable(ResetDisplayData)
end

---@return table<integer, MapRoomDisplayData>
function Minimap.CreateBlankLevelDisplayData()
    local rooms = REVEL.level:GetRooms()
    local out = {}

    for idx = 0, rooms.Size - 1 do
        out[idx] = Minimap.CreateBlankDisplayData()
    end

    return out
end

---Sets all rooms to hidden.
-- 
-- If done before entering room
-- will then set that room as visited and close ones as visible
-- as normal
function Minimap.ResetLevelRoomsDisplayData()
    REVEL.DebugStringMinor("Dante | Ran ResetLevelRoomDisplayData")

    local roomsSize = REVEL.level:GetRoomCount()

    for idx = 0, roomsSize - 1 do
        local desc = REVEL.GetRoomDescByListIdx(idx)
        SetSingleRoomDisplayData(desc, ResetDisplayData)
    end
end


---For debug; prints the level's room display data in the log
---@param useData? table<string, MapRoomDisplayData>
function Minimap.PrintMapDisplayData(useData)
    useData = useData or Minimap.GetCurrentLevelRoomsDisplayData()

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
                str1 = tostring(useData[idx].DisplayFlags)
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
                str1 = useData[idx].Clear and "X" or "o"
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

end

return Minimap