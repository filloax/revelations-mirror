return function()

-----------------
-- LIL MICHAEL --
-----------------

--[[
A small angel hovers near the player. This familiar does not block friendly tears, but any friendly tears passing through it
will add their damage to its, and continue on uninterrupted. Once 20 tears have been fired, whether they pass through the
familiar or not, it sets off and homes into the highest health enemy in the room, and smacks it once, for 1.5x the damage
of all tears that passed through it, before returning to the player, and beginning the cycle a new. Inherits tear affects for his attack.

Familiar: a small angel the size of lil Belial, but with a huge sword that almost touches the floor. The sword has 4 levels of glow
to indicate how many tears he's absorbed.
0-5 normal
6-10 slight glow
11-15 bright glow
20 pure white.

Will attempt to orbit the player at the distance of an attack fly, but will move to intercept the current side of the
player that tears are currently being fired. He moves slowly though, so cannot react to multiple fast changes in tear direction.

Tweaks by coder:
Cannot charge in cleared rooms; slash hits enemies on sides for higher damage.
]]

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        player:CheckFamiliar(REVEL.ENT.LIL_MICHAEL.variant,
                                REVEL.ITEM.LIL_MICHAEL:GetCollectibleNum(player) *
                                    (player:GetEffects()
                                        :GetCollectibleEffectNum(
                                            CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) +
                                        1), RNG())
    end
end)

local BaseTearNum = 10
local DamageMult = 0.75
local IdleMinSpeed = 0.3
local IdleMaxSpeed = 1.2
local AttackSpeed = 1.7
local IdleFriction = 0.8
local AttackFriction = 0.9

local IdleRad = 80
local ShootRadLow = 25
local ShootRadHi = 40
local RadSpeed = 0.03
local ShootDist = 60
local ChargeAnims = {
    Flash2 = "Charge2",
    Flash3 = "Charge3",
    Flash4 = "Charge4"
}
local AttackWidth = 30 -- side distance where enemies are hit too
local GlowDur = 5
local TearFlagsToEnt = {
    [TearFlags.TEAR_SLOW] = EntityFlag.FLAG_SLOW,
    [TearFlags.TEAR_POISON] = EntityFlag.FLAG_POISON,
    [TearFlags.TEAR_FREEZE] = EntityFlag.FLAG_FREEZE,
    [TearFlags.TEAR_CHARM] = EntityFlag.FLAG_CHARM,
    [TearFlags.TEAR_CONFUSION] = EntityFlag.FLAG_CONFUSION,
    [TearFlags.TEAR_FEAR] = EntityFlag.FLAG_FEAR,
    [TearFlags.TEAR_BURN] = EntityFlag.FLAG_BURN,
    [TearFlags.TEAR_GODS_FLESH] = EntityFlag.FLAG_SHRINK,
    [TearFlags.TEAR_BLACK_HP_DROP] = EntityFlag.FLAG_SPAWN_BLACK_HP
}
-- TEAR_KNOCKBACK, TEAR_EXPLOSIVE, TEAR_LIGHT_FROM_HEAVEN also work

local function isGoodEnemy(e)
    return not e:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) and
                not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and e.Type ~=
                EntityType.ENTITY_SHOPKEEPER and e:IsVulnerableEnemy() and
                not e:IsInvincible()
end

local function applyFlag(fam, data, e)
    for tFlag, eFlag in pairs(TearFlagsToEnt) do
        if HasBit(data.tearFlags, tFlag) then
            e:AddEntityFlags(eFlag)
        end
    end

    if HasBit(data.tearFlags, TearFlags.TEAR_KNOCKBACK) then
        e.Velocity = e.Velocity + (e.Position - fam.Position):Resized(8)
    end
    if HasBit(data.tearFlags, TearFlags.TEAR_LIGHT_FROM_HEAVEN) then
        Isaac.Spawn(1000, 19, 0, e.Position + RandomVector() * 5,
                    Vector.Zero, fam)
    end
end

local function attackClose(fam, data)
    local angle = (data.targ.Position - fam.Position):GetAngleDegrees()

    if HasBit(data.tearFlags, TearFlags.TEAR_EXPLOSIVE) then
        Isaac.Explode(data.targ.Position, fam, data.tearDmg * DamageMult)
    else
        data.targ:TakeDamage(data.tearDmg * DamageMult, 0, EntityRef(fam), 20)
        data.targ:BloodExplode()
        REVEL.game:SpawnParticles(data.targ.Position,
                                    EffectVariant.BLOOD_PARTICLE,
                                    3 + math.random(2), math.random(4) + 1,
                                    Color.Default, -10)
    end
    applyFlag(fam, data, data.targ)
    local closeEnms = Isaac.FindInRadius(data.targ.Position, AttackWidth,
                                            EntityPartition.ENEMY)
    for i, e in ipairs(closeEnms) do
        if e.Index ~= data.targ.Index and isGoodEnemy(e) then
            -- damage if good enemy and close to the slash line (as in, if the slash was vertical (angle 0), close on the x coordinate)
            local rotatedDist = (data.targ.Position - e.Position):Rotated(-angle)
            if math.abs(rotatedDist.X) < 10 then
                e:TakeDamage(data.tearDmg * DamageMult * 0.5, 0, EntityRef(fam), 10)
                applyFlag(fam, data, e)
            end
        end
    end
