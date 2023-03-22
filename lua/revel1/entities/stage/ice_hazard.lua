local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local ShrineTypes       = require("lua.revelcommon.enums.ShrineTypes")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

----------------
-- ICE HAZARD --
----------------

local EmbeddedFrames = {0, 1}
local NonEmbeddedFrame = 2
local ShutsDoorsInClearStartRooms = true

--clotty replacement (should only happen when loaded as part of the room layout)
local function clottyReplacement(entType, entVariant, seed)
    if entType == REVEL.ENT.ICE_HAZARD_CLOTTY.id and entVariant == REVEL.ENT.ICE_HAZARD_CLOTTY.variant then
        local rng = REVEL.RNG()
        rng:SetSeed(seed, 0)

        if rng:RandomInt(100)+1 <= 2 then --2% chance to replace clotty with i blob
            return {
                REVEL.ENT.ICE_HAZARD_IBLOB.id,
                REVEL.ENT.ICE_HAZARD_IBLOB.variant,
                0,
                seed
            }
        end
    end
end
revel:AddCallback(ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN, function(_, entType, entVariant, entSubType, gridIndex, seed)
    local replacement = clottyReplacement(entType, entVariant, seed)
    if replacement then
        return replacement
    end
end)
StageAPI.AddCallback("Revelations", "PRE_SPAWN_ENTITY", 1, function(info, entityList, index, doGrids, doPersistentOnly, doAutoPersistent, avoidSpawning, persistentPositions)
    local replacement = clottyReplacement(info.Data.Type, info.Data.Variant, index+REVEL.room:GetSpawnSeed())
    if replacement then
        return replacement
    end
end)

--random ice hazards
local randomNumToIceVariant = {
    [0] = REVEL.ENT.ICE_HAZARD_GAPER.variant,
    [1] = REVEL.ENT.ICE_HAZARD_HORF.variant,
    [2] = REVEL.ENT.ICE_HAZARD_HOPPER.variant,
    [3] = REVEL.ENT.ICE_HAZARD_DRIFTY.variant,
    [4] = REVEL.ENT.ICE_HAZARD_CLOTTY.variant,
    [5] = REVEL.ENT.ICE_HAZARD_BROTHER.variant
}
local function randomIceHazard(entType, entVariant, entSubType, seed, onRoomLayout)
    if entType == REVEL.ENT.ICE_HAZARD_GAPER.id and entVariant == REVEL.ENT.ICE_HAZARD_GAPER.variant then
        if entSubType == 133 or entSubType == 134 then
            local rng = REVEL.RNG()
            rng:SetSeed(seed, 0)

            local randomNum
            if entSubType == 133 then --include all kinds of ice hazards
                randomNum = rng:RandomInt(6)
            elseif entSubType == 134 then --exlude brother bloody
                randomNum = rng:RandomInt(5)
            end

            local randomIce = {
                REVEL.ENT.ICE_HAZARD_GAPER.id,
                randomNumToIceVariant[randomNum] or REVEL.ENT.ICE_HAZARD_GAPER.variant,
                0,
                seed
            }

            if randomIce[2] == REVEL.ENT.ICE_HAZARD_CLOTTY.variant and onRoomLayout then
                local replacement = clottyReplacement(randomIce[1], randomIce[2], seed)
                if replacement then
                    randomIce = replacement
                end
            end

            return randomIce
        end
    end
end

revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, entType, entVariant, entSubType, position, velocity, spawner, seed)
    local replacement = randomIceHazard(entType, entVariant, entSubType, seed, false)
    if replacement then
        return replacement
    end
end)
revel:AddCallback(ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN, function(_, entType, entVariant, entSubType, gridIndex, seed)
    local replacement = randomIceHazard(entType, entVariant, entSubType, seed, true)
    if replacement then
        return replacement
    end
end)
StageAPI.AddCallback("Revelations", "PRE_SPAWN_ENTITY", 1, function(info, entityList, index, doGrids, doPersistentOnly, doAutoPersistent, avoidSpawning, persistentPositions)
    local replacement = randomIceHazard(info.Data.Type, info.Data.Variant, info.Data.SubType, index+REVEL.room:GetSpawnSeed(), true)
    if replacement then
        return replacement
    end
end)

