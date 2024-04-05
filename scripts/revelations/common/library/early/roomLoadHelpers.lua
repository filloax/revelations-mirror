---Room loading functions. Defined early as they are used in the preinit scripts.
---Handles loading a bunch of room editor files into a single RoomsLists table, which
---will be created with passed arguments.
---
---Note that the tables created with these functions are further processed in REVEL.LoadRevel(),
---in `main.lua`.
---
---Initially during file loading rooms are placed into `REVEL.Rooms`, keyed by room file name
---(so, still divided by author), in a table such as this:
---
---```Lua
---REVEL.Rooms[roomsKey] = {
---    Name = roomsGroupName,
---    Rooms = {<list of room layouts>}
---}
---```
---
---At this time, `REVEL.RoomLists` contains for each room set (so, for example, "Glacier") 
---only the list of keys to REVEL.Rooms that the list includes, for example
---"GlacierMario", "GlacierLuigi", etc.
---
---Then, in main.lua, the REVEL.RoomLists entries are converted to StageAPI RoomsLists, 
---by adding the rooms contained in the referenced `REVEL.Rooms` entries.
---
---Rooms can be filtered with [REVEL.FilteringAddRoomsSet], which places each room
---in a REVEL.Rooms and REVEL.RoomLists list depending on the filter return value.

------------------------
-- ROOM HELPER FUNCTIONS
------------------------

local DisabledEntities = {}
local HighWeightEntities = {}

---@param rooms RoomLayout[]
---@param listKey string | string[]
---@return boolean
local function RegisterRoomsTable(rooms, listKey, roomsKey, roomsGroupName)
    if not REVEL.Rooms then
        REVEL.Rooms = {}
    end

    if not REVEL.RoomLists then
        REVEL.RoomLists = {}
    end


    if not REVEL.Rooms[roomsKey] or not REVEL.Rooms[roomsKey].Rooms then
        REVEL.Rooms[roomsKey] = {
            Name = roomsGroupName,
            Rooms = {}
        }
    end

    for _, room in ipairs(rooms) do
        table.insert(REVEL.Rooms[roomsKey].Rooms, room)
    end

    if type(listKey) ~= "table" then
        listKey = {listKey}
    end

    for _, key in ipairs(listKey) do
        if not REVEL.RoomLists[key] then
            REVEL.RoomLists[key] = {}
        end

        local hasRooms = REVEL.includes(REVEL.RoomLists[key], roomsKey)

        if not hasRooms then
            table.insert(REVEL.RoomLists[key], roomsKey)
        end
    end

    return true
end