end

revel:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, fam)
    local spr, data = fam:GetSprite(), fam:GetData()

    data.tearCount = 0
    data.tearDmg = 0
    data.tearFlags = TearFlags.TEAR_NORMAL
    data.angle = 0
    data.State = "Idle"
    data.glow = 0
end, REVEL.ENT.LIL_MICHAEL.variant)

local function addDamage(data, dmg, flags, maxdmg)
    data.glow = GlowDur
    data.tearDmg = math.min(maxdmg, data.tearDmg + dmg)
    data.tearFlags = BitOr(data.tearFlags, (flags or TearFlags.TEAR_NORMAL))
end

local LaserVarWeight = {}

local function checkForTriggers(fam, data, maxdmg)
    for _, tear in ipairs(REVEL.roomTears) do
        if not tear:GetData().lilMiked 
        and tear.Position:DistanceSquared(fam.Position) < (tear.Size + fam.Size) ^ 2 + 80 
        then
            tear:GetData().lilMiked = true
            addDamage(data, tear.CollisionDamage, tear.TearFlags, maxdmg)
        end
        if tear.FrameCount == 1 and tear.SpawnerType == 1 then
            data.tearCount = (data.tearCount or 0) + 1
        end
    end

    for __, e in ipairs(REVEL.roomKnives) do
        local edata = e:GetData()
        if e:IsFlying() then
            if not edata.wasFlying then
                edata.wasFlying = true
                data.tearCount = data.tearCount 
                    + REVEL.Lerp(0.5, 4, REVEL.GetApproximateKnifeCharge(e))
            end
            if e.FrameCount % 2 == 0 
            and e.Position:DistanceSquared(fam.Position) < (fam.Size + 80) ^ 2 then
                addDamage(data, e.CollisionDamage * 1.5, e.TearFlags, maxdmg) -- the mult is because knifes don't hit it very often
            end
        else
            edata.wasFlying = false
        end
    end

    for __, e in ipairs(REVEL.roomLasers) do
        local edata = e:GetData()
        if e.SpawnerType == 1 then
            if e.FrameCount == 1 then
                if e.OneHit then
                    data.tearCount = data.tearCount + 1
                else
                    data.tearCount = data.tearCount + 2.5
                end
            end
            if REVEL.CollidesWithLaser(fam.Position, e, 40) then
                local dmg = e.CollisionDamage
                if not e.OneHit and not e:IsCircleLaser() then
                    dmg = dmg * 3
                end

                addDamage(data, e.CollisionDamage, e.TearFlags, maxdmg)
            end
        end
    end

    for __, e in ipairs(REVEL.roomBombdrops) do
        local edata = e:GetData()
        if e.SpawnerType == 1 and not e:GetData().lilMiked and
            e.Position:DistanceSquared(fam.Position) < (e.Size + fam.Size) ^
            2 + 30 then
            e:GetData().lilMiked = true
            addDamage(data, e.ExplosionDamage * 1.5,
                BitOr(e.Flags, TearFlags.TEAR_EXPLOSIVE, maxdmg))
        end
        if e.FrameCount == 1 and e.SpawnerType == 1 then
            data.tearCount = (data.tearCount or 0) + 1
        end
    end
