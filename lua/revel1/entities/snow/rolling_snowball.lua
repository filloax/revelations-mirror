REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

----------------------
-- ROLLING SNOWBALL --
----------------------

local function GetOverlayColoration(r, g, b)
    return Color(r / 135, g / 135, b / 135, 1,conv255ToFloat( 0, 0, 0))
end

local snotProjColor = GetOverlayColoration(52, 93, 89)
local snotCreepColor = REVEL.CustomColor(39, 126, 113, 1)

local RollParticle = REVEL.ParticleType.FromTable {
    Name = "Snowball Roll",
    Anm2 =  "gfx/effects/revelcommon/white_particle.anm2",
    BaseLife = 15,
    Variants = 6,
    FadeOutStart = 0.3,
    StartScale = 1,
    EndScale = 0.6,
    RotationSpeedMult = 0.2
}
RollParticle:SetColor(Color(0.9, 0.9, 0.9), 0.1)

local RollParticle2 = REVEL.ParticleType.FromTable {
    Name = "Snotball Roll",
    Anm2 =  "gfx/effects/revelcommon/white_particle.anm2",
    BaseLife = 15,
    Variants = 6,
    FadeOutStart = 0.3,
    StartScale = 1,
    EndScale = 0.6,
    RotationSpeedMult = 0.2
}
RollParticle2:SetColor(Color(0.2, 0.8, 0.7), 0.1)
local PARTICLE_EMITTER_NAME = "Rolling Snowball"

