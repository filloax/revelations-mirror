local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local KnifeSubtype = require "lua.revelcommon.enums.KnifeSubtype"
local KnifeVariant = require "lua.revelcommon.enums.KnifeVariant"
return function()

-- Hockey Puck
local PushSpeed = 15
local InitialFrictionTime = 3
local InitialGroundedFriction = 0.8
local GroundedFriction = 0.67
local FrictionCooldown = 1
local ExplosionMaxSpeed = 19
local PushCooldownTime = 3
local ExplosionCooldownTime = 45
local PuckDamage = 13
local HurtPlayers = false
local TearsPush = false

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
    local data = player:GetData()

    local mov = player:GetMovementVector()
    local len = mov:Length()

    if len > 0.1 then
        data.LastMovement = mov / len
    end
end)

function REVEL.PushPushableEnt(npc, data, vel)
    npc.Velocity = vel
    data.PushableData.FrictionTimer = FrictionCooldown
    data.PushableData.Cooldown = PushCooldownTime
    data.PushableData.Pushed = true
    data.PushableData.PushFrames = 0
end

-- Entities to match in findinradius, 
-- as the tear partition returns tears, knives, etc
local RadiusPushers = {
    EntityType.ENTITY_PLAYER,
    {EntityType.ENTITY_KNIFE, -1, KnifeSubtype.SWING},
}

function REVEL.UpdatePushableEnt(npc, data)
    local d = data
    data = data.PushableData
    data.Cooldown = data.Cooldown or 0
    data.FrictionTimer = data.FrictionTimer or 0
    data.Pushers = data.Pushers or {}

    if data.FrictionTimer > 0 then
        data.FrictionTimer = data.FrictionTimer - 1
    end

    if data.Cooldown > 0 then
        data.Cooldown = data.Cooldown - 1
        return
    end

    -- this doesn't actually find effects so we need a redundant check
    -- tear isn't used for actual tears as that is handled by collision check, 
    -- but it also returns knives
    local pushers = Isaac.FindInRadius(npc.Position, 80, BitOr(EntityPartition.PLAYER, EntityPartition.TEAR))
    for _, ent in ipairs(pushers) do
        local goodPusher = false
        for _, toMatch in ipairs(RadiusPushers) do
            if type(toMatch) == "number"
            and ent.Type == toMatch 
            then
                goodPusher = true
                break
            elseif type(toMatch) == "table"
            and ent.Type == toMatch[1]
            and (toMatch[2] < 0 or ent.Variant == toMatch[2])
            and (toMatch[3] < 0 or ent.SubType == toMatch[3])
            then
                goodPusher = true
                break
            end
        end

        if goodPusher then
            local position, size = ent.Position, ent.Size

            if ent.Type == EntityType.ENTITY_KNIFE 
            and ent.SubType == KnifeSubtype.SWING 
            then
                local knife = ent:ToKnife()
                local parent = knife.Parent
                if parent:ToPlayer() then
                    -- find the center of the swing object
                    position = knife.Position
                    local scale = 30
                    if knife.Variant == KnifeVariant.BONE_SCYTHE then
                        scale = 42
                    end
                    scale = scale * knife.SpriteScale.X
                    local offset = Vector(scale, 0)
                    offset = offset:Rotated(knife.Rotation)
                    position = position + offset

                    size = scale
                else
                    goodPusher = false
                end
            end

            if goodPusher and position:DistanceSquared(npc.Position) < (size + npc.Size) ^ 2 then
                local vel = nil
                if ent.Type == EntityType.ENTITY_PLAYER then
                    local mov = ent:GetData().LastMovement
                    local bet = (npc.Position - ent.Position):Normalized()

                    -- If the player's direction of movement generally aligns with the offset from the ent,
                    -- use their direction when pushing. Else, just send it in the standard collision direction
                    if mov:Dot(bet) > 0.7 then -- cos 45 = ~0.7
                        vel = mov
                    else
                        vel = bet
                    end

                    --REVEL.DebugLog(mov, bet, mov:Dot(bet), vel)
                    vel = vel:Resized(data.PlayerPushSpeed)
                elseif ent.Type == EntityType.ENTITY_KNIFE 
                and ent.SubType == KnifeSubtype.SWING 
                then
                    vel = (position - ent.Parent.Position):Resized(data.PlayerPushSpeed)
                end

                if vel then
                    REVEL.HockeyImpactEffect(npc)
                    REVEL.PushPushableEnt(npc, d, vel)
                    d.Speed = vel:Length()
                    return vel
                end
            end
        end
    end

    -- FindInRadius has gaps... for some reason
    for _, pushEnt in ipairs(data.ExtraPushers) do
        local pushers = Isaac.FindByType(pushEnt.id, pushEnt.variant or -1, pushEnt.subtype or -1, false, false)
        for _, ent in ipairs(pushers) do
            if GetPtrHash(ent) ~= GetPtrHash(npc) and ent.Position:DistanceSquared(npc.Position) <= (npc.Size + pushEnt.sizeOverride or ent.Size) ^ 2 then
                local vel = data.CollisionCheck(npc, ent, d)

                if vel then
                    REVEL.PushPushableEnt(npc, d, vel)
                    d.Speed = vel:Length()
                    return vel
                end
            end
        end
    end
