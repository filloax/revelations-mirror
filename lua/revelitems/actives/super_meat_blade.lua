---@diagnostic disable: need-check-nil

local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

----------------------
-- SUPER MEAT BLADE --
----------------------

local SMBladeBalance = {
    Radius = 27 * REVEL.SCREEN_TO_WORLD_RATIO,
    SpriteSide = 64,
    ThrowSpeed = 18,
    WallSpeed = 15,
    SpriteRotatesClockwise = true,
    Damage = 3.5,
    ThrowPreviousVelocityInfluence = 0,
    WallEmbedDepth = 32,
    WallDistance = 20, --distance from the actual end of the room space where the embed cutoff starts (aka "height")
    SfxLevelKills = {
        0, --kills needed for level 1
        3, --kills needed for level 2
        6, --kills needed for level 3
    },
    EnableRoomCharges = false, --if true, the item will be x max charges worth (defined in xml), and be recharging only for the duration of the room you use it in
}

local function SMBladeItemUse(_, itemID, itemRNG, player, useFlags, activeSlot, customVarData)
    if not HasBit(useFlags, UseFlag.USE_CARBATTERY) then
        if itemID == REVEL.ITEM.SMBLADE_UNUSED.id or REVEL.GetCharge(player) >= REVEL.GetMaxCharge(player, true) then
            if REVEL.ToggleShowActive(player, true) then --toggle holding the item and fling meat blades when holding up the item too
                REVEL.FlingMeatBlades(player)
            end
        else
            REVEL.FlingMeatBlades(player)
            return true
        end
    end
end

revel:AddCallback(ModCallbacks.MC_USE_ITEM, SMBladeItemUse, REVEL.ITEM.SMBLADE.id)
revel:AddCallback(ModCallbacks.MC_USE_ITEM, SMBladeItemUse, REVEL.ITEM.SMBLADE_UNUSED.id)

REVEL.AddCustomBar(REVEL.ITEM.SMBLADE.id, 250)

local SparkParticles = REVEL.ParticleType.FromTable{
    Name = "Sparks",
    Anm2 =  "gfx/1000.066_ember particle.anm2",
    AnimationName = "Idle",
    Variants = 8,
    ScaleRandom = 0.2,
    StartScale = 1,
    EndScale = 0.5,
    BaseLife = 10,
    DieOnLand = false,
    Turbulence = true,
    TurbulenceReangleMinTime = 10,
    TurbulenceReangleMaxTime = 30,
    TurbulenceMaxAngleXYZ = Vec3(45,35,35),
}
SparkParticles:SetColor(Color(1.8, 1.8, 1.8, 1,conv255ToFloat( 0, 0, 0)), 0)

local SparkSystem = REVEL.PartSystem.FromTable{
    Name = "Spark System",
    Gravity = 0.02,
    AirFriction = 0.95,
    GroundFriction = 0.95,
    Clamped = true,
    RoomClampOffset = Vector(-SMBladeBalance.WallDistance, -SMBladeBalance.WallDistance)
}

local PARTICLE_EMITTER_ID = "SMBlade Emitter"

local function emitParticles(segStart, segEnd, dir, blade)
    local wd = SMBladeBalance.WallDistance
    local mid =  REVEL.Lerp(segStart, segEnd, 0.5)
    local pos1 = REVEL.Lerp(segStart, mid, math.random())
    local pos2 = REVEL.Lerp(mid, segEnd, math.random())

    local emitter = REVEL.GetEntityParticleEmitter(blade, PARTICLE_EMITTER_ID)
    emitter:EmitParticlesPerSec(SparkParticles, SparkSystem, Vec3(pos1.X, pos1.Y + wd, -wd), Vec3(dir * 5 - blade.Velocity * 0.6, -1.2), 40, 0.1, 40, nil, 1000)
    emitter:EmitParticlesPerSec(SparkParticles, SparkSystem, Vec3(pos2.X, pos2.Y + wd, -wd), Vec3(dir * 5 - blade.Velocity * 0.6, -1.2), 40, 0.1, 40, nil, 1000)