--prevent poofs
local preventHazardPoof
revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, entType, entVariant, entSubType, position, velocity, spawner, seed)
    if preventHazardPoof and (preventHazardPoof + 3 > REVEL.game:GetFrameCount()) and entType == EntityType.ENTITY_EFFECT and entVariant == EffectVariant.POOF01 then
        return {
            StageAPI.E.DeleteMeEffect.T,
            StageAPI.E.DeleteMeEffect.V,
            0,
            seed
        }
    end
end)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    preventHazardPoof = nil
end)

--handle sprite on init
local function iceHazardInit(npc)
    local spr, data = npc:GetSprite(), npc:GetData()

    spr:SetAnimation("Idle")

    local overlay = math.random(0, 2)
    spr:SetLayerFrame(0, overlay)
    spr:SetLayerFrame(2, overlay)

    if npc.Variant == REVEL.ENT.ICE_HAZARD_GAPER.variant then
        local skin = math.random(1, 3)
        spr:SetLayerFrame(1, skin + 11)
        data.Skin = skin
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_HORF.variant then
        spr:SetLayerFrame(1, math.random(3, 5))
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_HOPPER.variant then
        spr:SetLayerFrame(1, math.random(6, 8))
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_DRIFTY.variant then
        spr:SetLayerFrame(1, math.random(0, 2))
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_CLOTTY.variant then
        spr:SetLayerFrame(1, math.random(9, 11))
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_BROTHER.variant then
        spr:SetLayerFrame(1, math.random(15, 17))
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_BOMB.variant then
        spr:SetLayerFrame(1, math.random(18, 20))
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_IBLOB.variant then
        spr:SetLayerFrame(1, math.random(21, 23))
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_EMPTY.variant then
        spr:SetLayerFrame(1, 24)
    end

    npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    npc:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
end
StageAPI.AddCallback("Revelations", RevCallbacks.NPC_UPDATE_INIT, 1, iceHazardInit, REVEL.ENT.ICE_HAZARD_GAPER.id)

