local EffectVariantExtra = require "scripts.revelations.common.enums.EffectVariantExtra"
local EffectSubtype      = require "scripts.revelations.common.enums.EffectSubtype"
local RevCallbacks      = require "scripts.revelations.common.enums.RevCallbacks"

return function()

local DefaultTracerOffset = Vector(0, -20) -- hardcoded offset within the laser tracers

---@param position Vector
---@param duration integer
---@param direction Vector # absolute room position, unlike the tracer property which is relative to the start
---@param color? Color
---@param parent? Entity
---@param scale? number | Vector
---@return EntityEffect
local function SpawnDeathsHeadTracer(position, duration, direction, color, parent, scale)
    local effect = Isaac.Spawn(1000, EffectVariant.GENERIC_TRACER, 0, position, Vector.Zero, parent):ToEffect()
    effect.PositionOffset = -DefaultTracerOffset
    local data = REVEL.GetData(effect)
    effect.LifeSpan = duration
    effect.Timeout  = effect.LifeSpan
    effect.TargetPosition = direction -- tracers use relative position from their start pos
    if color then
        effect.Color = color
    end
    if parent then
        effect.Parent = parent
        effect:FollowParent(parent)
    end
    if scale then
        if type(scale) == "number" then
            effect.SpriteScale = Vector.One * scale
        else
            effect.SpriteScale = scale
        end
    end

    -- It flashes at full opacity for a frame
    -- go around it this way
    effect:Update()

    return effect
end

---Spawns a Death's Head tracer with simplifed params
-- Warning: this will end up at a fixed length depending on direction due to vanilla logic
---@param position Vector
---@param duration integer
---@param direction Vector # absolute room position, unlike the tracer property which is relative to the start
---@param color? Color
---@param parent? Entity
---@param scale? number | Vector
---@return EntityEffect
function REVEL.MakeLaserTracerAngleDir(position, duration, direction, color, parent, scale)
    REVEL.Assert(position, "MakeLaserTracerAngleDir: position nil!", 2)
    REVEL.Assert(duration, "MakeLaserTracerAngleDir: duration nil!", 2)
    REVEL.Assert(direction, "MakeLaserTracerAngleDir: direction nil!", 2)

    return SpawnDeathsHeadTracer(position, duration, direction, color, parent, scale)
end

---Spawns a Death's Head tracer with simplifed params
-- Warning: this will end up at a fixed length depending on direction due to vanilla logic
---@param position Vector
---@param duration integer
---@param targetPosition Vector # absolute room position, unlike the tracer property which is relative to the start
---@param color? Color
---@param parent? Entity
---@param scale? number | Vector
---@return EntityEffect
function REVEL.MakeLaserTracer(position, duration, targetPosition, color, parent, scale)
    REVEL.Assert(position, "MakeLaserTracer: position nil!", 2)
    REVEL.Assert(duration, "MakeLaserTracer: duration nil!", 2)
    REVEL.Assert(targetPosition, "MakeLaserTracer: targetPosition nil!", 2)

    return SpawnDeathsHeadTracer(position, duration, targetPosition - position, color, parent, scale)
end

---Spawns a Death's Head tracer with simplifed params
-- Warning: this will end up at a fixed length depending on direction due to vanilla logic
---@param position Vector
---@param duration integer
---@param angle number # absolute room position, unlike the tracer property which is relative to the start
---@param color? Color
---@param parent? Entity
---@param scale? number | Vector
---@return EntityEffect
function REVEL.MakeLaserTracerAngle(position, duration, angle, color, parent, scale)
    REVEL.Assert(position, "MakeLaserTracerAngle: position nil!", 2)
    REVEL.Assert(duration, "MakeLaserTracerAngle: duration nil!", 2)
    REVEL.Assert(angle, "MakeLaserTracerAngle: angle nil!", 2)

    return SpawnDeathsHeadTracer(position, duration, Vector.FromAngle(angle), color, parent, scale)
end