end

local function isInRoom(pos)
    return REVEL.room:IsPositionInRoom(pos, - SMBladeBalance.WallDistance - SMBladeBalance.WallEmbedDepth)
end

local function isOnWall(blade)
    for i = 0, 3 do --check two velocity components
        local dir = REVEL.dirToVel[i]

        local ray = dir * (SMBladeBalance.Radius)
        local nextEdge = blade.Position + ray

        if not REVEL.room:IsPositionInRoom(nextEdge, 0) then
            return true
        end
    end

    return false
end

local function playBladeLevelSfx(level)
    local playingLevel = true
    for i = 1, level do
        playingLevel = playingLevel and REVEL.sfx:IsPlaying(REVEL.SFX.MEATBLADE[i])
    end

    if not (REVEL.sfx:IsPlaying(REVEL.SFX.MEATBLADE.BASE) and playingLevel) then
        local baseVol, vol, pitch = 0.75, 0.83, 1
        --restart sounds so they're synced
        for i = 1, level do
            REVEL.sfx:Stop(REVEL.SFX.MEATBLADE[i])
        end
        REVEL.sfx:Stop(REVEL.SFX.MEATBLADE.BASE)
        REVEL.sfx:Play(REVEL.SFX.MEATBLADE.BASE, baseVol, 0, true, pitch)
        for i = 1, level do
            REVEL.sfx:Play(REVEL.SFX.MEATBLADE[i], vol, 0, true, pitch)
        end
    end
    if level < #REVEL.SFX.MEATBLADE then
        for i = level + 1, #REVEL.SFX.MEATBLADE do
            REVEL.sfx:Stop(REVEL.SFX.MEATBLADE[i])
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    local sprite, data = player:GetSprite(), player:GetData()
    if REVEL.ITEM.SMBLADE:PlayerHasCollectible(player) or REVEL.ITEM.SMBLADE_UNUSED:PlayerHasCollectible(player) then

        local c = REVEL.GetCharge(player)

        if player:GetActiveItem() == REVEL.ITEM.SMBLADE.id and c then
            if c < REVEL.GetMaxCharge(player, false) then
                REVEL.AddCharge(1, player, false)
                if c < REVEL.GetMaxCharge(player, true) and REVEL.GetCharge(player) >= REVEL.GetMaxCharge(player, true) then
                    REVEL.sfx:Play(SoundEffect.SOUND_ITEMRECHARGE, 0.8, 0, false, 1)

                    if data.HasNoBladeCostume then
                        player:AddNullCostume(REVEL.ITEM.SMBLADE.costume)
                        player:TryRemoveNullCostume(REVEL.COSTUME.SMBLADE_NOBLADE)
                        data.HasNoBladeCostume = nil
                    end
                else
                    REVEL.ChargeYellowOn(player)
                end
            end
        end

        if (REVEL.GetShowingActive(player) == REVEL.ITEM.SMBLADE.id or REVEL.GetShowingActive(player) == REVEL.ITEM.SMBLADE_UNUSED.id) 
        and REVEL.IsShooting(player, true, true) then
            REVEL.HideActive(player)

            if REVEL.ITEM.SMBLADE_UNUSED:PlayerHasCollectible(player) then
                REVEL.ConsumeActiveCharge(player)
                player:RemoveCollectible(REVEL.ITEM.SMBLADE_UNUSED.id)
                player:AddCollectible(REVEL.ITEM.SMBLADE.id, 1)
                c = REVEL.GetCharge(player)
            end

            REVEL.SetCharge(c - REVEL.GetMaxCharge(player, true), player, false)

            local dir = REVEL.AxisAlignVector(player:GetShootingInput()):Normalized()

            local blade = REVEL.SpawnDecorationFromTable(player.Position + dir * 15, dir * SMBladeBalance.ThrowSpeed + player.Velocity * SMBladeBalance.ThrowPreviousVelocityInfluence, REVEL.BladeDeco)
            local bdata = blade:GetData()
            bdata.Velocity = blade.Velocity
            bdata.OnWall = false
            bdata.Player = player
            bdata.SuperMeatBlade = true
            blade.Color = REVEL.NO_COLOR
            REVEL.AddEntityParticleEmitter(blade, REVEL.Emitter(), PARTICLE_EMITTER_ID)
            REVEL.sfx:Play(SoundEffect.SOUND_SWORD_SPIN, 1, 0, false, 0.7)

            if not data.HasNoBladeCostume then
                player:TryRemoveNullCostume(REVEL.ITEM.SMBLADE.costume)
                player:AddNullCostume(REVEL.COSTUME.SMBLADE_NOBLADE)
                data.HasNoBladeCostume = true
            end

            if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
                player:AddWisp(REVEL.ITEM.SMBLADE.id, player.Position)
            end

        end
    elseif data.HasNoBladeCostume then
        player:TryRemoveNullCostume(REVEL.ITEM.SMBLADE.costume)
    end
