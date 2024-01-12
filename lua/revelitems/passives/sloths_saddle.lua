local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()
-------------------
-- SLOTHS SADDLE --
-------------------

--[[
A little version of Sloth rides around ontop of Isaac's head. While in a cleared room,
Sloth whips the player, setting speed to max. For every 10 damage the player does to enemies,
Sloth spawns a tiny charger which will try to keep pace with the player. Should they
align with an enemy they charge and do constant damage to the enemy until it dies. When no
enemies exist, they have a chance to die every frame. Resulting in a quick pace required
to maintain a force of maggots.

The damage required to spawn a maggot starts at 10, then increases with maggots spawned (with formula 10 * (1 + 0.2 * maggots^1.5))
Damage dealt vs bosses in boss rooms is also nerfed with maggots spawned
]]

local WhipCooldownMax = 80
local BaseDmgTrigger = 10
local SpitCoolMax = 25

local function IsGoodEnemy(e)
    return not e:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) and
                not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and e.Type ~=
                EntityType.ENTITY_SHOPKEEPER and e:IsVulnerableEnemy() and
                not e:IsInvincible()
end

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, p)
    local data = p:GetData()
    if REVEL.ITEM.SLOTHS_SADDLE:PlayerHasCollectible(p) then
        if not data.slothState then
            data.slothState = "Idle"
            data.slothDmgCount = 0
            data.slothSpawnCount = 0
            data.slothWhipCool = WhipCooldownMax
            data.spitCool = SpitCoolMax
            data.slothVolDown = 0
        end

        if not data.SlothSaddle or not data.SlothSaddle:Exists() then
            data.SlothSaddle = REVEL.SpawnCustomGlow(p, "HeadDown",
                                                        "gfx/itemeffects/revelcommon/slothsaddle.anm2")
            data.SlothSaddle:AddEntityFlags(
                EntityFlag.FLAG_NO_STATUS_EFFECTS |
                    EntityFlag.FLAG_DONT_OVERWRITE |
                    EntityFlag.FLAG_NO_TARGET)
        end

        local e, spr = data.SlothSaddle,
                        data.SlothSaddle:GetData().customGlowSprite
        local goodEnms = REVEL.GetFilteredArray(REVEL.roomEnemies,
                                                IsGoodEnemy)
        local headDir = p:GetHeadDirection()

        if spr:IsEventTriggered("Whip") then
            REVEL.sfx:Play(SoundEffect.SOUND_ANIMAL_SQUISH, 0.5 -
                                math.min(0.3, data.slothVolDown * 0.3 / 4),
                            0, false, 1)
        elseif spr:IsEventTriggered("Whoosh") then
            REVEL.sfx:Play(SoundEffect.SOUND_SHELLGAME, 0.5 -
                                math.min(0.3, data.slothVolDown * 0.3 / 4),
                            0, false, 1.2)
        elseif spr:IsEventTriggered("Spawn") then
            REVEL.sfx:Play(SoundEffect.SOUND_WHEEZY_COUGH, 0.5, 0, false,
                            1.2)
        end

        if data.slothState == "Idle" then
            if REVEL.room:IsClear() and #goodEnms == 0 then
                data.slothState = "Whip"
                spr:Play("Whip", true)
                p:AddCacheFlags(CacheFlag.CACHE_SPEED)
                p:EvaluateItems()
            end

            if data.slothDmgCount >= BaseDmgTrigger *
                (1 + 0.2 * data.slothSpawnCount ^ 1.7) then
                data.slothState = "Spit"
                data.slothDmgCount = 0
                data.slothSpawnCount = data.slothSpawnCount + 1
                spr:Play("Shoot", true)
                data.spitCool = SpitCoolMax
            end

        elseif data.slothState == "Whip" then
            if not spr:IsPlaying("Whip") then
                if data.slothWhipCool > 0 then
                    data.slothWhipCool = data.slothWhipCool - 1
                else
                    spr:Play("Whip", true)
                    data.slothWhipCool = WhipCooldownMax
                    data.slothVolDown = data.slothVolDown + 1
                end
            end

            if not (REVEL.room:IsClear() and #goodEnms == 0) then
                p:AddCacheFlags(CacheFlag.CACHE_SPEED)
                p:EvaluateItems()
                data.slothState = "Idle"
                data.slothVolDown = 0
            end
        elseif data.slothState == "Spit" then
            if spr:IsEventTriggered("Spawn") and not data.spawnedCharger then
                local c = REVEL.ENT.LIL_CHARGER:spawn(p.Position +
                                                            Vector(0, 20),
                                                        p.Velocity +
                                                            Vector(0, 2), p)
                c.Parent = p
                data.spawnedCharger = true
            elseif spr:IsFinished("Shoot") then
                data.spitCool = SpitCoolMax
                data.spawnedCharger = false
            elseif not spr:IsPlaying("Shoot") then
                if data.spitCool > 0 then
                    data.spitCool = data.spitCool - 1
                else
                    data.slothState = "Idle"
                end
            end
        end

        if not REVEL.MultiPlayingCheck(spr, "Shoot", "Whip") then
            spr:SetFrame("Head" .. REVEL.dirToString[headDir],
                            p:GetSprite():GetOverlayFrame())
        end
        e.DepthOffset = 10

    elseif data.slothState then
        data.slothState = nil
        if data.SlothSaddle then
            data.SlothSaddle:Remove()
            data.SlothSaddle = nil
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, dmg, flag, src)
    local player = REVEL.GetPlayerFromDmgSrc(src)
    if player and REVEL.ITEM.SLOTHS_SADDLE:PlayerHasCollectible(player) then
        player:GetData().slothDmgCount = player:GetData().slothDmgCount + dmg
    end
