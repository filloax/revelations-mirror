local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local RandomPickupSubtype = require("lua.revelcommon.enums.RandomPickupSubtype")
local RevRoomType         = require("lua.revelcommon.enums.RevRoomType")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.MirrorRoom.SetStageHasNarcLostBonus(REVEL.STAGE.Glacier)

local DANTESATANMEGA_ROOM_ID = "DanteSatanBig"
local DANTESATANMEGA_ROOM_TYPE = RevRoomType.DANTE_MEGA_SATAN

local DANTESATAN_METAEENT = "Dante Mega Satan"

local FROZEN_BODY_SOUL_DROP_CHANCE = 5 / 100

REVEL.DanteSatan2 = {}

local BodyEffects = {}

local function MakeDanteSatanRoom()
    return StageAPI.LevelRoom {
        SpawnSeed = REVEL.room:GetSpawnSeed(),
        Shape = RoomShape.ROOMSHAPE_1x2,
        RoomType = DANTESATANMEGA_ROOM_TYPE,
        RoomsList = REVEL.RoomLists.GlacierDanteSatan2,
        IsExtraRoom = true,
        IgnoreDoors = true,
        Music = REVEL.SFX.GLACIER_ENTRANCE,
    }
end

---@param firstSpawn? boolean
function REVEL.DanteSatan2.SpawnDoor(firstSpawn)
    REVEL.MirrorRoom.SpawnLostModeDoor(DANTESATANMEGA_ROOM_ID, MakeDanteSatanRoom, firstSpawn)
end

if REVEL.DEBUG then
    function GoToDanteSatan2(instant)
        local pos = REVEL.room:GetCenterPos()

        local defaultMap = StageAPI.GetDefaultLevelMap()
        local extraRoomData = defaultMap:GetRoomDataFromRoomID(DANTESATANMEGA_ROOM_ID)
        local extraRoom
        if not extraRoomData then
            extraRoom = MakeDanteSatanRoom()
            extraRoomData = defaultMap:AddRoom(extraRoom, {RoomID = DANTESATANMEGA_ROOM_ID})
        else
            ---@type LevelRoom
            extraRoom = defaultMap:GetRoom(extraRoomData)
        end

        extraRoom.PersistentData.ExitRoom = REVEL.level:GetCurrentRoomIndex()
        extraRoom.PersistentData.ExitRoomPosition = {X = pos.X, Y = pos.Y}
        
        if instant then 
            StageAPI.ExtraRoomTransition(
                extraRoomData.MapID, 
                nil, 
                -1, 
                StageAPI.DefaultLevelMapID, 
                nil, nil,
                pos + Vector(0, 40)
            )
        else
            StageAPI.ExtraRoomTransition(
                extraRoomData.MapID, 
                nil, 
                RoomTransitionAnim.PIXELATION, 
                StageAPI.DefaultLevelMapID, 
                nil, nil,
                pos + Vector(0, 40)
            )
        end
    end
end

local function danteSatan2_PostUpdate()
    if StageAPI.GetCurrentRoomType() == DANTESATANMEGA_ROOM_TYPE then
        REVEL.Darken(0.75, 50)
    end
end
    
-- grid coords offset from center
local SATAN_WALL_PATTERN = {
    Vector(-5, 3), Vector(-5, 2), Vector(-5, 1), Vector(-5, 0),
    Vector(-4, 0), Vector(-3, 0), Vector(-2, 0), Vector(-1, 0),
    Vector(0, 0),
    Vector(1, 0), Vector(2, 0), Vector(3, 0), Vector(4, 0),
    Vector(-5, -1), Vector(-4, -1), Vector(-3, -1), Vector(-2, -1), Vector(-1, -1),
    Vector(0, -1),
    Vector(1, -1), Vector(2, -1), Vector(3, -1), Vector(4, -1), Vector(5, -1),
    Vector(5, 0), Vector(5, 1), Vector(5, 2), Vector(5, 3),
}

local function danteSata2_NewRoom()
    BodyEffects = {}
end

