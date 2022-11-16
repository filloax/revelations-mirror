REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

---------------------
-- BROTHER BLOODY --
---------------------
local brotherBloodShootColor = Color(1, 1, 1, 0.6, 0.05, 0.05, 0.3)

local DefaultTimeUntilNoHostDeath = 3

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant == REVEL.ENT.BROTHER_BLOODY.variant then

        local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

        local isFriendly = npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)

        -- if spawned in glacier becomes glacier variant
        if not data.Spawned then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
            npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            -- npc:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
            sprite:Play("CustomAppear", true)

            data.NoBrotherOrbit = true
            data.TimeUntilNoHostDeath = DefaultTimeUntilNoHostDeath
            
            if REVEL.room:GetFrameCount() <= 2 then
                data.SpawnedOnRoomInit = true
            end

            data.Spawned = true
        end

        if sprite:IsFinished("Idle") then
            if isFriendly and target.Type < 10 then
                sprite:Play("Idle", true)
            else
                sprite:Play("Shoot", true)
            end
        end

        if sprite:IsFinished("Shoot") or sprite:IsFinished("CustomAppear") then
            sprite:Play("Idle", true)
        end
        if sprite:IsPlaying("NoHostDeath") or sprite:IsPlaying("CustomAppear") then
            npc.Velocity = Vector(0,0)
        end
        if sprite:IsPlaying("Idle") or sprite:IsPlaying("Shoot") then
            sprite.PlaybackSpeed = 2/3
        else 
            sprite.PlaybackSpeed = 1 
        end

        if not sprite:IsPlaying("NoHostDeath") then
            local host = data.Host and data.Host.Ref
            -- checks if he still is rotating around a living enemy
            if not host or not host:Exists() or host:IsDead() or host.Type == 1 then
                local dist
                local newhost
                -- friendly synergy: search for the closest friendly enemy or player if no enemies
                if isFriendly then
                    local playerHost = data.PlayerHost and data.PlayerHost.Ref
                    if not playerHost or not playerHost:Exists() or playerHost:IsDead() then
                        local distPlayer
                        for _, player in ipairs(REVEL.players) do
                            local distance = player.Position:Distance(npc.Position)
                            if not distPlayer or distance < distPlayer then
                                playerHost = player
                                distPlayer = distance
                            end
                        end
                        data.PlayerHost = EntityPtr(playerHost)
                    end
                    for _, e in ipairs(REVEL.roomEnemies) do
                        if e:IsVulnerableEnemy() 
                        and not e:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) 
                        and e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) 
                        and not e:GetData().NoBrotherOrbit then
                            local distance = e.Position:Distance(npc.Position)
                            if not dist or distance < dist then
                                newhost = e
                                dist = distance
                                data.TimeUntilNoHostDeath = DefaultTimeUntilNoHostDeath
                                data.PlayerHost = nil
                            end
                        end
                    end
                    if not newhost and playerHost then
                        newhost = playerHost
                        data.TimeUntilNoHostDeath = DefaultTimeUntilNoHostDeath
                    end
                -- not friendly: search for the closest enemy
                else
                    for _, e in ipairs(REVEL.roomEnemies) do
                        if e:IsVulnerableEnemy() and REVEL.CanShutDoors(e)
                        and not e:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) 
                        and not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) 
                        and not e:GetData().NoBrotherOrbit then
                            local distance = e.Position:Distance(npc.Position)
                            if not dist or distance < dist then
                                newhost = e
                                dist = distance
                                data.TimeUntilNoHostDeath = DefaultTimeUntilNoHostDeath
                                data.PlayerHost = nil
                            end
                        end
                    end
                end
                if newhost then
                    if (not host or newhost.InitSeed ~= host.InitSeed) and npc.FrameCount > 2 then
                        sprite:Play("Idle", true)
                    end
                    data.Host = EntityPtr(newhost)
                    host = newhost
                elseif data.TimeUntilNoHostDeath > 0 then -- give some breathing room for enemies that spawn other enemies (like snowbobs)
                    data.TimeUntilNoHostDeath = data.TimeUntilNoHostDeath - 1
                else
                    sprite:Play("NoHostDeath", true)
                    npc.Velocity = Vector.Zero
                    data.Host = nil
                end
            end
            -- movement
            if host then
                if sprite:IsPlaying("CustomAppear") and data.SpawnedOnRoomInit then
                    if not data.StartPosRelativeToHost then
                        data.StartPosRelativeToHost = Vector(
                            math.sin(math.rad(npc.FrameCount * 3 + (37 * 3) + npc.InitSeed)) * 35,
                            math.cos(math.rad(npc.FrameCount * 3 + (37 * 3) + npc.InitSeed)) * 35
                        )
                        npc.Position = host.Position+data.StartPosRelativeToHost
                    end
                    local distance = host.Position:Distance(npc.Position)
                    npc.Velocity = ((host.Position + data.StartPosRelativeToHost) - npc.Position)
                        * (0.2 - math.min(math.max((distance - 50) / 500,0), 0.1))
                elseif not sprite:IsPlaying("CustomAppear") then
                    local distance = host.Position:Distance(npc.Position)
                    npc.Velocity = ((host.Position + Vector(
                        math.sin(math.rad(npc.FrameCount * 3 + npc.InitSeed)) * 35,
                        math.cos(math.rad(npc.FrameCount * 3 + npc.InitSeed)) * 35
                    )) - npc.Position) * (0.2 - math.min(math.max((distance - 50) / 500,0), 0.1))

                    if distance > 65 then
                        if not data.LostHostFrame then
                            data.LostHostFrame = npc.FrameCount
                        end
                        if npc.FrameCount >= data.LostHostFrame + 2 and npc.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE then
                            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                        end
                    else
                        if data.LostHostFrame then
                            data.LostHostFrame = nil
                        end
                        npc.Velocity = npc.Velocity + host.Velocity
                        if isFriendly then
                            if npc.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_ALL then
                                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                            end
                        else
                            if npc.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_PLAYEROBJECTS then
                                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
                            end
                        end
                    end
                end
            else
                npc.Velocity = Vector.Zero
            end
        end

        -- shooting
        if sprite:IsEventTriggered("Shoot") then
            REVEL.SpawnNPCProjectile(npc, (target.Position-npc.Position):Resized(8))
            local blood = Isaac.Spawn(1000, EffectVariant.BLOOD_EXPLOSION, 5, npc.Position, Vector.Zero, npc)
            if REVEL.STAGE.Glacier:IsStage() then
                blood:GetSprite():ReplaceSpritesheet(4, "gfx/effects/revel1/effect_002_bloodpoof_alt_glacier.png")
                blood:GetSprite():LoadGraphics()
                blood.Color = brotherBloodShootColor
            end
        
            REVEL.sfx:Play(SoundEffect.SOUND_CUTE_GRUNT, 1, 0, false, 1)
        end

        -- Exploding
        if sprite:IsEventTriggered("Explosion") then
            for i=0, 5 do
                REVEL.SpawnNPCProjectile(npc, Vector.FromAngle(i * 60) * 8)
            end
            npc:Kill()
        end
    end
end, REVEL.ENT.BROTHER_BLOODY.id)

--[[revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, data, dmg, flag, src, invuln)
    if e.Type == REVEL.ENT.BROTHER_BLOODY.id and e:GetSprite():IsPlaying("CustomAppear") then
        return false
    end
end)]]

end