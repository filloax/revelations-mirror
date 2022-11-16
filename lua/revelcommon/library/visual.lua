local EffectVariantExtra = require "lua.revelcommon.enums.EffectVariantExtra"
local EffectSubtype      = require "lua.revelcommon.enums.EffectSubtype"
local StageAPICallbacks  = require "lua.revelcommon.enums.StageAPICallbacks"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

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

    entity:GetData().DashTrailFrameDelay = frameDelay
    entity:GetData().DashTrailFrameDuration = duration
    entity:GetData().DashTrailAdded = entity.FrameCount

    entity:GetData().DashTrailAnimation = anim or entity:GetSprite():GetAnimation()
    entity:GetData().DashTrailColor = color or Color.Default

    local hash = GetPtrHash(entity)
    if not dashEntities[hash] then
        dashEntities[hash] = entity
    end
end

local function dashTrailPostUpdate()
    local toRemove = {}
    for hash, entity in pairs(dashEntities) do
        local data = entity:GetData()
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

-- clutch / purgatory soul tail rendering

---@param segment integer
---@param numSegments integer
---@param effect EntityEffect
---@return Vector
local function GhostTrailGetOffsetDefault(segment, numSegments, effect)
    local vel = effect.Velocity

    -- TODO: remove this when lua extension adds support for metamethods/operators in 3.5
    ---@diagnostic disable-next-line: return-type-mismatch
    return -vel * 5 * segment / numSegments * REVEL.WORLD_TO_SCREEN_RATIO
end

--- clutch / purgatory soul tail rendering
-- to be used in POST_x_RENDER
-- Uses a function to get the segments and offset, 
-- since it depends on the specific thing
---@param entity Entity
---@param sprite Sprite
---@param anim string
---@param layer integer
---@param layerBack integer
---@param numSegments integer
---@param invertFrameOrder? boolean
---@param getOffset? fun(seg: integer, numSegments: integer, e: Entity): Vector
---@param getColor? Color | fun(seg: integer, numSegments: integer, e: Entity): Color
function REVEL.RenderGhostTrail(entity, sprite, anim, layer, layerBack, numSegments, invertFrameOrder, getOffset, getColor)
    getOffset = getOffset or GhostTrailGetOffsetDefault
    local pos = Isaac.WorldToScreen(entity.Position)

    local segmentPosition = {}

    -- Render back layers (outline), then front layers
    -- head is assumed to be handled by the entity

    if getColor then
        sprite.Color = Color.Default
    end
    for i = 1, numSegments do
        local frame = invertFrameOrder and numSegments - i or i - 1
        segmentPosition[i] = pos + getOffset(i, numSegments, entity)
        sprite:SetFrame(anim, frame)
        sprite:RenderLayer(layerBack, segmentPosition[i])
    end

    for i = 1, numSegments do
        local frame = invertFrameOrder and numSegments - i or i - 1
        if getColor then
            sprite.Color = (type(getColor) == "function") and getColor(i, numSegments, entity) or getColor
        end
        sprite:SetFrame(anim, frame)
        sprite:RenderLayer(layer, segmentPosition[i])
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
    ent:GetData().targ:MultiplyFriction(0)
end

function REVEL.SpawnThunder(ent, color)
    local t = REVEL.SpawnDecorationFromTable(ent.Position, Vector.Zero, {
        Sprite = "gfx/effects/revel2/resurrect_lightning.anm2",
        Anim = "Shock",
        RemoveOnAnimEnd = false,
        Color = color,
        Update = thunderUpdate,
    })

    t:GetData().targ = ent
    ent.Color = color
    ent:GetData().Thunder = t
    ent:GetData().ThunderColor = color
    REVEL.sfx:Play(REVEL.SFX.BUFF_LIGHTNING, 1, 0, false, 1)
    REVEL.SpawnLightFlash(ent.Position, color, 3, false, 11, 7)
end

local colorFrames = 10

local function thunder_EntUpdate(_, ent)
    local data = ent:GetData()
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

function REVEL.BishopShieldEffect(npc, offset, scale, sfx)
    local shield = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BISHOP_SHIELD, 0, npc.Position, Vector.Zero, npc):ToEffect()
    shield.Target = npc
    shield.SpriteOffset = Vector(0,-15)
    shield.SpriteScale = Vector(1.1,1.1)

    sfx = sfx or true
    if sfx and not REVEL.sfx:IsPlaying(SoundEffect.SOUND_BISHOP_HIT) then
        REVEL.sfx:Play(SoundEffect.SOUND_BISHOP_HIT, 0.6, 0, false, 1)
    end

    return shield
end

--#region FadeToColor

local FadeAboveHud = false
local Fade = REVEL.LazyLoadLevelSprite{
    ID = "lib_Fade",
    Anm2 = "gfx/backdrop/Black.anm2",
}
local DoingScreenFade = false

local function fade_PostUpdate()
    if REVEL.DoingScreenFade() then
        Fade:Update()
        if Fade:IsFinished("FadeIn") then
            Fade:Play("Default", false)
        end
        if Fade:IsFinished("FadeOut") then
            DoingScreenFade = false
        end
    end
end

local function fade_PostRender()
    if not FadeAboveHud and
    REVEL.DoingScreenFade() then
        Fade:RenderLayer(0, Vector.Zero)
    end
end

local function fade_PostRenderHud()
    if FadeAboveHud and
    REVEL.DoingScreenFade() then
        Fade:RenderLayer(0, Vector.Zero)
    end
end

---Fade screen to a color (below hud)
---@param length number in frames
---@param aboveHud? boolean
---@param r? number
---@param g? number
---@param b? number
---@overload fun(length: number, aboveHud?: boolean, lightness?: number)
function REVEL.FadeOut(length, aboveHud, r, g, b)
    if not r then
        Fade.Color = Color.Default
    elseif not g or not b then
        Fade.Color = Color(1,1,1,1, r, r, r)
    else
        Fade.Color = Color(1,1,1,1, r, g, b)
    end

    Fade:Play("FadeIn", true)
    Fade.PlaybackSpeed = 30/length
    FadeAboveHud = not not aboveHud
    DoingScreenFade = true
end

---Fade from `REVEL.FadeOut`
---@param length number in frames
function REVEL.FadeIn(length)
    Fade:Play("FadeOut", true)
    Fade.PlaybackSpeed = 30/length
end

function REVEL.IsFullyFaded()
    return DoingScreenFade and Fade:GetAnimation() == "Default"
end

function REVEL.DoingScreenFade()
    return DoingScreenFade
end

--#region FadeToColor

-- Callbacks

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, dashTrailPostUpdate)
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, thunder_EntUpdate)
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, thunder_EntUpdate)

revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, pulseBig_PostNpcInit, EntityType.ENTITY_MONSTRO)
revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, pulseBig_PreEntitySpawn)
revel:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, pulseBig_PreNpcCollision, EntityType.ENTITY_MONSTRO)
revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, pulseSmall_PostNpcInit, EntityType.ENTITY_PORTAL)
revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, pulseSmall_PreEntitySpawn)
revel:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, pulseSmall_PreNpcCollision, EntityType.ENTITY_PORTAL)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, fade_PostUpdate)
revel:AddCallback(ModCallbacks.MC_POST_RENDER, fade_PostRender)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_HUD_RENDER, 9999, fade_PostRenderHud)

end