---Use in case you want the deaths head tracer to be longer, 
-- spawns an additional one that follows the parent
---@param parent EntityEffect
---@param offset number
---@param scale? number | Vector
---@return EntityEffect
function REVEL.SpawnLaserTracerExtension(parent, offset, scale)
    REVEL.Assert(parent, "SpawnLaserTracerExtension: parent nil!", 2)
    REVEL.Assert(offset, "SpawnLaserTracerExtension: offset nil!", 2)

    local pos = parent.Position + parent.TargetPosition:Resized(offset)
    local e = SpawnDeathsHeadTracer(
        pos, 
        parent.LifeSpan, 
        parent.TargetPosition, 
        parent.Color, 
        parent.Parent, 
        parent.SpriteScale * (scale or 1)
    )
    e.Timeout = parent.Timeout

    REVEL.GetData(e).TracerExtension = {
        Parent = parent,
        Offset = offset,
    }

    return e
end

---@param effect EntityEffect
local function tracerExtension_PostEffectUpdate(_, effect)
    local data = REVEL.GetData(effect)

    if data.TracerExtension then
        ---@type EntityEffect
        local parent = data.TracerExtension.Parent

        effect.Timeout = parent.Timeout
        effect.Color = parent.Color

        effect.TargetPosition = parent.TargetPosition

        effect.Position = parent.Position + parent.TargetPosition:Resized(data.TracerExtension.Offset)

        effect.Velocity = parent.Velocity
    end
end


function REVEL.SpawnFireParticles(entityOrPosition, yOffset, xDistance, replaceFrameCount, spritesheet, replaceMod)
    if (replaceFrameCount or entityOrPosition.FrameCount) % (replaceMod or 4) == 0 then
        local entity = entityOrPosition.Position and entityOrPosition
        local part = Isaac.Spawn(
            1000,
            EffectVariant.EMBER_PARTICLE,
            0,
            (entityOrPosition.Position or entityOrPosition)
                + Vector((math.random() * 2 - 1)
                    * (xDistance or entity.Size), yOffset),
            REVEL.VEC_UP * 3,
            entity
        )
        if spritesheet then
            part:GetSprite():ReplaceSpritesheet(0, spritesheet)
            part:GetSprite():LoadGraphics()
        end
        part.Parent = entity
        return part
    end
end

local SubtypesForPart = {
    [EffectVariant.TOOTH_PARTICLE] = 1,
}

---@param anm2 string
---@param position Vector
---@param velocity Vector
---@param variant? integer
---@param parent? Entity
---@return Entity
function REVEL.SpawnParticleGibs(anm2, position, velocity, variant, parent)
    local eff = Isaac.Spawn(
        1000, 
        variant or EffectVariant.DIAMOND_PARTICLE, 
        SubtypesForPart[variant] or 0, 
        position, 
        velocity or Vector.Zero,
        parent
    )
    local sprite = eff:GetSprite()
    local anim = sprite:GetAnimation()
    sprite:Load(anm2, true)
    sprite:Play(anim, true)

    return eff
end


---Spawn Gideon suction effect, keep doing every frame it should
---be active as this handles timing etc
---@param entity Entity
---@param offset? Vector
---@param spriteOffset? Vector
---@param scale? number
function REVEL.DoGideonSuctionEffect(entity, offset, spriteOffset, scale)
    scale = scale or 1
    local basePos = entity.Position + (offset or Vector.Zero)

    if entity.FrameCount % 6 == 0 then
        ---@type EntityEffect
        local eff = Isaac.Spawn(
            1000,
            EffectVariantExtra.GIDEON_ATTRACT_RING,
            EffectSubtype.GIDEON_ATTRACT_RING,
            basePos,
            Vector.Zero,
            entity
        ):ToEffect()

        eff.MaxRadius = (math.random() * 0.3 + 1.25) * scale
        eff.SpriteOffset = spriteOffset
        eff:Update()
    end

    if entity.FrameCount % 3 == 0 then
        ---@type EntityEffect
        local eff = Isaac.Spawn(
            1000,
            EffectVariantExtra.GIDEON_ATTRACT_TAIL,
            EffectSubtype.GIDEON_ATTRACT_TAIL,
            basePos,
            Vector.Zero,
            entity
        ):ToEffect()

        eff.MaxRadius = 20 * scale
        eff:GetSprite().Rotation = math.random(360)
        eff.SpriteOffset = spriteOffset
        eff:Update()
    end
end


