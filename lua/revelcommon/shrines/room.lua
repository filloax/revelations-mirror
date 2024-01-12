local StageAPICallbacks = require "lua.revelcommon.enums.StageAPICallbacks"
-- not actually a lua file the mod uses, just an example to copy paste.
return function()

REVEL.ShrineRoomRNG = REVEL.RNG()

local STAGE_2_MAX_ATTEMPTS = 3

-- Maths
-- Source: geometric distribution, P(X <= k) = 1 - (1-p)^k
-- where X attempts for success, p probability of single attempt
-- Calculated with wolfram alpha
local STAGE_1_MAX_ATTEMPTS = 3
local STAGE_2_LOW_VANITY_CHANCE = 1 - 3^(2/3) / 10^(1/3) -- leads to 0.1 total chance
local STAGE_2_HIGH_VANITY_CHANCE = 1 - (1 / 2^(1/STAGE_2_MAX_ATTEMPTS)) -- leads to 0.5 total chance
local HIGH_VANITY = 4

-- Normally true for stage 2 of chapter
local function UseReducedChance()
    local chapter = REVEL.GetStageChapter()
    return revel.data.run.spawnedShrineRoomChapters[chapter]
        and REVEL.IsLastChapterStage() -- use full price if returned to stage 1 somehow
        and not REVEL.IsThereCurse(LevelCurse.CURSE_OF_LABYRINTH)
end

local function IsRoomDescValid(roomDesc, roomList)
    if roomDesc.Data.Type ~= RoomType.ROOM_DEFAULT
    or roomDesc.Data.Shape ~= RoomShape.ROOMSHAPE_1x1 
    then
        return false
    end

    local doors = REVEL.GetDoorsForRoomFromDesc(roomDesc)
    local validDoors = false
    for listID, layout in pairs(roomList.All) do
        if StageAPI.DoLayoutDoorsMatch(layout, doors) then
            validDoors = true
            break
        end
    end
    if not validDoors then
        return false
    end

    return true
end

local function GetNumValidRooms(roomList)
    local rooms = REVEL.level:GetRooms()
    local count = 0
    for i = 0, rooms.Size - 1 do
        local roomDesc = rooms:Get(i)
        if IsRoomDescValid(roomDesc, roomList) then
            count = count + 1
        end
    end
    return count
end

---@param newRoom LevelRoom
---@param roomList RoomsList
---@return boolean
function REVEL.ShrineRoomSpawnCheck(newRoom, roomList)
    if not revel.data.run.level.spawnedShrineRoom
    and not StageAPI.InOrTransitioningToExtraRoom() and not newRoom.IsExtraRoom 
    and IsRoomDescValid(REVEL.level:GetCurrentRoomDesc(), roomList)
    then
        if revel.data.run.level.shrineRoomIndex == -1 then
            REVEL.DebugStringMinor("Is valid room to attempt shrine room check")

            if revel.data.run.level.maxShrineRoomAttempts < 0 then
                revel.data.run.level.maxShrineRoomAttempts 
                    = math.min(GetNumValidRooms(roomList), STAGE_1_MAX_ATTEMPTS)
            end
                
            REVEL.ShrineRoomRNG:SetSeed(newRoom.Seed, 0)

            -- Stage 1: find in one of first 3 valid rooms
            -- Stage 2: 10% chance in first 3 rooms, 50% in first 3 rooms if >= 10 vanity already,
            --          0% chance after first 3 rooms

            local isShrineRoom = false

            if REVEL.DEBUG_SHRINES then
                isShrineRoom = true
            end

            local chapter = REVEL.GetStageChapter()

            if not isShrineRoom then
                -- First stage or came in later
                if not UseReducedChance() then
                    local inverseChance = revel.data.run.level.maxShrineRoomAttempts - revel.data.run.level.shrineRoomSpawnAttempts
                    -- local inverseChance = 1
                    isShrineRoom = StageAPI.Random(1, math.max(1, inverseChance), REVEL.ShrineRoomRNG) == 1
                    REVEL.DebugStringMinor(("shrine room check, chance: %2.2f, success: %s, second: false"):format(1/inverseChance, isShrineRoom))
                elseif revel.data.run.level.shrineRoomSpawnAttempts < STAGE_2_MAX_ATTEMPTS then
                    local chancePerRoom = (REVEL.GetShrineVanity() >= HIGH_VANITY) 
                        and STAGE_2_HIGH_VANITY_CHANCE or STAGE_2_LOW_VANITY_CHANCE
                    
                    isShrineRoom = StageAPI.RandomFloat(0, 1, REVEL.ShrineRoomRNG) < chancePerRoom
                    REVEL.DebugStringMinor(("shrine room check, chance: %2.2f, success: %s, second: true"):format(chancePerRoom, isShrineRoom))
                else
                    return false -- too many attempts for stage 2, quit
                end
            end

            if isShrineRoom then
                local roomsList = REVEL.level:GetRooms()
                for i = 0, roomsList.Size do
                    local roomDesc = roomsList:Get(i)
                    if roomDesc and roomDesc.VisitedCount > 0 then
                        revel.data.run.level.roomsBeforeShrinesTriggered[#revel.data.run.level.roomsBeforeShrinesTriggered + 1] = roomDesc.ListIndex
                    end
                end

                revel.data.run.level.shrineRoomIndex = newRoom.LevelIndex or -1
                revel.data.run.level.spawnedShrineRoom = true
                revel.data.run.spawnedShrineRoomChapters[chapter] = true
                return true
            else
                revel.data.run.level.shrineRoomSpawnAttempts = revel.data.run.level.shrineRoomSpawnAttempts + 1
            end
        else
            return newRoom.LevelIndex == revel.data.run.level.shrineRoomIndex
        end
    end
end

function REVEL.WasRoomSpawnedBeforeShrinesTriggered(newRoom)
    for _, index in ipairs(revel.data.run.level.roomsBeforeShrinesTriggered) do
        if newRoom.LevelIndex == index then
            return true
        end
    end
end

function REVEL.IsShrineRoom()
    local currentRoom = StageAPI.GetCurrentRoom()
    return currentRoom 
        and currentRoom.LevelIndex == revel.data.run.level.shrineRoomIndex
end

local function shrineRoomSpawning_PostUseRKey()
    revel.data.run.spawnedShrineRoomChapters = {}
end

-- Troll bombs trigger pre entity spawn again after getting morphed from a 
-- random pickup, convenient
local function shrineRoom_TrollBombs_PreEntitySpawn(_, type, variant, subtype, pos, vel, spawner, seed)
    if not revel.data.run then return end
    if REVEL.IsShrineRoom()
    and REVEL.room:IsFirstVisit()
    and REVEL.room:GetFrameCount() < 5
    and type == EntityType.ENTITY_BOMB
    and (variant == BombVariant.BOMB_TROLL or variant == BombVariant.BOMB_SUPERTROLL) 
    then
        REVEL.DebugStringMinor("Prevented shrine room troll bomb at", REVEL.room:GetGridIndex(pos))
        return {
            StageAPI.E.DeleteMePickup.T,
            StageAPI.E.DeleteMePickup.V,
            0,
            seed
        }
    end
end

--Lightable fire tutorial room
local tutorialRoomRNG = REVEL.RNG()

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_ROOMS_LIST_USE, 1, function(newRoom)
    if not revel.data.seenLightableFireRoom
    and not StageAPI.InOrTransitioningToExtraRoom() and not newRoom.IsExtraRoom 
    and IsRoomDescValid(REVEL.level:GetCurrentRoomDesc(), REVEL.RoomLists.GlacierLightableFire)
    and REVEL.STAGE.Glacier:IsStage() then
        tutorialRoomRNG:SetSeed(newRoom.Seed, 0)
        if StageAPI.Random(1, 5, tutorialRoomRNG) == 1 then
            revel.data.seenLightableFireRoom = true
            return REVEL.RoomLists.GlacierLightableFire
        end
    end
end)