end)

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if REVEL.ITEM.SLOTHS_SADDLE:PlayerHasCollectible(player) and flag ==
        CacheFlag.CACHE_SPEED and REVEL.room:IsClear() then
        local goodEnms = REVEL.GetFilteredArray(REVEL.roomEnemies,
                                                IsGoodEnemy)
        if #goodEnms == 0 then player.MoveSpeed = 2 end
    end
end)

-- Lil charger

local ChargerDistanceTrigger = 20 -- alignment max distance from a charger to an enemy for the charger to start charging
local NonBlockCollisions = {GridCollisionClass.COLLISION_NONE}
local WalkAnims = {
    Horizontal = "Move Hori",
    Up = "Move Up",
    Down = "Move Down"
}
local AttackAnims = {
    Horizontal = "Attack Hori",
    Up = "Attack Up",
    Down = "Attack Down"
}
local ChargeSpd = 9

local function LerpOffset(data)
    if data.offsetLerp <= data.offsetLerpTime then
        data.offset.X = data.MaxOffset.X *
                            REVEL.Lerp2(1, -1, data.offsetLerp, 0,
                                        data.offsetLerpTime)
    elseif data.offsetLerp <= data.offsetLerpTime * 2 then
        local x = data.offsetLerp - data.offsetLerpTime
        data.offset.Y = data.MaxOffset.Y *
                            REVEL.Lerp2(1, -1, x, 0, data.offsetLerpTime)
    elseif data.offsetLerp <= data.offsetLerpTime * 3 then
        local x = data.offsetLerp - data.offsetLerpTime * 2
        data.offset.X = data.MaxOffset.X *
                            REVEL.Lerp2(-1, 1, x, 0, data.offsetLerpTime)
    else
        local x = data.offsetLerp - data.offsetLerpTime * 3
        data.offset.Y = data.MaxOffset.Y *
                            REVEL.Lerp2(-1, 1, x, 0, data.offsetLerpTime)
    end
end

revel:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, f)
    local data, spr = f:GetData(), f:GetSprite()
    data.State = "Appear"
    spr:Play("Appear", true)

    local r = REVEL.RNG()
    r:SetSeed(f.InitSeed, 0)
    data.MaxOffset = (Vector.One * (15 + r:RandomInt(30)))
        :Rotated(90 * r:RandomInt(4))
    data.offsetLerpTime = 20
    data.offsetLerp = r:RandomInt(data.offsetLerpTime * 4)
    data.offset = Vector(0, 0)
    data.canCharge = 0
    LerpOffset(data)

    f.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
