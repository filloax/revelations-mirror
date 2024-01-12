local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local RevRoomType       = require("lua.revelcommon.enums.RevRoomType")

return function()

REVEL.MirrorRoom = {}

REVEL.MirrorSpawnRNG = REVEL.RNG()

local function mirrorDoorExitFunction(door, data, sprite, doorData, persistData)
    -- Normal entering, disable mirror lost mode if exited last time
    local leadsTo = persistData.LeadsTo
    local levelMap = StageAPI.GetDefaultLevelMap()
    ---@type LevelRoom
    local mirrorRoom = levelMap and levelMap:GetRoom(leadsTo)
    if mirrorRoom and not REVEL.MirrorRoom.DefeatedNarcissusThisChapter() then
        mirrorRoom.PersistentData.TheLostMirrorBoss = false
    end
end

REVEL.MirrorRoom.Door = StageAPI.CustomDoor(
    "MirrorRoomDoor", 
    "gfx/grid/revelcommon/doors/mirror.anm2", 
    nil, nil, nil, nil, 
    true,
    false,
    mirrorDoorExitFunction
)

local LAYOUT_NAME = "MirrorRoom"

REVEL.MirrorRoom.RoomId = "MirrorRoom"
REVEL.MirrorRoom.Layout = StageAPI.CreateEmptyRoomLayout(RoomShape.ROOMSHAPE_1x1)
REVEL.MirrorRoom.Layout.Type = RevRoomType.MIRROR
StageAPI.RegisterLayout(LAYOUT_NAME, REVEL.MirrorRoom.Layout)

function REVEL.MirrorRoom.CheckSpawnDoor()
    local room = REVEL.room
    local level = REVEL.level
    if room:IsFirstVisit() and not revel.data.run.level.MirrorDoorSpawned 
    and level:GetCurrentRoomDesc().GridIndex == revel.data.run.level.mirrorDoorRoomIndex
    and revel.data.run.level.hasMirrorDoor
    then
        revel.data.run.level.MirrorDoorSpawned = true

        local defaultMap = StageAPI.GetDefaultLevelMap()
        ---@type LevelMap.RoomData
        local mirrorRoomData = defaultMap:GetRoomDataFromRoomID(REVEL.MirrorRoom.RoomId)

        local slot = revel.data.run.level.mirrorDoorRoomSlot
        StageAPI.SpawnCustomDoor(slot, mirrorRoomData.MapID, defaultMap.Dimension, REVEL.MirrorRoom.Door.Name)
    end
end

function REVEL.MirrorRoom.SpawnNextMirror(npc)
    if not REVEL.IsRevelStage() then
        REVEL.DebugToString("[REVEL] SpawnNextMirror | not in revel stage!")
        return
    end

    ---@type CustomStage
    local currentStage = StageAPI.GetCurrentStage()
    local alreadySpawned = revel.data.run.spawnedMirrorShard[currentStage.Name]
    if not alreadySpawned then
        REVEL.DebugToString("[REVEL] SpawnNextMirror | spawning item...")
        if REVEL.OnePlayerHasCollectible(REVEL.ITEM.MIRROR.id) then
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, REVEL.ITEM.MIRROR2.id, REVEL.room:GetCenterPos(), Vector.Zero, nil)
        else
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, REVEL.ITEM.MIRROR.id,  REVEL.room:GetCenterPos(), Vector.Zero, nil)
        end
        revel.data.run.spawnedMirrorShard[currentStage.Name] = true
    else
        REVEL.DebugToString("[REVEL] SpawnNextMirror | already spawned shard!")
    end
end