--break ice hazard
function REVEL.BreakIceHazard(npc)
    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FREEZE_SHATTER, 0.95, 0, false, 1)
    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_ROCK_CRUMBLE, 0.95, 0, false, 1.05)
    for i=1, 8 do
        REVEL.SpawnIceRockGib(npc.Position, Vector.FromAngle(1*math.random(0, 360)):Resized(math.random(1, 5)), npc, npc:GetData().DarkIce and REVEL.IceGibType.DARK or REVEL.IceGibType.DEFAULT)
    end

    local npctype = nil
    local npcvariant = nil
    local gaperSkin = nil
    local explode = nil
    if npc.Variant == REVEL.ENT.ICE_HAZARD_GAPER.variant then
        npctype = EntityType.ENTITY_GAPER
        npcvariant = 1
        gaperSkin = tostring(npc:GetData().Skin)
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_DRIFTY.variant then
        npctype = REVEL.ENT.DRIFTY.id
        npcvariant = REVEL.ENT.DRIFTY.variant
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_HORF.variant then
        npctype = EntityType.ENTITY_HORF
        npcvariant = 0
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_HOPPER.variant then
        npctype = EntityType.ENTITY_HOPPER
        npcvariant = 0
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_CLOTTY.variant then
        npctype = EntityType.ENTITY_CLOTTY
        npcvariant = 0
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_BROTHER.variant then
        npctype = REVEL.ENT.BROTHER_BLOODY.id
        npcvariant = REVEL.ENT.BROTHER_BLOODY.variant
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_BOMB.variant then
        explode = true
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_IBLOB.variant then
        npctype = EntityType.ENTITY_CLOTTY
        npcvariant = 2
    elseif npc.Variant == REVEL.ENT.ICE_HAZARD_EMPTY.variant then
        npctype = nil
        npcvariant = nil
    end

    local smackVel
    smackVel = npc:GetData().ChuckSmackVel or nil

    local shotVel, shotRotated
    shotVel = npc:GetData().BreakShotVel or nil
    shotRotated = npc:GetData().BreakShotRotated or nil

    if shotVel then
        local rotated = 0
        if shotRotated == 1 then rotated = 45 end
        for i = 1, 4 do
            Isaac.Spawn(9, 4, 0, npc.Position, Vector.FromAngle((i * 90) + rotated) * shotVel, npc)
        end
    end

    if npc:ToNPC() then

        npc:Remove()

        if explode then
            Isaac.Explode(npc.Position, npc, 1)
        end

        if npctype and npcvariant then

            preventHazardPoof = REVEL.game:GetFrameCount()

            local enemy = Isaac.Spawn(npctype, npcvariant, 0, npc.Position, Vector(0,0), npc.SpawnerEntity or npc):ToNPC()
            enemy.SpawnerEntity = npc.SpawnerEntity or npc
            local enemySprite = enemy:GetSprite()

            if not REVEL.STAGE.Glacier:IsStage() then
                REVEL.ForceReplacement(enemy, "Glacier")
            end

            if smackVel then
                enemy:GetData().ChuckSmacked = smackVel
                enemy:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                REVEL.sfx:Play(SoundEffect.SOUND_PUNCH)
            else
                enemy.State = NpcState.STATE_APPEAR
            end

            enemy:Update()
            enemySprite:Play("Appear", true)
            enemy.Visible = true
            enemy.HitPoints = enemy.MaxHitPoints
            enemy:GetData().FromIceHazard = true

            if npctype == EntityType.ENTITY_GAPER then
                enemySprite:ReplaceSpritesheet(1, "gfx/monsters/revel1/reskins/glacier_gaper" .. gaperSkin .. ".png")
                enemySprite:LoadGraphics()
            end

            if ShutsDoorsInClearStartRooms and REVEL.WasRoomClearFromStart() then
                enemy:GetData().IceHazardKeepDoorsClosed = true
                if not REVEL.GlacierDoorCloseDoneThisRoom then
                    REVEL.room:SetClear(false)
                    REVEL.ShutDoors()
                    REVEL.GlacierDoorCloseDoneThisRoom = true
                end
            end

            return enemy

        end

    end
end

