return function()

------------------------
-- BARGAINER'S BURDEN --
------------------------

--[[
A sack familiar follows Isaac, with weighted momentum (akin to Guppy's Hairball). It's size and momentum scale with the combined amount of pickups the player currently has. While the player is holding the shoot button the sack will flash and shake in place, when they release it the sack will fly forward, dealing damage and knockback based on it's size.
Coins 0-99. Keys 0-99. Bombs 0-99. = 0-297 consumables.
First 10 bombs and keys cont as 5 each.

Sprites

Pedestal - Sack filled with coins.

Familiar - 5 sizes. The sack swells with coins in each iteration.
Small = 0-10 consumables.
Medium = 11-50 consumables.
Large = 51-100 consumables
Huge = 101-200 consumables.
MY GOD IT'S MASSIVE = 201-297
]]

local Cooldown = 30
local MinDmg = 4.5
local MaxDmg = 13
local NoChargeDmgMult = 1
local MidDistanceDmgMult = 1.5
local MaxDistanceDmgMult = 2
local MidDistance = 120
local MaxDistance = 300
local ChargeDamageBoostTime = 10
local MinThrowSpeedFromDist = 7.5
local MaxThrowSpeedFromDist = 20
local MinThrowSpeedMultFromCharge = 0.6
local MaxThrowSpeedMultFromCharge = 1.5
local MinKnockFromLevel = 6 -- further affected by velocity
local MaxKnockFromLevel = 14
local AvgSpeed = 12
local XSpeedSwingTreshold = 7
local MaxBomsKeysWorthExtra = 10
local BombsKeysExtraValue = 5
local MaxConsumables = 99
local SwingTimeAfterPlayerStopped = 3

local TiersPct = {5, 20, 40, 68, 101}

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if HasBit(flag, CacheFlag.CACHE_FAMILIARS) then
        local num = (REVEL.ITEM.BARG_BURD:GetCollectibleNum(player)) *
                        (player:GetEffects():GetCollectibleEffectNum(
                            CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
        local rng = REVEL.RNG()
        rng:SetSeed(math.random(635), 0)
        player:CheckFamiliar(REVEL.ENT.BARG_BURD.variant, num, rng:GetRNG())
    end
end)

local function getLevel(p)
    local total = MaxConsumables * 3 + MaxBomsKeysWorthExtra * 2 *
                        (BombsKeysExtraValue - 1)
    local b = p:GetNumBombs()
    b = b + math.min(b, MaxBomsKeysWorthExtra) * (BombsKeysExtraValue - 1)
    local k = p:GetNumKeys()
    k = k + math.min(k, MaxBomsKeysWorthExtra) * (BombsKeysExtraValue - 1)
    local count = p:GetNumCoins() + b + k

    for level, tierPct in ipairs(TiersPct) do
        if count <= total * tierPct / 100 then return level end
    end
end

revel:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, fam)
    local data = fam:GetData()

    data.Charging = false
    data.FollowFrame = -Cooldown
    data.Hit = {}
    data.TimeSinceSwinging = 0
    data.damageMult = NoChargeDmgMult
    data.damageBoostTime = 0
    fam:GetSprite():Play("Idle", true)
end, REVEL.ENT.BARG_BURD.variant)

local function shake(fam, spr, data)
    if fam.SpriteOffset.X >= 0 then
        fam.SpriteOffset = Vector(-0.5, 0)
    else
        fam.SpriteOffset = Vector(0.5, 0)
    end
end

local function isGoodEnemy(e)
    return not e:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) and
                not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and e.Type ~=
                EntityType.ENTITY_SHOPKEEPER and e:IsVulnerableEnemy() and
                not e:IsInvincible()
end

local IsAnimationTowardsRight = true

local function manageAnim(fam, spr, data, level)
    local xVel = fam.Velocity.X

    if IsAnimOn(spr, "SwingRight") and xVel * data.SwingDir <
        XSpeedSwingTreshold then -- if moving opposite direction than previous swing, swing back
        spr:Play("SwingCenter", true)
    end

    if spr:IsFinished("SwingCenter") or IsAnimOn(spr, "Idle") then
        if math.abs(xVel) >= XSpeedSwingTreshold then
            spr.FlipX = not ((xVel > 0) == IsAnimationTowardsRight)
            data.SwingDir = xVel > 0 and 1 or -1

            spr:Play("SwingRight", true)
        elseif spr:IsFinished("SwingCenter") then
            spr:Play("Bounce", true)
        end
    elseif spr:IsFinished("Bounce") then
        spr:Play("Idle", true)
    end
