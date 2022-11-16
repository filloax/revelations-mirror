REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Innard

local tarColor = Color(1, 1, 1, 1)
tarColor:SetColorize(0.7,0.7,0.75,1)
REVEL.TarParticle1 = REVEL.ParticleType.FromTable{
    Name = "Tar Particle Large",
    Anm2 =  "gfx/effects/revelcommon/blood_particle.anm2",
    BaseLife = 60,
    LifeRandom = 0.2,
    Variants = 3,
    FadeOutStart = 0.0,
    StartScale = 0.9,
    EndScale = 0.8,
    RotationSpeedMult = 0.9
}
REVEL.TarParticle1:SetColor(tarColor, 0.05)
REVEL.TarParticle2 = REVEL.ParticleType.FromTable{
    Name = "Tar Particle Small",
    Anm2 =  "gfx/effects/revelcommon/gore_particle_small.anm2",
    BaseLife = 40,
    LifeRandom = 0.2,
    Variants = 3,
    FadeOutStart = 0.0,
    EndScale = 1.1,
    RotationSpeedMult = 0.7
}
REVEL.TarParticle2:SetColor(tarColor, 0.05)
REVEL.TarPartSystem = REVEL.ParticleSystems.Basic
local innardEmitter = REVEL.HalfSphereEmitter(10, REVEL.VEC3_Y)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.INNARD.variant then
        return
    end

    local sprite, data = npc:GetSprite(), npc:GetData()

    if data.FramesUntilDeath then
        if data.FramesUntilDeath == 0 then
            npc:TakeDamage(npc.HitPoints, 0, EntityRef(npc), 0)
        else
            data.FramesUntilDeath = data.FramesUntilDeath-1
        end
    end

    if sprite:IsFinished("Death") then
        npc:Remove()
        return
    elseif not sprite:IsPlaying("Death") then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        if data.KillTimer then
            data.KillTimer = data.KillTimer - 1
            sprite:Play("Death", true)
            if data.KillTimer <= 0 then
                npc:Remove()
                return
            end
        end
    end

    if not (sprite:IsPlaying("Death") or sprite:IsFinished("Death")) then
        if not sprite:IsPlaying("Move") then
            sprite:Play("Move", true)
        end

        if npc.FrameCount % 10 == 0 then
            local creep = REVEL.SpawnCreep(EffectVariant.CREEP_BLACK, 0, npc.Position, npc, false)
            creep:ToEffect():SetTimeout(60)
        end

        if sprite:WasEventTriggered("Move") and not sprite:WasEventTriggered("Stop") then
            REVEL.MoveRandomly(npc, 180, 4, 8, 0.15, 0.8, npc.Position)
        else
            npc.Velocity = npc.Velocity * 0.8
        end
    else
        npc.Velocity = Vector.Zero
        if sprite:IsEventTriggered("Spawn") then
            local creep = REVEL.SpawnCreep(EffectVariant.CREEP_BLACK, 0, npc.Position, npc, false)
            REVEL.UpdateCreepSize(creep, creep.Size * 4, true)
            creep:ToEffect():SetTimeout(300)
            for i = 1, REVEL.game:GetFrameCount() % 22 do
                creep:GetSprite():Update()
            end

            for i = 1, 2 do
                EntityNPC.ThrowSpider(npc.Position, npc, npc.Position + RandomVector() * math.random(50, 100), false, 0)
            end

            innardEmitter:SetLookDir(Vec3(0, 0, -1))
            innardEmitter:EmitParticlesNum(REVEL.TarParticle2, REVEL.TarPartSystem, Vec3(npc.Position, -3), Vec3(0,0,-25), math.random(10) + 8, 0, 45)
            for i = 1, math.random(16, 20) do
                local proj = REVEL.SpawnNPCProjectile(npc, RandomVector() * math.random() * 3, npc.Position + RandomVector() * math.random() * 10)
                proj.Color = tarColor
                proj.FallingSpeed = math.random(-80, -30)
                proj.FallingAccel = 1.5
                proj:Update()

                -- innardEmitter:EmitParticlesNum(REVEL.TarParticle1, REVEL.TarPartSystem, Vec3(npc.Position, -3), Vec3(0,0,-25), 2, 0, math.pi * 0.2)
            end
        end
    end
end, REVEL.ENT.INNARD.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, amount)
    if e.Variant ~= REVEL.ENT.INNARD.variant then
        return
    end

    if e.HitPoints - amount - REVEL.GetDamageBuffer(e) <= 0 then
        e.HitPoints = 0
        if not e:GetData().KillTimer then
            e:GetData().KillTimer = 30
        end

        if not e:GetSprite():IsPlaying("Death") and not e:GetSprite():IsFinished("Death") then
            e.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            e:BloodExplode()
            e:GetSprite():Play("Death", true)
        end
        return false
    end
end, REVEL.ENT.INNARD.id)

end