end)

function REVEL.FlingMeatBlades(player) -- no player specified: all of them
    local blades = REVEL.filter(REVEL.ENT.DECORATION:getInRoom(false, false, false), 
        function(deco) 
            return deco:GetData().SuperMeatBlade and isOnWall(deco) and (not player or GetPtrHash(deco:GetData().Player) == GetPtrHash(player))
        end)

    local flungOne = false

    for _, blade in ipairs(blades) do
        local data = blade:GetData()
        data.OnWall = false
        data.NextVelocity = data.Velocity

        for i = -1, 1, 2 do
            local angle = 90 * i
            local perpRay = data.Velocity:Resized(SMBladeBalance.Radius + 20):Rotated(angle)

            if not isInRoom(blade.Position + perpRay) then
                -- FDEBUG.RenderForFrames(IDebug.RenderLine, 10, blade.Position, blade.Position + perpRay, false, Color(0, 1, 0, 1,conv255ToFloat( 0, 0, 0)))

                local newVel = (data.Velocity * SMBladeBalance.ThrowPreviousVelocityInfluence + data.Velocity:Rotated(angle + 180)):Resized(SMBladeBalance.ThrowSpeed)
                data.Velocity = newVel

                REVEL.SpawnDecorationFromTable(REVEL.room:GetClampedPosition(blade.Position + perpRay, 0), Vector.Zero, REVEL.BoulderDust)

                flungOne = true

                break
            end
        end

        blade.Velocity = data.Velocity
    end

    if flungOne then
        REVEL.sfx:Play(REVEL.SFX.WHOOSH, 1, 0, false, 0.9)

        local wisps = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.WISP, REVEL.ITEM.SMBLADE.id)
        for _, wisp in ipairs(wisps) do
            if wisp:ToFamiliar() then
                for i = 0, 360, 90 do
                    wisp:ToFamiliar():FireProjectile(Vector(1,0):Rotated(i))
                end
            end
        end
    end
end

local roomKills = 0

