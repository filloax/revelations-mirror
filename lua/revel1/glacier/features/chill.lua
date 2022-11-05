local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local ShrineTypes       = require("lua.revelcommon.enums.ShrineTypes")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-----------------
-- CHILL ROOMS --
-----------------
    
---@type Rev.WarmAuraData[]
local WarmAuras = {}

REVEL.DEFAULT_CHILL_FADE_TIME = 75

function REVEL.GetChillWarmRadius()
    if REVEL.IsShrineEffectActive(ShrineTypes.FROST) then
        return REVEL.GlacierBalance.DefaultWarmRadius * REVEL.GlacierBalance.ChillShrineWarmthMod
    else
        return REVEL.GlacierBalance.DefaultWarmRadius
    end
end

function REVEL.GetChillFreezeRadius()
    if REVEL.IsShrineEffectActive(ShrineTypes.FROST) then
        return REVEL.GlacierBalance.DefaultFreezeRadius * REVEL.GlacierBalance.ChillShrineFreezeMod
    else
        return REVEL.GlacierBalance.DefaultFreezeRadius
    end
end

function REVEL.GetChillFreezingPoint(player)
    local speed = player.MoveSpeed
    local time = REVEL.Lerp2Clamp(
        REVEL.GlacierBalance.ChillTimeToFreeze.LowSpeed, 
        REVEL.GlacierBalance.ChillTimeToFreeze.HighSpeed, 
        speed,
        REVEL.GlacierBalance.ChillTimeToFreeze.EndLow, 
        REVEL.GlacierBalance.ChillTimeToFreeze.EndHigh
    )

    if REVEL.IsShrineEffectActive(ShrineTypes.FROST) then
        time = time * 0.8
    end

    return time
end

function REVEL.EvaluateChill(player)
    local data = player:GetData()
    if data.GlacierChill then
        if data.GlacierChill > 0 then
            player:SetColor( REVEL.ColorLerp2Clamp(Color.Default, REVEL.GlacierBalance.ChillColor, data.GlacierChill, 0, REVEL.GetChillFreezingPoint(player)), 3, 1000, false, false )
        end
    end
end

function REVEL.Freeze(player, noEval)
    player = player or REVEL.player
    local data = player:GetData()
    
    if data.TotalFrozen then return end
    
    if not REVEL.IsChilly() then
        data.FrozenLastFrame = 2
    end
    data.GlacierChill = data.GlacierChill or 0
    data.GlacierChill = math.min(data.GlacierChill + 1, REVEL.GetChillFreezingPoint(player))
    if not noEval then
        REVEL.EvaluateChill(player)
    end
end

function REVEL.Warm(player, noEval, force, forceBonus)
    player = player or REVEL.player
    local data = player:GetData()

    if not data.ForceFrozenTime and data.GlacierChill and (not data.FrozenLastFrame or force) then
        data.GlacierChill = 0
        --data.GlacierChill = math.max(0, data.GlacierChill - mult)
        if not noEval then
            REVEL.EvaluateChill(player)
        end
    end

    -- if forceBonus or (REVEL.IsShrineEffectActive(ShrineTypes.FROST) and REVEL.IsChilly()) then
    if forceBonus then
        local shouldEval = not data.ChillShrineBonus
        data.ChillShrineBonus = 2
        if shouldEval then
            player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
            player:EvaluateItems()
        end
    end

    data.Warmed = true
end

function REVEL.IsChillRoom(currentRoom)
    currentRoom = currentRoom or StageAPI.GetCurrentRoom()
    return currentRoom and REVEL.includes(REVEL.ChillRoomTypes, StageAPI.GetCurrentRoomType())
end

function REVEL.IsChilly(currentRoom)
    currentRoom = currentRoom or StageAPI.GetCurrentRoom()
    return REVEL.IsChillRoom(currentRoom) 
    and (currentRoom.WasClearAtStart or not REVEL.room:IsClear() 
        or currentRoom.PersistentData.ChillShrine or currentRoom.FirstLoad) 
    and not REVEL.WilliwawDisableChill
end

local SOUND_FREEZE = SoundEffect.SOUND_FREEZE

