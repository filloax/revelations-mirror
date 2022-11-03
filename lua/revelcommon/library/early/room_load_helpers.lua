-- Different loading as these definitions need to already be there when the mod starts loading

------------------------
-- ROOM HELPER FUNCTIONS
------------------------

local disabledEntities = {}
local highWeightEntities = {}

--The REVEL.Rooms and REVEL.RoomLists tables get further processed in REVEL.LoadRevel()
function REVEL.AddRoomsTable(rooms, listKey, roomsKey, roomsGroupName, setWeight)
    if setWeight then
        for _, room in ipairs(rooms) do
            room.WEIGHT = setWeight
        end
    end

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

function REVEL.ModifyRoomsWithEntities(rooms)
    local newRooms = {}
    for _, room in ipairs(rooms) do
        local isDisabled
        for _, object in ipairs(room) do
            for _, entData in ipairs(object) do
                for _, ent in ipairs(disabledEntities) do
                    local id, variant
                    if type(ent) == "string" then
                        id, variant = Isaac.GetEntityTypeByName(ent), Isaac.GetEntityVariantByName(ent)
                    else
                        id, variant = ent.Type, ent.Variant
                    end

                    if entData.TYPE == id and entData.VARIANT == variant then
                        isDisabled = true
                    end
                end

                if isDisabled then
                    break
                end

                for _, ent in ipairs(highWeightEntities) do
                    local id, variant
                    if type(ent) == "string" then
                        id, variant = Isaac.GetEntityTypeByName(ent), Isaac.GetEntityVariantByName(ent)
                    else
                        id, variant = ent.Type, ent.Variant
                    end

                    if entData.TYPE == id and entData.VARIANT == variant then
                        room.WEIGHT = 1000
                    end
                end
            end

            if isDisabled then
                break
            end
        end

        if not isDisabled then
            newRooms[#newRooms + 1] = room
        end
    end

    return newRooms
end

function REVEL.GetRoomsIfExistent(roomsFileName, prefix)
    prefix = prefix or "resources.luarooms."
    roomsFileName = prefix .. roomsFileName

    local roomsExist, rooms = pcall(require, roomsFileName)

    if roomsExist then
        if #disabledEntities > 0 or #highWeightEntities > 0 then
            rooms = REVEL.ModifyRoomsWithEntities(rooms)
        end

        return rooms
    end
end

function REVEL.AddRoomsIfPossible(listKey, roomsKey, roomsGroupName, roomsFileName, setWeight, prefix)
    local rooms = REVEL.GetRoomsIfExistent(roomsFileName, prefix)
    if rooms then
        return REVEL.AddRoomsTable(rooms, listKey, roomsKey, roomsGroupName, setWeight)
    end
end

-- REVEL.SimpleAddRoomsSet("Glacier", "Glacier", nil, "glacier_", {"Blorenge", "Koala", "Melon"}, {"Test"})
function REVEL.SimpleAddRoomsSet(listKey, roomsKeyPrefix, groupNamePrefix, fileNamePrefix, editors, testEditors, fileNamePrePrefix)
    groupNamePrefix = groupNamePrefix or ""
    for _, editor in ipairs(editors) do
        REVEL.AddRoomsIfPossible(listKey, roomsKeyPrefix .. editor, groupNamePrefix .. editor, fileNamePrefix .. string.lower(editor), nil, fileNamePrePrefix)
    end

    for _, editor in ipairs(testEditors) do
        REVEL.AddRoomsIfPossible(listKey, roomsKeyPrefix .. editor, groupNamePrefix .. editor, fileNamePrefix .. string.lower(editor), 1000, fileNamePrePrefix)
    end
end

function REVEL.ProcessIndividualBossData(boss)
    if StageAPI.RoomsLists[boss.ListName] then
        boss.Rooms = StageAPI.RoomsLists[boss.ListName]
    elseif boss.Entity then
        boss.Rooms = StageAPI.CreateSingleEntityRoomList(boss.Entity.Type or 20, boss.Entity.Variant or 0, boss.Entity.SubType or 0, boss.Entity.Name or "Placeholder", RoomType.ROOM_BOSS, boss.Entity.Name or "Placeholder")
    end

    boss.RoomPrefix = nil
    -- boss.Entity = nil
    return StageAPI.AddBossData(boss.Name, boss)
end

function REVEL.ProcessBossData(bossDataList) -- followup to PreloadBossRooms, after StageAPI has been loaded. in main just to be next to PreloadBossRooms.
    local outBossData = {}
    for _, boss in ipairs(bossDataList) do
        if not boss.NoStageAPI then
            outBossData[#outBossData + 1] = REVEL.ProcessIndividualBossData(boss)
        end
    end

    return outBossData
end

function REVEL.AddBossRooms(bossKey, floorPrefix, prefix, editors)
    if not REVEL.UnsplitBosses then
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