-- This assumes the callback runs after NEW_ROOM for stageapi -> after CheckSpawnDoor
local function shrineMinimapPostMapPosUpdate(room, pos)
    local room = REVEL.room
    local level = REVEL.level
    if room:IsFirstVisit() and revel.data.run.level.MirrorDoorSpawned
    and level:GetCurrentRoomDesc().GridIndex == revel.data.run.level.mirrorDoorRoomIndex then
        local entranceMRoom = MinimapAPI:GetCurrentRoom()
        if entranceMRoom then
            if not REVEL.includes(entranceMRoom.PermanentIcons, "Mirror Entrance") then
                table.insert(entranceMRoom.PermanentIcons, "Mirror Entrance")
            end
        end
    end
end

if MinimapAPI then
    MinimapAPI:AddPlayerPositionCallback("Revelations", shrineMinimapPostMapPosUpdate)
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    REVEL.MirrorRoom.CheckSpawnDoor()
end)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_CHECK_VALID_ROOM, 1, function(layout, roomList, seed, shape, rtype, requireRoomType)
    if revel.data.run.level.mirrorDoorRoomIndex > -1 and REVEL.level:GetCurrentRoomDesc().GridIndex == revel.data.run.level.mirrorDoorRoomIndex then
        for _, door in ipairs(layout.Doors) do
            if door.Slot == revel.data.run.level.mirrorDoorRoomSlot and not door.Exists then
                return false
            end
        end
    end
end)

function REVEL.IsRoomDescMirrorValid(roomDesc)
    -- REVEL.DebugToString(roomDesc.GridIndex, roomDesc.Data.Shape)

    local validDoorSlots, avaiableDoorSlots = REVEL.GetRoomDescDoorSlots(roomDesc)

    -- REVEL.DebugToString("--", validDoorSlots, avaiableDoorSlots)

    return roomDesc.GridIndex ~= REVEL.level:GetStartingRoomIndex() 
    and roomDesc.ListIndex ~= revel.data.run.level.dante.StartingRoomIndex
    and roomDesc.Data.Type == RoomType.ROOM_DEFAULT
    and #avaiableDoorSlots > 0
end