function REVEL.ChillFreezePlayer(player, forceDuration, forceInChillRooms)
    local data = player:GetData()

    if forceDuration == true then
        forceDuration = REVEL.GlacierBalance.DarkIceChillDuration
    end

    local doForce = forceDuration and (forceInChillRooms or not REVEL.IsChilly())

    if ((not REVEL.IsChilly() and forceDuration) or (REVEL.IsChilly() and not data.Warmed)) and not data.TotalFrozen then
        if not data.Frozen then
            data.Frozen = true
            REVEL.sfx:Play(SOUND_FREEZE, 1, 0, false, doForce and 0.9 or 1)
        end

        if REVEL.IsChilly() then
            data.GlacierChill = REVEL.GetChillFreezingPoint(player)
        end

        if doForce then
            data.ForceFrozenTime = forceDuration
        end
    end
end

local CHILL_SNOWBALL_VARIANT = ProjectileVariant.PROJECTILE_TEAR

function REVEL.ShootChillSnowball(source, pos, vel, chillTime)
    local proj = Isaac.Spawn(9, CHILL_SNOWBALL_VARIANT, 0, pos, vel, source):ToProjectile()
    proj:GetData().FreezeOnHit = chillTime
    proj:GetData().IsSnow = true
    proj:GetData().Flomp = true
    proj.SpawnerEntity = source
    proj.Scale = 1.5
    local psprite = proj:GetSprite()
    local anim = psprite:GetAnimation()
    psprite:Load("gfx/effects/revelcommon/projectile_no_flash.anm2", true)
    psprite:Play(anim, true)
    REVEL.sfx:Play(REVEL.SFX.ICE_THROW)
    -- Snowball sprite is the default
    -- psprite:ReplaceSpritesheet(0, "gfx/effects/revel1/snowball_projectiles_chill.png")
    -- psprite:LoadGraphics()

    return proj
end
    

local SnowParticle = REVEL.ParticleType.FromTable{
    Name = "Chill Shot",
    Anm2 =  "gfx/effects/revelcommon/white_particle.anm2",
    BaseLife = 15,
    Variants = 6,
    FadeOutStart = 0.3,
    StartScale = 0.9,
    EndScale = 1.1,
    RotationSpeedMult = 0.2
}
SnowParticle:SetColor(Color(0.5,0.8,1), 0.02)

local SnowParticleSystem = REVEL.ParticleSystems.NoGravity

local SnowParticleEmitterID = "Snow Particle Emitter"

---@param projectile EntityProjectile
local function chillSnowball_PostProjectileUpdate(_, projectile)
    local data = projectile:GetData()

    if data.FreezeOnHit then
        local dir = -projectile.Velocity:Normalized():Rotated(math.random(-30, 30))
        local pos = projectile.Position
        local vel = dir * 5
        local parent = projectile.Parent or projectile.SpawnerEntity
        local emitterParent = parent or projectile
        local emitter = REVEL.GetEntityParticleEmitter(emitterParent, SnowParticleEmitterID)

        if not emitter then
            emitter = REVEL.SphereEmitter(5)
            REVEL.AddEntityParticleEmitter(emitterParent, emitter, SnowParticleEmitterID)
        end
        emitter:EmitParticlesPerSec(
            SnowParticle, 
            SnowParticleSystem, 
            Vec3(pos, -22), 
            Vec3(vel, 0), 
            45, 
            0.4, 
            30
        )
    end
end

---@param projectile EntityProjectile
---@param collider Entity
---@param low boolean
---@return boolean? ignoreCollision
local function chill_PreProjectileCollision(_, projectile, collider, low)
    if projectile:GetData().FreezeOnHit then
        if collider.Type == EntityType.ENTITY_PLAYER then
            REVEL.ChillFreezePlayer(collider:ToPlayer(), projectile:GetData().FreezeOnHit, REVEL.GlacierBalance.DarkIceInChill)
    
            if REVEL.ENT.PRANK_GLACIER:isEnt(projectile.SpawnerEntity) then
                projectile.SpawnerEntity:GetData().FrozePlayerFrame = projectile.SpawnerEntity.FrameCount
            end

            projectile:Die()

            -- Collide but do not run callbacks or internal code
            return false
        elseif collider.Type == EntityType.ENTITY_FAMILIAR 
        and (
            collider.Variant == FamiliarVariant.WISP 
            or collider.Variant == FamiliarVariant.ITEM_WISP
        ) then
            -- Ignore collision
            return true
        end
    end
