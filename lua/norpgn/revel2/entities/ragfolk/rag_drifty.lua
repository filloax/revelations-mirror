local ShrineTypes = require "lua.revelcommon.enums.ShrineTypes"
return function()

-- Rag drifty

local Anm2GlowNull0
local Anm2GlowNull1

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.RAG_DRIFTY.variant and npc.Variant ~= REVEL.ENT.PSEUDO_RAG_DRIFTY.variant then
        return
    end

    local data, sprite = npc:GetData(), npc:GetSprite()
    local isPseudoDrifty = npc.Variant == REVEL.ENT.PSEUDO_RAG_DRIFTY.variant
    if not data.State then
        if not isPseudoDrifty then
            npc.SplatColor = REVEL.PurpleRagSplatColor
        else
            data.AttackCooldown = (math.random() ^ 2) * 30
        end
        data.State = "Idle"
    end

    npc.Velocity = npc.Velocity * 0.95

    if data.Buffed then
        REVEL.EmitBuffedParticles(npc, Anm2GlowNull0, 2)
        REVEL.EmitBuffedParticles(npc, Anm2GlowNull1, 2)
    end

    if data.State == "Idle" then
        if not sprite:IsPlaying("Appear") and npc.FrameCount > 20 then
            local isFriendlyTargetingPlayer = npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and npc:GetPlayerTarget().Type == EntityType.ENTITY_PLAYER
            if not data.AttackCooldown and not data.Projectiles and not isFriendlyTargetingPlayer then
                data.ShotDirection = Vector.FromAngle((math.random(1, 4) * 90) + 45)
                sprite.FlipX = data.ShotDirection.X > 0

                if not data.Buffed then
                    if data.ShotDirection.Y < 0 then
                        sprite:Play("ShootDown", true)
                    else
                        sprite:Play("ShootUp", true)
                    end

                    data.State = "Shoot"
                else
                    local anim
                    if data.ShotDirection.Y < 0 then
                        anim = "ShootDown"
                    else
                        anim = "ShootUp"
                    end

                    data.ShootAnimation = anim
                    sprite:Play(data.ShootAnimation .. "Start", true)
                    data.State = "ShootBuffed"
                    data.ShotCount = 0
                end

                if isPseudoDrifty then
                    data.AttackCooldown = (math.random() ^ 2) * 30
                end
            elseif data.AttackCooldown then
                if not data.ShotDirection then
                    if not sprite:IsPlaying("Idle") then
                        sprite:Play("Idle", true)
                    end
                else
                    if data.ShotDirection.Y < 0 then
                        if not sprite:IsPlaying("IdleDown") then
                            sprite:Play("IdleDown", true)
                        end
                    else
                        if not sprite:IsPlaying("IdleUp") then
                            sprite:Play("IdleUp", true)
                        end
                    end
                end

                data.AttackCooldown = data.AttackCooldown - 1

                if data.AttackCooldown <= 0 then
                    data.AttackCooldown = nil
                end
            elseif data.Projectiles or isFriendlyTargetingPlayer then
                sprite.FlipX = false
                local anim = "Idle"
                if data.Buffed then
                    anim = "Idle2"
                end

                if not sprite:IsPlaying(anim) then
                    sprite:Play(anim, true)
                end

                npc.Velocity = npc.Velocity + (npc:GetPlayerTarget().Position - npc.Position):Resized(0.1)
            end
        end
    elseif data.State == "Shoot" then
        if sprite:IsFinished("ShootUp") or sprite:IsFinished("ShootDown") then
            data.State = "Idle"
        end
    elseif data.State == "ShootBuffed" then
        if sprite:IsFinished(data.ShootAnimation .. "Start") then
            sprite:Play(data.ShootAnimation .. "Loop", true)
        end

        if sprite:IsEventTriggered("Shoot") then
            data.ShootTimer = 25
        end

        if data.ShootTimer then
            data.ShootTimer = data.ShootTimer - 1
            data.ShouldShoot = data.ShootTimer % 5 == 0
            if data.ShootTimer <= 0 then
                sprite:Play(data.ShootAnimation .. "End")
                data.ShootTimer = nil
                data.ShouldShoot = nil
            end
        end

        if sprite:IsFinished(data.ShootAnimation .. "End") then
            data.State = "Idle"
            data.ShootAnimation = nil
        end
    end

    if data.Projectiles then
        for i, pro in ripairs(data.Projectiles) do
            if not pro:Exists() then
                table.remove(data.Projectiles, i)
            end
        end

        if #data.Projectiles == 0 then
            data.Projectiles = nil
        end
    end

    if sprite:IsEventTriggered("Shoot") or (data.State == "ShootBuffed" and data.ShouldShoot) then
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_LITTLE_SPIT, 1, 0, false, 1)
        npc.Velocity = (-data.ShotDirection) * 8
        if not isPseudoDrifty then
            local pro = REVEL.SpawnNPCProjectile(npc, data.ShotDirection * 8)
            pro:GetData().DriftyDeaccel = 0.9
            pro.ProjectileFlags = BitOr(pro.ProjectileFlags, ProjectileFlags.SMART)
            pro.FallingSpeed = -10

            if data.State == "ShootBuffed" then
                if not data.Projectiles then
                    data.Projectiles = {}
                end
                data.Projectiles[#data.Projectiles + 1] = pro
            end
        else
            local params = ProjectileParams()
            params.Variant = ProjectileVariant.PROJECTILE_PUKE
            if npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) or npc:HasEntityFlags(EntityFlag.FLAG_CHARM) then
                params.BulletFlags = BitOr(ProjectileFlags.CANT_HIT_PLAYER, ProjectileFlags.HIT_ENEMIES)
            end

            for i = 1, 7 do
                local pro = npc:FireBossProjectiles(1, npc.Position + data.ShotDirection, 0, params)
                if i == 1 then
                    pro:Die()
                else
                    pro:AddScale(math.random() * 0.5)
                end
            end
        end
    end

    if not isPseudoDrifty and npc:IsDead() and not data.NoRags and (not data.Buffed or (REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) and math.random(1, 5) == 1)) then
        REVEL.SpawnRevivalRag(npc)
    end
