local ShrineTypes = require "scripts.revelations.common.enums.ShrineTypes"
return function()

-- Rag Fatty

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.RAG_FATTY.variant then
        return
    end

    npc.SplatColor = REVEL.PurpleRagSplatColor

    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

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
        REVEL.EmitBuffedParticles(npc)
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

                    REVEL.GetData(pro).RagFattyHoming = npc:GetPlayerTarget()
                    local homingSpeed = 1.2
                    REVEL.GetData(pro).RagFattyHomingSpeed = REVEL.Lerp(homingSpeed, homingSpeed + 0.2, numProjectiles / 6) + math.random() * 0.1
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
        if e.HitPoints - amount - REVEL.GetDamageBuffer(e) <= 0 and REVEL.GetData(e).Buffed and not REVEL.GetData(e).PhaseTwo then
            e:BloodExplode()
            local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, e.Position, e, false)
            creep.Color = REVEL.CustomColor(146, 39, 143)
            REVEL.UpdateCreepSize(creep, creep.Size * 3, true)

            REVEL.GetData(e).PhaseTwo = true
            e.HitPoints = e.MaxHitPoints + amount
            e:GetSprite():Play("HeadTransition", true)
            REVEL.GetData(e).State = "Head"
        elseif REVEL.GetData(e).State == "InflateFart" then
            REVEL.GetData(e).BeenHit = true
        end
    end
end, REVEL.ENT.RAG_FATTY.id)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
    if REVEL.GetData(pro).RagFattyHoming and REVEL.GetData(pro).RagFattyHoming:Exists() and pro.FrameCount > 5 then
        pro.Velocity = pro.Velocity * 0.95 + (REVEL.GetData(pro).RagFattyHoming.Position - pro.Position):Resized(REVEL.GetData(pro).RagFattyHomingSpeed)
    end
end)

end