end

revel:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, function(_, npc, ent)
    local data = npc:GetData()
    if not data.PushableData then return end

    local vel, cancelCollision = data.PushableData.CollisionCheck(npc, ent, data)

    if vel then
        REVEL.PushPushableEnt(npc, data, vel)
        data.Speed = vel:Length()
    end

    return cancelCollision
end)

function REVEL.hockeyCollisionCheck(npc, ent, data)
    if ent.Type == EntityType.ENTITY_EFFECT and ent.Variant == EffectVariant.BOMB_EXPLOSION then
        data.ExplodeCooldown = ExplosionCooldownTime
        REVEL.HockeyImpactEffect(npc, false, true)
        return (npc.Position - ent.Position):Resized(ExplosionMaxSpeed)
    elseif TearsPush and ent:ToTear() then
        ent:Die()
        REVEL.HockeyImpactEffect(npc, false, true)
        return (npc.Position - ent.Position):Resized(PushSpeed * 0.25)
    else
        local speed = npc.Velocity:Length()
        if speed > PushSpeed * 0.3 then
            local angle = npc.Velocity:GetAngleDegrees()
            local puck_to_ent_angle = (ent.Position-npc.Position):GetAngleDegrees()
            if REVEL.ENT.ICE_HAZARD_GAPER.id == ent.Type or REVEL.ENT.FROZEN_SPIDER:isEnt(ent) then
                ent.Velocity = npc.Velocity
                REVEL.HockeyImpactEffect(npc, false, true)
                return npc.Velocity:Rotated(math.random(-85, 85))
            elseif REVEL.ENT.HOCKEY_PUCK:isEnt(ent) then
                local otherData = ent:GetData()
                if otherData.PushableData.Cooldown <= 0 then
                    REVEL.PushPushableEnt(ent, otherData, npc.Velocity:Resized(data.Speed):Rotated(math.random(-15, 15)))
                    otherData.PushableData.Cooldown = 10
                    otherData.Speed = data.Speed
                    REVEL.HockeyImpactEffect(npc, false, true)
                    return npc.Velocity:Rotated(math.random(-85, 85)), false
                end
            elseif ent.Type == EntityType.ENTITY_FIREPLACE then
                if not ent:IsDead() then
                    if ent.Variant == 0 or ent.Variant == 1 then
                        ent:Die()
                    end
                    REVEL.HockeyImpactEffect(npc, false, true)
                    return npc.Velocity:Rotated(math.random(-85, 85))
                end
            elseif ent:IsVulnerableEnemy() and (math.abs((angle+180)-(puck_to_ent_angle+180)) <= 90 or math.abs((angle+540)-(puck_to_ent_angle+180)) <= 90) then
                ent:TakeDamage(PuckDamage * (data.ExplodeCooldown and 1.5 or 1), 0, EntityRef(npc), 25)
                REVEL.sfx:Play(SoundEffect.SOUND_FETUS_JUMP, 1, 0, false, 0.75 + math.random() * 0.1)
                REVEL.HockeyImpactEffect(npc, false, true)
                return nil, false
            elseif ent.Type == EntityType.ENTITY_MOVABLE_TNT then
                if ent.HitPoints > 0.5 then
                    ent:Die()
                    data.ExplodeCooldown = ExplosionCooldownTime
                    return npc.Velocity:Resized(ExplosionMaxSpeed)
                end
            end
        elseif ent:IsVulnerableEnemy() then
            return nil, false
        end
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if not REVEL.ENT.HOCKEY_PUCK:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), npc:GetData()

    if not data.Init then
        npc:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES

        npc.SpriteScale = Vector(1.4, 1.4)

        data.CurrVel = npc.Velocity
        data.Speed = npc.Velocity:Length()
        data.IceTimer = 0

        data.PushableData = {}
        data.PushableData.PlayerPushSpeed = PushSpeed
        data.PushableData.PushFrames = 0

        data.PushableData.ExtraPushers = {
            { id = EntityType.ENTITY_EFFECT, variant = EffectVariant.BOMB_EXPLOSION, sizeOverride = 144 },
        }

        data.PushableData.CollisionCheck = REVEL.hockeyCollisionCheck

        --npc.Mass = 100

        data.Init = true
    end

    if data.ExplodeCooldown then
        data.ExplodeCooldown = data.ExplodeCooldown - 1
        if data.ExplodeCooldown <= 0 then
            data.ExplodeCooldown = nil
        end
    end

    local pushData = data.PushableData

    if npc:CollidesWithGrid() then
        local grid = REVEL.GetGridCollisionInfo(npc.Position, npc.Velocity, data.CurrVel)

        if grid then
            local oldSpeed = data.CurrVel:Length()

            if oldSpeed > PushSpeed + 0.1 then
                if data.ExplodeCooldown and grid and REVEL.STAGE.Glacier:IsStage() and grid.Desc.Type == GridEntityType.GRID_ROCK_ALT then
                    REVEL.room:DestroyGrid(REVEL.room:GetGridIndex(grid.Position), false)
                end
            end
            if oldSpeed > PushSpeed * 0.3 then
                if grid.Desc.Type == GridEntityType.GRID_TNT and REVEL.CanGridBeDestroyed(grid) then
                    grid:Hurt(999)
                    data.ExplodeCooldown = ExplosionCooldownTime
                    npc.Velocity = npc.Velocity:Resized(ExplosionMaxSpeed)
                end
            end
        end

        npc.Velocity = npc.Velocity:Rotated(math.random(-30, 30))

        if not data.PrevCollidedWithGrid then
            REVEL.HockeyImpactEffect(npc, true)
            data.PrevCollidedWithGrid = true
        end
    else
        data.PrevCollidedWithGrid = nil
    end

    REVEL.UpdatePushableEnt(npc, data)

    local speed = npc.Velocity:Length()

    local grindex = REVEL.room:GetGridIndex(npc.Position + npc.Velocity * ((npc.Size + speed) / speed))
    local grid = REVEL.room:GetGridEntity(grindex)
    data.NextGrid = grid

    if data.ExplodeCooldown and npc.FrameCount % 2 == 0 then
        local fire = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HOT_BOMB_FIRE, 0, npc.Position, Vector.Zero, nil)
        fire:GetData().Scale = 0.5
        fire.SpriteScale = Vector.One * 0.5
        fire:GetData().HockeyFire = true
    end

    pushData.PushFrames = pushData.PushFrames + 1

    if pushData.Pushed and REVEL.Glacier.CheckIce(npc, StageAPI.GetCurrentRoom(), true) then
        npc.Velocity = npc.Velocity:Resized(data.Speed)
    elseif pushData.FrictionTimer <= 0 then
        if pushData.PushFrames >= InitialFrictionTime then
            pushData.Pushed = false
        end

        if speed < 0.1 then
            npc.Velocity = Vector.Zero
            data.ExplodeCooldown = nil
        else
            npc.Velocity = npc.Velocity * (pushData.PushFrames < InitialFrictionTime and InitialGroundedFriction or GroundedFriction)
        end
    end

    if npc.Velocity:LengthSquared() > 0.5 then
        data.CurrVel = npc.Velocity
    end
