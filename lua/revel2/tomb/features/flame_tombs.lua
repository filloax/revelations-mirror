local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local RevRoomType       = require("lua.revelcommon.enums.RevRoomType")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.MirrorRoom.SetStageHasNarcLostBonus(REVEL.STAGE.Tomb)

REVEL.FlamingTombs = {}

--#region Flaming Tombs

local FlamingTomb = {
    -- For ease of use
    Anims = {
        IDLE = "Idle",
        IDLE_FLAME = "Idle (flame)",
        OPEN = "Open", 
        OPEN_LOOP = "Open (loop)",
        TRINKET_TAKE = "Trinket take",
        TRINKET_SHAKE = "Trinket shake", 
        TRINKET_SPIT = "Trinket spit",
    },
    GridPattern = {
        Vector(-1, -1), Vector(0, -1), Vector(1, -1),
        Vector(-1, 0), Vector(1, 0),
    },
    SpritePath = "gfx/grid/revel2/tomb_flamingtomb.anm2",
    MetaEntName = "Flaming Tomb",
}

REVEL.RegisterMachine(REVEL.ENT.FLAMING_TOMB)

local TombData = {}

local function GetTombIndices(centerIndex, rotation, flipped)
    local indices = {centerIndex}

    local w = REVEL.room:GetGridWidth()
    local gridx, gridy = StageAPI.GridToVector(centerIndex, w)
    for _, off in ipairs(FlamingTomb.GridPattern) do
        local rotatedOff = off:Rotated(rotation * 90)
        if flipped then
            rotatedOff = REVEL.VectorMult(rotatedOff, Vector(-1, 1))
        end
        -- rounding errors with rotation
        rotatedOff = REVEL.Round(rotatedOff)
        
        local x, y = gridx + rotatedOff.X, gridy + rotatedOff.Y
        local idx = StageAPI.VectorToGrid(x, y, w)
        indices[#indices+1] = idx
    end
    table.sort(indices)
    return indices
end

---@param currentRoom LevelRoom
---@param firstLoad boolean
local function flamingTomb_PostRoomLoad(currentRoom, firstLoad)
    TombData = {}
    local flamingTombMetaents = currentRoom.Metadata:Search{Name = FlamingTomb.MetaEntName}
    if firstLoad then
        for _, metaent in ipairs(flamingTombMetaents) do
            REVEL.GRIDENT.FLAMING_TOMB:Spawn(metaent.Index, true)
        end
    end
end

---@param customGridEntity CustomGridEntity
---@param force boolean
---@param respawning boolean
local function flamingTomb_PostInit(customGridEntity, force, respawning)
    local effect = REVEL.SpawnDecorationFromTable(customGridEntity.Position, Vector.Zero, {
        Sprite = FlamingTomb.SpritePath,
        RemoveOnAnimEnd = false,
    })
    local sprite = effect:GetSprite()
    TombData[customGridEntity.PersistentIndex] = {
        Effect = EntityPtr(effect),
    }

    local currentRoom = StageAPI.GetCurrentRoom()
    local metaent = currentRoom.Metadata:Search{
        Name = FlamingTomb.MetaEntName, 
        Index = customGridEntity.GridIndex,
    }[1]
    customGridEntity.PersistentData.Rotation = metaent.BitValues.Rotation
    customGridEntity.PersistentData.Decorative = metaent.BitValues.Decorative == 1

    if customGridEntity.PersistentData.Decorative then
        sprite:Play(FlamingTomb.Anims.IDLE_FLAME, true)
    else
        sprite:Play(FlamingTomb.Anims.OPEN, true)
    end

    sprite.Rotation = customGridEntity.PersistentData.Rotation * 90

    -- align to grid and use sprite offset

    -- set position to top block top margin
    -- vertical: add less offset
    if customGridEntity.PersistentData.Rotation == 2 then
        effect.Position = effect.Position + Vector(0, -20)
        effect.SpriteOffset = Vector(0, 20) * REVEL.WORLD_TO_SCREEN_RATIO
    else
        effect.Position = effect.Position + Vector(0, -60)
        effect.SpriteOffset = Vector(0, 60) * REVEL.WORLD_TO_SCREEN_RATIO
    end

    effect.PositionOffset = effect.PositionOffset + Vector(0, -15):Rotated(sprite.Rotation)

    if customGridEntity.Position.X > REVEL.room:GetCenterPos().X
    == (customGridEntity.PersistentData.Rotation % 2 == 1) then
        sprite.FlipX = true
        effect.PositionOffset = REVEL.VectorMult(effect.PositionOffset, Vector(-1, 1))
    end

    -- Spawn invisible grids for collision
    -- Pattern if rotation 0 (horizontal tomb) is
    -- ###
    -- #O#

    local tombIndices = GetTombIndices(
        customGridEntity.GridIndex, customGridEntity.PersistentData.Rotation, sprite.FlipX
    )
    for _, idx in ipairs(tombIndices) do
        if idx ~= customGridEntity.GridIndex then
            local gridPos = REVEL.room:GetGridPosition(idx)
            if REVEL.room:IsFirstVisit() then
                Isaac.GridSpawn(GridEntityType.GRID_PILLAR, 0, gridPos)
            end
            local grid = REVEL.room:GetGridEntity(idx)
            grid:GetSprite().Scale = Vector.Zero
        else
            local grid = REVEL.room:GetGridEntity(idx)
            grid:GetSprite().Scale = Vector.Zero
        end
    end
end

local function IsNearIndex(index1, index2)
    local x1, y1 = StageAPI.GridToVector(index1, REVEL.room:GetGridWidth())
    local x2, y2 = StageAPI.GridToVector(index2, REVEL.room:GetGridWidth())
    return math.abs(x1 - x2) <= 1
        or math.abs(y1 - y2) <= 1
end

---@param customGridEntity CustomGridEntity
local function flamingTomb_PostUpdate(customGridEntity)
    local data = TombData[customGridEntity.PersistentIndex]
    local persistData = customGridEntity.PersistentData
    local effect = data.Effect.Ref

    if not effect then return end
    if customGridEntity.PersistentData.Decorative then
        return
    end

    ---@type Sprite
    local sprite = effect:GetSprite()

    if sprite:IsEventTriggered("Grind") then
        REVEL.sfx:Play(REVEL.SFX.COFFIN_OPEN, 1, 0, false, 1) 
    end
    if sprite:IsEventTriggered("Clunk") then
        REVEL.sfx:Play(REVEL.SFX.BOULDER_THUMP, 1, 0, false, 1) 
    end
    if sprite:IsEventTriggered("Shake") then
        REVEL.sfx:Play(SoundEffect.SOUND_BIRD_FLAP, 1, 0, false, 1) 
    end

    if sprite:IsFinished(FlamingTomb.Anims.OPEN) then
        sprite:Play(FlamingTomb.Anims.OPEN_LOOP, true)

    -- Check player collision
    elseif sprite:IsPlaying(FlamingTomb.Anims.OPEN_LOOP) then
        local tombIndices = GetTombIndices(
            customGridEntity.GridIndex, persistData.Rotation, sprite.FlipX
        )

        local players = REVEL.players
        ---@type EntityPlayer?
        local collidingPlayer
        for _, player in ipairs(players) do
            local playerIndex = REVEL.room:GetGridIndex(player.Position + player.Velocity)
            local closestIndex = REVEL.GetClosestGridIndexToPosition(player.Position + player.Velocity, tombIndices)
            local closestPos = REVEL.room:GetGridPosition(closestIndex)
            if player:GetTrinket(0) > 0
            and REVEL.some(
                tombIndices,
                function(idx) return IsNearIndex(idx, playerIndex) end
            )
            and player:GetMovementInput():Dot(closestPos - player.Position) > 0
            and player:CollidesWithGrid()
            then
                collidingPlayer = player
                break
            end
        end

        if collidingPlayer then
            data.CollidingPlayer = EntityPtr(collidingPlayer)
            persistData.CurrentTrinket = collidingPlayer:GetTrinket(0)
            REVEL.DebugStringMinor("Flaming tomb: taking trinket", persistData.CurrentTrinket)
            collidingPlayer:TryRemoveTrinket(persistData.CurrentTrinket)

            local trinketConfig = REVEL.config:GetTrinket(persistData.CurrentTrinket)
            sprite:ReplaceSpritesheet(3, trinketConfig.GfxFileName)
            sprite:LoadGraphics()
            sprite:Play(FlamingTomb.Anims.TRINKET_TAKE, true)

        end
    
    elseif sprite:IsFinished(FlamingTomb.Anims.TRINKET_TAKE) then
        sprite:Play(FlamingTomb.Anims.TRINKET_SHAKE, true)
        data.ShakeCount = 0
    elseif sprite:IsFinished(FlamingTomb.Anims.TRINKET_SHAKE) then
        if data.ShakeCount >= 1 then
            sprite:Play(FlamingTomb.Anims.TRINKET_SPIT, true)
            data.ShakeCount = 0
        else
            sprite:Play(FlamingTomb.Anims.TRINKET_SHAKE, true)
            data.ShakeCount = data.ShakeCount + 1
        end
    elseif sprite:IsPlaying(FlamingTomb.Anims.TRINKET_SPIT) then
        if sprite:IsEventTriggered("Open") then
            local player = data.CollidingPlayer.Ref:ToPlayer()
            REVEL.AddSmeltedTrinket(player, persistData.CurrentTrinket)
            persistData.CurrentTrinket = -1
            REVEL.sfx:Play(SoundEffect.SOUND_POWERUP1, 1, 0, false, 1)

            for i = 1, math.random(4, 7) do
                local e = Isaac.Spawn(
                    1000, EffectVariant.DUST_CLOUD, 0, 
                    customGridEntity.Position + Vector(0, -40) + REVEL.VectorMult(RandomVector() * math.random(1, 20), Vector(3, 1)), 
                    Vector.Zero, 
                    nil
                ):ToEffect()
                e.Timeout = math.random(45, 90)
                e.LifeSpan = e.Timeout
                e.Color = Color(0.5, 0.5, 0.5, 0.75)    
                e.SpriteScale = Vector.One * 1.5  
            end
            REVEL.sfx:Play(SoundEffect.SOUND_FIREDEATH_HISS, 1, 0, false, 1)
        end
    elseif sprite:IsFinished(FlamingTomb.Anims.TRINKET_SPIT) then
        sprite:Play(FlamingTomb.Anims.OPEN_LOOP, true)
    end
end

--#endregion

--#region Flaming Tomb Room

local FLAMINGTOMB_ROOM_ID = "FlamingTombs"

local function flamingTombRoom_PostRoomLoad(currentRoom, firstLoad)
    if currentRoom.PersistentData.ExitSlot and firstLoad
    and currentRoom:GetType() == RevRoomType.FLAMING_TOMBS then
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
end

local function MakeFlamingTombsRoom()
    return StageAPI.LevelRoom {
        SpawnSeed = REVEL.room:GetSpawnSeed(),
        Shape = RoomShape.ROOMSHAPE_1x2,
        RoomType = RevRoomType.FLAMING_TOMBS,
        RoomsList = REVEL.RoomLists.TombFlamingTombs,
        IsExtraRoom = true,
        IgnoreDoors = true,
        Music = REVEL.SFX.TOMB_ENTRANCE,
    }
end

---@param firstSpawn? boolean
function REVEL.FlamingTombs.SpawnDoor(firstSpawn)
    REVEL.MirrorRoom.SpawnLostModeDoor(FLAMINGTOMB_ROOM_ID, MakeFlamingTombsRoom, firstSpawn)
end

--#endregion

--#region Callbacks

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 0, flamingTomb_PostRoomLoad)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 0, flamingTombRoom_PostRoomLoad)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SPAWN_CUSTOM_GRID, 0, flamingTomb_PostInit, REVEL.GRIDENT.FLAMING_TOMB.Name)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_CUSTOM_GRID_UPDATE, 0, flamingTomb_PostUpdate, REVEL.GRIDENT.FLAMING_TOMB.Name)

--#endregion

end

REVEL.PcallWorkaroundBreakFunction()