end

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, fam)
    local spr, data = fam:GetSprite(), fam:GetData()

    local level = getLevel(fam.Player)
    if level ~= data.prevLevel then
        spr:ReplaceSpritesheet(0,
                                "gfx/familiar/revelcommon/bargainers_burden_" ..
                                    level .. ".png")
        spr:LoadGraphics()
        data.prevLevel = level
    end

    local vl = fam.Velocity:Length()

    if vl > 5 then
        data.TimeSinceSwinging = 0
    else
        data.TimeSinceSwinging = math.min(SwingTimeAfterPlayerStopped,
                                            data.TimeSinceSwinging + 1)
    end

    if REVEL.IsShooting(fam.Player) and fam.FrameCount - data.FollowFrame >
        Cooldown / 2 then
        if not data.Charging then
            data.ChargeFrame = fam.FrameCount
        end
        data.Charging = true

        shake(fam, spr, data)
        fam:MultiplyFriction(0.9)
    elseif data.Charging then -- launch
        data.Charging = false
        fam.SpriteOffset = Vector.Zero

        local l = fam.Player.Position:Distance(fam.Position)
        local t = fam.FrameCount - data.ChargeFrame
        local lm = REVEL.Lerp2Clamp(MinThrowSpeedFromDist,
                                    MaxThrowSpeedFromDist, l, 0, 240)
        local tm = REVEL.Lerp2Clamp(MinThrowSpeedMultFromCharge,
                                    MaxThrowSpeedMultFromCharge, t, 0, 60)
        data.damageMult = REVEL.Lerp3PointClamp(NoChargeDmgMult,
                                                MidDistanceDmgMult,
                                                MaxDistanceDmgMult, l, 0,
                                                MidDistance, MaxDistance)
        -- REVEL.DebugToConsole(l, data.damageMult)
        data.damageBoostTime = ChargeDamageBoostTime
        fam.Velocity = (fam.Player.Position - fam.Position) * (lm * tm / l)
        if l > 80 then
            REVEL.sfx:Play(REVEL.SFX.WHOOSH, math.min(0.2+(l*0.02), 0.7), 0, false, 0.7+(l*0.01))
        end
    else
        local l = fam.Player.Velocity:Length()

        if data.damageBoostTime > 0 then
            data.damageBoostTime = data.damageBoostTime - 1
        else
            data.damageMult = NoChargeDmgMult
        end

        local distSq = (fam.Player.Position:DistanceSquared(fam.Position))
        local increase = 0
        local reduce = 1
        if l > 0.1 or data.TimeSinceSwinging < SwingTimeAfterPlayerStopped then
            reduce = 0.92
            if distSq > 40 * 40 then
                increase = 0.035
            else
                increase = 0.015
            end
        else
            reduce = 0.8
            if distSq > 40 * 40 then increase = 0.01 end
        end

        fam.Velocity = fam.Velocity * reduce +
                            (fam.Player.Position - fam.Position) * increase

        if not REVEL.room:IsPositionInRoom(fam.Position, -40) then
            local toCenter = REVEL.room:GetCenterPos() - fam.Position
            local angleToCenterDir = sign(
                                            toCenter:GetAngleDegrees() -
                                                fam.Velocity:GetAngleDegrees())
            fam.Velocity = (fam.Velocity +
                                Vector.FromAngle(
                                    fam.Velocity:GetAngleDegrees() +
                                        angleToCenterDir * 90) * 0.1) * 0.93
        end
    end

    if vl > 10 then
        local knockMult = vl / AvgSpeed

        local closeEnms = Isaac.FindInRadius(fam.Position, 40, EntityPartition.ENEMY)
        for _, enm in ipairs(closeEnms) do
            if isGoodEnemy(enm) and not data.Hit[enm.InitSeed] then
                enm:TakeDamage(
                    REVEL.Lerp2Clamp(MinDmg, MaxDmg, level, 1, 5) *
                        data.damageMult, 0, EntityRef(fam), 10)
                local dir = (enm.Position * 2) - fam.Position -
                                fam.Player.Position
                REVEL.PushEnt(enm, knockMult *
                                    REVEL.Lerp2Clamp(MinKnockFromLevel,
                                                    MaxKnockFromLevel, level,
                                                    1, 5), dir, 12)
                data.Hit[enm.InitSeed] = 15
                REVEL.game:SpawnParticles(fam.Position,
                                            EffectVariant.BLOOD_PARTICLE,
                                            math.random(2),
                                            math.random(3) + 1, Color.Default,
                                            -15)

                if vl>20 then
                    REVEL.sfx:Play(SoundEffect.SOUND_WHIP_HIT, 0.6, 0, false,
                                1 + math.random() * 0.1)
                else
                    REVEL.sfx:Play(SoundEffect.SOUND_FETUS_JUMP, 0.8, 0, false,
                                0.75 + math.random() * 0.1)
                end
            end
        end
    end

    for enemySeed, cooldown in pairs(data.Hit) do
        data.Hit[enemySeed] = cooldown - 1
        if cooldown <= 0 then data.Hit[enemySeed] = nil end
    end

    manageAnim(fam, spr, data, level)
end, REVEL.ENT.BARG_BURD.variant)

end
