REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-------------
-- ANTLION --
-------------

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.ANTLION.variant then
        return
    end

    local data, sprite = npc:GetData(), npc:GetSprite()
    if not data.State then
        local shouldSpawnEmerged = false
        local currentRoom = StageAPI.GetCurrentRoom()
        if currentRoom and currentRoom.Metadata:Has{Index = REVEL.room:GetGridIndex(npc.Position), Name = "AntlionAutoemerge"} then
            shouldSpawnEmerged = true
        end

        if not shouldSpawnEmerged then
            npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            sprite:Play("Appear", true)
        else
            npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            npc:Morph(npc.Type, npc.Variant, 1, -1)
            sprite:Play("Appear Fly", true)
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        end

        data.State = "Appear"
    end

    if data.PitfallingPlayer then
        if data.PitfallingPlayer:IsExtraAnimationFinished() then
            data.PitfallingPlayer = nil
        elseif data.PitfallingPlayer:GetSprite():IsPlaying("JumpOut") then
            data.PitfallingPlayer.Velocity = (data.PitfallingPlayer.Position - npc.Position):Resized(5)
        end
    end

    if data.UsePlayerFlyingMap and data.State ~= "Fly" then
        data.Path = nil
        data.PathIndex = nil
        data.UsePlayerFlyingMap = nil
    end

    if data.State == "Appear" then
        npc.Velocity = Vector.Zero
        if sprite:IsFinished("Appear Fly") then
            data.State = "Fly"
            data.AttackCooldown = math.random(25, 35)
            sprite:Play("Idle Fly", true)
        elseif sprite:IsFinished("Appear") or (not sprite:IsPlaying("Appear") and not sprite:IsPlaying("Appear Fly")) then
            data.State = "Suck"
            data.SuckTimer = 0
            sprite:Play("Suck Start", true)
        end
    elseif data.State == "Suck" then
        if sprite:IsFinished("Suck Start") then
            sprite:Play("Suck", true)
        end

        if sprite:IsPlaying("Suck") then
            data.SuckTimer = math.min(data.SuckTimer + 1, 450)
            local suckStrength = data.SuckTimer / 450
            local radius = suckStrength * 150
            local taperRadius = suckStrength * 100
            local strength = suckStrength * 0.9
            local taperStrength = suckStrength * 0.1
            if data.SuckTimer > 90 then
                for _, enemy in ipairs(Isaac.FindInRadius(npc.Position, radius + taperRadius, EntityPartition.ENEMY)) do
                    if enemy:IsVulnerableEnemy() and not enemy:HasEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK) and not enemy:HasEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK) and not enemy:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) then
                        local useStrength = strength
                        local dist = enemy.Position:Distance(npc.Position)
                        if dist > radius then
                            local percent = (dist - radius) / taperRadius
                            useStrength = REVEL.Lerp(strength, taperStrength, percent)
                        end

                        enemy.Velocity = enemy.Velocity + (npc.Position - enemy.Position):Resized(useStrength)
                        if dist < (enemy.Size + npc.Size) then
                            data.State = "Chomp"
                            sprite:Play("Chomp", true)
                        end
                    end
                end
            end

            for _, player in ipairs(REVEL.players) do
                local dist = player.Position:DistanceSquared(npc.Position)
                if dist < (radius + taperRadius) ^ 2 then
                    dist = player.Position:Distance(npc.Position)
                    local useStrength = strength
                    if dist > radius then
                        local percent = (dist - radius) / taperRadius
                        useStrength = REVEL.Lerp(strength, taperStrength, percent)
                    end

                    if player.MoveSpeed < 1 then
                        useStrength = useStrength * REVEL.Lerp(0.6, 1, player.MoveSpeed / 1)
                    end
                    player.Velocity = player.Velocity + (npc.Position - player.Position):Resized(useStrength)
                    if not data.PitfallingPlayer and dist < (player.Size + npc.Size) then
                        data.State = "Chomp"
                        sprite:Play("Chomp", true)
                        player:AnimatePitfallIn()
                        data.PitfallingPlayer = player
                    end
                end
            end

            for _, bomb in ipairs(Isaac.FindByType(EntityType.ENTITY_BOMBDROP, -1, -1, false, false)) do
                if bomb.Position:DistanceSquared(npc.Position) < (bomb.Size + npc.Size) ^ 2 then
                    ---@type EntityBomb
                    bomb = bomb:ToBomb()
                    sprite:Play("Suck End", true)
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, bomb.Position, Vector.Zero, npc)
                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_VAMP_GULP, 0.6, 0, false, 1)
                    data.State = "Bombed"
                    data.BombFlags = bomb.Flags
                    data.BombExplosionDamage = bomb.ExplosionDamage
                    data.BombRadiusMultiplier = bomb.RadiusMultiplier
                    bomb:Remove()
                end
            end
        end

        if REVEL.room:IsClear() and not sprite:IsPlaying("Suck End") then
            sprite:Play("Suck End", true)
            data.State = "LeaveRoom"
        end

        if sprite:IsFinished("Suck End") then
            data.State = "Fly"
            data.AttackCooldown = math.random(25, 35)
            sprite:Play("Emerge", true)
        end

        npc.Velocity = Vector.Zero
    elseif data.State == "Chomp" then
        if sprite:IsEventTriggered("Splatter") then
            local killedBonyOnly
            local killedSomething
            for _, enemy in ipairs(Isaac.FindInRadius(npc.Position, npc.Size, EntityPartition.ENEMY)) do
                if enemy:IsVulnerableEnemy() and not enemy:HasEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK) and not enemy:HasEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK) and not enemy:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) then
                    if killedBonyOnly == nil or killedBonyOnly then
                        if (enemy.Type == REVEL.ENT.RAG_BONY.id and enemy.Variant == REVEL.ENT.RAG_BONY.variant) or enemy.Type == EntityType.ENTITY_BONY then
                            killedBonyOnly = true
                        else
                            killedBonyOnly = false
                        end
                    end

                    killedSomething = true

                    enemy:BloodExplode()
                    enemy:Die()
                end
            end

            for _, bomb in ipairs(Isaac.FindByType(EntityType.ENTITY_BOMBDROP, -1, -1, false, false)) do
                if bomb.Position:DistanceSquared(npc.Position) < (bomb.Size + npc.Size) ^ 2 then
                    ---@type EntityBomb
                    bomb = bomb:ToBomb()
                    bomb:SetExplosionCountdown(0)
                end
            end

            if killedSomething then
                local splatVariant = 0
                if killedBonyOnly then
                    splatVariant = ProjectileVariant.PROJECTILE_BONE
                end

                local splatPro = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, splatVariant, 0, npc.Position + Vector(0, 1), Vector.Zero, npc)
                splatPro:Die()

                for i = 1, math.random(5, 8) do
                    local variant = 0
                    if killedBonyOnly or math.random(1, 3) == 1 then
                        variant = ProjectileVariant.PROJECTILE_BONE
                    end

                    local p = REVEL.SpawnNPCProjectile(npc, RandomVector() * math.random(4, 8), nil, variant)
                    p.Height = math.random(30, 45) * -1
                    p.FallingSpeed = math.random(10, 20) * -1
                    p.FallingAccel = 1
                    p.Scale = ( 1 + ( math.random(0, 6) / 10 ) )
                end

                data.KilledSomething = true
            end
        end

        if sprite:IsFinished("Chomp") then
            if data.KilledSomething then
                npc:Morph(npc.Type, npc.Variant, 1, -1)
                sprite:Play("Suck End", true)
            else
                sprite:Play("Suck Start", true)
            end

            data.State = "Suck"
        end

        npc.Velocity = Vector.Zero
    elseif data.State == "Bombed" then
        if sprite:GetFrame() == 16 then
            npc:TakeDamage(data.BombExplosionDamage, 0, EntityRef(npc), 0)
            REVEL.game:BombExplosionEffects(npc.Position, data.BombExplosionDamage, data.BombFlags, Color.Default, npc, data.BombRadiusMultiplier, true, true)
        end

        if sprite:IsFinished("Suck End") then
            sprite:Play("Suck Start", true)
            data.State = "Suck"
        end
    elseif data.State == "LeaveRoom" then
        npc.Velocity = Vector.Zero
        if sprite:IsFinished("DigIn") then
            npc:Remove()
        end

        if sprite:IsFinished("Suck End") then
            sprite:Play("DigIn", true)
        end
    elseif data.State == "Fly" then
        if not REVEL.IsUsingPathMap(REVEL.GenericFlyingChaserPathMap, npc) then
            REVEL.UsePathMap(REVEL.GenericFlyingChaserPathMap, npc)
        end
        data.UsePlayerFlyingMap = true
        
        if not sprite:IsPlaying("Emerge") and not sprite:IsPlaying("Appear Fly") and not sprite:IsPlaying("Idle Fly") then
            sprite:Play("Idle Fly", true)
        end

        if sprite:IsEventTriggered("Emerge") or (not sprite:IsPlaying("Emerge") and npc.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_ALL) then
            npc:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
            npc:ClearEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        end

        if sprite:IsEventTriggered("Emerge") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MAGGOT_BURST_OUT, 1, 0, false, 1)
        end

        if sprite:IsEventTriggered("Pound") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
        end

        if sprite:IsPlaying("Idle Fly") then
            if data.Path then
                REVEL.FollowPath(npc, 0.4, data.Path, true, 0.8, false, true)
            end

            data.AttackCooldown = data.AttackCooldown - 1
            if data.AttackCooldown <= 0 then
                local canAttack = REVEL.room:GetGridCollisionAtPos(npc.Position) == 0
                local grid = REVEL.room:GetGridEntityFromPos(npc.Position)
                if grid then
                    if not canAttack then
                        if grid.Desc.Type == GridEntityType.GRID_POOP then
                            canAttack = true
                        end
                    elseif grid.Desc.Type == GridEntityType.GRID_SPIKES or grid.Desc.Type == GridEntityType.GRID_SPIKES_ONOFF then
                        canAttack = false
                    end
                end

                if canAttack then
                    sprite:Play("Spit Fly", true)
                    data.State = "Spit"
                    npc.Velocity = Vector.Zero
                end
            end
        else
            npc.Velocity = npc.Velocity * 0.8
        end
    elseif data.State == "Spit" then
        if sprite:IsEventTriggered("Pound") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
            local grid = REVEL.room:GetGridEntityFromPos(npc.Position)
            if grid and grid.Desc.Type == GridEntityType.GRID_POOP then
                grid:Destroy(true)
            end

            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
        end

        if sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOSS_GURGLE_ROAR, 1, 0, false, 1)
        end

        if not data.TargetPosition then
            data.TargetPosition = npc:GetPlayerTarget().Position
        else
            data.TargetPosition = REVEL.Lerp(data.TargetPosition, npc:GetPlayerTarget().Position, 0.4)
        end

        if sprite:IsFinished("Spit Fly") then
            sprite:Play("SpitLoop", true)
        end

        if sprite:IsFinished("SpitEnd") then
            npc:Morph(npc.Type, npc.Variant, 0, -1)
            sprite:Play("Idle Dead", true)
        end

        if sprite:IsPlaying("SpitLoop") or (sprite:IsPlaying("Spit Fly") and sprite:WasEventTriggered("Shoot")) or (sprite:IsPlaying("SpitEnd") and not sprite:WasEventTriggered("Stop")) then
            local percentBone = 0
            if npc.HitPoints > npc.MaxHitPoints / 2.5 then
                percentBone = ((npc.HitPoints - npc.MaxHitPoints / 2.5) / (npc.MaxHitPoints / 2.5)) * 0.5
            end

            local variant = ProjectileVariant.PROJECTILE_NORMAL
            if math.random(1, 4) == 1 then
                variant = ProjectileVariant.PROJECTILE_PUKE
            elseif math.random() < percentBone then
                variant = ProjectileVariant.PROJECTILE_BONE
            end

            local dir = (data.TargetPosition - npc.Position)
            local len = dir:Length()
            local velocity = dir * (0.028 + math.random(-100, 100) * 0.00005)

            if not data.FireDelay then
                data.FireDelay = 0
            end

            data.FireDelay = data.FireDelay - 1
            if data.FireDelay <= 0 then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOSS2_BUBBLES, 0.1, 0, false, 1.2 + math.random() * 0.2)
                local p = REVEL.SpawnNPCProjectile(npc, velocity:Rotated(math.random(-2, 2)), npc.Position + RandomVector() * math.random(1, 30), variant)
                p.Height = -30
                p.FallingSpeed = -35
                p.FallingAccel = 1
                p.RenderZOffset = npc.RenderZOffset + 100
                data.FireDelay = math.random(1, 3)
            end

            if not sprite:IsPlaying("SpitEnd") then
                npc.HitPoints = npc.HitPoints - 0.1
                if npc.HitPoints <= 5 then
                    sprite:Play("SpitEnd", true)
                end
            end
        end

        npc.Velocity = npc.Velocity * 0.8
    end
end, REVEL.ENT.ANTLION.id)

end

REVEL.PcallWorkaroundBreakFunction()