--- Spawn trail effect, such as the one used by b judas
-- credits: Eevee mod by Sanio
---@param parent Entity
---@param color? Color
---@param offset? Vector
---@param width? number
---@param despawnSpeed? number
---@param noFollow? boolean
function REVEL.SpawnTrailEffect(parent, color, offset, width, despawnSpeed, noFollow)
    local trail = Isaac.Spawn(
        EntityType.ENTITY_EFFECT, 
        EffectVariant.SPRITE_TRAIL, 
        0, 
        parent.Position + (offset or Vector.Zero), 
        Vector.Zero, 
        nil
    ):ToEffect()

    trail.Parent = parent
    if not noFollow then
        trail:FollowParent(parent)
    end
    if color then
        trail.Color = color
    end
    if offset then
        trail.ParentOffset = offset
    end
    if width then
        trail.SpriteScale = Vector(width, 1)
    end
    -- How fast the trail "despawns" behind you. The shorter the number the longer the trail.
    trail.MinRadius = despawnSpeed or 0.2
    trail.RenderZOffset = -10
    trail:Update()

    return trail
end


function REVEL.SpawnMeltEffect(pos, doSound, noCreep)
    if doSound == nil then doSound = true end

    if not noCreep then
        REVEL.SpawnIceCreep(pos, nil)
    end
    local poof = Isaac.Spawn(1000, EffectVariant.POOF01, 0, pos, Vector.Zero, nil)
    poof.Color = Color(1, 1, 1, 1, conv255ToFloat(50, 90, 120))

    if doSound then
        REVEL.sfx:Play(SoundEffect.SOUND_FIREDEATH_HISS, 0.5, 0, false, 1.1 + math.random() * 0.3)
    end

    for i = 1, 4 do
        REVEL.SpawnIceRockGib(pos, Vector.FromAngle(1 * math.random(0, 360)):Resized(math.random(1, 5)), nil)
    end
end

local normal = Color(1, 1, 1, 1)

local function thunderUpdate(ent)
    REVEL.GetData(ent).targ:MultiplyFriction(0)
end

function REVEL.SpawnThunder(ent, color)
    local t = REVEL.SpawnDecorationFromTable(ent.Position, Vector.Zero, {
        Sprite = "gfx/effects/revel2/resurrect_lightning.anm2",
        Anim = "Shock",
        RemoveOnAnimEnd = false,
        Color = color,
        Update = thunderUpdate,
    })

    REVEL.GetData(t).targ = ent
    ent.Color = color
    REVEL.GetData(ent).Thunder = t
    REVEL.GetData(ent).ThunderColor = color
    REVEL.sfx:Play(REVEL.SFX.BUFF_LIGHTNING, 1, 0, false, 1)
    REVEL.SpawnLightFlash(ent.Position, color, 3, false, 11, 7)
end

local colorFrames = 10

local function thunder_EntUpdate(_, ent)
    local data = REVEL.GetData(ent)
    if data.Thunder and (not data.Thunder:Exists() or data.Thunder.FrameCount > 10) then
        if not data.ThunderColorFrames then
            data.ThunderColorFrames = 0
        end

        ent.Color = Color.Lerp(data.ThunderColor, normal, data.ThunderColorFrames / colorFrames)

        if data.ThunderColorFrames == colorFrames then
            data.Thunder = nil
            data.ThunderColorFrames = nil
        else
            data.ThunderColorFrames = data.ThunderColorFrames + 1
        end
    end
end

function REVEL.SpawnSandGibs(position, velocity, spawner)
    velocity = velocity or Vector.Zero
    local eff = Isaac.Spawn(1000, EffectVariant.POOP_PARTICLE, 0, position, velocity, spawner)
    eff:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel2/sand_gibs.png")
    eff:GetSprite():LoadGraphics()
    return eff
end

local PULSE_ENT_SUBTYPE = 300

---Spawns a shockwave like monstro's effect in rep
---@param position Vector
---@param big? boolean
---@param noDelay? boolean
function REVEL.SpawnBlurShockwave(position, big, noDelay)
    local toRun = function()
        if big then
            Isaac.Spawn(EntityType.ENTITY_MONSTRO, 0, PULSE_ENT_SUBTYPE, position, Vector.Zero, nil)
        else
            Isaac.Spawn(EntityType.ENTITY_PORTAL, 0, PULSE_ENT_SUBTYPE, position, Vector.Zero, nil)
        end
    end
    if noDelay then
        toRun()
    else
        -- won't work inside npc updates else for some reason
        REVEL.DelayFunction(toRun, 0)
    end
end

-- Pulse Effect (Small)
-- From Fiend Folio, credits to sbody