end, REVEL.ENT.HOCKEY_PUCK.id)

-- local PuckColor = Color(74/255, 72/255, 77/255, 1,conv255ToFloat( 0, 0, 0))

local PuckImpactParticle = REVEL.ParticleType.FromTable{
    Name = "Hockey Particle",
    Anm2 = "gfx/1000.035_tooth particle.anm2",
    AnimPrefix = "Gib0",
    BaseColor = Color(0.2, 0.2, 0.3),
    AnimNum = 8,
    Variants = 15,
    BaseLife = 180,
    FadeOutStart = 0.1,
    RotationSpeedMult = 0,
    StartScale = 0.7,
    EndScale = 0.7,
}

function REVEL.HockeyImpactEffect(npc, gridGibs, entityImpact)
    -- local pos, vel = npc.Position, npc.Velocity * 0.7
    -- REVEL.ParticleBurst(Vec3(pos, -5), Vec3(vel, -3), math.random(2, 4), "gfx/effects/revelcommon/black_particle.anm2", 1, "Particle4", 25, nil, PuckColor, nil, 30)

    if gridGibs then
        for i = 1, 3 do
            PuckImpactParticle:Spawn(REVEL.IceRockSystem, Vec3(npc.Position,-5), Vec3(npc.Velocity * 0.3, -10))
        end
    end

    if entityImpact then
        Isaac.Spawn(1000, EffectVariant.IMPACT, 0, npc.Position, Vector.Zero, npc)
    end

    REVEL.sfx:NpcPlay(npc, REVEL.SFX.HOCKEY_HIT, 0.8, 0, false, 1)
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    if effect:GetData().HockeyFire then
        local scale = REVEL.SmoothLerp2(effect:GetData().Scale, 0, effect.FrameCount, 40, 50)
        effect.SpriteScale = Vector.One * scale
        if scale <= 0 then
            effect:Remove()
        end
    end
end, EffectVariant.HOT_BOMB_FIRE)

end