REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Mother Pucker

local puckerStartHeight = Vector(0, -10)
local puckerFallSpeed = -3
local puckerFallAccel = 1

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    local data = npc:GetData()
    if data.JustSpawnedPucker then
        data.FallSpeed = data.FallSpeed + puckerFallAccel
        local newHeight = npc.SpriteOffset.Y + data.FallSpeed
        if newHeight > 0 then
            newHeight = 0
            data.JustSpawnedPucker = nil
        end

        npc.SpriteOffset = Vector(0, newHeight)
    end
end, REVEL.ENT.PUCKER.id)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.MOTHER_PUCKER.variant then
        return
    end

    local data, sprite = npc:GetData(), npc:GetSprite()

    if not data.State then
        data.State = "Idle"
    end

    npc.Velocity = Vector.Zero
    if data.State == "Idle" then
        if not sprite:IsPlaying("Idle") then
            sprite:Play("Idle", true)
        end

        if not data.AttackCooldown then
            data.AttackCooldown = math.random(25, 55)
        end

        data.AttackCooldown = data.AttackCooldown - 1
        if data.AttackCooldown <= 0 then
            data.AttackCooldown = nil
            local attacks = {
                Shoot = 3,
                Sucker = 2
            }

            if (Isaac.CountEntities(npc, REVEL.ENT.PUCKER.id, REVEL.ENT.PUCKER.variant, -1) or 0) < 2 then
                attacks.Pucker = 1
            end

            local attack = REVEL.WeightedRandom(attacks)

            if attack == "Shoot" then
                data.State = "Shoot"
                sprite:Play("Shoot", true)
            elseif attack == "Sucker" then
                data.State = "SpawnSucker"
                local target = npc:GetPlayerTarget()
                data.Direction = (target.Position - npc.Position):Resized(1)
                if target.Position.X < npc.Position.X then
                    sprite:Play("SpawnLeft", true)
                else
                    sprite:Play("SpawnRight", true)
                end
            else
                data.State = "SpawnPucker"
                sprite:Play("Spawn2", true)
            end
        end
    elseif data.State == "Dig" then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        if sprite:IsFinished("DigIn") or sprite:IsFinished("Spawn2") then
            local validPositions = {}
            for i = 0, REVEL.room:GetGridSize() do
                local pos = REVEL.room:GetGridPosition(i)
                if REVEL.room:IsPositionInRoom(pos, 0) then
                    if REVEL.room:GetGridCollision(i) == 0 then
                        local nearAvoidPos = npc.Position:DistanceSquared(pos) < 100 * 100
                        if not nearAvoidPos then
                            for _, player in ipairs(REVEL.players) do
                                if player.Position:DistanceSquared(pos) < 100 * 100 then
                                    nearAvoidPos = true
                                    break
                                end
                            end
                        end

                        if not nearAvoidPos then
                            validPositions[#validPositions + 1] = pos
                        end
                    end
                end
            end

            npc.Position = validPositions[math.random(1, #validPositions)]
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEATHEADSHOOT, 1, 0, false, 1)
            sprite:Play("DigOut", true)
        end

        if sprite:IsFinished("DigOut") then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            data.State = "Idle"
        end
    elseif data.State == "Shoot" then
        if sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_HEARTOUT, 1, 0, false, 1)
            local target = npc:GetPlayerTarget()
            local dir = target.Position - npc.Position
            local p = Isaac.Spawn(9, 0, 0, npc.Position, dir * 0.0325, npc):ToProjectile()
            p:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revelcommon/intense_projectiles.png")
            p:GetSprite():LoadGraphics()
            p:GetData().PunkerBigShot = true
            p.Scale = 2
            p.SpawnerEntity = npc
            p.Height = -75
            p.FallingSpeed = -20
            p.FallingAccel = 1
        end

        if sprite:IsFinished("Shoot") then
            data.State = "Dig"
            sprite:Play("DigIn", true)
        end
    elseif data.State == "SpawnSucker" then
        if sprite:IsEventTriggered("Spawn") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_HEARTOUT, 1, 0, false, 1)
            local suck = Isaac.Spawn(EntityType.ENTITY_SUCKER, 0, 0, npc.Position + data.Direction * 10, data.Direction * 4, npc)
            suck.RenderZOffset = npc.RenderZOffset + 1
            suck:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        end

        if sprite:IsFinished("SpawnLeft") or sprite:IsFinished("SpawnRight") then
            data.State = "Dig"
            sprite:Play("DigIn", true)
        end
    elseif data.State == "SpawnPucker" then
        if sprite:IsEventTriggered("PuckerSpawn") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_HEARTOUT, 1, 0, false, 1)
            local puck = Isaac.Spawn(REVEL.ENT.PUCKER.id, REVEL.ENT.PUCKER.variant, 0, npc.Position, Vector.Zero, npc)
            puck.SpawnerEntity = npc
            puck:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            puck:GetData().FallSpeed = puckerFallSpeed
            puck:GetData().JustSpawnedPucker = true
            puck.SpriteOffset = puckerStartHeight
            puck.RenderZOffset = npc.RenderZOffset + 1
            data.State = "Dig"
        end
    end
end, REVEL.ENT.MOTHER_PUCKER.id)

end

REVEL.PcallWorkaroundBreakFunction()