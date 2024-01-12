return function()

--Harfang

local harfangBal = {
    wakeUpTimer = 10,
    wakeUpRandom = 75,
    wakeUpChance = 60, --Not a percentage chance
    wakeUpMax = 120,
    wakeUpDistance = 100,
    attackChance = 40,
    flapSpeed = 17,
}

local SnowParticle = REVEL.ParticleType.FromTable{
    Name = "Harfang Flap",
    Anm2 =  "gfx/effects/revelcommon/white_particle.anm2",
    BaseLife = 15,
    Variants = 6,
    FadeOutStart = 0.3,
    StartScale = 0.9,
    EndScale = 1.1,
    RotationSpeedMult = 0.2
}
local SnowParticleUp = REVEL.ParticleType.FromTable{
    Name = "Harfang Attack",
    Anm2 =  "gfx/effects/revelcommon/white_particle.anm2",
    BaseLife = 30,
    Variants = 6,
    FadeOutStart = 0.3,
    StartScale = 2,
    EndScale = 1,
    RotationSpeedMult = 0.2
}

local PARTICLE_EMITTER_ID = "Harfang Particle Emitter"

local function harfangFindLandSpot(npc, target, avoid)
    local room = REVEL.room
    local size = room:GetGridSize()
    local realSpots = {}
    local avoidSpots = {}
    local avoidSpot
    if avoid then
        local pos = npc.Position+(room:GetCenterPos()-npc.Position)*2
        if npc.Position:Distance(pos) > 300 then
            pos = npc.Position+(pos-npc.Position):Resized(300)
        end
        if not room:IsPositionInRoom(pos, 0) then
            avoid = nil
        else
            avoidSpot = pos
        end
    end

    for i=0,size do
        local pos = room:GetGridPosition(i)
        if room:GetGridCollision(i) == GridCollisionClass.COLLISION_NONE and room:IsPositionInRoom(pos, 0) then
            if pos:Distance(target.Position) > 90 and pos:Distance(npc.Position) > 100 and pos:Distance(npc.Position) < 600 then
                table.insert(realSpots, pos)
                if avoid and npc.Position:Distance(pos) > npc.Position:Distance(avoidSpot) then
                    table.insert(avoidSpots, pos)
                end
            end
        end
    end
    if avoid and #avoidSpots > 0 then
        return avoidSpots
    elseif #realSpots > 0 then
        return realSpots
    else
        return {Isaac.GetFreeNearPosition(Isaac.GetRandomPosition(), 40)}
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.HARFANG.variant then return end

    local data = npc:GetData()
    local sprite = npc:GetSprite()
    local target = npc:GetPlayerTarget()
    local rng = npc:GetDropRNG()

    if not data.init then
        data.state = "Idle"

        if not REVEL.HasEntityParticleEmitter(npc, PARTICLE_EMITTER_ID) then
            REVEL.AddEntityParticleEmitter(npc, REVEL.Emitter(), PARTICLE_EMITTER_ID)
        end
        npc.SplatColor = REVEL.WaterSplatColor
        data.init = true
    else
        npc.StateFrame = npc.StateFrame+1
    end
    local particleEmitter = REVEL.GetEntityParticleEmitter(npc, PARTICLE_EMITTER_ID)
    
    if data.state == "Idle" then
        --npc.Velocity = REVEL.Lerp(npc.Velocity, Vector.Zero, 0.5)
        local wakeUp = nil
        if npc.Position:Distance(target.Position) < harfangBal.wakeUpDistance then
            wakeUp = true
            data.avoid = true
        elseif npc.StateFrame > harfangBal.wakeUpRandom and rng:RandomInt(harfangBal.wakeUpChance) == 0 then
            wakeUp = true
        elseif npc.StateFrame > harfangBal.wakeUpMax then
            wakeUp = true
        end

        if wakeUp then
            data.state = "FlyUp"
        end

        if not sprite:IsPlaying("Idle") then
            sprite:Play("Idle", true)
        end

        npc.Velocity = Vector.Zero
    elseif data.state == "Flying" then
        if sprite:IsEventTriggered("Flap") then
            npc:PlaySound(SoundEffect.SOUND_ANGEL_WING, 1, 0, false, math.random(95,110)/100)
            data.flapSpeed = harfangBal.flapSpeed
            if data.avoid then
                data.flapSpeed = data.flapSpeed+5.5
            end

            for i=1,10 do
                particleEmitter:EmitParticlesNum(SnowParticle, REVEL.FireSystem, Vec3(npc.Position.X + math.random(-60,60), npc.Position.Y, -100), -Vec3(npc.Velocity.X, npc.Velocity.Y, -8), 1, 0.5, 60)
            end
            --particleEmitter:EmitParticlesNum(SnowParticle, REVEL.FireSystem, Vec3(npc.Position.X + math.random(-60,60), npc.Position.Y, -100), -Vec3(npc.Velocity.X, npc.Velocity.Y, -8), 10, 0.5, 60)
        else
            if not sprite:IsPlaying("Fly_Loop") then
                sprite:Play("Fly_Loop", true)
            end
        end

        if data.flapSpeed > 0 then
            data.flapSpeed = data.flapSpeed*0.82
        end

        local dist = npc.Position:Distance(data.dest)
        if not data.attacked and data.attacking and dist < data.distance*0.5 and sprite:GetFrame() == 18 then
            data.state = "AttackPrep"
        end

        if dist > 20 then
            npc.Velocity = REVEL.Lerp(npc.Velocity, (data.dest-npc.Position):Resized(data.flapSpeed), 0.2)
        elseif dist > 5 then
            npc.Velocity = REVEL.Lerp(npc.Velocity, (data.dest-npc.Position):Resized(3), 0.2)
        elseif sprite:GetFrame() == 18 then
            data.state = "FlyDown"
        else
            npc.Velocity = data.dest-npc.Position
        end
    elseif data.state == "AttackPrep" then
        if sprite:IsFinished("Attack_Start") then
            data.state = "Attacking"

            local angleToAnim = {"Bottom_Left", "Down", "Bottom_Left", "Up_Left", "Up", "Up_Left"}
            local angle = (target.Position-npc.Position):GetAngleDegrees()
            if angle <= 0 then
                angle = angle+360
            end
            data.anim = "Attack_" .. angleToAnim[math.ceil(angle/60)]
            if angle > 90 and angle < 270 then
                sprite.FlipX = false
            else
                sprite.FlipX = true
            end
        elseif sprite:GetFrame() > 40 and data.icing then
            npc:PlaySound(SoundEffect.SOUND_FREEZE, 1, 0, false, 2)
            data.icing = false
        elseif sprite:IsEventTriggered("Flap") then
            npc:PlaySound(SoundEffect.SOUND_ANGEL_WING, 1, 0, false, math.random(95,110)/100)
            for i=1,10 do
                particleEmitter:EmitParticlesNum(SnowParticle, REVEL.FireSystem, Vec3(npc.Position.X + math.random(-60,60), npc.Position.Y, -100), -Vec3(npc.Velocity.X, npc.Velocity.Y, -8), 1, 0.5, 60)
            end
        elseif sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.OWL_OUT, 1, 0, false, 0.9+(math.random()*0.2))
            data.icing = true
        else
            if not sprite:IsPlaying("Attack_Start") then
                sprite:Play("Attack_Start", true)
            end
        end

        if data.icing then
            particleEmitter:EmitParticlesPerSec(SnowParticleUp, REVEL.ParticleSystems.NoGravity, Vec3(npc.Position.X + math.random(-70,70), npc.Position.Y, 0), Vec3(0, 0, -8), 20, 0.5, 60, npc, 0, nil, 0.5)
        end

        npc.Velocity = REVEL.Lerp(npc.Velocity, Vector.Zero, 0.3)
    elseif data.state == "Attacking" then
        if sprite:IsFinished(data.anim) then
            if REVEL.room:GetGridCollisionAtPos(npc.Position) == GridCollisionClass.COLLISION_NONE then
                data.state = "FlyDown"
            else
                data.state = "Flying"
                data.dest = Isaac.GetFreeNearPosition(npc.Position, 20)
                data.flapSpeed = 0
                data.attacked = true
            end
        elseif sprite:IsEventTriggered("Shoot") then
            npc:PlaySound(SoundEffect.SOUND_FREEZE_SHATTER, 1, 0, false, 1)
            local dir = (target.Position-npc.Position)
            for i=1,8 do
                local proj = REVEL.SpawnNPCProjectile(npc, dir:Resized(rng:RandomInt(3)+1.5):Rotated(rng:RandomInt(70)-35), npc.Position+dir:Resized(40), 4, 0)
                proj:GetSprite():Load("gfx/effects/revel1/projectile_icicle.anm2", true)
                proj:GetSprite():Play("Idle", true)
                proj:AddProjectileFlags(ProjectileFlags.ACCELERATE | ProjectileFlags.NO_WALL_COLLIDE)
                proj.Acceleration = 1
                proj.FallingSpeed = 12
                proj.FallingAccel = -0.1
                proj.Height = -140
                proj.Scale = (rng:RandomInt(30)+80)/100
                proj:GetData().projType = "Harfang"
                proj:GetData().harfangTimer = rng:RandomInt(20)
                proj:Update()
            end
            local poof = Isaac.Spawn(1000, 16, 5, npc.Position+dir:Resized(40), Vector.Zero, npc):ToEffect()
            poof.SpriteScale = Vector(0.5, 0.5)
            poof.SpriteOffset = Vector(0, -60)
            local color = Color(0.5,0.8,1,0.7,0.52,0.6,0.85)
            color:SetColorize(1,1,1,1)
            poof.Color = color
        else
            if not sprite:IsPlaying(data.anim) then
                sprite:Play(data.anim, true)
            end
        end

        npc.Velocity = REVEL.Lerp(npc.Velocity, Vector.Zero, 0.3)
    elseif data.state == "FlyUp" then
        if sprite:IsFinished("Fly_Start") then
            data.state = "Flying"
            if rng:RandomInt(100) > harfangBal.attackChance or data.guaranteeAttack then
                data.attacking = true
            else
                data.attacking = false
            end
            data.attacked = nil
            local tab = harfangFindLandSpot(npc, target, data.avoid)
            data.dest = tab[rng:RandomInt(#tab)+1]
            data.distance = npc.Position:Distance(data.dest)
            data.flapSpeed = 0
        elseif sprite:IsEventTriggered("Fly") then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.OWL_UP, 1, 0, false, 0.9+(math.random()*0.2))
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        else
            if not sprite:IsPlaying("Fly_Start") then
                sprite:Play("Fly_Start", true)
            end
        end

        npc.Velocity = Vector.Zero
    elseif data.state == "FlyDown" then
        if sprite:IsFinished("Fly_End") then
            data.state = "Idle"
            npc.StateFrame = 0
            data.avoid = nil
            if data.attacking then
                data.attacking = nil
                data.guaranteeAttack = nil
            else
                data.guaranteeAttack = true
            end
        elseif sprite:IsEventTriggered("Land") then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
            npc:PlaySound(SoundEffect.SOUND_SCAMPER, 1, 0, false, 1)
        else
            if not sprite:IsPlaying("Fly_End") then
                sprite:Play("Fly_End", true)
            end
        end

        npc.Velocity = Vector.Zero
    end
end, REVEL.ENT.HARFANG.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, npc)
    if npc.Variant == REVEL.ENT.HARFANG.variant then
        local npc = npc:ToNPC()
        local data = npc:GetData()
        if data.state == "Idle" then
            npc.StateFrame = npc.StateFrame+harfangBal.wakeUpTimer
        end
    end