--main ai
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    local spr, data = npc:GetSprite(), npc:GetData()

    if data.LockedInPlaceTime then
        data.LockedInPlaceTime = data.LockedInPlaceTime - 1
        if data.LockedInPlaceTime <= 0 then
            data.LockedInPlaceTime = nil
            data.LockedInPlace = nil
        else
            data.LockedInPlace = true
        end
    end

    npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    npc:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)

    if data.LockedInPlace then
        if type(data.LockedInPlace) == "boolean" then
            data.LockedInPlace = npc.Position
        end

        npc.Velocity = Vector.Zero
        npc.Position = data.LockedInPlace
        
        if REVEL.ZPos.GetPosition(npc) == 0 then
            if not data.EmbeddedFrame then
                data.EmbeddedFrame = REVEL.randomFrom(EmbeddedFrames)
            end
            spr:SetLayerFrame(3, data.EmbeddedFrame)
        elseif data.EmbeddedFrame then
            spr:SetLayerFrame(3, NonEmbeddedFrame)
            data.EmbeddedFrame = nil
        end
    elseif data.EmbeddedFrame then
        data.EmbeddedFrame = nil
        spr:SetLayerFrame(3, NonEmbeddedFrame)
    end

    local vel = npc.Velocity:Length()
    if data.VelocityLength ~= vel then
        if data.VelocityLength and vel < data.VelocityLength then
            npc.Velocity = npc.Velocity:Resized(data.VelocityLength)
        else
            data.VelocityLength = vel
        end
    end

    if vel < 0.1 then
        data.NotMovingLastFrame = true
    elseif data.NotMovingLastFrame and not data.SpawnedGibs then
        for i = 1, 3 do
            REVEL.SpawnIceRockGib(npc.Position, RandomVector() * math.random(1, 4), npc, npc:GetData().DarkIce and REVEL.IceGibType.DARK or REVEL.IceGibType.DEFAULT)
            end
        data.NotMovingLastFrame = nil
        data.SpawnedGibs = true
    end

    if vel > 4 then
        data.DustLastPos = data.DustLastPos or npc.Position

        if data.DustLastPos:DistanceSquared(npc.Position) > 30*30 then
            ---@type EntityEffect
            local dust = Isaac.Spawn(
                1000, 
                EffectVariant.DUST_CLOUD, 
                0, 
                npc.Position, 
                Vector.Zero, 
                npc
            ):ToEffect()
            dust.Timeout = math.random(30, 45)
            dust.LifeSpan = dust.Timeout
            dust.Color = Color(1.25, 1.25, 1.25, 0.75, 0.5, 0.5, 0.5)
            dust.DepthOffset = -75

            data.DustLastPos = npc.Position
        end
    end

    if REVEL.IsShrineEffectActive(ShrineTypes.FRAGILITY) and not data.LockedInPlace and (vel < 0.1 or data.Creeping)
    and npc.Variant ~= REVEL.ENT.ICE_HAZARD_EMPTY.variant then
        REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)
    
        if not data.Creeping then
            if not data.CreepingDelay then
                data.CreepingDelay = math.random(10, 20)
            else
                data.CreepingDelay = data.CreepingDelay - 1
                if data.CreepingDelay <= 0 then
                    if data.Path then
                        REVEL.FollowPath(npc, 3, data.Path, true, 0.9)
                    else
                        npc.Velocity = (npc:GetPlayerTarget().Position - npc.Position):Resized(3)
                    end
                    data.Creeping = true
                    data.CreepingDelay = nil
                end
            end
        end

        if data.Creeping then
            if vel > 3 then
                data.Creeping = nil
            else
                npc.Velocity = npc.Velocity * 0.9
                if npc.Velocity:LengthSquared() < 0.2 ^ 2 then
                    data.Creeping = nil
                    npc.Velocity = Vector.Zero
                end
                data.VelocityLength = nil
            end
        end
    end

    -- bounced toward target
    if data.HazardTime then
        data.HazardTime = data.HazardTime + 1
        if data.HazardTime <= data.HazardFlightTime then
            npc.Velocity = REVEL.Lerp(data.HazardStart, data.HazardTarget, data.HazardTime / data.HazardFlightTime) - npc.Position
        else
            data.HazardTime = nil

            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
            npc.Position = data.HazardTarget
            npc.Velocity = Vector.Zero
            data.VelocityLength = nil
            data.NoBreak = nil
        end
    end

    if not data.NoBreak then
        local doBreak = REVEL.room:GetGridCollisionAtPos(npc.Position + npc.Velocity) > GridCollisionClass.COLLISION_NONE

        if not doBreak then
            local stalagSpikes = REVEL.ENT.STALAGMITE_SPIKE:getInRoom()

            for _, spike in pairs(stalagSpikes) do
                if spike.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE and spike.Position:DistanceSquared(npc.Position) < (spike.Size + npc.Size)^2 then
                    doBreak = true
                    spike:GetSprite():Play("Explode" .. spike:GetData().randomnum, false)
                end
            end
        end

        if doBreak or (npc:IsDead() and not data.Overkill) then
            REVEL.BreakIceHazard(npc)
        end
    end
end, REVEL.ENT.ICE_HAZARD_GAPER.id)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    local data = npc:GetData()

    if data.IceHazardKeepDoorsClosed then
        REVEL.room:KeepDoorsClosed()
    end

    if data.ChuckSmacked then
        npc.Velocity = data.ChuckSmacked
        data.ChuckSmacked = REVEL.Lerp(data.ChuckSmacked,Vector.Zero,0.1)

        if data.ChuckSmacked:Length() < 1 then
            data.ChuckSmacked = nil
        end
    end