local function pulseSmall_PostNpcInit(_, npc)
    if npc.SubType == PULSE_ENT_SUBTYPE then
        npc.SplatColor = REVEL.NO_COLOR
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        npc.Visible = false
        npc.EntityCollisionClass = 0
        npc.Position = npc.Position + Vector(0, 20)
        for i = 0, 16 do
            npc:Update()
        end
        REVEL.DelayFunction(function()
            npc:Remove()
            REVEL.sfx:Stop(SoundEffect.SOUND_DEATH_BURST_LARGE)
            REVEL.sfx:Stop(161)
        end, 0)
    end
end

local function pulseSmall_PreEntitySpawn(_, typ, var, subt, pos, vel, spawner, seed)
    if spawner and spawner.Type == EntityType.ENTITY_PORTAL and spawner.SubType == PULSE_ENT_SUBTYPE then
        return { 1000, 122, 0, seed }
    end
end

local function pulseSmall_PreNpcCollision(_, npc1, npc2)
    if npc1.SubType == PULSE_ENT_SUBTYPE then return true end
end

-- Pulse Effect (Big)

local function pulseBig_PostNpcInit(_, npc)
    if npc.SubType == PULSE_ENT_SUBTYPE then
        npc.SplatColor = REVEL.NO_COLOR
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        npc.Visible = false
        npc.State = NpcState.STATE_STOMP
        npc.EntityCollisionClass = 0
        npc.Position = npc.Position + Vector(0, -10)
        local sprite = npc:GetSprite()
        sprite:Play("JumpDown", true)
        REVEL.SkipAnimFrames(sprite, 32)
        REVEL.DelayFunction(function()
            npc:Remove()
            REVEL.sfx:Stop(SoundEffect.SOUND_FORESTBOSS_STOMPS)
        end, 0)
    end
end

local function pulseBig_PreEntitySpawn(_, typ, var, subt, pos, vel, spawner, seed)
    if spawner and spawner.Type == 20 and spawner.SubType == PULSE_ENT_SUBTYPE then
        return { 1000, EffectVariant.BIG_HORN_HOLE_HELPER, 0, seed }
    end
end

local function pulseBig_PreNpcCollision(_, npc1, npc2)
    if npc1.SubType == PULSE_ENT_SUBTYPE then return true end
end

function REVEL.BishopShieldEffect(npc, offset, scale, parent, sfx)
    local shield = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BISHOP_SHIELD, 0, npc.Position, Vector.Zero, parent or npc):ToEffect()
    shield.Target = npc
    shield.SpriteOffset = offset or Vector(0,-15)
    shield.SpriteScale = scale or Vector.One
    if parent then
        shield.Parent = parent
    end

    if sfx == nil then
        sfx = true
    end
    if sfx then
        REVEL.sfx:Play(SoundEffect.SOUND_BISHOP_HIT, 0.8)
    end

    return shield
end
    
function REVEL.SpawnDustParticles(position, numParticles, spawner, color, velMin, velMax, scaleMin, scaleMax)
    local offset = math.random(0, 359)
    velMin = velMin or 500
    velMax = velMax or 800
    scaleMin = scaleMin or 100
    scaleMax = scaleMax or 150
    color = color or Color(1, 1, 1, 1,conv255ToFloat( 110, 90, 60))
    for i = 1, numParticles do
        local dustVelocity = Vector.FromAngle(offset + i * (360 / numParticles)) * math.random(velMin, velMax) * 0.01
        local dust = Isaac.Spawn(1000, EffectVariant.DARK_BALL_SMOKE_PARTICLE, 0, position, dustVelocity, spawner)
        dust.Color = color
        dust.SpriteScale = Vector(1, 1) * (math.random(scaleMin, scaleMax) * 0.01)
        local extraUpdates = math.random(0,2)
        if extraUpdates > 0 then
            for i=1, extraUpdates do
                dust:Update()
            end
        end
    end
end