end, REVEL.ENT.LIL_CHARGER.variant)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, f)
    local data, spr = f:GetData(), f:GetSprite()
    f.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

    if data.State == "Appear" then
        if spr:IsFinished("Appear") then data.State = "Follow" end
    elseif data.State == "Follow" then
        data.offsetLerp = (data.offsetLerp + 1) %
                                (data.offsetLerpTime * 4 + 1)
        LerpOffset(data)

        REVEL.AnimateWalkFrameSpeed(spr, f.Velocity, WalkAnims) -- done before to account for collision velocity changes

        if f.FrameCount % 3 == 0 then
            local goodEnemiesLeft = false
            for i, enemy in ipairs(REVEL.roomEnemies) do
                if IsGoodEnemy(enemy) then
                    goodEnemiesLeft = true
                    if data.canCharge == 0 and
                        not enemy:GetData().slothChargeCooldown then
                        local diff = enemy.Position - f.Position
                        local x, y = math.abs(diff.X), math.abs(diff.Y)
                        if x <= ChargerDistanceTrigger or y <=
                            ChargerDistanceTrigger then
                            data.State = "Charge"
                            data.canCharge = 6
                            if x > y then
                                data.ChargeVel = Vector(diff.X / x *
                                                            ChargeSpd, 0) -- orthogonal direction, ChargeSpd length
                            else
                                data.ChargeVel =
                                    Vector(0, diff.Y / y * ChargeSpd) -- orthogonal direction, ChargeSpd length
                            end
                            enemy:GetData().slothChargeCooldown = 8
                            f.Velocity = data.ChargeVel
                        end
                    end
                end
            end

            if not goodEnemiesLeft and math.random() > 0.95 then
                REVEL.game:SpawnParticles(f.Position,
                                            EffectVariant.BLOOD_PARTICLE,
                                            3 + math.random(2),
                                            math.random(4) + 1, Color.Default,
                                            -10)
                f:BloodExplode()
                f.Player:GetData().slothSpawnCount = f.Player:GetData()
                                                            .slothSpawnCount -
                                                            1
                f:Remove()
            end
        end

        local targPos = f.Player.Position + data.offset
        local dist = targPos:Distance(f.Position)
        local speed = 8

        if dist < 40 then
            f.Velocity = targPos - f.Position
            data.canCharge = math.max(0, data.canCharge - 1)
        else
            local id, tid = REVEL.room:GetGridIndex(f.Position),
                            REVEL.room:GetGridIndex(targPos)

            if not REVEL.includes(NonBlockCollisions,
                                REVEL.room:GetGridCollision(tid)) then
                local nearFree = REVEL.GetNearFreeGridIndexes(tid, 1, 0, {})
                if #nearFree > 0 then tid = nearFree[1] end
            end

            local path =
                REVEL.GeneratePathAStar(id, tid, NonBlockCollisions) -- check revel1_library
            if path and path[1] then
                f.Velocity = REVEL.room:GetGridPosition(path[1]) -
                                    f.Position
            end
        end

        local l = f.Velocity:Length()
        if l > speed then f.Velocity = f.Velocity * (speed / l) end

    elseif data.State == "Charge" then
        REVEL.AnimateWalkFrame(spr, f.Velocity, AttackAnims) -- done before to account for collision velocity changes
        f.Velocity = data.ChargeVel

        if f.FrameCount % 2 == 0 then
            local closeEnms = Isaac.FindInRadius(f.Position, f.Size + 60, EntityPartition.ENEMY)
            for i, e in ipairs(closeEnms) do
                if IsGoodEnemy(e) and f.Position:DistanceSquared(e.Position) <=
                    (f.Size + e.Size) ^ 2 then
                    local dmg = 0.9
                    if e:IsBoss() and REVEL.room:GetType() ==
                        RoomType.ROOM_BOSS then
                        dmg = dmg /
                                    (1 + f.Player:GetData().slothSpawnCount /
                                        2)
                    end

                    e:TakeDamage(dmg, 0, EntityRef(f), 10)
                end
            end
        end

        if not REVEL.includes(NonBlockCollisions,
                            REVEL.room:GetGridCollisionAtPos(
                                f.Position + f.Velocity)) then
            data.State = "Follow"
        end
    end
end, REVEL.ENT.LIL_CHARGER.variant)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    local data = npc:GetData()
    if data.slothChargeCooldown then
        data.slothChargeCooldown = data.slothChargeCooldown - 1
        if data.slothChargeCooldown <= 0 then
            data.slothChargeCooldown = nil
        end
    end
end)

end
