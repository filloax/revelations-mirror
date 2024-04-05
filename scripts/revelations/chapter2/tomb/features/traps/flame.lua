local ShrineTypes = require "scripts.revelations.common.enums.ShrineTypes"
return function()

REVEL.TrapTypes.FlameTrap = {
    OnSpawn = function(tile, data, index)
        local rotation = data.TrapData.Rotation
        local pos = tile.Position

        if rotation==90 then pos = Vector(REVEL.room:GetBottomRightPos().X, pos.Y)
        elseif rotation==180 then pos = Vector(pos.X, REVEL.room:GetBottomRightPos().Y)
        elseif rotation==270 then pos = Vector(REVEL.room:GetTopLeftPos().X, pos.Y)
        elseif rotation==0 then pos = Vector(pos.X, REVEL.room:GetTopLeftPos().Y) end

        local alreadyExists
        local spawnPos = pos + (Vector.FromAngle(rotation-90)*5)

        local flameTraps = Isaac.FindByType(REVEL.ENT.FLAME_TRAP.id, REVEL.ENT.FLAME_TRAP.variant, -1, false, false)
        for _, trap in ipairs(flameTraps) do
            if REVEL.room:GetGridIndex(trap.Position) == REVEL.room:GetGridIndex(spawnPos) and trap:GetSprite().Rotation == rotation then
                alreadyExists = trap
                break
            end
        end

        if not alreadyExists then
            local eff = Isaac.Spawn(REVEL.ENT.FLAME_TRAP.id, REVEL.ENT.FLAME_TRAP.variant, 0, spawnPos, Vector.Zero, nil)
            REVEL.GetData(eff).TrapSpawned = true
            eff:GetSprite().Rotation = rotation
            data.FlameTrap = eff
        else
            data.FlameTrap = alreadyExists
        end
    end,
    OnTrigger = function(tile, data)
        local fdata = REVEL.GetData(data.FlameTrap)
        fdata.NoHitPlayer = data.TrapIsPositiveEffect
        fdata.DeactivateAt = data.FlameTrap.FrameCount + 150

        local sprite = data.FlameTrap:GetSprite()
        if not sprite:IsPlaying("Shoot") then
            sprite:Play("Shoot", true)
        end
    end,
    Cooldown = 150,
    Animation = "Flame"
}

local flameTrapProjectileFade = 16
local flameTrapSizeFadeStart = -2 --relative to projectile fade start set in shoot function
local slowdownStart = 10 --absolute
local stopHurtingFrame = 2 --absolute

local flameTrapProjectileColorStart = Color(1, 1, 1, 1,conv255ToFloat( 64, 128, 64))
local flameTrapProjectileColorNormal = Color(1, 1, 1, 1,conv255ToFloat( 0, 0, 0))
local invisibleFlameTrapProjectile = Color(1, 1, 1, 0,conv255ToFloat( 0, 0, 0))

local timeToNormal = 6

local flameTrapProjectileMinSize = 100
local flameTrapProjectileMaxSize = 140

local rotationsOffsets = {
    [0] = Vector(0, -5),
    [90] = Vector(10, 0),
    [180] = Vector(0, 15),
    [270] = Vector(-10, 0)
}

local timedFlameRate = 60
local timedFlameTime = 20
local flameSpriteOffset = Vector(0, 5)