function REVEL.SpawnCustomShockwave(pos, vel, gfx, timeout, collision, spawnrate, minVarianceEachSpawn, maxVarianceEachSpawn, soundEachSpawn, onCollide, onUpdate, specialCollisionCheck)
    local lead = Isaac.Spawn(REVEL.ENT.CUSTOM_SHOCKWAVE.id, REVEL.ENT.CUSTOM_SHOCKWAVE.variant, 0, pos, vel, nil)
    spawnrate = spawnrate or math.floor(lead.Size / (vel:Length() / 2))
    collision = collision or EntityGridCollisionClass.GRIDCOLL_GROUND
    lead.Size = math.floor(lead.Size * 1.5)
    lead.GridCollisionClass = collision
    lead.Visible = false
    local ldata = REVEL.GetData(lead)
    ldata.LeadShockwave = true
    ldata.Spawnrate = spawnrate
    ldata.Timeout = timeout
    ldata.Gfx = gfx
    ldata.MinVarianceEachSpawn = minVarianceEachSpawn
    ldata.MaxVarianceEachSpawn = maxVarianceEachSpawn
    ldata.SoundEachSpawn = soundEachSpawn
    ldata.OnCollide = onCollide
    ldata.OnUpdate = onUpdate
    ldata.SpecialCollisionCheck = specialCollisionCheck
    return lead
end

--for effects :CollidesWithGrid seemsto only work with walls used with effects
local function schockwaveCollides(eff)
    if eff:CollidesWithGrid() then return true end

    for i = 1, 2 do
        local pos
        if i == 1 then
            pos = eff.Position
        else
            pos = eff.Position + eff.Velocity
        end

        local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(pos))

        if grid and grid.Desc.Type == GridEntityType.GRID_PIT then
            return true
        end
    end

    return false
end

local function shockwavePostEffectUpdate(_, eff)
    local data = REVEL.GetData(eff)
    if data.LeadShockwave then
        if data.OnUpdate then
            data.OnUpdate(eff)
        end

        if data.Timeout then
            data.Timeout = data.Timeout - 1
            if data.Timeout <= 0 then
                eff:Remove()
                return
            end
        end

        local collided
        if (data.SpecialCollisionCheck and data.SpecialCollisionCheck(eff)) or (not data.SpecialCollisionCheck and schockwaveCollides(eff)) then
            collided = true
            if data.OnCollide then
                local ret = data.OnCollide(eff)
                if ret == false or not eff:Exists() then
                    return
                end
            else
                eff:Remove()
                return
            end
        end

        if eff.FrameCount % data.Spawnrate == 0 and not collided then
            local shock = Isaac.Spawn(REVEL.ENT.CUSTOM_SHOCKWAVE.id, REVEL.ENT.CUSTOM_SHOCKWAVE.variant, 0, eff.Position, Vector.Zero, nil)
            REVEL.GetData(shock).IgnoreRocks = data.IgnoreRocks
            if data.Gfx then
                local sprite = shock:GetSprite()
                sprite:ReplaceSpritesheet(0, data.Gfx)
                sprite:LoadGraphics()
            end

            if data.Color then
                local sprite = shock:GetSprite()
                sprite.Color = data.Color
                REVEL.GetData(shock).Color = data.Color
            end

            if data.MinVarianceEachSpawn then
                local min, max = data.MinVarianceEachSpawn, data.MaxVarianceEachSpawn
                if not max then
                    max = min
                    min = -min
                end

                eff.Velocity = eff.Velocity:Rotated(math.random(min, max))
            end

            if data.SoundEachSpawn then
                REVEL.sfx:Play(data.SoundEachSpawn, 0.25, 0, false, 1)
            end
        end
    else
        local sprite = eff:GetSprite()
        for _, player in ipairs(REVEL.players) do
            if player.Position:Distance(eff.Position) < player.Size + eff.Size then
                player:TakeDamage(1, DamageFlag.DAMAGE_EXPLOSION, EntityRef(eff), 0)
            end
        end

        if sprite:IsFinished("Break") then
            eff:Remove()
        end

        if not data.IgnoreRocks then
            local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(eff.Position))
            if grid and grid:ToRock() then
                grid:Destroy(false)
            end
        end
    end
end

--Lamb dash trail
local dashEntities = {}

local function isColor(c)
    return getmetatable(c) == getmetatable(Color).__class
end

---Leave a Lamb-like trail behind the entity
---@param entity Entity
---@param frameDelay integer
---@param duration number
---@param anim? string
---@param color? Color
---@overload fun(entity, frameDelay: integer, duration: number, color: any)
function REVEL.DashTrailEffect(entity, frameDelay, duration, anim, color)
    if isColor(anim) then
        color = anim
        anim = nil
    end

    REVEL.GetData(entity).DashTrailFrameDelay = frameDelay
    REVEL.GetData(entity).DashTrailFrameDuration = duration
    REVEL.GetData(entity).DashTrailAdded = entity.FrameCount

    REVEL.GetData(entity).DashTrailAnimation = anim or entity:GetSprite():GetAnimation()
    REVEL.GetData(entity).DashTrailColor = color or Color.Default

    local hash = GetPtrHash(entity)
    if not dashEntities[hash] then
        dashEntities[hash] = entity
    end