--Pick randomly between the 3 closest rooms to the boss room, if there aren't any ones pick the closest
function REVEL.MirrorRoom.PlaceInLevel()
    local lastBoss = REVEL.level:GetLastBossRoomListIndex()
    local map = REVEL.GetPathMapToRoomIndex(lastBoss)
    local validRooms, validRoomsFallback = {}, {}

    REVEL.MirrorLevelSpawnRNG = REVEL.RNG()
    REVEL.MirrorLevelSpawnRNG:SetSeed(REVEL.level:GetDungeonPlacementSeed(), 40)

    for gridIndex, distance in pairs(map) do
        if distance > 0 then
            local desc = REVEL.level:GetRoomByIdx(gridIndex)
            if REVEL.IsRoomDescMirrorValid(desc) then
                if distance <= 3 then
                    validRooms[#validRooms + 1] = desc
                end
                validRoomsFallback[desc] = distance
            end
        end
    end

    local mirrorDoorDesc

    if #validRooms > 0 then
        mirrorDoorDesc = validRooms[StageAPI.Random(1, #validRooms, REVEL.MirrorLevelSpawnRNG)]
    else
        local minDist, closest
        for desc, dist in pairs(validRoomsFallback) do
            if not minDist or dist < minDist then
                minDist = dist
                closest = desc
            end
        end

        mirrorDoorDesc = closest
    end

    -- REVEL.PrintLevelMap()

    -- REVEL.DebugToString(validRooms, validRoomsFallback)

    if mirrorDoorDesc then
        local defaultMap = StageAPI.GetDefaultLevelMap()

        -- for now, only support vanilla map, no custom levels
        revel.data.run.level.mirrorDoorRoomDimension = nil
        revel.data.run.level.mirrorDoorRoomIndex = mirrorDoorDesc.GridIndex
        revel.data.run.level.hasMirrorDoor = true

        local _, avaiableDoorSlots = REVEL.GetRoomDescDoorSlots(mirrorDoorDesc)
        local slot = avaiableDoorSlots[StageAPI.Random(1, #avaiableDoorSlots, REVEL.MirrorLevelSpawnRNG)]

        revel.data.run.level.mirrorDoorRoomSlot = slot
        revel.data.run.level.mirrorRoomIndex = REVEL.GetRoomIdxRelativeToSlot(mirrorDoorDesc, slot)
        
        REVEL.DebugStringMinor("Mirror room at:", revel.data.run.level.mirrorDoorRoomIndex, revel.data.run.level.mirrorRoomIndex, revel.data.run.level.mirrorDoorRoomSlot)

        local x, y = StageAPI.GridToVector(revel.data.run.level.mirrorRoomIndex, 13)
        x = x + 1
        y = y + 1

        local mirrorRoom = StageAPI.LevelRoom {
            LayoutName = LAYOUT_NAME,
            SpawnSeed = REVEL.room:GetSpawnSeed() + 5,
            Shape = RoomShape.ROOMSHAPE_1x1,
            RoomType = RevRoomType.MIRROR,
            IsExtraRoom = true,
        }
        mirrorRoom:SetTypeOverride(RevRoomType.MIRROR)
        local roomData = defaultMap:AddRoom(mirrorRoom, {
            RoomID = REVEL.MirrorRoom.RoomId,
            X = x,
            Y = y,
        }, true)

        if MinimapAPI then
            local pos = MinimapAPI:GridIndexToVector(revel.data.run.level.mirrorRoomIndex)
            local exitSlot = (slot + 2) % 4
            local dir = StageAPI.DoorToDirection[exitSlot]

            -- TODO: make revelaed by blue map when minimapapi is fixed

            --Reminder for displayflags: 3 bits "xyz", x:show icon, y:show room shadow, z:show room shape
            local mirrorRoomArgs = {
                ID = "Mirror",
                Position = pos,--a vector representing the position of the room on the minimap.
                Shape = "MirrorRoom" .. REVEL.dirToString[dir], --RoomShape.ROOMSHAPE_1x1,
                TeleportHandler = {
                    Teleport = function(_, room)
                        if REVEL.STAGE.Glacier:IsStage() then
                            Isaac.ExecuteCommand("mirror")
                            return true
                        elseif REVEL.STAGE.Tomb:IsStage() then
                            Isaac.ExecuteCommand("mirror t")
                            return true
                        end
                        return false
                    end,
                    ---@param room MinimapAPI.Room
                    CanTeleport = function(_, room, allowUnclear)
                        if allowUnclear then
                            return room:GetDisplayFlags() > 0
                        else
                            return REVEL.MirrorRoom.DefeatedNarcissusThisChapter()
                        end
                    end,
                },
                -- Type = --A RoomType enum value. Optional, but recommended if you want the room to work as expected with minimap revealing items.
                PermanentIcons = {"Mirror Room"},
                LockedIcons = {"Mirror Room Locked"},--A list of strings like above, but this is only shown when the player does not know the room's type (eg locked shop, dice room)
                DisplayFlags = RoomDescriptor.DISPLAY_NONE,
                AdjacentDisplayFlags = RoomDescriptor.DISPLAY_NONE, --The display flags that this room will take on if seen from an adjacent room. This is usually 0 for secret rooms, 3 for locked rooms and 5 for all others.
                Color = Color(0.9, 1.15, 1.25),
                Secret = true,
            }

            local mirrorMRoom = MinimapAPI:GetRoomAtPosition(pos)

            if mirrorMRoom then
                for k, v in pairs(mirrorRoomArgs) do
                    mirrorMRoom[k] = v
                end
            else
                REVEL.DebugToString("WARNING | Mirror room minimap room not found when creating!")
            end

            if REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_COMPASS) then
                local doorPos = MinimapAPI:GridIndexToVector(revel.data.run.level.mirrorDoorRoomIndex)
                local entranceMRoom = MinimapAPI:GetRoomAtPosition(doorPos)
                if entranceMRoom then
                    table.insert(entranceMRoom.PermanentIcons, "Mirror Entrance")
                end
            end
        end
    end
end

function REVEL.MirrorRoom.CanHaveThisChapter()
    return (REVEL.STAGE.Glacier:IsStage() and not revel.data.run.NarcissusGlacierDefeated) 
        or (REVEL.STAGE.Tomb:IsStage() and not revel.data.run.NarcissusTombDefeated)
end

function REVEL.MirrorRoom.DefeatedNarcissusThisChapter()
    return (REVEL.STAGE.Glacier:IsStage() and revel.data.run.NarcissusGlacierDefeated) 
        or (REVEL.STAGE.Tomb:IsStage() and revel.data.run.NarcissusTombDefeated)
end

revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
    if REVEL.MirrorRoom.CanHaveThisChapter() then
        REVEL.MirrorRoom.PlaceInLevel()
    end
end)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SPAWN_CUSTOM_DOOR, 1, function(door, data, sprite, doorData, customGrid, force, respawning)
    if REVEL.MirrorRoom.DefeatedNarcissusThisChapter() then
        if StageAPI.GetCurrentRoomType() == RevRoomType.MIRROR then
            sprite:Play("Mirror Open Dark", true)
        else
            sprite:Play("Default Open Dark", true)
        end

        StageAPI.SetDoorOpen(true, door)
    else
        local persistData = customGrid.PersistentData
        
        if StageAPI.GetCurrentRoomType() == RevRoomType.MIRROR then
            sprite:Play("Mirror Closed", true)
            StageAPI.SetDoorOpen(false, door)
        else
            if persistData.Broken then
                sprite:Play("Default Open", true)
                StageAPI.SetDoorOpen(true, door)
            else
                sprite:Play("Default Closed", true)
                StageAPI.SetDoorOpen(false, door)
            end
        end
    end
end, "MirrorRoomDoor")

---@param door EntityEffect
---@param data table
---@param sprite Sprite
---@param doorData CustomDoor
---@param persistData table
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_CUSTOM_DOOR_UPDATE, 1, function(door, data, sprite, doorData, persistData)
    if sprite:IsPlaying("Default Closed") or sprite:IsFinished("Default Closed") then
        for _, e in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, -1, false, false)) do
            if e.Position:DistanceSquared(door.Position) < 144 * 144 then
                persistData.Broken = true
                local currentMusic = REVEL.music:GetCurrentMusicID()
                REVEL.PlayJingleForRoom(REVEL.SFX.MIRROR_DOOR_OPENS)
                REVEL.music:Queue(currentMusic)
                sprite:Play("Default Break", true)

                if MinimapAPI then
                    local mroom = MinimapAPI:GetRoomByID("Mirror")
                    mroom.DisplayFlags = BitOr(mroom.DisplayFlags, tonumber("010", 2))
                end
            end
        end

        -- Lost mode extra
        for _, player in ipairs(REVEL.players) do
            if REVEL.PlayerIsLost(player)
            and player.Position:DistanceSquared(door.Position) < (player.Size + 25) ^ 2
            -- if moving to door
            and player.Velocity:Dot(door.Position - REVEL.room:GetCenterPos()) > 0
            then
                local leadsTo = persistData.LeadsTo
                local levelMap = StageAPI.GetCurrentLevelMap()
                ---@type LevelRoom
                local mirrorRoom = levelMap:GetRoom(leadsTo)

                mirrorRoom.PersistentData.TheLostMirrorBoss = true

                StageAPI.ExtraRoomTransition(
                    leadsTo, nil, 
                    RoomTransitionAnim.FADE_MIRROR, 
                    StageAPI.DefaultLevelMapID, 
                    mirrorRoom.PersistentData.ExitSlot
                )
            end
        end
    elseif sprite:IsPlaying("Mirror Closed") or sprite:IsFinished("Mirror Closed") then
        if REVEL.MirrorRoom.DefeatedNarcissusThisChapter() then
            sprite:Play("Mirror Break", true)
        end
    end

    if sprite:IsFinished("Default Break") then
        sprite:Play("Default Open", true)
        StageAPI.SetDoorOpen(true, door)
    elseif sprite:IsFinished("Mirror Break") then
        sprite:Play("Mirror Open", true)
        StageAPI.SetDoorOpen(true, door)
    end