end, REVEL.ENT.RAG_DRIFTY.id)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
    if pro:GetData().DriftyDeaccel ~= nil then
        pro.Velocity = pro.Velocity * pro:GetData().DriftyDeaccel
    end
end)


Anm2GlowNull0 = {
    ShootUpStart = {
        Offset = {Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(10, -18), Vector(9, -20), Vector(8, -21), Vector(7, -22), Vector(4, -21), Vector(4, -18), Vector(4, -14), Vector(4, -14)},
        Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, false, false}
    },
    ShootUpEnd = {
        Offset = {Vector(0, 0), Vector(0, 0), Vector(0, 0), Vector(0, 0), Vector(0, 0), Vector(0, 0), Vector(0, 0), Vector(0, 0), Vector(6, -15), Vector(8, -22), Vector(9, -20), Vector(10, -17), Vector(10, -18), Vector(9, -20), Vector(9, -20), Vector(9, -19), Vector(9, -19), Vector(9, -19)},
        Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {false, false, false, false, false, false, false, false, true, true, true, true, true, true, true, true, true, true}
    },
    ShootDownStart = {
        Offset = {Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(9, -19), Vector(10, -18), Vector(9, -20), Vector(8, -21), Vector(8, -21), Vector(8, -21)},
        Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, false}
    },
    ShootDownEnd = {
        Offset = {Vector(9, -19), Vector(6, -19), Vector(4, -18), Vector(2, -18), Vector(-1, -18), Vector(-4, -17), Vector(-6, -17), Vector(-8, -16), Vector(-11, -16), Vector(7, -22), Vector(8, -20), Vector(10, -17), Vector(9, -18), Vector(8, -20), Vector(8, -20), Vector(8, -20), Vector(9, -19), Vector(9, -19)},
        Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {false, false, false, false, false, false, false, false, true, true, true, true, true, true, true, true, true, true}
    },
    Idle2 = {
        Offset = {Vector(9, -19)},
        Scale = {Vector(20, 20)},
        Alpha = {255},
        Visible = {true}
    },
}

Anm2GlowNull1 = {
    ShootUpStart = {
        Offset = {Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-10, -18), Vector(-9, -20), Vector(-8, -21), Vector(-7, -22), Vector(-7, -22)},
        Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, false}
    },
    ShootUpEnd = {
        Offset = {Vector(0, 0), Vector(0, 0), Vector(0, 0), Vector(0, 0), Vector(0, 0), Vector(0, 0), Vector(0, 0), Vector(0, 0), Vector(6, -15), Vector(-7, -22), Vector(-8, -20), Vector(-10, -17), Vector(-10, -18), Vector(-9, -20), Vector(-9, -20), Vector(-9, -19), Vector(-9, -19), Vector(-9, -19)},
        Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {false, false, false, false, false, false, false, false, false, true, true, true, true, true, true, true, true, true}
    },
    ShootDownStart = {
        Offset = {Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-9, -19), Vector(-10, -18), Vector(-9, -20), Vector(-8, -21), Vector(-8, -22), Vector(-7, -24), Vector(-7, -24), Vector(-7, -24), Vector(-7, -24)},
        Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, false, false}
    },
    ShootDownEnd = {
        Offset = {Vector(9, -19), Vector(7, -19), Vector(5, -20), Vector(4, -20), Vector(2, -20), Vector(0, -21), Vector(-2, -21), Vector(-3, -21), Vector(-5, -22), Vector(-7, -22), Vector(-8, -20), Vector(-10, -17), Vector(-9, -18), Vector(-8, -20), Vector(-8, -20), Vector(-8, -20), Vector(-9, -19), Vector(-9, -19)},
        Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {false, false, false, false, false, false, false, false, false, true, true, true, true, true, true, true, true, true}
    },
    Idle2 = {
        Offset = {Vector(-9, -19)},
        Scale = {Vector(20, 20)},
        Alpha = {255},
        Visible = {true}
    },
}

end