end

---@param familiar EntityFamiliar
---@param collider Entity
---@param low boolean
---@return boolean? ignoreCollision
local function chill_wisps_PreFamiliarCollision(_, familiar, collider, low)
    if collider.Type == EntityType.ENTITY_PROJECTILE and collider.Variant == CHILL_SNOWBALL_VARIANT
    and collider:GetData().FreezeOnHit then
        -- Ignore collision
        return true
    end
end

local SHOOT_ACTIONS = {
    ButtonAction.ACTION_SHOOTLEFT,
    ButtonAction.ACTION_SHOOTUP,
    ButtonAction.ACTION_SHOOTRIGHT,
    ButtonAction.ACTION_SHOOTDOWN,
}

local FORCE_INPUT_IDS = {
    [InputHook.IS_ACTION_PRESSED] = {
        [ButtonAction.ACTION_SHOOTLEFT] = "chill_left",
        [ButtonAction.ACTION_SHOOTUP] = "chill_up",
        [ButtonAction.ACTION_SHOOTRIGHT] = "chill_right",
        [ButtonAction.ACTION_SHOOTDOWN] = "chill_down",
    },
    [InputHook.GET_ACTION_VALUE] = {
        [ButtonAction.ACTION_SHOOTLEFT] = "chill_get_left",
        [ButtonAction.ACTION_SHOOTUP] = "chill_get_up",
        [ButtonAction.ACTION_SHOOTRIGHT] = "chill_get_right",
        [ButtonAction.ACTION_SHOOTDOWN] = "chill_get_down",
    },
}

-- Handles incubi by directly affecting input,
-- should work better with Repentance
local function KeepShootingDisabled(player)
    for _, action in ipairs(SHOOT_ACTIONS) do
        REVEL.ForceInput(player, action, InputHook.IS_ACTION_PRESSED, false, true)
        REVEL.ForceInput(player, action, InputHook.GET_ACTION_VALUE, 0, true)
    end
end

local function chillPlayerUpdate(_, player)
    local data = player:GetData()
    if data.TotalFrozen then
        return
    end

    local justUnfrozen
    local justFrozen
    if data.Frozen and data.ForceFrozenTime then
        data.ForceFrozenTime = data.ForceFrozenTime - 1
        if data.ForceFrozenTime <= 0 then
            data.ForceFrozenTime = nil
        end
    elseif data.GlacierChill then
        if data.GlacierChill >= REVEL.GetChillFreezingPoint(player) and not data.Frozen and not data.TotalFrozen then
            data.Frozen = true
            REVEL.sfx:Play(SOUND_FREEZE, 1, 0, false, 1)
        elseif data.GlacierChill < REVEL.GetChillFreezingPoint(player) and data.Frozen then
            justUnfrozen = true
        end
    elseif data.Frozen then
        justUnfrozen = true
    end

    data.JustUnfrozen = nil
    if justUnfrozen then
        data.JustUnfrozen = true
        data.Frozen = false
        data.LastChillMeltFrame = player.FrameCount
        -- EnableShooting(player)
    end

    if data.Frozen and not data.WasFrozen then
        justFrozen = true
    end
    data.WasFrozen = data.Frozen

    if data.Frozen or justUnfrozen then
        -- Incubus fix (temp? depends on base game patches)
        KeepShootingDisabled(player)
        if not justFrozen then
            player.FireDelay = player.MaxFireDelay
            player:SetShootingCooldown(3)
        end
    end

    if data.ChillShrineBonus then
        data.ChillShrineBonus = data.ChillShrineBonus - 1
        if data.ChillShrineBonus <= 0 then
            data.ChillShrineBonus = nil
            player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
            player:EvaluateItems()
        end
    end

    if data.FrozenLastFrame then
        data.FrozenLastFrame = data.FrozenLastFrame - 1
        if data.FrozenLastFrame <= 0 then
            data.FrozenLastFrame = nil
        end
    end    

    if not REVEL.IsChilly() and data.GlacierChill then
        REVEL.Warm(player, true)
        REVEL.EvaluateChill(player)
    end