local function rolling_NpcUpdate(_, npc)
    if npc.Variant == REVEL.ENT.ROLLING_SNOWBALL.variant 
    or npc.Variant == REVEL.ENT.ROLLING_SNOTBALL.variant then

        npc.SplatColor = REVEL.SnowSplatColor
        local player = npc:GetPlayerTarget()
        local data = npc:GetData()

        if not REVEL.IsUsingPathMap(REVEL.GenericChaserPathMap, npc) then
            REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)
        end

        data.UsePlayerMap = true

        if npc:IsDead() and not data.Died then
            if data.SnotVariant then
                local ec = REVEL.SpawnCreep(EffectVariant.CREEP_BLACK, 0, npc.Position, npc, false)
                REVEL.UpdateCreepSize(ec, ec.Size * 4, true)
                ec:ToEffect().Timeout = 300
                ec.Color = snotCreepColor
            else
                local ec = REVEL.SpawnIceCreep(npc.Position, npc)
                REVEL.UpdateCreepSize(ec, ec.Size * 4, true)
                ec:ToEffect().Timeout = 300
            end

            data.Died = true
        end

        if not data.Init then
            data.CreepFrame = 0
            data.Size = 1
            data.Speed = 0.3
            data.DashSpeed = 10
            data.Friction = 0.95
            data.Cooldown = math.random(40, 150)
            data.SnotVariant = npc.Variant == REVEL.ENT.ROLLING_SNOTBALL.variant or false
            REVEL.AddEntityParticleEmitter(npc, REVEL.SphereEmitter(npc.Size), PARTICLE_EMITTER_NAME)

            data.Init = true
        end

        if npc:GetSprite():IsFinished("Appear") then
            data.State = "Roll"
        end

        if data.State == "Roll" then
            if data.Path then
                REVEL.FollowPath(npc, data.Speed, data.Path, true, data.Friction)
            end

            if npc.FrameCount % 6 == 0 then
                if data.SnotVariant then
                    local ec = REVEL.SpawnCreep(EffectVariant.CREEP_BLACK, 0, npc.Position, npc, false)
                    ec:ToEffect().Timeout = 300
                    ec.Color = snotCreepColor
                else
                    local ec = REVEL.SpawnIceCreep(npc.Position, npc)
                    -- REVEL.UpdateCreepSize(ec, ec.Size * 1, true)
                    ec:ToEffect().Timeout = 300
                end
            end

            if not data.Cooldown or data.Cooldown < 0 then
                data.State = "Charge"
                data.DashFrame = 0
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.SNOWBALL, 0.5, 0, false, 1)
                npc:GetSprite().PlaybackSpeed = 1
                data.Cooldown = math.random(45, 75)
            else
                data.Cooldown = data.Cooldown - 1
            end
        elseif data.State == "Charge" then
            data.DashFrame = data.DashFrame + 1
            npc:GetSprite().PlaybackSpeed = 1+data.DashFrame/30

            local dir = (player.Position - npc.Position):Normalized()

            npc.Velocity = dir * 0.0001 --just to change the direction

            local particleType = RollParticle
            if data.SnotVariant then
                particleType = RollParticle2
            end

            local emitter = REVEL.GetEntityParticleEmitter(npc, PARTICLE_EMITTER_NAME)
            emitter:EmitParticlesPerSec(
                particleType, 
                REVEL.ParticleSystems.BasicClamped, 
                Vec3(npc.Position - dir * 4, -4),
                Vec3(-dir * 8, -8),
                20,
                0.25,
                0.5
            )

            if data.DashFrame == 60 then
                REVEL.sfx:NpcPlay(npc,SoundEffect.SOUND_SWORD_SPIN,1,0,false,1.2)
                data.State = "Dash"
                data.dashVel = npc.Velocity:Resized(data.DashSpeed)
                data.DashFrame = 0
            end

        elseif data.State == "Dash" then
            npc:GetSprite().PlaybackSpeed = 3
            if npc:CollidesWithGrid() then
                REVEL.sfx:NpcPlay(npc,SoundEffect.SOUND_MEAT_IMPACTS,1,0,false,0.8)

                local par = ProjectileParams()
                if not data.SnotVariant then
                    par.Variant = ProjectileVariant.PROJECTILE_TEAR
                end

                for i = 1, data.Size * 2 do
                    local projectile = npc:FireBossProjectiles(1, Vector.Zero, 8, par)
                    local pdata = projectile:GetData()

                    if data.SnotVariant then
                        projectile:GetSprite():Load('gfx/projectiles/low_flash_projectile.anm2', true)
                        pdata.ColoredProjectile = snotProjColor
                        pdata.IsSickieTear = true
                        pdata.SpawnerSeed = npc.InitSeed
                    else
                        pdata.Flomp = true
                        pdata.ChangeToSnow = true
                    end
                    pdata.RandomizeScaleSmall = true

                    -- if data.Size == 3 and not data.DontSpawn and i <= 3 and numSnowdips < 2 then
                    --     pdata.SpawnDip = true
                    --     pdata.SpawnDipParent = npc
                    --     pdata.SpawnScaleData = data.CustomScaleData
                    -- end
                end

                if data.Size < 3 then
                    npc.Velocity = npc.Velocity:Resized(data.DashSpeed)
                    data.dashVel = npc.Velocity
                    data.Size = data.Size + 1
                else
                    REVEL.sfx:NpcPlay(npc,SoundEffect.SOUND_HEARTOUT,1,0,false,1)
                    npc:GetSprite().PlaybackSpeed = 1
                    data.State = "Slow"
                    data.RestartAt = npc.FrameCount + 35
                    data.DashFrame = 0
                    data.Cooldown = math.random(55, 85)
                    data.Size = 1

                    npc.Velocity = -data.dashVel
                end
            else
                npc:GetSprite().PlaybackSpeed = 3
                npc.Velocity = data.dashVel
            end
        elseif data.State == "Slow" then
            npc.Velocity = npc.Velocity * 0.95
            if npc.FrameCount >= data.RestartAt then
                data.State = "Roll"
            end
        end

        if data.State == "Dash" or data.State == "Roll" or data.State == "Charge" or data.State == "Slow" then
            if data.Size == 1 then
                npc:AnimWalkFrame("Roll H Small", "Roll V Small", 0.0001)
            elseif data.Size == 2 then
                npc:AnimWalkFrame("Roll H Medium", "Roll V Medium", 0.0001)
            elseif data.Size == 3 then
                npc:AnimWalkFrame("Roll H Large", "Roll V Large", 0.0001)
            end
        end
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, rolling_NpcUpdate, REVEL.ENT.ROLLING_SNOWBALL.id)

end

REVEL.PcallWorkaroundBreakFunction()