--The REVEL.Rooms and REVEL.RoomLists tables get further processed in REVEL.LoadRevel()
---@param rooms table[]|RoomLayout[]
---@param listKey string | string[] | (fun(room: RoomLayout): (string|string[])?)
---@return boolean
local function AddRoomsTable(rooms, listKey, roomsKey, roomsGroupName, setWeight)
    ---@type RoomLayout[]
    local formattedRooms = {}
    for _, room in ipairs(rooms) do
        if room.PreSimplified then
            formattedRooms[#formattedRooms+1] = room
        else
            formattedRooms[#formattedRooms+1] = StageAPI.SimplifyRoomLayout(room)
        end
    end

    if setWeight then
        for _, room in ipairs(formattedRooms) do
            room.Weight = setWeight
        end
    end

    if type(listKey) ~= "function" then
        return RegisterRoomsTable(formattedRooms, listKey, roomsKey, roomsGroupName)
    else
        local filter = listKey
        local groups = {}
        for _, room in ipairs(formattedRooms) do
            local filterOut = filter(room)
            if type(filterOut) == "table" then
                for _, listKeyF in ipairs(filterOut) do
                    if not groups[listKeyF] then groups[listKeyF] = {} end
                    table.insert(groups[listKeyF], room)
                end
            elseif type(filterOut) == "string" then
                if not groups[filterOut] then groups[filterOut] = {} end
                table.insert(groups[filterOut], room)
            end
        end

        local allSuccess = true

        for groupName, group in pairs(groups) do
            local success = RegisterRoomsTable(
                group, groupName, 
                roomsKey and (roomsKey .. groupName),
                roomsGroupName and (roomsGroupName .. groupName)
            )
            allSuccess = allSuccess and success
        end

        return allSuccess
    end
end

---@param rooms table[] Loaded from room layout
---@return RoomLayout[] # Pre-simplified
local function ModifyRoomsWithEntities(rooms)
    local newRooms = {}
    for _, room in ipairs(rooms) do
        local newRoom = StageAPI.SimplifyRoomLayout(room)
        local isDisabled

        for _, entData in ipairs(newRoom.Entities) do
            for _, ent in ipairs(DisabledEntities) do
                local id, variant
                if type(ent) == "string" then
                    id, variant = Isaac.GetEntityTypeByName(ent), Isaac.GetEntityVariantByName(ent)
                else
                    id, variant = ent.Type, ent.Variant
                end

                if entData.Type == id and entData.Variant == variant then
                    isDisabled = true
                end
            end

            if isDisabled then
                break
            end

            for _, ent in ipairs(HighWeightEntities) do
                local id, variant
                if type(ent) == "string" then
                    id, variant = Isaac.GetEntityTypeByName(ent), Isaac.GetEntityVariantByName(ent)
                else
                    id, variant = ent.Type, ent.Variant
                end

                if entData.Type == id and entData.Variant == variant then
                    newRoom.Weight = 1000
                end
            end
        end

        if not isDisabled then
            newRooms[#newRooms + 1] = newRoom
        end
    end

    return newRooms
end

---@param roomsFileName string
---@param prefix? string
---@return (table[]|RoomLayout[])?
function REVEL.GetRoomsIfExistent(roomsFileName, prefix)
    prefix = prefix or "resources.luarooms."
    roomsFileName = prefix .. roomsFileName

    -- rooms here is a loaded room layout (so, not simplified aka following the user-facing stageapi structure)
    local roomsExist, rooms = pcall(require, roomsFileName)

    if roomsExist then
        if #DisabledEntities > 0 or #HighWeightEntities > 0 then
            rooms = ModifyRoomsWithEntities(rooms)
        end

        return rooms
    else
        ---@cast rooms string
        if not rooms:find("not found") then
            error("REVEL ROOM LOAD ERROR: " .. tostring(rooms))
        end
    end
end

---Adds rooms to REVEL.Rooms and registers table in REVEL.RoomLists
---if the specified file exists.
---
---Allows passing a filter function instead of a static listKey
---to split into more room lists (see [REVEL.FilteringAddRoomsSet]).
---@param listKey string | string[] | (fun(room: RoomLayout): (string|string[])?)
---@param roomsKey string
---@param roomsGroupName string
---@param roomsFileName string
---@param setWeight? integer
---@param prefix? string
---@return boolean
function REVEL.AddRoomsIfPossible(listKey, roomsKey, roomsGroupName, roomsFileName, setWeight, prefix)
    local rooms = REVEL.GetRoomsIfExistent(roomsFileName, prefix)
    if rooms then
        return AddRoomsTable(rooms, listKey, roomsKey, roomsGroupName, setWeight)
    end
    return false
end

---Example: REVEL.SimpleAddRoomsSet("Glacier", "Glacier", nil, "glacier_", {"Blorenge", "Koala", "Melon"}, {"Test"})
---@param listKey string | string[]
---@param roomsKeyPrefix string
---@param groupNamePrefix? string
---@param fileNamePrefix string
---@param editors string[]
---@param testEditors string[]
---@param fileNamePrePrefix? string
function REVEL.SimpleAddRoomsSet(listKey, roomsKeyPrefix, groupNamePrefix, fileNamePrefix, editors, testEditors, fileNamePrePrefix)
    groupNamePrefix = groupNamePrefix or ""
    for _, editor in ipairs(editors) do
        REVEL.AddRoomsIfPossible(listKey, roomsKeyPrefix .. editor, groupNamePrefix .. editor, fileNamePrefix .. string.lower(editor), nil, fileNamePrePrefix)
    end

    for _, editor in ipairs(testEditors) do
        REVEL.AddRoomsIfPossible(listKey, roomsKeyPrefix .. editor, groupNamePrefix .. editor, fileNamePrefix .. string.lower(editor), 1000, fileNamePrePrefix)
    end
end

---Adds rooms, allowing to place them in various room lists depending on
---the value returned by filter. Return nil with filter to not add a specific room.
---@param filter (fun(room: RoomLayout): (string|string[])?)
---@param roomsKeyPrefix string
---@param groupNamePrefix? string
---@param fileNamePrefix string
---@param editors string[]
---@param testEditors string[]
---@param fileNamePrePrefix? string
function REVEL.FilteringAddRoomsSet(
    filter, roomsKeyPrefix, groupNamePrefix, fileNamePrefix, 
    editors, testEditors, fileNamePrePrefix
)
    groupNamePrefix = groupNamePrefix or ""
    for _, editor in ipairs(editors) do
        REVEL.AddRoomsIfPossible(filter, roomsKeyPrefix .. editor, groupNamePrefix .. editor, fileNamePrefix .. string.lower(editor), nil, fileNamePrePrefix)
    end

    for _, editor in ipairs(testEditors) do
        REVEL.AddRoomsIfPossible(filter, roomsKeyPrefix .. editor, groupNamePrefix .. editor, fileNamePrefix .. string.lower(editor), 1000, fileNamePrePrefix)
    end
end

---@param boss Rev.BossEntry
---@return string
local function ProcessIndividualBossData(boss)
    if StageAPI.RoomsLists[boss.ListName] then
        boss.Rooms = StageAPI.RoomsLists[boss.ListName]
    elseif boss.Entity then
        boss.Rooms = StageAPI.CreateSingleEntityRoomList(boss.Entity.Type or 20, boss.Entity.Variant or 0, boss.Entity.SubType or 0, boss.Entity.Name or "Placeholder", RoomType.ROOM_BOSS, boss.Entity.Name or "Placeholder")
    end

    boss.RoomPrefix = nil
    -- boss.Entity = nil
    return StageAPI.AddBossData(boss.Name, boss)
end

---Adds bosses to StageAPI, returns registered IDs.
---@param bossDataList Rev.BossEntry[]
---@return string[]
function REVEL.ProcessBossData(bossDataList) -- followup to PreloadBossRooms, after StageAPI has been loaded. in main just to be next to PreloadBossRooms.
    local outBossData = {}
    for _, boss in ipairs(bossDataList) do
        if not boss.NoStageAPI then
            outBossData[#outBossData + 1] = ProcessIndividualBossData(boss)
        end
    end

    return outBossData
end

---@param bossKey string
---@param floorPrefix string
---@param prefix string
---@param editors string[]
function REVEL.AddBossRooms(bossKey, floorPrefix, prefix, editors)
    if not REVEL.UnsplitBosses then
        ---@type table<string, table[]>
        REVEL.UnsplitBosses = {}
    end

    local files = {}
    for _, editor in ipairs(editors) do
        table.insert(files, { editor, prefix .. string.lower(editor) })
        table.insert(files, { editor, prefix .. floorPrefix .. '_bosses_' .. string.lower(editor) })
    end

    for _, boss in ipairs(REVEL.Bosses[bossKey]) do
        if not boss.NoStageAPI then
            for _, editor in ipairs(REVEL.RoomEditors) do
                table.insert(files, { editor, prefix .. boss.FilePrefix .. string.lower(editor) })
            end
        end
    end

    for _, entry in ipairs(files) do
        if not REVEL.UnsplitBosses[bossKey] then
            REVEL.UnsplitBosses[bossKey] = {}
        end

        local editor, file = table.unpack(entry)
        local rooms = REVEL.GetRoomsIfExistent(file)

        if rooms then
            REVEL.forEach(rooms, function(room) room.RoomFilename = editor end)
            table.insert(REVEL.UnsplitBosses[bossKey], rooms)
        end
    end
end

---Adds sin rooms from the files. Note that they must use the Miniboss room type.
---@param listName string
---@param prefix string
---@param editors string[]
function REVEL.AddSinRooms(listName, prefix, editors)
    if not REVEL.UnsplitSins then
        REVEL.UnsplitSins = {}
    end

    if not REVEL.UnsplitSins[listName] then
        REVEL.UnsplitSins[listName] = {}
    end

    local files = {}
    for _, editor in ipairs(editors) do
        table.insert(files, { editor, prefix .. string.lower(editor) })
    end

    for _, sin in ipairs(REVEL.SinFilenames) do
        for _, editor in ipairs(editors) do
            table.insert(files, { editor, prefix .. sin .. string.lower(editor) })
        end
    end

    for _, entry in ipairs(files) do
        local editor, file = table.unpack(entry)

        local rooms = REVEL.GetRoomsIfExistent(file)
        if rooms then
            table.insert(REVEL.UnsplitSins[listName], REVEL.filter(rooms, function(room)
                if room.TYPE ~= RoomType.ROOM_MINIBOSS then
                    REVEL.DebugLog('Could not use sin room, must be miniboss room!',
                                    file, '->', room.NAME, '(id ' .. room.VARIANT .. ')')
                    return false
                end

                room.RoomFilename = editor
                return true
            end))
        end
    end
end

---@param entName string
---@param fallbackRoomName? string
---@param subType? integer
---@param ignoreVariant? boolean
---@return {Type: integer, FallbackRoomName: string, SubType: integer?, Name: string}
function REVEL.GetBossEntityData(entName, fallbackRoomName, subType, ignoreVariant) -- preinit runs before definitions are loaded, so its necessary to get the relevant entity types from name.
    fallbackRoomName = fallbackRoomName or entName .. " Placeholder"
    local entityData = {
        Type = Isaac.GetEntityTypeByName(entName),
        FallbackRoomName = fallbackRoomName,
        SubType = subType,
        Name = entName
    }

    if not ignoreVariant then
        entityData.Variant = Isaac.GetEntityVariantByName(entName)
    end

    return entityData
end