end, "MirrorRoomDoor")

revel:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemID, itemRNG, player, useFlags, activeSlot, customVarData)
    local doors = Isaac.FindByType(1000, StageAPI.E.Door.V, -1, false, false)
    if #doors ~= 0 then
        local door, data
        for i,v in ipairs(doors) do
            data = v:GetData()
            if data.DoorGridData and data.DoorGridData.DoorDataName == "MirrorRoomDoor" then
                door = v
                break
            end
        end
        if not data.DoorGridData.Broken then
            local sprite = door:GetSprite()
            data.DoorGridData.Broken = true
            local currentMusic = REVEL.music:GetCurrentMusicID()
            REVEL.PlayJingleForRoom(REVEL.SFX.MIRROR_DOOR_OPENS)
            REVEL.music:Queue(currentMusic)
            sprite:Play("Default Break", true)
        end
    end
end, CollectibleType.COLLECTIBLE_DADS_KEY)


StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, function(newRoom, isFirstLoad)
    if StageAPI.GetCurrentRoomType() == RevRoomType.MIRROR and isFirstLoad then
        -- remove decorations
        StageAPI.ClearRoomLayout(false, true, false, false, nil, false, true)

        local mirrorDoorSlot = revel.data.run.level.mirrorDoorRoomSlot
        local slot = (mirrorDoorSlot + 2) % 4

        StageAPI.SpawnCustomDoor(
            slot, 
            revel.data.run.level.mirrorDoorRoomIndex, 
            revel.data.run.level.mirrorDoorRoomDimension, 
            REVEL.MirrorRoom.Door.Name, 
            nil, 
            mirrorDoorSlot
        )
    end