local function bladeUpdate(entity, data, sprite)
    entity.Velocity = data.Velocity

    -- IDebug.RenderUntilNextUpdate(IDebug.RenderLine, entity.Position, entity.Position + data.Velocity * 2)

    local sfxLevel = math.floor(REVEL.Lerp3PointClamp(1, 2, 3, roomKills, SMBladeBalance.SfxLevelKills[1], SMBladeBalance.SfxLevelKills[2], SMBladeBalance.SfxLevelKills[3]))
    playBladeLevelSfx(sfxLevel)

    if not data.OnWall then
        for i = 1, 2 do --check two velocity components
            local dir = i == 1 and REVEL.VEC_RIGHT * sign(data.Velocity.X) or REVEL.VEC_DOWN * sign(data.Velocity.Y)

            local ray = dir * (SMBladeBalance.Radius)
            local nextEdge = entity.Position + ray

            if not isInRoom(nextEdge) then
                data.OnWall = true
                REVEL.sfx:Play(SoundEffect.SOUND_FETUS_LAND, 0.9, 0, false, 0.95)
                REVEL.game:ShakeScreen(5)

                entity.Velocity = REVEL.room:GetClampedPosition(nextEdge, - SMBladeBalance.WallDistance - SMBladeBalance.WallEmbedDepth) - ray - entity.Position
                
                local clockwise

                if i == 1 then --hori
                    local s = sign(data.Velocity.Y)
                    if s == 0 then s = sign(math.random() - 0.5) end
                    data.Velocity = REVEL.VEC_DOWN * (s * SMBladeBalance.WallSpeed)

                    clockwise = (data.Velocity.X > 0) == (data.Velocity.Y < 0)
                else --vert
                    local s = sign(data.Velocity.X)
                    if s == 0 then s = sign(math.random() - 0.5) end
                    data.Velocity = REVEL.VEC_RIGHT * (s * SMBladeBalance.WallSpeed)
                    clockwise = (data.Velocity.X > 0) == (data.Velocity.Y > 0)
                end

                if clockwise ~= data.Clockwise then
                    data.Clockwise = clockwise
                    local frame = sprite:GetFrame()
                    if clockwise then
                        sprite:Play("idle_clock", true)
                        REVEL.SkipAnimFrames(sprite, frame)
                    else
                        sprite:Play("idle_counterclock", true)
                    end
                end
                break
            end
        end
    else
        local centerToWallDistance = {[-1] = {}, [1] = {}} --distance from the center to the walls in the top left, top right, etc
        --check POST_RENDER, only difference is that this uses world coordinates
        
        local collidingCorners = 0
        local radius = SMBladeBalance.Radius
        
        --need to do this here as it's needed every frame
        --could be optimized by calculating it in render only on every odd frame and using the update one on other frames
        for y = -1, 1, 2 do
            for x = -1, 1, 2 do
                local corner = entity.Position + Vector(radius * x, radius * y)

                if not REVEL.room:IsPositionInRoom(corner, -SMBladeBalance.WallDistance) then
                    collidingCorners = collidingCorners + 1
                    local closestPosOnWall = REVEL.room:GetClampedPosition(corner, -SMBladeBalance.WallDistance)
                    centerToWallDistance[y][x] = closestPosOnWall - entity.Position
                end
            end
        end

        local pos = entity.Position

        --TODO: unhardcode the direction stuff as it's done like 3 times in this code
        if centerToWallDistance[-1][-1] and centerToWallDistance[-1][1] then --colliding at top
            local dir = REVEL.VEC_DOWN
            emitParticles(pos + centerToWallDistance[-1][-1], pos + centerToWallDistance[-1][1], dir, entity)
        end
        if centerToWallDistance[1][-1] and centerToWallDistance[1][1] then --colliding at bottom
            local dir = REVEL.VEC_UP
            emitParticles(pos + centerToWallDistance[1][-1], pos + centerToWallDistance[1][1], dir, entity)
        end
        if centerToWallDistance[-1][-1] and centerToWallDistance[1][-1] then --colliding at left
            local dir = REVEL.VEC_RIGHT
            emitParticles(pos + centerToWallDistance[-1][-1], pos + centerToWallDistance[1][-1], dir, entity)
        end
        if centerToWallDistance[-1][1] and centerToWallDistance[1][1] then --colliding at right
            local dir = REVEL.VEC_LEFT
            emitParticles(pos + centerToWallDistance[-1][1], pos + centerToWallDistance[1][1], dir, entity)
        end

        -- actual movement collision detection
        -- separate since it also takes the wall embed in consideration when checking if the entity is out of the room, to detect when it slams against the wall and turns around

        local dir = entity.Velocity:Normalized()
        local ray = dir * (SMBladeBalance.Radius)
        local nextEdge = entity.Position + ray

        if not isInRoom(nextEdge) then
            for i = -1, 1, 2 do
                local perpDir = dir:Rotated(90 * i)
                local perpRay = perpDir * (SMBladeBalance.Radius * 1.1)

                if REVEL.room:IsPositionInRoom(entity.Position + perpRay, - SMBladeBalance.WallDistance - SMBladeBalance.WallEmbedDepth) then
                    data.Velocity = data.Velocity:Rotated(90 * i)
                    entity.Velocity = REVEL.room:GetClampedPosition(nextEdge, - SMBladeBalance.WallDistance - SMBladeBalance.WallEmbedDepth) - ray - entity.Position
                    break
                end
            end
        end
    end

    -- local r = SMBladeBalance.WallDistance + SMBladeBalance.WallEmbedDepth
    -- local tr = Vector(REVEL.room:GetBottomRightPos().X, REVEL.room:GetTopLeftPos().Y)
    -- local bl = Vector(REVEL.room:GetTopLeftPos().X, REVEL.room:GetBottomRightPos().Y)

    -- IDebug.RenderUntilNextUpdate(IDebug.RenderLine, REVEL.room:GetTopLeftPos() + Vector(-1, -1) * r, tr + Vector(1, -1) * r, false, Color(0, 0, 1, 1,conv255ToFloat( 0, 0, 0)))
    -- IDebug.RenderUntilNextUpdate(IDebug.RenderLine, bl + Vector(-1, 1) * r, REVEL.room:GetBottomRightPos() + Vector(1, 1) * r, false, Color(0, 0, 1, 1,conv255ToFloat( 0, 0, 0)))
    -- IDebug.RenderUntilNextUpdate(IDebug.RenderLine, REVEL.room:GetTopLeftPos() + Vector(-1, -1) * r, bl + Vector(-1, 1) * r, false, Color(0, 0, 1, 1,conv255ToFloat( 0, 0, 0)))
    -- IDebug.RenderUntilNextUpdate(IDebug.RenderLine, REVEL.room:GetBottomRightPos() + Vector(1, 1) * r, tr + Vector(1, -1) * r, false, Color(0, 0, 1, 1,conv255ToFloat( 0, 0, 0)))

    local hittable = REVEL.roomEnemies
    if entity.FrameCount > 30 then
        hittable = REVEL.ConcatTables(hittable, REVEL.players)
    end

    for i = 1, #hittable do
        local target = hittable[i]
        if ((target.Type ~= 1 and target.EntityCollisionClass >= EntityCollisionClass.ENTCOLL_PLAYEROBJECTS) or (target.Type == 1 and target.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE))
        and target.Position:DistanceSquared(entity.Position) < (target.Size + SMBladeBalance.Radius) ^ 2 then
            target:TakeDamage(target.Type == 1 and 1 or SMBladeBalance.Damage, 0, EntityRef(data.Player), 1)
            target:GetData().HitByBladeAt = target.FrameCount

            if not target:GetData().SawBloodFrame or target:GetData().SawBloodFrame + 5 < target.FrameCount then
                target:BloodExplode()
                target:GetData().SawBloodFrame = target.FrameCount
            end
            --play hit sound
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, entity)
    if entity:GetData().HitByBladeAt and REVEL.dist(entity:GetData().HitByBladeAt, entity.FrameCount) < 2 then
        roomKills = roomKills + 1
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    roomKills = 0
    REVEL.sfx:Stop(REVEL.SFX.MEATBLADE.BASE)
    for _, sfx in ipairs(REVEL.SFX.MEATBLADE) do
        REVEL.sfx:Stop(sfx)
    end

    if SMBladeBalance.EnableRoomCharges then
        for _, player in ipairs(REVEL.players) do
            if REVEL.ITEM.SMBLADE:PlayerHasCollectible(player) then
                player:RemoveCollectible(REVEL.ITEM.SMBLADE.id)
                player:AddCollectible(REVEL.ITEM.SMBLADE_UNUSED.id, 1)
            end
        end
    end