---@param currentRoom LevelRoom
---@param firstLoad boolean
local function danteSatan2_PostRoomLoad(currentRoom, firstLoad)
    local danteSatans = currentRoom.Metadata:Search{Name = DANTESATAN_METAEENT}
    if firstLoad then
        local frozenBodies = currentRoom.Metadata:Search{Name = REVEL.GRIDENT.FROZEN_BODY.Name}
        for _, metaent in ipairs(frozenBodies) do
            REVEL.GRIDENT.FROZEN_BODY:Spawn(metaent.Index, true, false)
        end
        for _, metaent in ipairs(danteSatans) do
            local w = REVEL.room:GetGridWidth()
            local gridx, gridy = StageAPI.GridToVector(metaent.Index, w)
            local centerx, centery = gridx, gridy + 1
            for _, off in ipairs(SATAN_WALL_PATTERN) do
                local x, y = centerx + off.X, centery + off.Y
                local idx = StageAPI.VectorToGrid(x, y, w)
                local gridPos = REVEL.room:GetGridPosition(idx)
                Isaac.GridSpawn(GridEntityType.GRID_PILLAR, 0, gridPos)
                local grid = REVEL.room:GetGridEntity(idx)
                grid:GetSprite().Scale = Vector.Zero
            end
        end

        if currentRoom:GetType() == DANTESATANMEGA_ROOM_TYPE
        and currentRoom.PersistentData.ExitSlot then
            StageAPI.SpawnCustomDoor(
                currentRoom.PersistentData.ExitSlot, 
                currentRoom.PersistentData.LeadTo, 
                StageAPI.DefaultLevelMapID, 
                REVEL.MirrorRoom.LostModeDoor.Name, 
                nil, 
                currentRoom.PersistentData.LeadToSlot,
                nil, 
                RoomTransitionAnim.FADE_MIRROR
            )        
        end
    else
        for _, metaent in ipairs(danteSatans) do
            local w = REVEL.room:GetGridWidth()
            local gridx, gridy = StageAPI.GridToVector(metaent.Index, w)
            local centerx, centery = gridx, gridy + 1
            for _, off in ipairs(SATAN_WALL_PATTERN) do
                local x, y = centerx + off.X, centery + off.Y
                local idx = StageAPI.VectorToGrid(x, y, w)
                local grid = REVEL.room:GetGridEntity(idx)
                if grid then
                    grid:GetSprite().Scale = Vector.Zero
                else
                    REVEL.DebugToString("WARNING: no wall present for dante satan on room reenter at index", idx)
                end
            end
        end
    end
    for _, metaent in ipairs(danteSatans) do
        local pos = REVEL.room:GetGridPosition(metaent.Index)
        REVEL.SpawnDecorationFromTable(pos, Vector.Zero, {
            Sprite = "gfx/grid/revel1/glacier_dante_satan_2.anm2",
            Anim = "Above",
            RemoveOnAnimEnd = false,
        })

        REVEL.SpawnDecorationFromTable(pos, Vector.Zero, {
            Sprite = "gfx/grid/revel1/glacier_dante_satan_2.anm2",
            Anim = "Below",
            RemoveOnAnimEnd = false,
            Floor = true,
            Color = Color(1, 1, 1, 0.5),
        })

        local off = Vector(0, 200)
        local aboveWings = REVEL.SpawnDecorationFromTable(pos + off, Vector.Zero, {
            Sprite = "gfx/grid/revel1/glacier_dante_satan_2.anm2",
            Anim = "Wings",
            RemoveOnAnimEnd = false,
        })
        aboveWings.SpriteOffset = -off * REVEL.WORLD_TO_SCREEN_RATIO
    end
end


---@param customGrid CustomGridEntity
local function frozenBody_PostSpawnCustomGrid(customGrid)
    local eff = REVEL.SpawnDecorationFromTable(customGrid.Position, Vector.Zero, {
        Sprite = customGrid.GridConfig.Anm2,
        Anim = customGrid.GridConfig.Animation,
        SetFrame = customGrid.GridEntity:GetSprite():GetFrame(),
        RemoveOnAnimEnd = false,
    })
    BodyEffects[customGrid.PersistentIndex] = EntityPtr(eff)
    eff:GetSprite().FlipX = customGrid.GridEntity:GetSprite().FlipX
end

---@param customGrid CustomGridEntity
local function frozenBody_PostCustomGridUpdate(customGrid)
    if not customGrid:IsOnGrid() then
        if BodyEffects[customGrid.PersistentIndex] and BodyEffects[customGrid.PersistentIndex].Ref then
            BodyEffects[customGrid.PersistentIndex].Ref:Remove()
            BodyEffects[customGrid.PersistentIndex] = nil
        end
    end
end

---@param customGrid CustomGridEntity
local function frozenBody_PostCustomGridDestroy(customGrid)
    if BodyEffects[customGrid.PersistentIndex] and BodyEffects[customGrid.PersistentIndex].Ref then
        local eff = BodyEffects[customGrid.PersistentIndex].Ref
        for i=1, 6 do
            REVEL.SpawnIceRockGib(eff.Position, Vector.FromAngle(1*math.random(0, 360)):Resized(math.random(1, 5)), eff)
        end

        local rng = eff:GetDropRNG()
        local chance = rng:RandomFloat()
        print(chance)
        if chance < FROZEN_BODY_SOUL_DROP_CHANCE then
            local dir = RandomVector()
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_SOUL,
                customGrid.Position + dir * 3, dir * 3,
                nil
            )
        end

        eff:Remove()
        BodyEffects[customGrid.PersistentIndex] = nil
    end
end

local function danteSatan2_PreEntitySpawn(_, etype, variant, subtype, pos, vel, spawner, seed)
    if etype == EntityType.ENTITY_PICKUP and variant == PickupVariant.PICKUP_COLLECTIBLE
    and subtype == 0
    and StageAPI.GetCurrentRoomType() == DANTESATANMEGA_ROOM_TYPE then
        local devilItem = REVEL.pool:GetCollectible(ItemPoolType.POOL_DEVIL, true, seed)
        return {
            etype,
            variant,
            devilItem,
            seed,
        }
    end
end

local function danteSatan2_PostGetCollectible(_, selectedCollectible, itemPoolType, decrease, seed)
    if StageAPI.GetCurrentRoomType() == DANTESATANMEGA_ROOM_TYPE
    and itemPoolType ~= ItemPoolType.POOL_DEVIL then
        return REVEL.pool:GetCollectible(ItemPoolType.POOL_DEVIL, decrease, seed)
    end
end


revel:AddCallback(ModCallbacks.MC_POST_UPDATE, danteSatan2_PostUpdate)
revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, danteSatan2_PreEntitySpawn)
revel:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE, danteSatan2_PostGetCollectible)    

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_STAGEAPI_NEW_ROOM, 1, danteSata2_NewRoom)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, danteSatan2_PostRoomLoad)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SPAWN_CUSTOM_GRID, 1, frozenBody_PostSpawnCustomGrid, REVEL.GRIDENT.FROZEN_BODY.Name)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_CUSTOM_GRID_UPDATE, 1, frozenBody_PostCustomGridUpdate, REVEL.GRIDENT.FROZEN_BODY.Name)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_CUSTOM_GRID_DESTROY, 1, frozenBody_PostCustomGridDestroy, REVEL.GRIDENT.FROZEN_BODY.Name)

end