end)

local EntToIceHazardToConvert = {
    [EntityType.ENTITY_GAPER] = REVEL.ENT.ICE_HAZARD_GAPER,
    [REVEL.ENT.DRIFTY.id] = REVEL.ENT.ICE_HAZARD_DRIFTY,
    [EntityType.ENTITY_HORF] = REVEL.ENT.ICE_HAZARD_HORF,
    [EntityType.ENTITY_HOPPER] = REVEL.ENT.ICE_HAZARD_HOPPER,
    [REVEL.ENT.BROTHER_BLOODY] = REVEL.ENT.ICE_HAZARD_BROTHER,
    [{id = EntityType.ENTITY_CLOTTY, variant = 0}] = REVEL.ENT.ICE_HAZARD_CLOTTY,
    [{id = EntityType.ENTITY_CLOTTY, variant = 2}] = REVEL.ENT.ICE_HAZARD_IBLOB,
}
--Convert to faster accessible format, the one above is just faster to write
REVEL.EntToIceHazardIds = {}
for entityInfo, iceHazardDef in pairs(EntToIceHazardToConvert) do
    if type(entityInfo) == "table" then
        REVEL.EntToIceHazardIds[entityInfo.id] = REVEL.EntToIceHazardIds[entityInfo.id] or {}
        REVEL.EntToIceHazardIds[entityInfo.id][entityInfo.variant] = iceHazardDef
    else
        REVEL.EntToIceHazardIds[entityInfo] = iceHazardDef
    end
end

function REVEL.GetIceHazardForEnt(entity)
    local hazardDef
    --Either use one table for all variants, or a table for each variant
    if REVEL.EntToIceHazardIds[entity.Type] then
        if REVEL.EntToIceHazardIds[entity.Type].id then
            hazardDef = REVEL.EntToIceHazardIds[entity.Type]
        elseif REVEL.EntToIceHazardIds[entity.Type][entity.Variant] then
            hazardDef = REVEL.EntToIceHazardIds[entity.Type][entity.Variant]
        end
    end
    return hazardDef
end

function REVEL.MorphToIceHazard(entity, lockTime, spiked)
    local hazardDef = REVEL.GetIceHazardForEnt(entity)
    if hazardDef then
        entity:ToNPC():Morph(hazardDef.id, hazardDef.variant, 0, -1)
        entity:RemoveStatusEffects()
        REVEL.sfx:Play(REVEL.SFX.LOW_FREEZE, 1, 0, false, 1.4)
        REVEL.SpawnMeltEffect(entity.Position)
        if lockTime then
            entity:GetData().LockedInPlaceTime = lockTime
        end
        if spiked then
            REVEL.AddSpikesToIceHazard(entity, true)
        end
        iceHazardInit(entity)
        return true
    end
end

-- prevent horf insta shooting
local function icehazardHorfPreUpdate(_, npc)
    if npc:GetData().FromIceHazard and npc.FrameCount <= 60 then
        local sprite = npc:GetSprite()
        if sprite:IsPlaying("Attack") then
            sprite:Play("Shake", true)
        end
    end
end

revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, icehazardHorfPreUpdate, EntityType.ENTITY_HORF)

local function icehazardDmg(_, npc, amount, flags)
    if HasBit(flags, DamageFlag.DAMAGE_EXPLOSION) 
    or HasBit(flags, DamageFlag.DAMAGE_FIRE) 
    or HasBit(flags, DamageFlag.DAMAGE_CRUSH) then
        if amount > npc.MaxHitPoints*5 then
            npc:GetData().Overkill = true
            REVEL.sfx:Play(SoundEffect.SOUND_FREEZE_SHATTER, 0.95, 0, false, 1)
            REVEL.sfx:Play(SoundEffect.SOUND_ROCK_CRUMBLE, 0.95, 0, false, 1.05)
        end
    else
        return false
    end
end
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, icehazardDmg, REVEL.ENT.ICE_HAZARD_GAPER.id)


end