end

-- Doesn't work currently in Rep as FireCooldown
-- doesn't affect incubi anymore
local function chillIncubusPostUpdate(_, fam)
    if fam.Player and fam.Player:ToPlayer() then
        local player = fam.Player:ToPlayer()
        local pdata = player:GetData()
        if pdata.Frozen or pdata.JustUnfrozen then
            fam.FireCooldown = player.MaxFireDelay
        end
    end
end

local function chillEvaluateCache(_, player, flag)
    local data = player:GetData()
    if data.ChillShrineBonus and flag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage * 1.3
    end
end

local freezeHeadAnimations = {
    "HeadDown",
    "HeadUp",
    "HeadLeft",
    "HeadRight"
}

local forcedIceColor = Color(0.5, 0.5, 0.5, 1,conv255ToFloat( 0, 0, 0))

---@param player EntityPlayer
---@param renderOffset Vector
local function chillPostPlayerRender(_, player, renderOffset)
    local data = player:GetData()
    local isNormalPass = REVEL.IsRenderPassNormal()

    if data.GlacierChill or data.Frozen or data.WaitForMeltAnimation then

        if isNormalPass then
            if data.Frozen then
                if not data.FrozenSprite then
                    data.FrozenSprite = Sprite()
                    data.FrozenSprite:Load("gfx/effects/revel1/freezehead.anm2", true)
                    data.FrozenSprite:Play("Freeze", true)
                end

                data.FrozenSpriteSpritesheet = data.FrozenSpriteSpritesheet or {}
                data.FrozenSpriteSpritesheet[0] = data.FrozenSpriteSpritesheet[0] or {[0] = "gfx/effects/revel1/freezehead.png", [1] = "gfx/effects/revel1/freezeheadmelt.png"} --defaults to 0 if not defined for other characters
                data.FrozenSpriteSpritesheet[PlayerType.PLAYER_THEFORGOTTEN] = data.FrozenSpriteSpritesheet[PlayerType.PLAYER_THEFORGOTTEN] or {[0] = "gfx/effects/revel1/freezehead_forgotten.png", [1] = "gfx/effects/revel1/freezeheadmelt_forgotten.png"}
                data.FrozenSpriteLastSpritesheet = data.FrozenSpriteLastSpritesheet or 0

                local playerTypeSpritesheet = player:GetPlayerType()
                if not data.FrozenSpriteSpritesheet[playerTypeSpritesheet] then
                    playerTypeSpritesheet = 0
                end
                if data.FrozenSpriteLastSpritesheet ~= playerTypeSpritesheet then
                    data.FrozenSpriteLastSpritesheet = playerTypeSpritesheet
                    for i=0, 1 do
                        data.FrozenSprite:ReplaceSpritesheet(i, data.FrozenSpriteSpritesheet[playerTypeSpritesheet][i])
                    end
                    data.FrozenSprite:LoadGraphics()
                end

                local isPlayingHeadAnimation
                for _, anim in ipairs(freezeHeadAnimations) do
                    if data.FrozenSprite:IsPlaying(anim) or data.FrozenSprite:IsFinished(anim) then
                        isPlayingHeadAnimation = true
                        break
                    end
                end

                if not (data.FrozenSprite:IsPlaying("Freeze") or data.FrozenSprite:IsFinished("Freeze") or isPlayingHeadAnimation) then
                    data.FrozenSprite:Play("Freeze", true)
                elseif isPlayingHeadAnimation or data.FrozenSprite:IsFinished("Freeze") then
                    local headDir = player:GetHeadDirection()
                    local frame = 0
                    if player:GetFireDirection() ~= Direction.NO_DIRECTION then
                        frame = 3
                    end

                    if headDir == Direction.DOWN then
                        data.FrozenSprite:SetFrame("HeadDown", frame)
                    elseif headDir == Direction.LEFT then
                        data.FrozenSprite:SetFrame("HeadLeft", frame)
                    elseif headDir == Direction.RIGHT then
                        data.FrozenSprite:SetFrame("HeadRight", frame)
                    elseif headDir == Direction.UP then
                        data.FrozenSprite:SetFrame("HeadUp", frame)
                    end
                end

                data.WaitForMeltAnimation = true
            elseif data.FrozenSprite then
                if not (data.FrozenSprite:IsPlaying("Melt") or data.FrozenSprite:IsFinished("Melt")) then
                    data.FrozenSprite:Play("Melt", true)
                    REVEL.sfx:Play(SoundEffect.SOUND_FIREDEATH_HISS, 0.33, 0, false, 1)
                elseif data.FrozenSprite:IsFinished("Melt") then
                    data.WaitForMeltAnimation = false
                end
            end
        end

        if data.FrozenSprite then
            if isNormalPass then
                data.FrozenSprite.Scale = player:GetSprite().Scale

                if StageAPI.IsOddRenderFrame and not REVEL.game:IsPaused() then
                    data.FrozenSprite:Update()
                end
            end

            if not data.FrozenSprite:IsFinished("Melt") and player:IsExtraAnimationFinished() and not data.TotalFrozen then
                local renderPlayer = true
                for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.GUILLOTINE, -1, false, false)) do
                    if entity:ToFamiliar().Player and entity:ToFamiliar().Player.InitSeed == player.InitSeed then
                        renderPlayer = false
                    end
                end

                if renderPlayer then
                    local renderPos = player.Position
                    if player:IsFlying() then
                        renderPos = renderPos + Vector(0,-5)
                    end

                    if isNormalPass then
                        if data.ForceFrozenTime then
                            data.FrozenSprite.Color = REVEL.ColorLerp2Clamp(Color.Default, forcedIceColor, data.ForceFrozenTime, 0, 5)
                        else
                            data.FrozenSprite.Color = Color.Default
                        end
                    end

                    data.FrozenSprite:Render(Isaac.WorldToScreen(renderPos) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
                end
            end
        end
    end
end

local function chillGuillotinePostRender(_, fam, renderOffset)
    local player = fam.Player
    local data = player:GetData()
    if data.GlacierChill and data.FrozenSprite and not data.FrozenSprite:IsFinished("Melt") and player:IsExtraAnimationFinished() then
        local renderPos = fam.Position
        data.FrozenSprite:Render(Isaac.WorldToScreen(renderPos) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
    end
end

function REVEL.ShouldUseWarmthAuras()
    return REVEL.IsChilly() or REVEL.ENT.CHILL_O_WISP:countInRoom() + REVEL.ENT.ICE_WRAITH:countInRoom(true) > 0
end

---@class Rev.WarmAuraData
---@field Radius number
---@field Parent Entity?
---@field Position Vector?
---@field Aura EntityPtr

-- Entities with warm auras to check
local WarmAuraTypes = {
    -- Manually add fireplaces so they're specially handled
    [EntityType.ENTITY_FIREPLACE] = {
        [-1] = true,
    }
}

---@param entity Entity
---@param radius? number
---@param noAura? boolean
---@return Rev.WarmAuraData
---@overload fun(entity: Entity, auraData: Rev.WarmAuraData): Rev.WarmAuraData
function REVEL.SetWarmAura(entity, radius, noAura)
    local data = entity:GetData()

    if type(radius) ~= "table" then
        radius = radius or REVEL.GetChillWarmRadius()
        if not data.WarmAuraData then
            data.WarmAuraData = {}
        end
        data.WarmAuraData.Parent = entity
        data.WarmAuraData.Radius = radius

        local aura = data.WarmAuraData.Aura and data.WarmAuraData.Aura.Ref
        if not noAura and not aura then
            local isFireAura = entity.Type == EntityType.ENTITY_FIREPLACE
            aura = REVEL.SpawnAura(
                radius or REVEL.GetChillWarmRadius(), 
                entity.Position, 
                REVEL.WARM_COLOR, 
                entity, 
                true, 
                isFireAura, 
                entity, 
                false, 
                true
            )
            data.WarmAuraData.Aura = EntityPtr(aura)
        elseif aura then
            REVEL.UpdateAuraRadius(aura, radius)
        end
    else
        data.WarmAuraData = REVEL.CopyTable(radius)
        data.WarmAuraData.Parent = entity
        if data.WarmAuraData.Aura and data.WarmAuraData.Aura.Ref then
            local aura = data.WarmAuraData.Aura.Ref:ToEffect()
            aura.Parent = entity
            aura.SpawnerEntity = entity
            aura:FollowParent(entity)
        end
    end

    WarmAuraTypes[entity.Type] = WarmAuraTypes[entity.Type] or {}
    WarmAuraTypes[entity.Type][entity.Variant] = true

    return data.WarmAuraData
end

---@param entity Entity
function REVEL.RemoveWarmAura(entity)
    local auraData = REVEL.GetWarmAuraData(entity)
    if auraData then
        if auraData.Aura and auraData.Aura.Ref then
            auraData.Aura.Ref:Remove()
        end
        entity:GetData().WarmAuraData = nil
    end
end

---@param entity Entity
---@return Rev.WarmAuraData
function REVEL.GetWarmAuraData(entity)
    return entity:GetData().WarmAuraData
end

REVEL.WARM_COLOR = Color(1.6, 0.9, 0.3, 0.12,conv255ToFloat( 0, 0, 0))

---@param pos Vector | {Position: Vector}
---@return boolean includes
function REVEL.IncludesWarmAura(pos)
    if pos.Position then pos = pos.Position end

    for _, auraData in pairs(WarmAuras) do
        if not auraData.Radius or (not auraData.Parent and not auraData.Position) then
            error("Invalid WarmAuraData!" .. REVEL.ToString(auraData) .. REVEL.TryGetTraceback(), 2)
        end
        local center = auraData.Position or auraData.Parent.Position
        if pos:DistanceSquared(center) <= auraData.Radius * auraData.Radius then
            return true
        end
    end
    return false
end

---@type Rev.WarmAuraData[]
local BrazierAuras = {}

-- Not only called but exported for use in the main glacier.lua to 
-- set order manually with other modules
function REVEL.UpdateChill()
    if REVEL.ShouldUseWarmthAuras() then
        local newRoom
        local frame = REVEL.room:GetFrameCount()
        if frame <= 1 then
            newRoom = true
        end
    
        if #WarmAuras > 0 then WarmAuras = {} end

        for warmType, warmVariants in pairs(WarmAuraTypes) do
            for variant, _ in pairs(warmVariants) do
                local entities = Isaac.FindByType(warmType, variant)
                for _, e in ipairs(entities) do
                    local auraData = REVEL.GetWarmAuraData(e)
                    
                    if e.Type == EntityType.ENTITY_FIREPLACE then
                        if e.HitPoints > 1 and not auraData then
                            auraData = REVEL.SetWarmAura(e)
                        elseif e.HitPoints <= 1 and auraData then
                            REVEL.RemoveWarmAura(e)
                            auraData = nil
                        end
                    end
        
                    if auraData then
                        WarmAuras[#WarmAuras + 1] = auraData
                    end
                end
            end
        end

        for _, aura in ipairs(BrazierAuras) do
            table.insert(WarmAuras, aura)
        end

        for _, player in ipairs(REVEL.players) do
            local data = player:GetData()
            data.GlacierChill = data.GlacierChill or 0
            data.Warmed = nil

            if newRoom then
                data.GlacierChill = 0
            end

            if frame > 60 then
                if not REVEL.IsChilly() or REVEL.IncludesWarmAura(player) then
                    REVEL.Warm(player, true)
                else
                    REVEL.Freeze(player, true)
                end

                REVEL.EvaluateChill(player)
            end
        end
    end
    if not REVEL.IsChilly() and REVEL.IsChillRoom() then
        for _, overlay in ipairs(REVEL.GetChillFadingOverlays()) do
            if (not overlay.Alpha or overlay.Alpha > 0) and not overlay.Fading and not overlay.FadingFinished then
                overlay:Fade(REVEL.DEFAULT_CHILL_FADE_TIME, REVEL.DEFAULT_CHILL_FADE_TIME, -1)
            end
        end
    end
end

local function CheckBrazierAuras()
    BrazierAuras = {}

    local braziers = StageAPI.GetCustomGrids(nil, REVEL.GRIDENT.BRAZIER.Name)

    for _, brazier in ipairs(braziers) do
        local pos = REVEL.room:GetGridPosition(brazier.GridIndex)
        -- in case of ingame reload
        -- no effect partition, as usual
        local alreadyPresentAura = REVEL.filter(
            Isaac.FindInRadius(pos, 3),
            function(e) return e.Type == EntityType.ENTITY_EFFECT end
        )[1]

        ---@type Rev.WarmAuraData
        local auraData = {
            Position = pos, 
            Radius = REVEL.GetChillWarmRadius(),
        }
        if REVEL.ShouldUseWarmthAuras() then
            auraData.Aura = EntityPtr(alreadyPresentAura or REVEL.SpawnAura(
                REVEL.GetChillWarmRadius(), 
                pos, 
                REVEL.WARM_COLOR, 
                nil, 
                false, 
                false, 
                nil, 
                false, 
                true
            ))
        end
        BrazierAuras[#BrazierAuras + 1] = auraData
    end
end

local function chill_PostNewRoom()
    CheckBrazierAuras()

    for _, player in ipairs(REVEL.players) do
        local data = player:GetData()
        if data.GlacierChill then
            data.GlacierChill = 0
            data.ForceFrozenTime = nil
            REVEL.EvaluateChill(player)
            data.GlacierChill = nil
            data.LastChillMeltFrame = nil
        end
    end
end


-- Chill aura
local RoomHasChillAura = false
local FREEZE_TIMER = 0.3 * 30

---@class Rev.ChillAuraData
---@field Offset Vector
---@field Radius number
---@field Timer integer
---@field Aura EntityPtr
---@field Enabled boolean # use if you want to disable it (like warm areas and chillos) without clearing all data

---@param entity Entity
---@param radius? number
---@param offset? Vector
---@param timer? integer
---@param noAura? boolean
---@return Rev.ChillAuraData
---@overload fun(entity: Entity, auraData: Rev.ChillAuraData): Rev.ChillAuraData
function REVEL.SetChillAura(entity, radius, offset, timer, noAura)
    local data = entity:GetData()

    if type(radius) == "table" then
        REVEL.Assert(radius.Radius, "SetChillAura | no Radius in data", 2)
        if not data.ChillAuraData then
            data.ChillAuraData = {
                Enabled = true,
                Offset = Vector.Zero,
                Timer = FREEZE_TIMER,
            }
        end
        data.ChillAuraData.Radius = data.ChillAuraData.Radius or radius.Radius
        data.ChillAuraData.Aura = data.ChillAuraData.Aura or radius.Aura
        data.ChillAuraData.Offset = data.ChillAuraData.Offset or radius.Offset
        data.ChillAuraData.Timer = data.ChillAuraData.Timer or radius.Timer
        if radius.Enabled ~= nil then
            data.ChillAuraData.Enabled = radius.Enabled
        end
    elseif radius then
        if not data.ChillAuraData then
            data.ChillAuraData = {
                Enabled = true,
            }
        end
        data.ChillAuraData.Offset = offset or Vector.Zero
        data.ChillAuraData.Radius = radius
        data.ChillAuraData.Timer = timer or FREEZE_TIMER

        local aura = data.ChillAuraData.Aura and data.ChillAuraData.Aura.Ref
        if not noAura and not aura then
            aura = REVEL.SpawnAura(radius, entity.Position, REVEL.CHILL_COLOR_LOWA, entity, true)
            data.ChillAuraData.Aura = EntityPtr(aura)
        elseif aura then
            REVEL.UpdateAuraRadius(aura, radius)
        end
    else
        error("SetChillAura | invalid radius or data", 2)
    end

    RoomHasChillAura = true

    return data.ChillAuraData
end

function REVEL.EnableChillAura(entity)
    local auraData = REVEL.GetChillAuraData(entity)
    if not auraData then
        error("EnableChillAura | Entity doesn't have chill aura", 2)
    end
    auraData.Enabled = true
    if auraData.Aura and auraData.Aura.Ref then
        auraData.Aura.Ref.Visible = true
    end
end

function REVEL.DisableChillAura(entity)
    local auraData = REVEL.GetChillAuraData(entity)
    if not auraData then
        error("EnableChillAura | Entity doesn't have chill aura", 2)
    end
    auraData.Enabled = false
    if auraData.Aura and auraData.Aura.Ref then
        auraData.Aura.Ref.Visible = false
    end
end

function REVEL.RemoveChillAura(entity)
    local auraData = REVEL.GetChillAuraData(entity)
    if auraData then
        if auraData.Aura and auraData.Aura.Ref then
            auraData.Aura.Ref:Remove()
        end
        entity:GetData().ChillAuraData = nil
    end
end

---@param entity Entity
---@return Rev.ChillAuraData
function REVEL.GetChillAuraData(entity)
    return entity:GetData().ChillAuraData
end

local function chillAura_PostUpdate()
    if RoomHasChillAura then
        local roomNPCs = REVEL.GetRoomNPCs()
        for _, entity in ipairs(roomNPCs) do
            local auraData = REVEL.GetChillAuraData(entity)
            if auraData and auraData.Enabled then
                for _, player in ipairs(REVEL.players) do
                    local ed = entity:GetData()
                    local d = player:GetData()
                    if player.Position:DistanceSquared(entity.Position + auraData.Offset) <= auraData.Radius ^ 2 
                    and not REVEL.IncludesWarmAura(player)
                    and not (d.Frozen or d.TotalFrozen) then
                        local timer = auraData.Timer
                        if not ed.ChillPlayer then
                            ed.ChillPlayer = player.Index
                        else
                            if not d.ChillAuraTimer then
                                d.ChillAuraTimer = timer
                                REVEL.sfx:Play(REVEL.SFX.ICE_BEAM)
                            elseif d.ChillAuraTimer > 0 then
                                local mult = (-d.ChillAuraTimer+timer)*0.08
                                local color = Color.Lerp(Color(1-(0.8*mult),1+(0.2*mult),1+(3*mult),1,0,0,mult),player:GetSprite().Color,0.5)
                                player:SetColor(color, 1, 1, false, false)
                                d.ChillAuraTimer = d.ChillAuraTimer - 1
                            else
                                REVEL.ChillFreezePlayer(player, true, REVEL.GlacierBalance.DarkIceInChill)
                                REVEL.Chillo.OnFreeze(entity)
                                ed.ChillPlayer = nil
                                d.ChillAuraTimer = nil
                                REVEL.sfx:Stop(REVEL.SFX.ICE_BEAM)
                            end
                        end
                    elseif ed.ChillPlayer == player.Index then
                        d.ChillAuraTimer = nil
                        ed.ChillPlayer = nil
                        REVEL.sfx:Stop(REVEL.SFX.ICE_BEAM)
                    end
                end
            end
        end
    end
end

local function chillAura_PostNewRoom()
    RoomHasChillAura = false
    local roomNPCs = REVEL.GetRoomNPCs()
    for i, npc in ipairs(roomNPCs) do
        local auraData = REVEL.GetChillAuraData(npc)
        if auraData then
            RoomHasChillAura = true
            auraData.Aura = EntityPtr(
                REVEL.SpawnAura(auraData.Radius, npc.Position, REVEL.CHILL_COLOR_LOWA, npc, true)
            )

            break
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, REVEL.UpdateChill)
revel:AddCallback(ModCallbacks.MC_POST_UPDATE, chillAura_PostUpdate)
revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, chillSnowball_PostProjectileUpdate, CHILL_SNOWBALL_VARIANT)
revel:AddCallback(ModCallbacks.MC_PRE_PROJECTILE_COLLISION, chill_PreProjectileCollision, CHILL_SNOWBALL_VARIANT)
revel:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, chill_wisps_PreFamiliarCollision, FamiliarVariant.WISP)
revel:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, chill_wisps_PreFamiliarCollision, FamiliarVariant.ITEM_WISP)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 1, CheckBrazierAuras)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_STAGEAPI_NEW_ROOM, 1, chill_PostNewRoom)
revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, chillPlayerUpdate)
revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, chillIncubusPostUpdate, FamiliarVariant.INCUBUS)
revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, chillEvaluateCache)
revel:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, chillPostPlayerRender)
revel:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, chillGuillotinePostRender, FamiliarVariant.GUILLOTINE)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, chillAura_PostNewRoom)

end

REVEL.PcallWorkaroundBreakFunction()