end

local function dashTrailPostUpdate()
    local toRemove = {}
    for hash, entity in pairs(dashEntities) do
        local data = REVEL.GetData(entity)
        if not entity or not entity:Exists() 
        or not data.DashTrailAdded 
        or entity.FrameCount - data.DashTrailAdded > 2 then
            toRemove[#toRemove + 1] = hash
        elseif entity.FrameCount % data.DashTrailFrameDelay == 0 then
            local sprite = entity:GetSprite()
            local deco = REVEL.SpawnDecoration(entity.Position, Vector.Zero,
                data.DashTrailAnimation,
                sprite:GetFilename(),
                nil,
                0,
                data.DashTrailFrameDuration,
                nil,
                nil,
                sprite:GetFrame(),
                false,
                data.DashTrailColor
            )
            deco:GetSprite().FlipX = sprite.FlipX
            deco:GetSprite().FlipY = sprite.FlipY
        end
    end

    for _, hash in ipairs(toRemove) do
        dashEntities[hash] = nil
    end
end


--#region Light
---------------------------
-- Custom light and dark --
---------------------------

--[[Useful type/vars:
    -Effects:
    BLUE_FLAME: faint blue light, small, flickering
    RED_CANDLE_FLAME: red light, small, flickering
    FIREWORKS (with subtype 4): firework spark, scalable, can be colored and (vanilla behaviour, disabled by default, set data.DecreaseRadius to true to enable) gets smaller with time
]]

local Lights = {}

StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 2, function()
    local e = Isaac.GetRoomEntities()
    for i, ent in ipairs(e) do
        if REVEL.GetData(ent).CustomLight then
            table.insert(Lights, ent)
        end
    end
end)

function REVEL.SpawnLight(pos, color, size, force, type, variant, subtype)
    if revel.data.cLightSetting > 0 and (REVEL.IsDark() or force) then
        local light = Isaac.Spawn(type or 1000, variant or EffectVariant.FIREWORKS, subtype or 4, pos, Vector.Zero, nil)
        color = REVEL.CloneColor(color)
        light:SetColor(color, -1, 999, false, false) -- maybe not necessary? might've just kept this in when i switched to setting sheet to none
        light:GetSprite():ReplaceSpritesheet(0, "gfx/ui/none.png")
        REVEL.GetData(light).Color = color
        light:GetSprite():LoadGraphics()
        light.SpriteScale = light.SpriteScale * (size or 1)
        REVEL.GetData(light).CustomLight = true
        REVEL.GetData(light).LightColor = color

        if light.Type == 1000 and light.Variant == EffectVariant.FIREWORKS and light.SubType == 4 then
            REVEL.GetData(light).OrigScale = REVEL.CloneVec(light.SpriteScale)
        end

        table.insert(Lights, light)
        return light
    end
end

function REVEL.SpawnLightFlash(pos, color, size, force, time, fade) --fade is after time, both in frames
    local light = REVEL.SpawnLight(pos, color, size, force)
    if light then
        REVEL.GetData(light).FlashTime = time + fade
        REVEL.GetData(light).FlashFade = fade

        return light
    end
end

function REVEL.SpawnLightAtEnt(ent, color, size, offset, followOffset, force, type, variant, subtype)
    local light = REVEL.SpawnLight(ent.Position + (offset or Vector.Zero), color, size or 1, force, type, variant, subtype)
    if light then
        REVEL.GetData(light).lightSpawnerEntity = ent
        REVEL.GetData(light).LightOffset = offset
        REVEL.GetData(light).LightFollowOffset = followOffset --false/true
    end

    return light
end

function REVEL.SetLightSize(light, size)
    light.SpriteScale = light.SpriteScale * size
    if light.Type == 1000 and light.Variant == EffectVariant.FIREWORKS and light.SubType == 4 then
        REVEL.GetData(light).OrigScale = REVEL.CloneVec(light.SpriteScale)
    end
end