function REVEL.ShootFlameTrap(eff, rotation, dontHitEnms, scaleMult, speed, cooldownMult, position, noOffset, forceScale)
    local fireDir = Vector.FromAngle(rotation + 90)
    local offset = Vector.Zero
    rotation = rotation % 360
    if not noOffset and rotationsOffsets[rotation] then
        offset = rotationsOffsets[rotation]
    end

    local t = Isaac.Spawn(REVEL.ENT.FLAME_TRAP_FIRE.id, REVEL.ENT.FLAME_TRAP_FIRE.variant, 0, position or (eff.Position + offset), fireDir:Rotated(math.random(-12, 12)) * (speed or 9), eff)

    local tData = REVEL.GetData(t)
    tData.NoHitEnemies = dontHitEnms
    t.SpriteOffset = flameSpriteOffset
    t.CollisionDamage = 5

    if not forceScale then
        scaleMult = (scaleMult or 1) * math.random(flameTrapProjectileMinSize, flameTrapProjectileMaxSize) * 0.01
    else
        scaleMult = forceScale
    end

    t.Size = (t.Size * scaleMult) * 0.4
    t.SpriteScale = (Vector.One * scaleMult) * 0.4

    local tSprite = t:GetSprite()

    if eff then
        t.DepthOffset = eff.DepthOffset + 100
        local effData = REVEL.GetData(eff)
        tData.NoHitPlayer = effData.NoHitPlayer
        tData.Homing = not not effData.HomingCooldown

        if effData.HomingCooldown then
            tSprite:ReplaceSpritesheet(0, "gfx/effects/effect_005_fire_purple.png")
            tSprite:LoadGraphics()
        end
    end

    tData.FlameTrapBaseSize = t.Size
    tData.FlameTrapBaseScale = Vector(t.SpriteScale.X, t.SpriteScale.Y)
    tData.FlameTrapCooldown = flameTrapProjectileFade * (cooldownMult or 1)
    tData.FlameTrapCooldownStart = tData.FlameTrapCooldown

    return t
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    local sprite = eff:GetSprite()
    if sprite:IsFinished("Shoot") then
        sprite:Play("ShootLoop", true)
    end

    if sprite:IsFinished("ShootEnd") then
        sprite:Play("Idle", true)
    end

    local data = REVEL.GetData(eff)
    local frame = eff.FrameCount
    if not data.TrapSpawned then
        if data.DisableOnClear then
            data.Disabled = REVEL.room:IsClear()
        end

        if not data.Disabled then
            if not data.TrapSpawned and not data.FlameTrapType then
                if not (sprite:IsPlaying("Shoot") or sprite:IsPlaying("ShootLoop") or sprite:IsPlaying("ShootEnd")) then
                    sprite:Play("Shoot", true)
                end

                data.DeactivateAt = frame + timedFlameTime
            end

            if data.FlameTrapType == "Timed" and frame % timedFlameRate == 0 then
                sprite:Play("Shoot", true)
                data.DeactivateAt = frame + timedFlameTime
            elseif data.FlameTrapType == "TimedOffset" and (frame + timedFlameRate / 2) % timedFlameRate == 0 then
                sprite:Play("Shoot", true)
                data.DeactivateAt = frame + timedFlameTime
            end
        end
    end

    if data.DeactivateAt and frame > data.DeactivateAt then
        data.DeactivateAt = nil
        sprite:Play("ShootEnd", true)
    end

    if data.HomingCooldown then
        data.HomingCooldown = data.HomingCooldown - 1
        if not data.HomingInit then
            sprite:ReplaceSpritesheet(0, "gfx/grid/revel2/traps/trap_firetrap_purple.png")
            sprite:LoadGraphics()
            data.HomingInit = true
        end
        if data.HomingCooldown <= 0 then
            data.HomingCooldown = nil
        end
    else
        if data.HomingInit then
            sprite:ReplaceSpritesheet(0, "gfx/grid/revel2/traps/trap_firetrap.png")
            sprite:LoadGraphics()
            data.HomingInit = false
        end
    end

    if sprite:IsEventTriggered("Shoot") then
        if not REVEL.sfx:IsPlaying(REVEL.SFX.FIRE_START) and not REVEL.sfx:IsPlaying(REVEL.SFX.FIRE_LOOP) then
            REVEL.sfx:Play(REVEL.SFX.FIRE_START, 0.3, 0, false, 1)
        end
    end

    local shouldBeShooting = sprite:WasEventTriggered("Shoot") or sprite:IsPlaying("ShootLoop") or (sprite:IsPlaying("ShootEnd") and not sprite:WasEventTriggered("End"))
    if shouldBeShooting and not REVEL.sfx:IsPlaying(REVEL.SFX.FIRE_START) and not REVEL.sfx:IsPlaying(REVEL.SFX.FIRE_LOOP) then
        REVEL.sfx:Play(REVEL.SFX.FIRE_LOOP, 0.3, 0, false, 1)
    end

    if sprite:IsEventTriggered("End") then
        REVEL.sfx:Play(REVEL.SFX.FIRE_END, 0.3, 0, false, 1)
        local isOtherShooting
        for _, trap in ipairs(Isaac.FindByType(REVEL.ENT.FLAME_TRAP.id, REVEL.ENT.FLAME_TRAP.variant, -1, false, false)) do
            local tsprite = trap:GetSprite()
            if tsprite:WasEventTriggered("Shoot") or tsprite:IsPlaying("ShootLoop") or (tsprite:IsPlaying("ShootEnd") and not tsprite:WasEventTriggered("End")) then
                isOtherShooting = true
            end
        end

        if not isOtherShooting then
            REVEL.sfx:Stop(REVEL.SFX.FIRE_LOOP)
        end
    end

    if eff.FrameCount % 2 == 0 and shouldBeShooting then
        if eff.FrameCount % 16 == 0 then
            local fireDir = Vector.FromAngle(sprite.Rotation + 90)
            local checkPositions = {eff.Position + fireDir * 30, eff.Position + fireDir * 70, eff.Position + fireDir * 110}
            for _, pos in ipairs(checkPositions) do
                local grid = REVEL.room:GetGridEntityFromPos(pos)
                if grid and (grid.Desc.Type == GridEntityType.GRID_POOP or grid.Desc.Type == GridEntityType.GRID_TNT) 
                and not REVEL.IsGridBroken(grid) then
                    grid:Hurt(1)
                end
            end
        end

        if eff.FrameCount % 30 == 0 and REVEL.IsShrineEffectActive(ShrineTypes.PERIL) then
            REVEL.ShootFlameTrap(eff, sprite.Rotation, false, nil, nil, 2)
        end
        REVEL.ShootFlameTrap(eff, sprite.Rotation)
    end
