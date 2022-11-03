local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local GlacierOneNoElites = true

function REVEL.GetRoomsNecessaryToReachBoss()
    local lastBoss = REVEL.level:GetLastBossRoomListIndex()
    local map = REVEL.GetPathMapToRoomIndex(lastBoss)
    if not map then return end

    local checkIndices = {REVEL.level:GetStartingRoomIndex()}
    local checkedIndices = {}

    local onPotentialRoutes = {}


    while #checkIndices > 0 do
        local index = checkIndices[#checkIndices]
        checkedIndices[index] = true
        checkIndices[#checkIndices] = nil
        local adjacent = {
            index + 1,
            index - 1,
            index + REVEL.LevelPathMapNoSecret.Width,
            index - REVEL.LevelPathMapNoSecret.Width
        }

        local indValue = map[index]
        for _, adj in ipairs(adjacent) do
            if map[adj] and not checkedIndices[adj] then
                if map[adj] < indValue then
                    onPotentialRoutes[#onPotentialRoutes + 1] = adj
                    checkIndices[#checkIndices + 1] = adj
                end

                checkedIndices[adj] = true
            end
        end
    end

    local indicesOnRouteWithUniqueDistance, keyed = {}, {}
    for _, index in ipairs(onPotentialRoutes) do
        local sharesDistance
        for _, ind2 in ipairs(onPotentialRoutes) do
            if index ~= ind2 and map[index] == map[ind2] then
                sharesDistance = true
                break
            end
        end

        if not sharesDistance then
            keyed[index] = true
            indicesOnRouteWithUniqueDistance[#indicesOnRouteWithUniqueDistance + 1] = {Index = index, Distance = map[index]}
        end
    end

    return indicesOnRouteWithUniqueDistance, keyed
end

function REVEL.GetValidEliteShapes()
    local elites
    if REVEL.STAGE.Glacier:IsStage() then
        elites = REVEL.GlacierElites
    elseif REVEL.STAGE.Tomb:IsStage() then
        elites = REVEL.TombElites
    end

    if elites and #elites > 0 then
        local validShapes = {}
        for _, boss in ipairs(elites) do
            local bdata = StageAPI.GetBossData(boss)
            local shapes = bdata.Shapes or bdata.Rooms.Shapes
            if shapes then
                REVEL.extend(validShapes, table.unpack(shapes))
            end
        end

        return validShapes
    end
end

function REVEL.RoomDescIsValidElite(roomDesc, validShapes)
    if REVEL.includes(validShapes, roomDesc.Data.Shape) and roomDesc.Data.Type == RoomType.ROOM_DEFAULT then
        local slots = REVEL.toSet(REVEL.GetRoomDescDoorSlots(roomDesc))

        local success, usingElites = false, (REVEL.STAGE.Glacier:IsStage() and REVEL.GlacierElites) or (REVEL.STAGE.Tomb:IsStage() and REVEL.TombElites)

        for _, elite in ipairs(usingElites) do
            local bossData = StageAPI.GetBossData(elite)
            local rooms = bossData.Rooms.ByShape[roomDesc.Data.Shape]

            -- temporary but not hurtful, to check for an error that happened
            -- sometimes and otherwise hard to debug
            if not rooms then
                REVEL.DebugToString("Elite doesn't have rooms for shape", elite, roomDesc.Data.Shape, REVEL.getKeyFromValue(RoomShape, roomDesc.Data.Shape))
            else
                for _, layout in ipairs(rooms) do
                    if StageAPI.DoLayoutDoorsMatch(layout, slots) then
                        success = true
                        break
                    end
                end
            end


            if success then
                break
            end
        end

        return success
    end
end

local eliteSpawnRNG = REVEL.RNG()
revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function() -- Figure out which room should be an elite room
    if (REVEL.STAGE.Glacier:IsStage() and not revel.data.run.eliteEncountered.glacier) 
    or (REVEL.STAGE.Tomb:IsStage() and not revel.data.run.eliteEncountered.tomb) then
        local validShapes = REVEL.GetValidEliteShapes()

        eliteSpawnRNG:SetSeed(REVEL.level:GetDungeonPlacementSeed(), 0)

        local valid
        if GlacierOneNoElites then
            valid = StageAPI.Random(1, 3, eliteSpawnRNG) 
                and not (REVEL.STAGE.Glacier:IsStage() 
                    and (not StageAPI.GetCurrentStage().IsSecondStage 
                        or HasBit(REVEL.level:GetCurses(), LevelCurse.CURSE_OF_LABYRINTH)))
        else
            valid = StageAPI.Random(1, 3, eliteSpawnRNG) -- or StageAPI.GetCurrentStage().IsSecondStage
        end

        if valid then
            local necessaryRoomIndices = REVEL.GetRoomsNecessaryToReachBoss()
            local farthestValidRoom
            local eliteRoom
            for _, index in ipairs(necessaryRoomIndices) do
                local roomDesc = REVEL.level:GetRoomByIdx(index.Index)
                -- REVEL.DebugToString(index, REVEL.includes(validShapes, roomDesc.Data.Shape), farthestValidRoom)
                if roomDesc and REVEL.RoomDescIsValidElite(roomDesc, validShapes) then
                    if not farthestValidRoom or farthestValidRoom.Distance < index.Distance then
                        farthestValidRoom = index
                        eliteRoom = roomDesc
                    end
                end
            end

            if farthestValidRoom then
                revel.data.run.level.eliteRoomIndex = farthestValidRoom.Index
                -- REVEL.DebugToString("Found normally")
            else
                -- REVEL.DebugToString("Valid:", validShapes)
                local validRooms = REVEL.GetMatchingRoomDescs(function(roomDesc)
                    return REVEL.RoomDescIsValidElite(roomDesc, validShapes)
                end)
                if #validRooms > 0 then
                    eliteRoom = validRooms[StageAPI.Random(1, #validRooms, eliteSpawnRNG)]
                    revel.data.run.level.eliteRoomIndex = eliteRoom.GridIndex
                    -- REVEL.PrintLevelMap()
                else
                    -- REVEL.DebugToString("Not found!")
                end
            end

            if eliteRoom then
                if REVEL.DEBUG then
                    REVEL.DebugToString("Elite room at:", revel.data.run.level.eliteRoomIndex)
                end

                if MinimapAPI then
                    local pos = Vector(eliteRoom.SafeGridIndex % 13, math.floor(eliteRoom.SafeGridIndex / 13))
                    local mroom = MinimapAPI:GetRoomAtPosition(pos)
                    if mroom then
                        table.insert(mroom.PermanentIcons, "Miniboss")
                        if not REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_COMPASS) then
                            mroom.DisplayFlags = BitAnd(mroom.DisplayFlags, tonumber("011", 2))
                            mroom.AdjacentDisplayFlags = BitAnd(mroom.AdjacentDisplayFlags, tonumber("011", 2))
                        end
                        -- REVEL.DebugToString("Added icon")
                    end
                end
            end
        end
    end
end)

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_STAGEAPI_NEW_ROOM_GENERATION, 1, function(currentRoom)
    if (not currentRoom) and (not REVEL.GoingToSinami) and revel.data.run.level.eliteRoomIndex ~= -1 then
        local spawnElite
        local roomDesc = REVEL.level:GetCurrentRoomDesc()
        local eliteRoomDesc = REVEL.level:GetRoomByIdx(revel.data.run.level.eliteRoomIndex)

        if roomDesc.ListIndex == eliteRoomDesc.ListIndex then
            local newRoom, boss
            local unsuccessful, usingElites = true, (REVEL.STAGE.Glacier:IsStage() and REVEL.GlacierElites) or (REVEL.STAGE.Tomb:IsStage() and REVEL.TombElites)

            for _, elite in ipairs(usingElites) do
                local bossData = StageAPI.GetBossData(elite)
                local rooms = bossData.Rooms.ByShape[REVEL.room:GetRoomShape()]
                for _, layout in ipairs(rooms) do
                    if StageAPI.DoLayoutDoorsMatch(layout) then
                        unsuccessful = false
                        break
                    end
                end

                if not unsuccessful then
                    break
                end
            end

            if unsuccessful then
                return
            else
                if REVEL.STAGE.Glacier:IsStage() and REVEL.GlacierElites then
                    newRoom, boss = StageAPI.GenerateBossRoom({Bosses = REVEL.GlacierElites, CheckEncountered = true}, {RoomDescriptor = roomDesc})
                    revel.data.run.eliteEncountered.glacier = true
                elseif REVEL.STAGE.Tomb:IsStage() and REVEL.TombElites then
                    newRoom, boss = StageAPI.GenerateBossRoom({Bosses = REVEL.TombElites, CheckEncountered = true}, {RoomDescriptor = roomDesc})
                    revel.data.run.eliteEncountered.tomb = true
                end

                StageAPI.SetCurrentRoom(newRoom)
                newRoom:Load()

                revel.data.run.level.eliteRoomIndex = -1
                return newRoom, true, boss
            end
        end
    end
end)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_CLEAR, 1, function()
    for elite, data in pairs(REVEL.Elites) do
        if REVEL.IsEliteRoom(elite) then
            REVEL.SpawnEliteReward(Isaac.GetFreeNearPosition(REVEL.room:GetCenterPos(), 0))
        end
    end
end)

local PossibleChestVariants = {
    PickupVariant.PICKUP_CHEST,
    PickupVariant.PICKUP_REDCHEST,
    PickupVariant.PICKUP_BOMBCHEST,
    PickupVariant.PICKUP_LOCKEDCHEST
}

local boneChance = 33
local collectibleChance = 33

local pickupRNG = REVEL.RNG()
function REVEL.SpawnEliteReward(pos)
    pickupRNG:SetSeed(REVEL.room:GetAwardSeed(), 0)

    local heartSubType = 0

    if StageAPI.Random(1, 100, pickupRNG) <= collectibleChance then
        local item = REVEL.pool:GetCollectible(ItemPoolType.POOL_BOSS, true, REVEL.room:GetAwardSeed())
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, item, pos, Vector.Zero, nil)
    else
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PossibleChestVariants[StageAPI.Random(1, #PossibleChestVariants, pickupRNG)], 0, pos, Vector.Zero, nil)
        if StageAPI.Random(1, 100, pickupRNG) <= boneChance then
            heartSubType = HeartSubType.HEART_BONE
        end
    end

    local dir = RandomVector()
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, heartSubType, pos + dir * 5, dir * 2, nil)
end


Isaac.DebugString("Revelations: Loaded Elites!")
end
REVEL.PcallWorkaroundBreakFunction()