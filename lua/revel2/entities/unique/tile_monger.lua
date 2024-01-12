return function()

-- Tile Monger

function REVEL.SpawnTileMongerTile(ind)
    local tile = StageAPI.SpawnFloorEffect(REVEL.room:GetGridPosition(ind) + Vector(0, 6), Vector.Zero, nil, "gfx/monsters/revel2/tile_monger.anm2", true)
    local sprite, data = tile:GetSprite(), tile:GetData()
    sprite:Play("TileIdle", true)
    data.TileMongerTile = true
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.TILE_MONGER.variant then
        return
    end

    local currentRoom = StageAPI.GetCurrentRoom()
    if not currentRoom then
        npc:Remove()
        return
    end

    local data, sprite = npc:GetData(), npc:GetSprite()
    if not data.State then
        data.Index = REVEL.room:GetGridIndex(npc.Position)
        data.Position = npc.Position

        if not data.PairedMonger then
            local tileMongers = Isaac.FindByType(REVEL.ENT.TILE_MONGER.id, REVEL.ENT.TILE_MONGER.variant, -1, false, false)
            for _, monger in ipairs(tileMongers) do
                local index = REVEL.room:GetGridIndex(monger.Position)

                if REVEL.IndicesShareGroup(currentRoom, data.Index, index) then
                    data.PairedMonger = monger:ToNPC()
                    monger:GetData().PairedMonger = npc
                end
            end
        end

        npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
        data.Cooldown = 15
        data.State = "Idle"
        currentRoom.Metadata:AddMetadataEntity(data.Index, "TileMongerTile")
    end
    
    REVEL.ApplyKnockbackImmunity(npc)

    if data.PairedMonger and (not data.PairedMonger:Exists() or data.PairedMonger:IsDead() or data.PairedMonger:GetData().State == "Death") then
        data.PairedMonger = nil
    end

    if not data.PairedMonger then
        for _, monger in ipairs(Isaac.FindByType(REVEL.ENT.TILE_MONGER.id, REVEL.ENT.TILE_MONGER.variant, -1, false, false)) do
            if GetPtrHash(monger) ~= GetPtrHash(npc) and not monger:GetData().PairedMonger then
                data.PairedMonger = monger
                monger:GetData().PairedMonger = npc
                break
            end
        end
    end

    if data.State == "Idle" or data.State == "Shoot" then
        if data.PairedMonger then
            sprite.FlipX = data.PairedMonger.Position.X < npc.Position.X
        else
            sprite.FlipX = npc:GetPlayerTarget().Position.X < npc.Position.X
        end
    else
        sprite.FlipX = false
    end

    if data.State == "Idle" then
        if not sprite:IsPlaying("Appear") and not sprite:IsPlaying("Idle") then
            sprite:Play("Idle", true)
        end

        data.Cooldown = data.Cooldown - 1
        if data.Cooldown <= 0 then
            data.State = "Shoot"
            sprite:Play("ShootStart", true)
        end
    elseif data.State == "Shoot" then
        if sprite:IsEventTriggered("ShootStart") then
            REVEL.sfx:NpcPlay(npc,SoundEffect.SOUND_SPEWER, 1 ,0, false, 0.8+math.random()*0.15)
            data.StartedShooting = true
            if data.PairedMonger and not data.PairedMonger:GetData().Stuck then
                data.ShotDirection = data.PairedMonger.Position - npc.Position
                data.Cooldown = 120
            else
                data.ShotDirection = nil
                data.Cooldown = 30
            end
        end

        if sprite:IsFinished("ShootStart") then
            sprite:Play("ShootLoop", true)
        end

        if data.StartedShooting then
            local timeBetweenShots = 2
            if not data.ShotDirection then
                timeBetweenShots = 2
            end

            if data.Cooldown % timeBetweenShots == 0 then
                local dir = (data.ShotDirection or (npc:GetPlayerTarget().Position - npc.Position)):Rotated(math.random(-5, 5))
                Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, 0, npc.Position, dir:Resized(10), nil)
                REVEL.sfx:NpcPlay(npc,SoundEffect.SOUND_BLOODSHOOT, 0.5, 0, false, 1.2)
            end

            data.Cooldown = data.Cooldown - 1
            if data.Cooldown <= 0 or (data.ShotDirection and (not data.PairedMonger or data.PairedMonger:GetData().State ~= "Shoot")) then
                sprite:Play("ShootEnd", true)
                data.StartedShooting = nil
            end
        end

        if sprite:IsFinished("ShootEnd") then
            sprite:Play("Submerge", true)
            data.State = "Submerge"
        end
    elseif data.State == "Submerge" then
        if sprite:IsFinished("Submerge") and (not data.PairedMonger or data.PairedMonger:GetSprite():IsFinished("Submerge")) then
            local tileMongers = Isaac.FindByType(REVEL.ENT.TILE_MONGER.id, REVEL.ENT.TILE_MONGER.variant, -1, false, false)
            local readyMongers = {}
            local tileMongerFreeTiles = {}

            for _, monger in ipairs(tileMongers) do
                if monger:GetSprite():IsFinished("Submerge") and (not monger:GetData().PairedMonger or monger:GetData().PairedMonger:GetSprite():IsFinished("Submerge")) then
                    readyMongers[#readyMongers + 1] = monger
                    tileMongerFreeTiles[monger:GetData().Index] = true
                end
            end

            local floorEffects = Isaac.FindByType(StageAPI.E.FloorEffect.T, StageAPI.E.FloorEffect.V, -1, false, false)
            for _, eff in ipairs(floorEffects) do
                if eff:GetData().TileMongerTile then
                    local index = REVEL.room:GetGridIndex(eff.Position)
                    tileMongerFreeTiles[index] = true
                    readyMongers[#readyMongers + 1] = eff
                end
            end

            local freeSingleIndices = {}
            local freeIndexPairs = {}
            local tileMongerTiles = currentRoom.Metadata:Search{Name = "TileMongerTile"}
            for _, metaEntity in ipairs(tileMongerTiles) do
                local index = metaEntity.Index
                if tileMongerFreeTiles[index] then
                    freeSingleIndices[#freeSingleIndices + 1] = index

                    for __, metaEntity2 in ipairs(tileMongerTiles) do
                        local index2 = metaEntity2.Index
                        if index2 ~= index and tileMongerFreeTiles[index2] and REVEL.IndicesShareGroup(currentRoom, index, index2) then
                            freeIndexPairs[#freeIndexPairs + 1] = {index, index2}
                            freeSingleIndices[#freeSingleIndices + 1] = index2
                        end
                    end
                end
            end

            for _, monger in ipairs(readyMongers) do
                local isTile = monger:GetData().TileMongerTile
                if isTile or monger:GetData().State ~= "Arise" then
                    local usePair
                    if not isTile and monger:GetData().PairedMonger and #freeIndexPairs > 0 then
                        usePair = freeIndexPairs[math.random(1, #freeIndexPairs)]
                        local useIndex = math.random(0, 1)
                        local otherIndex = (useIndex + 1) % 2
                        useIndex = usePair[useIndex + 1]
                        otherIndex = usePair[otherIndex + 1]

                        for i = 1, 2 do
                            local modifyingData, modifyingIndex, modifyingSprite
                            if i == 1 then
                                modifyingData, modifyingIndex, modifyingSprite = monger:GetData(), useIndex, monger:GetSprite()
                            else
                                modifyingData, modifyingIndex, modifyingSprite = monger:GetData().PairedMonger:GetData(), otherIndex, monger:GetData().PairedMonger:GetSprite()
                            end

                            modifyingData.Index = modifyingIndex
                            modifyingData.Position = REVEL.room:GetGridPosition(modifyingIndex)
                            modifyingData.State = "Arise"
                            modifyingData.Cooldown = 15
                            modifyingData.Stuck = nil
                            modifyingSprite:Play("TileShakeStart", true)
                        end
                    elseif #freeSingleIndices > 0 then
                        local useIndex = freeSingleIndices[math.random(1, #freeSingleIndices)]
                        usePair = {useIndex}

                        if not isTile then
                            monger:GetData().Index = useIndex
                            monger:GetData().Position = REVEL.room:GetGridPosition(useIndex)
                            monger:GetData().State = "Arise"
                            monger:GetData().Cooldown = 15
                            monger:GetData().Stuck = nil
                            monger:GetSprite():Play("TileShakeStart", true)
                        else
                            monger.Position = REVEL.room:GetGridPosition(useIndex) + Vector(0, 6)
                        end
                    end

                    for i, pair in ripairs(freeIndexPairs) do
                        for _, index in ipairs(pair) do
                            if REVEL.includes(usePair, index) then
                                table.remove(freeIndexPairs, i)
                            end
                        end
                    end

                    for i, index in ripairs(freeSingleIndices) do
                        for _, index2 in ipairs(usePair) do
                            if index == index2 then
                                table.remove(freeSingleIndices, i)
                            end
                        end
                    end
                end
            end
        end
    elseif data.State == "Arise" then
        if sprite:IsFinished("TileShakeStart") then
            sprite:Play("TileShake", true)
        end

        if sprite:IsPlaying("TileShake") then
            data.Cooldown = data.Cooldown - 1
            local heldDown
            for _, player in ipairs(REVEL.players) do
                if player.Position:DistanceSquared(npc.Position) < player.Size + npc.Size ^ 2 then
                    data.Stuck = true
                    heldDown = true
                end
            end

            if data.Cooldown <= 0 and not data.Stuck then
                sprite:Play("Appear", true)
                data.State = "Idle"
                data.Cooldown = 15
            elseif data.Stuck then
                if (data.PairedMonger and data.PairedMonger:GetSprite():IsFinished("Submerge")) or not data.PairedMonger or not heldDown then
                    sprite:SetFrame("Submerge", 15)
                    data.State = "Submerge"
                end
            end
        end
    elseif data.State == "Death" then
        if sprite:IsEventTriggered("Explode") then
            npc:BloodExplode()
        end

        if sprite:IsFinished("Death") then
            REVEL.SpawnTileMongerTile(data.Index)
            npc:Remove()
        end
    end

    if sprite:IsEventTriggered("DMG") then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
    elseif sprite:IsEventTriggered("NoDMG") then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    end

    npc.Position = data.Position + Vector(0, 6)
    npc.Velocity = Vector.Zero
end, REVEL.ENT.TILE_MONGER.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount)
    if ent.Variant == REVEL.ENT.TILE_MONGER.variant and ent.HitPoints - amount - REVEL.GetDamageBuffer(ent) <= 0 then
        ent.HitPoints = 0
        if ent:GetData().State ~= "Death" then
            ent:GetSprite():Play("Death", true)
            ent:GetData().State = "Death"
        end

        return false
    end
end, REVEL.ENT.TILE_MONGER.id)

end