end, REVEL.ENT.FLAME_TRAP.variant)

local firePoof = Color(1.1, 0.75, 0, 0.5,conv255ToFloat( 0, 0, 0))
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, pro)
    local data = REVEL.GetData(pro)
    if data.FlameTrapCooldown then
        if data.FlameTrapCooldown >= data.FlameTrapCooldownStart - timeToNormal then
            pro.Color = Color.Lerp(flameTrapProjectileColorStart, flameTrapProjectileColorNormal, (data.FlameTrapCooldownStart - data.FlameTrapCooldown) / timeToNormal)
        else
            pro.Color = Color.Lerp(invisibleFlameTrapProjectile, flameTrapProjectileColorNormal, data.FlameTrapCooldown / (data.FlameTrapCooldownStart - timeToNormal))
        end

        if data.FlameTrapCooldown <= data.FlameTrapCooldownStart+flameTrapSizeFadeStart then
            local percent = data.FlameTrapCooldown / (data.FlameTrapCooldownStart+flameTrapSizeFadeStart)
            pro.Size = REVEL.Lerp(data.FlameTrapBaseSize * 2.5, data.FlameTrapBaseSize, percent)
            pro.SpriteScale = REVEL.Lerp(data.FlameTrapBaseScale * 2.5, data.FlameTrapBaseScale, percent)
        end

        if data.FlameTrapCooldown <= slowdownStart then
            pro.Velocity = pro.Velocity * 0.9
        end

        if data.FlameTrapCooldown > stopHurtingFrame then
            local impact
            if not data.NoHitPlayer then
                for _, player in ipairs(REVEL.players) do
                    if player.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE and player.Position:DistanceSquared(pro.Position) < (pro.Size + player.Size) ^ 2 then
                        player:TakeDamage(1, DamageFlag.DAMAGE_FIRE, EntityRef(pro), 0)
                        impact = true
                        pro:Remove()
                    end
                end
            end

            if not data.NoHitEnemies then
                for _, enemy in ipairs(REVEL.roomNPCs) do
                    if enemy.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE and enemy.Position:DistanceSquared(pro.Position) < (pro.Size + enemy.Size) ^ 2 and enemy:IsVulnerableEnemy() and enemy.HitPoints >= 0 and not enemy:IsDead() and not enemy:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) and not REVEL.GetData(enemy).FlameTrapPassThrough then
                        local dmg = pro.CollisionDamage
                        if enemy.Type == EntityType.ENTITY_PRIDE then
                            dmg = dmg * 0.2
                        end
                        enemy:TakeDamage(dmg, DamageFlag.DAMAGE_FIRE, EntityRef(pro), 0)
                        impact = true
                        pro:Remove()
                    end
                end
            end

            if impact then
                local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, pro.Position, Vector.Zero, nil)
                poof.Color = firePoof
                poof.SpriteScale = Vector.One * (0.5 + math.random() * 0.5)
            end
        end

        if data.FlameTrapCooldown <= 0 then
            pro:Remove()
        end

        data.FlameTrapCooldown = data.FlameTrapCooldown - 1
    end
end, REVEL.ENT.FLAME_TRAP_FIRE.variant)

end