local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Locusts

StageAPI.AddCallback("Revelations", "POST_SPAWN_ENTITY", 1, function(entity)
    if entity.Type == REVEL.ENT.LOCUST.id and entity.Variant == REVEL.ENT.LOCUST.variant then
        local data = entity:GetData()
        data.LocustsLeading = {}
        entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
        local locustCount
        if entity.SubType <= 0 then locustCount = 4
        else locustCount = entity.SubType-1 end
        for i = 1, locustCount do
            local locust = Isaac.Spawn(REVEL.ENT.LOCUST.id, REVEL.ENT.LOCUST.variant, 0, entity.Position + RandomVector() * math.random() * 30, Vector.Zero, nil)
            locust:GetData().Leader = entity
            locust.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
            data.LocustsLeading[#data.LocustsLeading + 1] = locust
        end
    end
end)

function REVEL.GetClampOffset(pos, margin)
    local clamp = REVEL.room:GetClampedPosition(pos, margin)
    local isDifferent, x, y
    if clamp.X ~= pos.X then
        isDifferent = true
        x = clamp.X
    end

    if clamp.Y ~= pos.Y then
        isDifferent = true
        y = clamp.Y
    end

    if isDifferent then
        return clamp, x, y
    end
end

local locustTimeBetweenHits = 5
local locustTimeBetweenBlood = 3
local locustSlowdownWhileEatingEnemy = 0.8
local locustDamage = 2
local locustRadiusSquared = 34 * 34
local locusthighpitch = false
local locustImmune = {
    EntityType.ENTITY_BONY,
    EntityType.ENTITY_FIREPLACE,
    REVEL.ENT.LOCUST.id,
    REVEL.ENT.RAG_BONY.id,
    REVEL.ENT.WRETCHER.id
}

local locustEdiblePickups = {
    PickupVariant.PICKUP_BOMB,
    PickupVariant.PICKUP_HEART,
    PickupVariant.PICKUP_PILL,
    PickupVariant.PICKUP_KEY,
    PickupVariant.PICKUP_COIN,
    PickupVariant.PICKUP_GRAB_BAG,
    PickupVariant.PICKUP_LIL_BATTERY,
    PickupVariant.PICKUP_TAROTCARD
}

local chests = {
    PickupVariant.PICKUP_BOMBCHEST,
    PickupVariant.PICKUP_ETERNALCHEST,
    PickupVariant.PICKUP_LOCKEDCHEST,
    PickupVariant.PICKUP_MIMICCHEST,
    PickupVariant.PICKUP_SPIKEDCHEST,
    PickupVariant.PICKUP_REDCHEST,
    PickupVariant.PICKUP_CHEST
}

local locustCanConvert = {
    EntityType.ENTITY_GAPER,
    EntityType.ENTITY_FATTY,
    REVEL.ENT.RAG_GAPER.id,
    REVEL.ENT.ARROWHEAD.id,
    REVEL.ENT.RAG_TAG.id,
    REVEL.ENT.PYRAMID_HEAD.id,
    REVEL.ENT.NECRAGMANCER.id,
    REVEL.ENT.RAG_FATTY.id,
    REVEL.ENT.PEASHY.id
}

local boneParams = ProjectileParams()
boneParams.Variant = ProjectileVariant.PROJECTILE_BONE

local normalParams = ProjectileParams()

revel:AddCallback(ModCallbacks.MC_POST_RENDER, function(_, npc)
    local locusts = Isaac.FindByType(REVEL.ENT.LOCUST.id, REVEL.ENT.LOCUST.variant, -1, false, false)
    local eatingEnemy
    local dashinglocust
    for _, locust in ipairs(locusts) do
        if locust:GetData().IsEatingEnemy then
            eatingEnemy = true
        end
        if locust:GetData().Dashing then
            dashinglocust = true
        end
    end

    if eatingEnemy then
        if not REVEL.sfx:IsPlaying(REVEL.SFX.LOCUST_EAT) then
            REVEL.sfx:Play(REVEL.SFX.LOCUST_EAT, 1, 0, false, 1)
        end
    elseif REVEL.sfx:IsPlaying(REVEL.SFX.LOCUST_EAT) then
        REVEL.sfx:Stop(REVEL.SFX.LOCUST_EAT)
    end

    if dashinglocust then
        if not locusthighpitch and REVEL.sfx:IsPlaying(REVEL.SFX.LOCUST_SWARM) then
            locusthighpitch = true
            REVEL.sfx:Play(REVEL.SFX.LOCUST_SWARM, 0.3, 0, true, 1.2)
        end
    else
        if locusthighpitch and REVEL.sfx:IsPlaying(REVEL.SFX.LOCUST_SWARM) then
            locusthighpitch = false
            REVEL.sfx:Play(REVEL.SFX.LOCUST_SWARM, 0.2, 0, true, 1)
        end
    end

    if #locusts == 0 and REVEL.sfx:IsPlaying(REVEL.SFX.LOCUST_SWARM) then
        REVEL.sfx:Stop(REVEL.SFX.LOCUST_SWARM)
    end
end)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.LOCUST.variant then
        return
    end

    local data, sprite = npc:GetData(), npc:GetSprite()
    if not data.Init then
        data.Init = true
        REVEL.sfx:Play(REVEL.SFX.LOCUST_SWARM, 0.2, 0, true, 1)
    end

    if data.Dashing then
        if sprite:IsFinished("DashStart") then
            sprite:Play("Dash", true)
        end

        local isDashing = (sprite:IsPlaying("Dash") or sprite:WasEventTriggered("Dash")) or (sprite:IsPlaying("DashEnd") and not sprite:WasEventTriggered("DashEnd"))

        if isDashing and not data.Scattered then
            data.IsDashing = true
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
            REVEL.MoveAt(npc, data.DashTarget.Position, 0.8, 0.95)
            if sprite:IsPlaying("Dash") and npc.Velocity:DistanceSquared(data.DashDirection) > npc.Velocity:DistanceSquared(data.DashDirection:Rotated(90)) then
                sprite:Play("DashEnd", true)
            end

            local clamp, x, y = REVEL.GetClampOffset(npc.Position + npc.Velocity * 2, 0)
            if clamp then
                data.Scattered = true
                if x then
                    npc.Velocity = Vector(-npc.Velocity.X, npc.Velocity.Y)
                end

                if y then
                    npc.Velocity = Vector(npc.Velocity.X, -npc.Velocity.Y)
                end

                npc.Velocity = npc.Velocity:Resized(10)
                sprite:Play("DashEnd", true)
            end
        else
            data.IsDashing = nil
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
            if data.Scattered then
                npc.Velocity = npc.Velocity * 0.9
            else
                npc.Velocity = npc.Velocity * 0.75
            end
        end

        if sprite:IsFinished("DashEnd") then
            data.LastEndPosition = REVEL.room:GetClampedPosition(npc.Position, 32)
            data.Dashing = nil
            data.IsDashing = nil
        end

        npc.Mass = 100
    else
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
        data.Scattered = nil
        data.IsDashing = nil
        if data.DashStartDelay then
            data.DashStartDelay = data.DashStartDelay - 1
            if data.DashStartDelay <= 0 then
                sprite:Play("DashStart", true)
                data.Dashing = true
                data.DashStartDelay = nil
            end
        end

        npc.Mass = 3
    end

    if data.LocustsLeading then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
        local locusts =  {npc}
        for i, locust in ripairs(data.LocustsLeading) do
            if not locust:Exists() or locust:IsDead() or locust:HasEntityFlags(EntityFlag.FLAG_ICE_FROZEN) then
                table.remove(data.LocustsLeading, i)
            else
                locust.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
                local lsprite = locust:GetSprite()
                if not locust:GetData().Dashing then
                    REVEL.MoveRandomly(locust, 30, 4, 8, 0.6, 0.9, npc.Position)
                    if not lsprite:IsPlaying("Angry") then
                        lsprite:Play("Angry", true)
                    end
                end

                lsprite.FlipX = locust.Velocity.X < 0
                locusts[#locusts + 1] = locust
            end
        end

        data.IsEatingEnemy = nil
        for _, ent in ipairs(REVEL.roomEnemies) do
            local edata = ent:GetData()
            if not REVEL.includes(locustImmune, ent.Type) and (ent:IsVulnerableEnemy() or ent.Type == EntityType.ENTITY_RAG_MEGA) then
                local nearLocusts = {}
                for _, locust in ipairs(locusts) do
                    if locust:GetData().IsDashing and locust.Position:DistanceSquared(ent.Position) < locustRadiusSquared then
                        nearLocusts[#nearLocusts + 1] = locust
                        locust.Velocity = locust.Velocity * locustSlowdownWhileEatingEnemy
                    end
                end

                if #nearLocusts >= 3 then
                    data.IsEatingEnemy = true
                    if ent.Type == REVEL.ENT.ANTLION.id and ent.Variant == REVEL.ENT.ANTLION.variant and ent:GetData().Burrowed and not ent:IsDead() then
                        for _, locust in ipairs(nearLocusts) do
                            locust:Kill()
                        end

                        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.LARGE_BLOOD_EXPLOSION, 0, ent.Position, Vector.Zero, ent)

                        for i = 1, math.random(5, 8) do
                            local params = normalParams
                            local boneOdds = math.random(1, 3)
                            if boneOdds == 1 then
                                params = boneParams
                            end

                            ent:ToNPC():FireBossProjectiles(1, Vector.Zero, 20, params)
                        end

                        ent:Kill()
                    end

                    if not edata.BloodFrame or edata.BloodFrame < ent.FrameCount then
                        edata.BloodFrame = ent.FrameCount + locustTimeBetweenBlood
                        ent:BloodExplode()
                        REVEL.sfx:Stop(SoundEffect.SOUND_DEATH_BURST_SMALL)
                    end

                    if not edata.LocustHit or edata.LocustHit + 60 < ent.FrameCount then
                        REVEL.sfx:NpcPlay(npc, REVEL.SFX.LOCUST_BITE, 0.8, 0, false, 1)
                    end

                    if (not edata.LocustHit or edata.LocustHit < ent.FrameCount) then
                        edata.LocustHit = ent.FrameCount + locustTimeBetweenHits
                        for i = 1, math.random(2, 3) do
                            local params = normalParams
                            local boneOdds = (1 - (ent.HitPoints / ent.MaxHitPoints)) + math.random()
                            if boneOdds > 1.2 then
                                params = boneParams
                            end

                            if npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) or npc:HasEntityFlags(EntityFlag.FLAG_CHARM) then
                                params.BulletFlags = params.BulletFlags | ProjectileFlags.CANT_HIT_PLAYER | ProjectileFlags.HIT_ENEMIES
                            else
                                params.BulletFlags = 0
                            end

                            ent:ToNPC():FireBossProjectiles(1, Vector.Zero, 20, params)
                        end

                        if ent.HitPoints - locustDamage * 2 < 0 and REVEL.includes(locustCanConvert, ent.Type) then
                            local bony = Isaac.Spawn(EntityType.ENTITY_BONY, 0, 0, ent.Position, ent.Velocity, ent)
                            bony:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.LARGE_BLOOD_EXPLOSION, 0, ent.Position, Vector.Zero, ent)
                            ent:Remove()
                        else
                            if ent.Type == EntityType.ENTITY_RAG_MEGA then
                                if not ent:IsVulnerableEnemy() then
                                    ent.HitPoints = ent.HitPoints - 60
                                else
                                    ent:TakeDamage(60, 0, EntityRef(npc), 0)
                                end
                            else
                                ent:TakeDamage(locustDamage, 0, EntityRef(npc), 0)
                            end
                        end

                        if npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) or npc:HasEntityFlags(EntityFlag.FLAG_CHARM) then
                            for _, locust in ipairs(nearLocusts) do
                                locust.HitPoints = locust.HitPoints - 1
                                if locust.HitPoints <= 0 then
                                    locust:Die()
                                end
                            end
                        end
                    end
                end
            end
        end

        for _, ent in ipairs(REVEL.roomBombdrops) do
            for _, locust in ipairs(locusts) do
                if locust.Position:DistanceSquared(ent.Position) < locustRadiusSquared then
                    ent:SetExplosionCountdown(0)
                end
            end
        end

        for _, ent in ipairs(REVEL.roomPickups) do
            local isEdible = REVEL.includes(locustEdiblePickups, ent.Variant)
            local isChest
            if not isEdible then
                isChest = REVEL.includes(chests, ent.Variant)
                isEdible = isChest
            end

            if isEdible and ent.FrameCount > 15 then
                local shouldDie
                for _, locust in ipairs(locusts) do
                    if locust:GetData().IsDashing and locust.Position:DistanceSquared(ent.Position) < locustRadiusSquared then
                        shouldDie = true
                        if ent.Variant == PickupVariant.PICKUP_HEART then
                            locust.HitPoints = locust.MaxHitPoints
                        elseif ent.Variant == PickupVariant.PICKUP_SPIKEDCHEST or ent.Variant == PickupVariant.PICKUP_MIMICCHEST then
                            locust:TakeDamage(5, 0, EntityRef(ent), 0)
                        end
                    end
                end

                if shouldDie then
                    if isChest then
                        ent:TryOpenChest()
                    else
                        if ent.Variant == PickupVariant.PICKUP_BOMB then
                            Isaac.Explode(ent.Position, ent, 40)
                        elseif ent.Variant == PickupVariant.PICKUP_HEART then
                            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 0, ent.Position, Vector.Zero, nil)
                        elseif ent.Variant == PickupVariant.PICKUP_PILL then
                            REVEL.game:Fart(ent.Position, 64, ent, 1, 0)
                        end

                        ent:Remove()
                    end
                end
            end
        end

        for _, locust in ipairs(locusts) do
            if locust:GetData().IsDashing then
                local grid = REVEL.room:GetGridEntityFromPos(locust.Position)
                if grid then
                    local gtype = grid.Desc.Type
                    if gtype == GridEntityType.GRID_POOP or gtype == GridEntityType.GRID_TNT then
                        grid:Hurt(999)
                    elseif gtype == GridEntityType.GRID_ROCK_ALT and not REVEL.IsGridBroken(grid) then
                        REVEL.LocustDestroyedGrids[REVEL.room:GetGridIndex(locust.Position)] = true
                        grid:Destroy()
                    end
                end
            end
        end

        if not data.LastEndPosition then
            data.LastEndPosition = npc.Position
        end

        if not data.Dashing then
            if not sprite:IsPlaying("Angry") then
                sprite:Play("Angry", true)
            end

            REVEL.MoveRandomly(npc, 90, 3, 6, 0.3, 0.95, data.LastEndPosition)

            if not data.DashTimer then
                data.DashTimer = math.random(30, 90)
            else
                data.DashTimer = data.DashTimer - 1
            end

            if data.DashTimer <= 0 then
                data.DashTimer = nil
                data.Scattered = nil
                data.Dashing = true
                local ragmega = Isaac.FindByType(EntityType.ENTITY_RAG_MEGA, -1, -1, false, false)
                data.DashTarget = ragmega[1] or npc:GetPlayerTarget()
                data.DashDirection = data.DashTarget.Position - npc.Position
                local stagger = math.random(0, 3)
                for i, locust in ipairs(data.LocustsLeading) do
                    local ldata = locust:GetData()
                    ldata.DashStartDelay = stagger
                    ldata.DashDirection = data.DashDirection
                    ldata.DashTarget = data.DashTarget
                    stagger = stagger + math.random(0, 3)
                end

                sprite:Play("DashStart", true)
            end
        end

        sprite.FlipX = npc.Velocity.X < 0

        if #data.LocustsLeading < 2 then
            data.LocustsLeading = nil
        end
    else
        if not data.Leader then
            local isFriendly = npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
            local locusts = Isaac.FindByType(REVEL.ENT.LOCUST.id, REVEL.ENT.LOCUST.variant, -1, false, false)
            local validLeaders = {}
            local lackingLeader = {}
            for _, locust in ipairs(locusts) do
                if not isFriendly or locust:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                    local ldata = locust:GetData()
                    if ldata.LocustsLeading then
                        if #ldata.LocustsLeading < 4 then
                            validLeaders[#validLeaders + 1] = locust
                        end
                    elseif not ldata.Leader and GetPtrHash(locust) ~= GetPtrHash(npc) then
                        lackingLeader[#lackingLeader + 1] = locust
                    end
                end
            end

            if #validLeaders > 0 then
                local closest, closestDist
                for _, locust in ipairs(validLeaders) do
                    local dist = locust.Position:DistanceSquared(npc.Position)
                    if not closestDist or dist < closestDist then
                        closest = locust
                        closestDist = dist
                    end
                end

                data.Leader = closest
                local ldata = closest:GetData()
                ldata.LocustsLeading[#ldata.LocustsLeading + 1] = npc
            elseif #lackingLeader > 1 then
                data.LocustsLeading = {}
            end

            if not data.Leader and not data.LocustsLeading and not data.Dashing then
                if not REVEL.IsUsingPathMap(REVEL.GenericFlyingChaserPathMap, npc) then
                    REVEL.UsePathMap(REVEL.GenericFlyingChaserPathMap, npc)
                end
                data.UsePlayerFlyingMap = true
                
                if not sprite:IsPlaying("Fly") then
                    sprite:Play("Fly", true)
                end

                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                local target = npc:GetPlayerTarget()

                sprite.FlipX = target.Position.X < npc.Position.X

                if data.Path then
                    REVEL.FollowPath(npc, 0.55, data.Path, true, 0.95, false, true)
                end
            else
                data.UsePlayerFlyingMap = nil
            end
        else
            data.UsePlayerFlyingMap = nil
            if not data.Leader:Exists() or data.Leader:IsDead() or data.Leader:HasEntityFlags(EntityFlag.FLAG_ICE_FROZEN) or not data.Leader:GetData().LocustsLeading or (npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and not data.Leader:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)) then
                data.Leader = nil
            end
        end
    end
end, REVEL.ENT.LOCUST.id)

end