end)

REVEL.BladeDeco = {
    Update = bladeUpdate,
    Sprite = "gfx/itemeffects/revelcommon/sawblade.anm2",
    Anim = "idle",
    RemoveOnAnimEnd = false
}

local function isZero(vec)
    return vec.X == 0 and vec.Y == 0
end

--- uses at most 4 rectangles (not our case but for completeness);
--- hole coordinates are their offset from the corresponding sprite corner;
--- alternative usage: renderWithCornerHoles(sprite, pos, width, height, holeOffset, cornerIndex) where cornerIndex is 0, 1, 2, 3 for topLeft, topRight, bottomLeft, bottomRight
---@param sprite Sprite
---@param pos Vector
---@param width number
---@param height number
---@param holeTl Vector
---@param holeTr Vector
---@param holeBl Vector
---@param holeBr Vector
---@overload fun(sprite: Sprite, pos: Vector, width: number, height: number, holeOffset: Vector, cornerIndex: integer)
local function renderWithCornerHoles(sprite, pos, width, height, holeTl, holeTr, holeBl, holeBr)
    local spriteTl = pos - Vector(width, height) / 2
    local spriteBr = pos + Vector(width, height) / 2

    if type(holeTr == "number") then
        if holeTr == 0 then -- *hardcoding*, this item's got plenty apparently
            holeTr = nil
        elseif holeTr == 1 then
            holeTr = holeTl
            holeTl = nil
        elseif holeTr == 2 then
            holeBl = holeTl
            holeTl = nil
            holeTr = nil
        elseif holeTr == 3 then
            holeBr = holeTl
            holeTl = nil
            holeTr = nil
        end
    end

    holeTl = holeTl and holeTl:Clamped(0, 0, width, height) or Vector.Zero
    holeTr = holeTr and holeTr:Clamped(-width, 0, 0, height) or Vector.Zero
    holeBl = holeBl and holeBl:Clamped(0, -height, width, 0) or Vector.Zero
    holeBr = holeBr and holeBr:Clamped(-width, -height, 0, 0) or Vector.Zero

    -- REVEL.DebugToConsole(holeTl, holeTr, holeBl, holeBr)

    --Center left branch
    if spriteTl.Y + holeTl.Y < spriteBr.Y + holeBl.Y then
        sprite:Render(pos, Vector(0, holeTl.Y), -Vector(math.min(holeBr.X, holeTr.X), holeBl.Y))
    end
    --Center right branch: arbitrarily not used when all of them are zero
    if not (isZero(holeTl) and isZero(holeBr) and isZero(holeTr) and isZero(holeBl)) and spriteTl.Y + holeTr.Y < spriteBr.Y + holeBr.Y then
        sprite:Render(pos, Vector(math.max(holeTl.X, holeBl.X), holeTr.Y), -Vector(0, holeBr.Y))
    end
    --Top center branch: same as center left when holeTl = zero, as center right when holeTr = zero
    if not isZero(holeTl) and not isZero(holeTr) and spriteTl.X + holeTl.X < spriteBr.X + holeTr.X then
        sprite:Render(pos, Vector(holeTl.X, 0), -Vector(holeTr.X, math.max(holeBr.Y, holeBl.Y)))
    end
    --Bottom center branch: same as center right when holeBr = zero, as center left when holeBl = zero
    if not isZero(holeBr) and not isZero(holeBl) and spriteTl.X + holeBl.X < spriteBr.X + holeBr.X then
        sprite:Render(pos, Vector(holeBl.X, 0), -Vector(holeBr.X, math.min(holeTr.Y, holeTl.Y)))
    end