local function updateLight(i, light)
    if not light:Exists() then
        table.remove(Lights, i)
        return
    end

    local data = REVEL.GetData(light)

    local disable = data.Disable
    data.Disable = false

    if data.FlashTime then
        data.FlashTime = data.FlashTime - 1
        data.Color.A = REVEL.Lerp2Clamp(0, 1, data.FlashTime, 0, data.FlashFade)
        if data.FlashTime <= 0 then
            light:Remove()
            table.remove(Lights, i)
            return
        end
    end

    if data.lightSpawnerEntity then
        if not data.lightSpawnerEntity:Exists() or data.lightSpawnerEntity:IsDead() then
            light:Remove()
            table.remove(Lights, i)
            return
        else
            disable = disable or (not data.lightSpawnerEntity.Visible) or IsAnimOn(data.lightSpawnerEntity:GetSprite(), "NoFire") or IsAnimOn(data.lightSpawnerEntity:GetSprite(), "Dissapear")
            if data.LightFollowOffset then
                data.LightOffset = data.lightSpawnerEntity.SpriteOffset
                if data.lightSpawnerEntity:ToTear() or data.lightSpawnerEntity:ToProjectile() then
                    data.lightSpawnerEntity = data.lightSpawnerEntity:ToTear() or data.lightSpawnerEntity:ToProjectile()
                    data.LightOffset = data.LightOffset + Vector(0, data.lightSpawnerEntity.Height)
                end
            end

            light.Position = data.lightSpawnerEntity.Position + (data.LightOffset or Vector.Zero)
            light.Velocity = data.lightSpawnerEntity.Velocity
        end
    end

    if disable then
        light.Color = REVEL.NO_COLOR
    else
        light.Color = data.Color
    end

    light = light:ToEffect()
    if light and light.Variant == EffectVariant.FIREWORKS and light.SubType == 4 and not data.DecreaseRadius then
        -- light.State = 1 --keep at max radius
        light.SpriteScale = data.OrigScale
    end
end

local function lights_PostUpdate()
    for i, light in ripairs(Lights) do
        updateLight(i, light)
    end
end

--#endregion

--#region footprints

function REVEL.SpawnFootprint(player, anm2, fade)
    if player:IsFlying() or not player.Visible then return end
    if REVEL.GetData(player).OnDuneTile then return end

    local data = REVEL.GetData(player)
    if data.LastFootprintPosition and data.LastFootprintPosition:DistanceSquared(player.Position) < 8 ^ 2 then
        return
    end

    local offset
    if math.abs(player.Velocity.Y) >= math.abs(player.Velocity.X) then
        offset = Vector(2, 0)
    else
        offset = Vector(0, 2)
    end

    if data.FootprintAlternate then
        offset = -offset
    end

    data.FootprintAlternate = not data.FootprintAlternate
    data.LastFootprintPosition = player.Position

    local eff = StageAPI.SpawnFloorEffect(player.Position + offset, Vector.Zero, nil, anm2, true)
    REVEL.GetData(eff).Footprint = true
    REVEL.GetData(eff).FootprintFade = not not fade
    eff:GetSprite():Play("idle", true)
    if not fade then
        eff:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR)
    end
end

local function footprint_PostEffectUpdate(_, eff)
    local data = REVEL.GetData(eff)
    if data.Footprint and data.FootprintFade then
        if eff.FrameCount > 30 then
            eff.Color = Color.Lerp(
                Color(1, 1, 1, 1), 
                Color(1, 1, 1, 0), 
                (eff.FrameCount - 30) / 30
            )
        end

        if eff.FrameCount > 60 then
            eff:Remove()
        end
    end
end

--#endregion

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, dashTrailPostUpdate)
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, shockwavePostEffectUpdate, REVEL.ENT.CUSTOM_SHOCKWAVE.variant)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, tracerExtension_PostEffectUpdate, EffectVariant.GENERIC_TRACER)
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, thunder_EntUpdate)
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, thunder_EntUpdate)

revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, pulseBig_PostNpcInit, EntityType.ENTITY_MONSTRO)
revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, pulseBig_PreEntitySpawn)
revel:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, pulseBig_PreNpcCollision, EntityType.ENTITY_MONSTRO)
revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, pulseSmall_PostNpcInit, EntityType.ENTITY_PORTAL)
revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, pulseSmall_PreEntitySpawn)
revel:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, pulseSmall_PreNpcCollision, EntityType.ENTITY_PORTAL)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, lights_PostUpdate)
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, footprint_PostEffectUpdate, StageAPI.E.FloorEffect.V)

end