--Snowman tutorial room

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_ROOMS_LIST_USE, 1, function(newRoom)
    if not revel.data.seenSnowmanRoom
    and not StageAPI.InOrTransitioningToExtraRoom() and not newRoom.IsExtraRoom 
    and IsRoomDescValid(REVEL.level:GetCurrentRoomDesc(), REVEL.RoomLists.GlacierSnowman)
    and REVEL.STAGE.Glacier:IsStage() then
        tutorialRoomRNG:SetSeed(newRoom.Seed, 0)
        if StageAPI.Random(1, 5, tutorialRoomRNG) == 2 then
            revel.data.seenSnowmanRoom = true
            return REVEL.RoomLists.GlacierSnowman
        end
    end
end)

--Dune tutorial room

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_ROOMS_LIST_USE, 1, function(newRoom)
    if not revel.data.seenDuneRoom
    and not StageAPI.InOrTransitioningToExtraRoom() and not newRoom.IsExtraRoom 
    and IsRoomDescValid(REVEL.level:GetCurrentRoomDesc(), REVEL.RoomLists.TombDune)
    and REVEL.STAGE.Tomb:IsStage() then
        tutorialRoomRNG:SetSeed(newRoom.Seed, 0)
        if StageAPI.Random(1, 5, tutorialRoomRNG) == 1 then
            revel.data.seenDuneRoom = true
            return REVEL.RoomLists.TombDune
        end
    end
end)

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_ROOM_LAYOUT_CHOOSE, 1, function(newRoom, roomsList)
    if roomsList == REVEL.RoomLists.GlacierLightableFire
    or roomsList == REVEL.RoomLists.GlacierSnowman
    or roomsList == REVEL.RoomLists.TombDune then
        return StageAPI.ChooseRoomLayout{
            RoomList = roomsList,
            Seed = newRoom.SpawnSeed,
            Shape = newRoom.Shape,
            IgnoreDoors = false,
            -- stageapi considers max possible doors for the original vanilla room layout
            -- that would have spawned instead of doors in room
            -- needed here as we don't necessarily have 4 door rooms
            Doors = REVEL.GetDoorsForRoomFromDesc(REVEL.level:GetCurrentRoomDesc()),
        }
    end
end)

revel:AddCallback(ModCallbacks.MC_USE_ITEM, shrineRoomSpawning_PostUseRKey, CollectibleType.COLLECTIBLE_R_KEY)
revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, shrineRoom_TrollBombs_PreEntitySpawn)

end