end)

-- Lost mode door

--#region LostDoor

local StagesWithNarcLostBonus = {}

---@param customStage CustomStage
function REVEL.MirrorRoom.SetStageHasNarcLostBonus(customStage)
    StagesWithNarcLostBonus[#StagesWithNarcLostBonus+1] = customStage
end

---@param customStage? CustomStage # default: currentStage
function REVEL.MirrorRoom.StageHasNarcLostBonus(customStage)
    customStage = customStage or StageAPI.GetCurrentStage()
    for _, stage in ipairs(StagesWithNarcLostBonus) do
        if StageAPI.IsSameStage(customStage, stage) then
            return true
        end
    end
    return false
end

REVEL.MirrorRoom.LostModeDoor = StageAPI.CustomDoor(
    "LostModeDoor", 
    "gfx/grid/revelcommon/doors/door_mirrorspecial.anm2", 
    "Open", "Close", 
    "Opened", "Closed", 
    false,
    nil
)

---@param roomId string|integer
---@param makeRoom fun(): LevelRoom
---@param firstSpawn? boolean
function REVEL.MirrorRoom.SpawnLostModeDoor(roomId, makeRoom, firstSpawn)
    local defaultMap = StageAPI.GetDefaultLevelMap()
    local extraRoomData = defaultMap:GetRoomDataFromRoomID(roomId)
    local extraRoom
    if not extraRoomData then
        extraRoom = makeRoom()
        extraRoomData = defaultMap:AddRoom(extraRoom, {RoomID = roomId})
    else
        ---@type LevelRoom
        extraRoom = defaultMap:GetRoom(extraRoomData)
    end

    local currentRoom = StageAPI.GetCurrentRoom()

    local slot = currentRoom.PersistentData.LostModeDoorSlot
    if not slot then
        local roomDesc = REVEL.level:GetCurrentRoomDesc()
        local availableSlots = StageAPI.GetDoorsForRoomFromData(roomDesc.Data)
        local validSlots = {}

        local hasUp = false

        for slot2 = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
            if availableSlots[slot2] and not REVEL.room:GetDoor(slot2)
            and not REVEL.GetCustomDoorBySlot(slot2)
            then
                -- prefer up for long room reasons
                if slot2 == DoorSlot.UP0 then
                    hasUp = true
                end
                validSlots[#validSlots+1] = slot2
            end
        end

        if #validSlots == 0 then
            error("No free slot to spawn Dante Satan room!")
        end

        slot = hasUp and DoorSlot.UP0 or REVEL.randomFrom(validSlots)
        currentRoom.PersistentData.LostModeDoorSlot = slot
    end

    local currentRoomData = defaultMap:GetCurrentRoomData()
    local mapId = currentRoomData and currentRoomData.MapID or REVEL.level:GetCurrentRoomIndex()

    extraRoom.PersistentData.ExitSlot = DoorSlot.DOWN0
    extraRoom.PersistentData.LeadTo = mapId
    extraRoom.PersistentData.LeadToMap = currentRoomData and defaultMap.Dimension
    extraRoom.PersistentData.LeadToSlot = slot

    StageAPI.SpawnCustomDoor(
        slot, 
        extraRoomData.MapID, 
        StageAPI.DefaultLevelMapID, 
        REVEL.MirrorRoom.LostModeDoor.Name,
        nil, 
        DoorSlot.DOWN0, 
        nil, 
        RoomTransitionAnim.FADE_MIRROR
    )

    if firstSpawn then
        -- Placeholder spawn animation
        local num = math.random(5, 10)
        for i = 1, num do
            local e = Isaac.Spawn(
                1000, EffectVariant.DUST_CLOUD, 0, 
                REVEL.room:GetDoorSlotPosition(slot) + RandomVector() * math.random(1, 20), Vector.Zero, 
                nil
            ):ToEffect()
            e.Timeout = math.random(15, 30)
            e.LifeSpan = e.Timeout
        end

        -- REVEL.DelayFunction(30, function()
        --     local lostModeDoors = StageAPI.GetCustomDoors(REVEL.MirrorRoom.LostModeDoor.Name)
        --     for _, door in ipairs(lostModeDoors) do
        --         StageAPI.SetDoorOpen(true, door)
        --     end
        -- end)
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    if StageAPI.GetCurrentRoomType() == RevRoomType.MIRROR then
        if MinimapAPI then
            local eroom = MinimapAPI:GetCurrentRoom()
            if eroom then
                eroom.DisplayFlags = tonumber("111", 2)
            end
        end

        local currentRoom = StageAPI.GetCurrentRoom()
        if currentRoom.PersistentData.TheLostMirrorBoss and not REVEL.MirrorRoom.DefeatedNarcissusThisChapter() then
            for _, player in ipairs(REVEL.players) do
                if not REVEL.PlayerIsLost(player) then
                    player:GetEffects():AddNullEffect(NullItemID.ID_LOST_CURSE, true)
                end
            end
        end
    end
end)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SPAWN_CUSTOM_DOOR, 1, function(door, data, sprite, doorData, customGrid, force, respawning)
    if StageAPI.GetCurrentRoomType() == RevRoomType.MIRROR
    and respawning
    then
        StageAPI.SetDoorOpen(false, door)
        if StageAPI.GetCurrentRoom().VisitCount <= 2 then
            sprite:Play("Close", true)
        else
            sprite:Play("Closed", true)
        end
    end
end, REVEL.MirrorRoom.LostModeDoor.Name)

--#endregion

Isaac.DebugString("Revelations: Loaded Mirror room generation!")

end