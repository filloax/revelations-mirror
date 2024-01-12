return function()

-- Trenchbip

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.TRENCHBIP.variant then
        return
    end

    local data, sprite = npc:GetData(), npc:GetSprite()

    data.CryTimer = data.CryTimer or math.random(0,149)
    if data.CryTimer ~= 150 then
        data.CryTimer = data.CryTimer+1
    end
    if data.CryTimer == 150 then
        REVEL.sfx:NpcPlay(npc, REVEL.SFX.BIP_CRY, 0.6)
        data.CryTimer = math.random(0,50)
    end

    if not data.State then
        data.State = "Submerged"
        data.Post = npc.Position
        npc.SplatColor = REVEL.SandSplatColor
    end

    if data.State == "Submerged" then
        if not sprite:IsPlaying("SubmergedIdle") and not sprite:IsPlaying("Submerge") then
            sprite:IsPlaying("SubmergedIdle", true)
        end

        if not data.SandstormPulled then
            npc.Velocity = Vector.Zero
        end

        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY

        local sandcastles = StageAPI.GetCustomGrids(nil, REVEL.GRIDENT.SAND_CASTLE.Name)
        local hasCastle
        for _, castle in ipairs(sandcastles) do
            local grid = REVEL.room:GetGridEntity(castle.GridIndex)
            if grid and not REVEL.IsGridBroken(grid)
            and REVEL.room:GetGridPosition(castle.GridIndex):DistanceSquared(npc.Position) < 75 ^ 2 then
                hasCastle = true
                break
            end
        end

        local impale
        for _, player in ipairs(REVEL.players) do
            if player.Position:DistanceSquared(npc.Position) < 50 ^ 2 then
                impale = true
                break
            end
        end

        if not impale and npc:GetPlayerTarget().Position:DistanceSquared(npc.Position) < 50 ^ 2 then
            impale = true
        end

        if not hasCastle then
            data.State = "Chase"
            sprite:Play("Impale", true)
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.BIP_EMERGE, 0.6, 0, false, 1)
        elseif impale then
            data.State = "Impale"
            sprite:Play("Impale", true)
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.BIP_EMERGE, 0.6, 0, false, 1)
        end
    elseif data.State == "Impale" then
        if sprite:IsFinished("Impale") then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            data.ChaseTimer = 30
            sprite:Play("Move", true)
        end

        if sprite:IsPlaying("Move") then
            if data.ChaseTimer then
                data.ChaseTimer = data.ChaseTimer - 1
                if data.ChaseTimer <= 0 then
                    data.ChaseTimer = nil
                end

                npc.Velocity = npc.Velocity * 0.8 + (npc:GetPlayerTarget().Position - npc.Position):Resized(1)
            else
                if npc.Position:DistanceSquared(data.Post) < npc.Size ^ 2 then
                    data.State = "Submerged"
                    sprite:Play("Submerge", true)
                    REVEL.sfx:NpcPlay(npc, REVEL.SFX.BIP_BURROW, 0.6, 0, false, 1)
                else
                    npc.Velocity = npc.Velocity * 0.8 + (data.Post - npc.Position):Resized(1)
                end
            end

            sprite.FlipX = npc.Velocity.X > 0
        else
            if not data.SandstormPulled then
                npc.Velocity = Vector.Zero
            end
        end
    elseif data.State == "Chase" then
        if sprite:IsFinished("Impale") then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            sprite:Play("Move", true)
        end

        if not sprite:IsPlaying("Impale") and not sprite:IsPlaying("Move") then
            sprite:Play("Impale", true)
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.BIP_EMERGE, 0.6, 0, false, 1)
        end

        if sprite:IsPlaying("Move") then
            npc.Velocity = npc.Velocity * 0.8 + (npc:GetPlayerTarget().Position - npc.Position):Resized(1)
        end

        sprite.FlipX = npc.Velocity.X > 0
    end

    data.SandstormPulled = false
end, REVEL.ENT.TRENCHBIP.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
    if npc.Variant == REVEL.ENT.TRENCHBIP.variant then
        for i=1, math.random(3,4) do
            REVEL.SpawnSandGibs(npc.Position, RandomVector() * 2, npc)
        end
    end
end, REVEL.ENT.TRENCHBIP.id)


end