end, REVEL.ENT.HARFANG.id)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, v)
    if v.SpawnerType == REVEL.ENT.HARFANG.id and v.SpawnerVariant == REVEL.ENT.HARFANG.variant then
        local d = v:GetData()
        if d.projType == "Harfang" then
            local s = v:GetSprite()
            if (v.FallingSpeed < 0.05 or v.Height > -20) and not d.stopped then
                v.FallingAccel = -0.05
                v.FallingSpeed = 0
                d.stopped = true
            elseif d.stopped then
                v.FallingAccel = -0.05
                v.FallingSpeed = 0
            end
            if v.Acceleration < 1.1 and v.FrameCount > d.harfangTimer then
                v.Acceleration = v.Acceleration+0.005
            end
            if v.Velocity:Length() > 20 then
                v:ClearProjectileFlags(ProjectileFlags.ACCELERATE)
            end
            s.Rotation = v.Velocity:GetAngleDegrees()

            if REVEL.room:GetGridCollisionAtPos(v.Position) == GridCollisionClass.COLLISION_WALL then
                REVEL.sfx:Play(SoundEffect.SOUND_FREEZE_SHATTER, 0.25, 0, false, math.random(130,160)/100)
                for i=1,2 do
                    --[[local tooth = Isaac.Spawn(1000, 35, 0, v.Position, RandomVector()*2, v):ToEffect()
                    tooth.Color = Color(1, 1, 1, 1, 0.4, 0.4, 0.6)]]
                    REVEL.SpawnIceRockGib(v.Position, RandomVector():Resized(math.random(1, 5)), v)
                end
                v:Remove()
            end
        end
    end
end)

end