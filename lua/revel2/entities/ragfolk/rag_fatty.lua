local ShrineTypes = require "lua.revelcommon.enums.ShrineTypes"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Rag Fatty

local Anm2GlowNull0

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.RAG_FATTY.variant then
        return
    end

    npc.SplatColor = REVEL.PurpleRagSplatColor

    local sprite, data = npc:GetSprite(), npc:GetData()
    data.UsePlayerMap = true

    if not data.State then
        data.State = "Idle"
        data.AttackCooldown = 90

        if data.SpecialAppear then
            npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            sprite:Play("Phase2Appear", true)
            data.State = "Head"
            data.PhaseTwo = true
            data.NoCreep = data.SpecialAppear.NoCreep
            data.NoJump = data.SpecialAppear.NoJump
            npc.HitPoints = 30
        end

        REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)
    end

    REVEL.RoarOccasionally(npc, SoundEffect.SOUND_MONSTER_ROAR_1, 90)

    if data.RagFattyProjectiles then
        for i, pro in ripairs(data.RagFattyProjectiles) do
            if not pro:Exists() then
                table.remove(data.RagFattyProjectiles, i)
            elseif pro.FrameCount > 10 then
                for i2, pro2 in ripairs(data.RagFattyProjectiles) do
                    if not pro2:Exists() then
                        table.remove(data.RagFattyProjectiles, i2)
                    else
                        if pro2.Position:DistanceSquared(pro.Position) < (pro.Size + pro2.Size) ^ 2 then
                            pro.Velocity = pro.Velocity + (pro.Position - pro2.Position) / 6
                        end
                    end
                end
            end
        end
    end

    if data.Buffed then
        REVEL.EmitBuffedParticles(npc, Anm2GlowNull0)
    end

    if data.State == "Idle" then
        if data.Path then
            local speed = 0.3
            if data.Buffed then
                speed = 0.4
            end

            REVEL.FollowPath(npc, speed, data.Path, true, 0.85)
        end

        if data.Buffed then
            REVEL.AnimateWalkFrame(sprite, npc.Velocity, {
                Left = "WalkLeft2",
                Right = "WalkRight2",
                Vertical = "WalkVert2"
            })
        else
            REVEL.AnimateWalkFrame(sprite, npc.Velocity, {
                Left = "WalkLeft",
                Right = "WalkRight",
                Vertical = "WalkVert"
            })
        end

        data.AttackCooldown = data.AttackCooldown - 1
        if data.AttackCooldown <= 0 then
            data.BeenHit = nil
            data.HoldTime = nil
            local min, max = 90, 120
            if data.Buffed then
                min, max = 75, 105
            end

            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_ANGRY_GURGLE, 0.6, 0, false, 1)

            data.AttackCooldown = math.random(min, max)
            if data.Buffed then
                sprite:Play("Inflate", true)
            else
                sprite:Play("InflateNormal", true)
            end

            data.State = "InflateFart"
        end
    elseif data.State == "InflateFart" then
        if sprite:IsFinished("Inflate") or sprite:IsFinished("InflateNormal") then
            if data.Buffed then
                sprite:Play("Hold", true)
            else
                sprite:Play("HoldNormal", true)
            end
        end

        if sprite:IsPlaying("Hold") or sprite:IsPlaying("HoldNormal") then
            if data.Path then
                REVEL.FollowPath(npc, 0.05, data.Path, true, 0.7)
            end

            if not data.HoldTime then
                data.HoldTime = 0
            end

            if data.Buffed then
                data.HoldTime = data.HoldTime + 2
            else
                data.HoldTime = data.HoldTime + 1
            end

            if data.BeenHit then
                if data.Buffed then
                    sprite:Play("Shoot", true)
                else
                    sprite:Play("ShootNormal", true)
                end
            end
        else
            npc.Velocity = npc.Velocity * 0.7
        end

        if sprite:IsEventTriggered("Fart") then
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector.Zero, nil)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FART, 1, 0, false, 1)
            local numProjectiles = math.min(math.floor(data.HoldTime / 30), 6)
            if not data.RagFattyProjectiles then
                data.RagFattyProjectiles = {}
            end

            for i = 1, numProjectiles + math.random(5, 7) do
                local params = ProjectileParams()
                params.Scale = math.random() + 0.5
                if not data.Buffed then
                    params.Variant = ProjectileVariant.PROJECTILE_PUKE
                    if i == 1 then
                        local pro = npc:FireBossProjectiles(1, npc:GetPlayerTarget().Position, 0, params)
                    end
                end
                local pro = npc:FireBossProjectiles(1, npc.Position + Vector(math.random(20,40)*0.1,0):Rotated(math.random(1,360)), 0, params)

                if data.Buffed then
                    pro.ProjectileFlags = BitOr(pro.ProjectileFlags, ProjectileFlags.SMART)
                    pro.FallingAccel = pro.FallingAccel * 0.6
                    pro:Update()
                    pro.ProjectileFlags = ClearBit(pro.ProjectileFlags, ProjectileFlags.SMART)

                    pro:GetData().RagFattyHoming = npc:GetPlayerTarget()
                    local homingSpeed = 1.2
                    pro:GetData().RagFattyHomingSpeed = REVEL.Lerp(homingSpeed, homingSpeed + 0.2, numProjectiles / 6) + math.random() * 0.1
                    data.RagFattyProjectiles[#data.RagFattyProjectiles + 1] = pro
                end
            end
        end

        if sprite:IsFinished("Shoot") or sprite:IsFinished("ShootNormal") then
            data.State = "Idle"
        end
    elseif data.State == "Head" then
        if sprite:IsFinished("HeadTransition") or sprite:IsFinished("Phase2Appear") then
            sprite:Play("HeadMove", true)
        end

        if sprite:IsPlaying("HeadMove") or sprite:WasEventTriggered("Move") then
            if data.Path then
                local speed = 0.7
                REVEL.FollowPath(npc, speed, data.Path, true, 0.95)
            end

            if npc.FrameCount % 10 == 0 and not data.NoCreep then
                local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, npc.Position, npc, false)
                creep.Color = REVEL.CustomColor(146, 39, 143)
            end

            if sprite:IsPlaying("HeadMove") and not data.NoJump then
                data.AttackCooldown = data.AttackCooldown - 1
                if data.AttackCooldown <= 0 then
                    data.AttackCooldown = math.random(75, 105)
                    sprite:Play("HeadJump", true)
                end
            end
        else
            npc.Velocity = npc.Velocity * 0.85
        end

        if sprite:IsPlaying("HeadJump") then
            if sprite:IsEventTriggered("Jump") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_JUMPS, 1, 0, false, 1)
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            end

            if sprite:IsEventTriggered("Shoot") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_IMPACTS, 1, 0, false, 1)
                local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, npc.Position, npc, false)
                creep.Color = REVEL.CustomColor(146, 39, 143)
                REVEL.UpdateCreepSize(creep, creep.Size * 3, true)

                local params = ProjectileParams()
                params.BulletFlags = ProjectileFlags.SMART

                local target = npc:GetPlayerTarget()
                for i = 1, 10 do
                    local projectile = npc:FireBossProjectiles(1, target.Position, 0, params)
                    local velocityLength = projectile.Velocity:Length()
                    projectile.Velocity = Vector.FromAngle((target.Position - projectile.Position):GetAngleDegrees() + math.random(-10, 10)) * velocityLength
                end

                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            end
        elseif sprite:IsFinished("HeadJump") then
            sprite:Play("HeadMove", true)
        end
    end

    if npc:IsDead() and (not data.Buffed or (REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) and math.random(1, 5) == 1)) then
        REVEL.SpawnRevivalRag(npc)
    end