end

local function vectorSign(vector)
    return Vector(vector.X >= 0 and 1 or -1, vector.Y >= 0 and 1 or -1)
end

local wallMarkSprite = REVEL.LazyLoadRunSprite{
    ID = "smb_wallMark",
    Anm2 = "gfx/itemeffects/revelcommon/sawblade_mark.anm2",
    Animation = "idle",
}
local LastWallMarkSpriteUpdateFrame = -1

local MinimumEmbedToRenderSeam = 10

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, entity, renderOffset)
    local sprite, data = entity:GetSprite(), entity:GetData()

    if data.SuperMeatBlade then
        sprite.Color = Color.Default

        local collidingCorners = 0
        local lastBusyCorner

        local spriteRadius = SMBladeBalance.SpriteSide / 2
        local worldSpriteRadius = spriteRadius * REVEL.SCREEN_TO_WORLD_RATIO

        --distance from the center to the walls in the top left, top right, etc
        --for example, if the blade is colliding on the right, both bottom and top right x distance from the wall will be the distance between the center and the right wall
        --if it's colliding on the right only on the bottom right (L room corners), only the bottom right distance will be set, while the top right one won't
        --need to do this here as it's needed every frame
        --could be optimized by calculating it in render only on every odd frame and using the update one on other frames
        local centerToWallRenderDistance = {[-1] = {}, [1] = {}} 

        for y = -1, 1, 2 do
            for x = -1, 1, 2 do
                local corner = entity.Position + Vector(worldSpriteRadius * x, worldSpriteRadius * y)

                if not REVEL.room:IsPositionInRoom(corner, -SMBladeBalance.WallDistance) then
                    collidingCorners = collidingCorners + 1
                    local closestPosOnWall = REVEL.room:GetClampedPosition(corner, -SMBladeBalance.WallDistance)
                    local centerToWallDistance = closestPosOnWall - entity.Position

                    local setY = y
                    if REVEL.IsRenderPassReflection() then
                        setY = -y
                        centerToWallDistance.Y = -centerToWallDistance.Y
                    end

                    centerToWallRenderDistance[setY][x] = centerToWallDistance * REVEL.WORLD_TO_SCREEN_RATIO
                    lastBusyCorner = {setY, x}
                end
            end
        end

        -- REVEL.DebugLog(REVEL.IsRenderPassReflection(), centerToWallRenderDistance)

        if collidingCorners > 1 then --colliding on more than 1 corner, just crop one or more sides off of it
            local topLeftClampX, topLeftClampY, botRightClampX, botRightClampY = 0, 0, 0, 0

            --if both top right and top left are set, their y should be the same, since walls are axis-aligned
            if centerToWallRenderDistance[-1][-1] and centerToWallRenderDistance[-1][1] then --colliding at top
                topLeftClampY = spriteRadius + centerToWallRenderDistance[-1][-1].Y
                -- REVEL.DebugLog("topLeftClampY", REVEL.IsRenderPassReflection(), topLeftClampY)
            end
            if centerToWallRenderDistance[1][-1] and centerToWallRenderDistance[1][1] then --colliding at bottom
                botRightClampY = spriteRadius - centerToWallRenderDistance[1][-1].Y
                -- REVEL.DebugLog("botRightClampY", REVEL.IsRenderPassReflection(), botRightClampY)
            end
            if centerToWallRenderDistance[-1][-1] and centerToWallRenderDistance[1][-1] then --colliding at left
                topLeftClampX = spriteRadius + centerToWallRenderDistance[-1][-1].X
            end
            if centerToWallRenderDistance[-1][1] and centerToWallRenderDistance[1][1] then --colliding at right
                botRightClampX = spriteRadius - centerToWallRenderDistance[1][1].X
            end

            -- REVEL.DebugLog(REVEL.IsRenderPassReflection(), Vector(topLeftClampX, topLeftClampY), Vector(botRightClampX, botRightClampY))

            local renderCenter = Isaac.WorldToScreen(entity.Position) + renderOffset - REVEL.room:GetRenderScrollOffset()

            if sprite.FlipX then
                sprite:Render(renderCenter, Vector(botRightClampX, topLeftClampY), Vector(topLeftClampX, botRightClampY))
            else
                sprite:Render(renderCenter, Vector(topLeftClampX, topLeftClampY), Vector(botRightClampX, botRightClampY))
            end

            local maxWallDistanceForSeam = spriteRadius - MinimumEmbedToRenderSeam * REVEL.WORLD_TO_SCREEN_RATIO

            if LastWallMarkSpriteUpdateFrame ~= REVEL.game:GetFrameCount() then
                LastWallMarkSpriteUpdateFrame = REVEL.game:GetFrameCount()
                wallMarkSprite:Update()
            end

            if centerToWallRenderDistance[-1][-1] and centerToWallRenderDistance[-1][1] and -centerToWallRenderDistance[-1][1].Y <= maxWallDistanceForSeam then --colliding at top
                wallMarkSprite.Rotation = 180
                local pos = Isaac.WorldToScreen(entity.Position) + Vector(0, centerToWallRenderDistance[-1][-1].Y)
                wallMarkSprite:Render(pos + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector(botRightClampX, 0), Vector(topLeftClampX, 0))
            end
            if centerToWallRenderDistance[1][-1] and centerToWallRenderDistance[1][1] and centerToWallRenderDistance[1][1].Y <= maxWallDistanceForSeam then --colliding at bottom
                wallMarkSprite.Rotation = 0
                local pos = Isaac.WorldToScreen(entity.Position) + Vector(0, centerToWallRenderDistance[1][-1].Y)
                wallMarkSprite:Render(pos + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector(topLeftClampX, 0), Vector(botRightClampX, 0))
            end
            if centerToWallRenderDistance[-1][-1] and centerToWallRenderDistance[1][-1] and -centerToWallRenderDistance[-1][-1].X <= maxWallDistanceForSeam then --colliding at left
                wallMarkSprite.Rotation = 90
                local pos = Isaac.WorldToScreen(entity.Position) + Vector(centerToWallRenderDistance[-1][-1].X, 0)
                wallMarkSprite:Render(pos + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector(topLeftClampY, 0), Vector(botRightClampY, 0))
            end
            if centerToWallRenderDistance[-1][1] and centerToWallRenderDistance[1][1] and centerToWallRenderDistance[-1][1].X <= maxWallDistanceForSeam  then --colliding at right
                wallMarkSprite.Rotation = 270
                local pos = Isaac.WorldToScreen(entity.Position) + Vector(centerToWallRenderDistance[-1][1].X, 0)
                wallMarkSprite:Render(pos + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector(botRightClampY, 0), Vector(topLeftClampY, 0))
            end
        elseif collidingCorners == 1 then --colliding with just 1 corner, meaning it's an L room, so cut that corner out
            local tl, br = REVEL.room:GetTopLeftPos(), REVEL.room:GetBottomRightPos()
            local roomCorner = tl + (br - tl) / 2
            -- corner of the perimeter of the room offset by WallDistance
            local expandedRoomCorner = roomCorner + vectorSign(roomCorner - REVEL.room:GetCenterPos()) * SMBladeBalance.WallDistance
            local corner = entity.Position + Vector(SMBladeBalance.Radius * lastBusyCorner[2], SMBladeBalance.Radius * lastBusyCorner[1])

            local cornerIndex = 1 + lastBusyCorner[1] + (lastBusyCorner[2] + 1) / 2
            local cornerOffset = expandedRoomCorner - corner

            renderWithCornerHoles(sprite, Isaac.WorldToScreen(entity.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), spriteRadius * 2, spriteRadius * 2,
                cornerOffset, cornerIndex)
        else
            sprite:Render(Isaac.WorldToScreen(entity.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
        end

        sprite.Color = REVEL.NO_COLOR
    end
end, REVEL.ENT.DECORATION.variant)

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function(_, player)
    if REVEL.ITEM.SMBLADE_UNUSED:PlayerHasCollectible(player) and not SMBladeBalance.EnableRoomCharges then
        player:RemoveCollectible(REVEL.ITEM.SMBLADE_UNUSED.id)
        player:AddCollectible(REVEL.ITEM.SMBLADE.id, 1)
    end
end)

end

REVEL.PcallWorkaroundBreakFunction()