end

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, fam)
    local spr, data = fam:GetSprite(), fam:GetData()

    if data.glow >= 0 then
        fam.Color = Color.Lerp(Color.Default, REVEL.COLOR_W, 0.25 * data.glow / GlowDur)
        data.glow = data.glow - 1
    end

    local tpos = fam.Position
    local speed, friction = IdleMinSpeed, IdleFriction

    if data.State == "Idle" then
        data.angle = (data.angle + RadSpeed) % 360
        local ptarg = fam.Player
        local radMult = 1
        if fam.Player:GetPlayerType() == PlayerType.PLAYER_LILITH then
            local incubi = Isaac.FindByType(3, FamiliarVariant.INCUBUS, -1, true, false)
            for _, incubus in ipairs(incubi) do
                local d = incubus:GetData()
                if d.LastMike == fam.InitSeed or not d.LastMike then
                    d.LastMike = fam.InitSeed
                    ptarg = incubus
                    radMult = 0.6
                    break
                end
            end
        end

        if REVEL.IsShooting(fam.Player) then
            local aimDir = fam.Player:GetAimDirection()
            if fam.Player:GetFireDirection() == Direction.LEFT 
            or fam.Player:GetFireDirection() == Direction.RIGHT then
                tpos = REVEL.GetOrbitPositionEllipse(
                    ptarg.Position + ptarg.Velocity + Vector(aimDir.X * ShootDist, 0), 
                    data.angle,
                    ShootRadLow * radMult,
                    ShootRadHi * radMult
                )
            else
                tpos = REVEL.GetOrbitPositionEllipse(
                    ptarg.Position + ptarg.Velocity + Vector(0, aimDir.Y * ShootDist),
                    data.angle,
                    ShootRadHi * radMult,
                    ShootRadLow * radMult
                )
            end
        else
            tpos = REVEL.GetOrbitPosition(ptarg, data.angle, IdleRad * radMult)
        end
        speed = speed * REVEL.Clamp(
            tpos:DistanceSquared(fam.Position) / 200, 1,
            IdleMaxSpeed / IdleMinSpeed
        )

        local prevDmg = data.tearDmg
        local tearNumTrigger = BaseTearNum * 10 / math.max(fam.Player.MaxFireDelay, 4)
        local stage2, stage3, stage4 =
            fam.Player.Damage * tearNumTrigger / 3,
            fam.Player.Damage * tearNumTrigger * 2 / 3,
            fam.Player.Damage * tearNumTrigger

        local hiHP, targ = 0, nil
        for i, e in ipairs(REVEL.roomEnemies) do
            if e.HitPoints > hiHP and isGoodEnemy(e) then
                hiHP = e.HitPoints
                targ = e
            end
        end

        if targ then
            checkForTriggers(fam, data, stage4)

            if data.tearCount >= tearNumTrigger then
                data.tearCount = 0
                data.attackTimer = 16 -- wait a bit for last tear to reach him
            end
            if data.attackTimer and data.attackTimer > 0 then
                data.attackTimer = data.attackTimer - 1
            end
        end

        if prevDmg < stage4 and data.tearDmg >= stage4 then
            spr:Play("Flash4", true)
        elseif prevDmg < stage3 and data.tearDmg >= stage3 then
            spr:Play("Flash3", true)
        elseif prevDmg < stage2 and data.tearDmg >= stage2 then
            spr:Play("Flash2", true)
        end

        for k, v in pairs(ChargeAnims) do
            if spr:IsFinished(k) then spr:Play(v, true) end
        end

        if data.attackTimer == 0 and
            not REVEL.MultiPlayingCheck(spr, "Flash2", "Flash3", "Flash4") and
            targ then
            data.targ = targ
            data.State = "Attack"
            data.tearCount = 0
            data.attackTimer = nil
        end

    elseif data.State == "Attack" then
        tpos = data.targ.Position - Vector(0, 40)
        speed = AttackSpeed *
            REVEL.Clamp(tpos:DistanceSquared(fam.Position) / 5000,
                0.7, 1)
        friction = AttackFriction *
            REVEL.Clamp(tpos:DistanceSquared(fam.Position) / 2500, 0.75, 1)

        if REVEL.dist(fam.Position.X, tpos.X) < 15 and tpos.Y -
            fam.Position.Y < 20 and tpos.Y > fam.Position.Y then
            data.State = "Slash"
            spr:Play("Attack", true)
        end

    elseif data.State == "Slash" then
        if spr:IsFinished("Attack") then
            spr:Play("Slash", true)
            REVEL.sfx:Play(REVEL.SFX.SWING, 1, 0, false, 1)
            REVEL.sfx:Play(SoundEffect.SOUND_FETUS_JUMP, 0.8, 0, false, 1)
            attackClose(fam, data)

            data.tearDmg = 0
            data.tearFlags = TearFlags.TEAR_NORMAL
        elseif spr:IsFinished("Slash") then
            data.targ = nil
            data.State = "Idle"
            spr:Play("Charge1", true)
        end
    end

    if data.State ~= "Slash" then
        fam.Velocity = fam.Velocity * friction +
            (tpos - fam.Position):Resized(speed)
    else
        fam.Position = data.targ.Position - Vector(0, 40)
        fam.Velocity = data.targ.Velocity
    end
end, REVEL.ENT.LIL_MICHAEL.variant)

-- revel:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, function(_, fam)
    -- local data = fam:GetData()
    -- if fam.Variant == REVEL.ENT.LIL_MICHAEL.variant and data.Slash then
    --     data.Slash:Render(data.SlashPos, Vector.Zero, Vector.Zero)
    -- end
-- end)

end