end, REVEL.ENT.RAG_FATTY.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, amount)
    if e.Variant == REVEL.ENT.RAG_FATTY.variant then
        if e.HitPoints - amount - REVEL.GetDamageBuffer(e) <= 0 and e:GetData().Buffed and not e:GetData().PhaseTwo then
            e:BloodExplode()
            local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, e.Position, e, false)
            creep.Color = REVEL.CustomColor(146, 39, 143)
            REVEL.UpdateCreepSize(creep, creep.Size * 3, true)

            e:GetData().PhaseTwo = true
            e.HitPoints = e.MaxHitPoints + amount
            e:GetSprite():Play("HeadTransition", true)
            e:GetData().State = "Head"
        elseif e:GetData().State == "InflateFart" then
            e:GetData().BeenHit = true
        end
    end
end, REVEL.ENT.RAG_FATTY.id)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
    if pro:GetData().RagFattyHoming and pro:GetData().RagFattyHoming:Exists() and pro.FrameCount > 5 then
        pro.Velocity = pro.Velocity * 0.95 + (pro:GetData().RagFattyHoming.Position - pro.Position):Resized(pro:GetData().RagFattyHomingSpeed)
    end
end)


Anm2GlowNull0 = {
    WalkRight2 = {
        Offset = {Vector(-10, -28), Vector(-10, -28), Vector(-10, -28), Vector(-10, -28), Vector(-10, -29), Vector(-9, -29), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-11, -22), Vector(-11, -23), Vector(-11, -25), Vector(-11, -26), Vector(-10, -27), Vector(-10, -28), Vector(-9, -29), Vector(-9, -29), Vector(-9, -29), Vector(-9, -29), Vector(-9, -29), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-11, -22), Vector(-11, -23), Vector(-10, -25), Vector(-10, -26), Vector(-10, -26), Vector(-10, -26)},
        Scale = {Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
    WalkLeft2 = {
        Offset = {Vector(-10, -28), Vector(-10, -28), Vector(-10, -28), Vector(-10, -28), Vector(-10, -29), Vector(-9, -29), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-11, -22), Vector(-11, -23), Vector(-11, -25), Vector(-11, -26), Vector(-10, -27), Vector(-10, -28), Vector(-9, -29), Vector(-9, -29), Vector(-9, -29), Vector(-9, -29), Vector(-9, -29), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-11, -22), Vector(-11, -23), Vector(-10, -25), Vector(-10, -26), Vector(-10, -26), Vector(-10, -26)},
        Scale = {Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
    WalkVert2 = {
        Offset = {Vector(-10, -28), Vector(-10, -28), Vector(-10, -28), Vector(-10, -28), Vector(-10, -29), Vector(-9, -29), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-11, -22), Vector(-11, -23), Vector(-11, -25), Vector(-11, -26), Vector(-10, -27), Vector(-10, -28), Vector(-9, -29), Vector(-9, -29), Vector(-9, -29), Vector(-9, -29), Vector(-9, -29), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-9, -30), Vector(-11, -22), Vector(-11, -23), Vector(-10, -25), Vector(-10, -26), Vector(-10, -26), Vector(-10, -26)},
        Scale = {Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
    Inflate = {
        Offset = {Vector(-10, -28), Vector(-10, -30), Vector(-9, -31), Vector(-10, -28), Vector(-10, -24), Vector(-10, -24), Vector(-10, -23), Vector(-9, -33), Vector(-9, -42), Vector(-8, -52), Vector(-8, -52), Vector(-8, -52), Vector(-8, -52), Vector(-8, -52), Vector(-8, -53), Vector(-8, -53), Vector(-8, -53), Vector(-8, -53), Vector(-8, -53), Vector(-8, -50), Vector(-8, -46), Vector(-7, -42), Vector(-7, -39), Vector(-7, -38), Vector(-7, -38), Vector(-7, -37), Vector(-7, -37)},
        Scale = {Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, false, false, false, false, true, true, true, true, true}
    },
    Hold = {
        Offset = {Vector(-8, -38), Vector(-8, -38), Vector(-8, -38), Vector(-8, -38), Vector(-8, -38), Vector(-8, -38), Vector(-8, -38), Vector(-8, -37), Vector(-8, -37), Vector(-8, -37), Vector(-8, -37), Vector(-8, -38), Vector(-8, -38), Vector(-8, -38), Vector(-8, -38)},
        Scale = {Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
    Shoot = {
        Offset = {Vector(-10, -28), Vector(-9, -32), Vector(-8, -35), Vector(-8, -35), Vector(-8, -35), Vector(-8, -35), Vector(-8, -35), Vector(-10, -30), Vector(-11, -24), Vector(-10, -26), Vector(-10, -28), Vector(-9, -30), Vector(-9, -30), Vector(-9, -29), Vector(-9, -29)},
        Scale = {Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {false, false, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
    HeadTransition = {
        Offset = {Vector(-10, -30), Vector(-10, -36), Vector(-10, -41), Vector(-10, -47), Vector(-10, -46), Vector(-10, -45), Vector(-9, -45), Vector(-9, -44), Vector(-9, -43), Vector(-8, -34), Vector(-7, -25), Vector(-6, -16), Vector(-11, -12), Vector(-16, -7), Vector(-13, -9), Vector(-11, -12), Vector(-8, -14), Vector(-9, -13), Vector(-10, -12), Vector(-10, -12), Vector(-11, -11), Vector(-11, -11), Vector(-10, -11), Vector(-10, -11), Vector(-10, -11), Vector(-10, -12), Vector(-10, -12), Vector(-10, -12), Vector(-10, -12), Vector(-10, -12), Vector(-10, -12), Vector(-10, -12), Vector(-10, -12), Vector(-9, -13), Vector(-8, -14), Vector(-9, -12), Vector(-10, -9), Vector(-10, -9), Vector(-10, -9), Vector(-10, -9), Vector(-10, -10), Vector(-9, -12), Vector(-9, -12), Vector(-9, -12)},
        Scale = {Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, false, false, false, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
    HeadMove = {
        Offset = {Vector(-9, -11), Vector(-9, -12), Vector(-9, -12), Vector(-10, -11), Vector(-10, -10), Vector(-10, -10), Vector(-10, -9), Vector(-10, -9), Vector(-10, -10), Vector(-9, -10), Vector(-9, -11)},
        Scale = {Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true}
    },
    HeadJump = {
        Offset = {Vector(-9, -11), Vector(-8, -12), Vector(-8, -12), Vector(-10, -10), Vector(-12, -8), Vector(-8, -12), Vector(-5, -16), Vector(-6, -36), Vector(-6, -55), Vector(-6, -87), Vector(-8, -88), Vector(-9, -90), Vector(-8, -91), Vector(-8, -92), Vector(-8, -88), Vector(-8, -84), Vector(-8, -80), Vector(-8, -76), Vector(-8, -60), Vector(-7, -44), Vector(-5, -15), Vector(-9, -12), Vector(-13, -8), Vector(-12, -9), Vector(-12, -9), Vector(-11, -10), Vector(-11, -10), Vector(-10, -11), Vector(-9, -12), Vector(-9, -12), Vector(-8, -13), Vector(-8, -13), Vector(-7, -14), Vector(-9, -12), Vector(-11, -10), Vector(-10, -11), Vector(-10, -11), Vector(-9, -12), Vector(-9, -12), Vector(-9, -11), Vector(-9, -11), Vector(-10, -10), Vector(-10, -9), Vector(-10, -9), Vector(-10, -9), Vector(-10, -9), Vector(-10, -10), Vector(-9, -12), Vector(-9, -12), Vector(-9, -11)},
        Scale = {Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, false, false, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
    Phase2Appear = {
        Offset = {Vector(-10, -28), Vector(-10, -27), Vector(-10, -27), Vector(-9, -26), Vector(-9, -26), Vector(-9, -25), Vector(-9, -25), Vector(-9, -24), Vector(-8, -23), Vector(-8, -23), Vector(-8, -22), Vector(-8, -22), Vector(-7, -21), Vector(-7, -20), Vector(-7, -20), Vector(-7, -19), Vector(-7, -19), Vector(-6, -18), Vector(-6, -18), Vector(-6, -17), Vector(-10, -12), Vector(-15, -7), Vector(-13, -9), Vector(-10, -12), Vector(-8, -14), Vector(-9, -13), Vector(-10, -12), Vector(-10, -12), Vector(-11, -11), Vector(-11, -11), Vector(-10, -12), Vector(-10, -12), Vector(-10, -12), Vector(-10, -12), Vector(-10, -12), Vector(-10, -12), Vector(-10, -12), Vector(-10, -12), Vector(-10, -12), Vector(-10, -12), Vector(-10, -12), Vector(-9, -13), Vector(-8, -14), Vector(-9, -12), Vector(-10, -9), Vector(-10, -9), Vector(-10, -9), Vector(-10, -9), Vector(-9, -10), Vector(-8, -12), Vector(-8, -12), Vector(-9, -11)},
        Scale = {Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30), Vector(30, 30)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, true, false, false, false, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
}

end