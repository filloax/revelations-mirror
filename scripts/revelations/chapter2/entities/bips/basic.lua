local GridUnbrokenState = require("scripts.revelations.common.enums.GridUnbrokenState")

return function()

-- Sandbob, Sandbit, Demobip, Bloatbip

function REVEL.SandFamilyMove(npc, speed, friction, sprite, data, digSuffix, chasePrefix, targetPos)
    sprite = sprite or npc:GetSprite()
    data = data or REVEL.GetData(npc)

    digSuffix = digSuffix or ""
    chasePrefix = chasePrefix or "Chase"

    if sprite:IsEventTriggered("Burrow") then
        REVEL.sfx:NpcPlay(npc, REVEL.SFX.BIP_BURROW, 0.6, 0, false, 1)
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
    end

    if sprite:IsEventTriggered("Emerge") then
        REVEL.sfx:NpcPlay(npc, REVEL.SFX.BIP_EMERGE, 0.6, 0, false, 1)
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
    end

    if npc.FrameCount < 5 then
        npc.Velocity = npc.Velocity * friction
    elseif data.Path then
        if not data.MoveState or data.MoveState == "Pathfinding" then
            if sprite:IsFinished(chasePrefix .. "Start") or sprite:IsFinished("Charge") or sprite:IsFinished("DigOut" .. digSuffix) then
                sprite:Play(chasePrefix .. "Loop", true)
            end

            if sprite:IsPlaying(chasePrefix .. "Loop") or sprite:WasEventTriggered("Dash") then
                REVEL.FollowPath(npc, speed, data.Path, true, friction)
            else
                npc.Velocity = npc.Velocity * friction
            end

            data.MoveState = "Pathfinding"
        elseif data.MoveState == "Burrowing" then
            if not data.FramesSinceBurrowing then
                data.FramesSinceBurrowing = 0
            end

            data.FramesSinceBurrowing = data.FramesSinceBurrowing + 1

            if data.FramesSinceBurrowing > 10 then
                sprite:Play("DigOut" .. digSuffix, true)
                data.MoveState = "Pathfinding"
                data.FramesSinceBurrowing = nil
            else
                REVEL.FollowPath(npc, 5, data.Path, true, 0)
            end
        end
    else
        if not data.MoveState or data.MoveState == "Pathfinding" then
            sprite:Play("DigIn" .. digSuffix, true)
            data.MoveState = "Burrowing"
        elseif data.MoveState == "Burrowing" then
            if sprite:IsFinished("DigIn" .. digSuffix) then
                sprite:Play("Burrowed", true)
            end

            if sprite:WasEventTriggered("Burrow") or sprite:IsFinished("Burrowed") or sprite:IsPlaying("Burrowed") then
                npc.Velocity = ((targetPos or npc:GetPlayerTarget().Position) - npc.Position):Resized(5)
            end
        end
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.SANDBOB.variant then
        return
    end

    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

    npc.SplatColor = REVEL.SandSplatColor

    if sprite:IsEventTriggered("Sound") then
        REVEL.sfx:NpcPlay(npc, REVEL.SFX.BOB_CRY, 0.6, 0, false, 1)
    end

    REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)

    if not data.Init then
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        sprite:Play("Burrowed", true)
        data.Init = true
        data.State = "WaitForCastle"
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    end

    if data.State == "WaitForCastle" then
        local sandcastles = StageAPI.GetCustomGrids(nil, REVEL.GRIDENT.SAND_CASTLE.Name)
        local deadCastles = 0
        for _, castle in ipairs(sandcastles) do
            local grid = REVEL.room:GetGridEntity(castle.GridIndex)
            if grid and REVEL.IsGridBroken(grid) then
                deadCastles = deadCastles + 1
            end
        end

        if deadCastles >= 2 or #sandcastles == 0 then
            data.State = "Emerge"
            sprite:Play("DigOutLong")
        end
    elseif data.State == "Emerge" then
        if sprite:IsEventTriggered("Emerge") then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.BIP_EMERGE, 0.6, 0, false, 1)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        end

        if sprite:IsFinished("DigOutLong") then
            sprite:Play("ChaseStart", true)
            data.State = "Chase"
        end
    elseif data.State == "Chase" then
        REVEL.SandFamilyMove(npc, 1.5, 0.75, sprite, data, " Fast")
        sprite.FlipX = npc.Velocity.X > 0
    end

    if npc:IsDead() then
        local deadCastles = {}
        for _, castle in ipairs(StageAPI.GetCustomGrids(nil, REVEL.GRIDENT.SAND_CASTLE.Name)) do
            local grid = REVEL.room:GetGridEntity(castle.GridIndex)
            if grid and REVEL.IsGridBroken(grid) then
                deadCastles[#deadCastles + 1] = castle.GridIndex
            end
        end

        for i = 1, 3 do
            local dir = RandomVector()
            local bip = Isaac.Spawn(REVEL.ENT.SANDBIP.id, REVEL.ENT.SANDBIP.variant, 0, npc.Position + dir * 10, dir * 5, npc)
            REVEL.GetData(bip).Init = true
            bip:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            if #deadCastles > 0 then
                bip:GetSprite():Play("ChaseStart", true)
                REVEL.GetData(bip).State = "RepairCastle"
                REVEL.GetData(bip).TargetIndices = deadCastles
            else
                bip:GetSprite():Play("ScaredStart", true)
                REVEL.GetData(bip).State = "FleePlayer"
            end
        end
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector.Zero, npc)
    end
end, REVEL.ENT.SANDBOB.id)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.SANDBIP.variant then
        return
    end

    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

    npc.SplatColor = REVEL.SandSplatColor

    local sandcastles = StageAPI.GetCustomGrids(nil, REVEL.GRIDENT.SAND_CASTLE.Name)
    local deadCastles = {}
    for _, castle in ipairs(sandcastles) do
        local grid = REVEL.room:GetGridEntity(castle.GridIndex)
        if grid and REVEL.IsGridBroken(grid) then
            local beingRepaired
            for _, bip in ipairs(Isaac.FindByType(REVEL.ENT.SANDBIP.id, REVEL.ENT.SANDBIP.variant, -1, false, false)) do
                if REVEL.GetData(bip).RepairingCastle == castle.GridIndex then
                    beingRepaired = true
                end
            end

            if not beingRepaired then
                deadCastles[#deadCastles + 1] = castle.GridIndex
            end
        end
    end

    REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)

    if not data.Init then
        data.State = "Appear"
        sprite:Play('Appear', true)
        data.Init = true
    end

    local hasActiveEnemy
    for _, enemy in ipairs(REVEL.roomEnemies) do
        if enemy.CanShutDoors and enemy:IsActiveEnemy(true) and not (enemy.Type == REVEL.ENT.URNY.id and enemy.Variant == REVEL.ENT.URNY.variant) and not (enemy.Type == REVEL.ENT.SANDBIP.id and enemy.Variant == REVEL.ENT.SANDBIP.variant) then
            hasActiveEnemy = true
            break
        end
    end

    if not hasActiveEnemy and data.State ~= "RepairingCastle" and data.State ~= "ChargePlayer" and data.State ~= "Appear" then
        sprite:Play("Charge", true)
        data.State = "ChargePlayer"
        data.TargetIndices = nil
    end

    if data.State == "Appear" then
        if not sprite:IsPlaying("Appear") then
            if #deadCastles > 0 then
                sprite:Play("ChaseStart", true)
                data.State = "RepairCastle"
                data.TargetIndices = deadCastles
            else
                sprite:Play("ScaredStart", true)
                data.State = "FleePlayer"
            end
        end
    elseif data.State == "RepairCastle" then
        if #deadCastles == 0 then
            sprite:Play("ScaredStart", true)
            data.State = "FleePlayer"
        else
            data.TargetIndices = deadCastles
            REVEL.SandFamilyMove(npc, 0.6, 0.9, sprite, data, " Fast")

            local index = REVEL.room:GetGridIndex(npc.Position)
            if REVEL.includes(deadCastles, index) then
                data.RepairingCastle = index
                data.State = "RepairingCastle"
                sprite:Play("ChaseStop", true)
                npc.Velocity = Vector.Zero
            end
        end
    elseif data.State == "RepairingCastle" then
        if sprite:IsFinished("ChaseStop") then
            sprite:Play("DigIn", true)
        end

        npc.Velocity = npc.Velocity * 0.8 + (REVEL.room:GetGridPosition(data.RepairingCastle) - npc.Position):Resized(0.2)

        if sprite:IsEventTriggered("Burrow") then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.BIP_BURROW, 0.6, 0, false, 1)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
        end

        if sprite:IsFinished("DigIn") then
            local grid = REVEL.room:GetGridEntity(data.RepairingCastle)
            if grid then
                grid.State = GridUnbrokenState.UNBROKEN_POOP
                Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, REVEL.room:GetGridPosition(data.RepairingCastle), Vector.Zero, npc)
                REVEL.UpdateSandCastleFrames()
            end
            npc:Remove()
        end
    elseif data.State == "FleePlayer" then
        if #deadCastles > 0 then
            sprite:Play("ChaseStart", true)
            data.State = "RepairCastle"
            data.TargetIndices = deadCastles
        else
            if not sprite:IsPlaying("ScaredStart") and not sprite:IsPlaying("ScaredLoop") then
                sprite:Play("ScaredLoop", true)
            end

            if not data.FleeAngle or math.random() < 0.1 then
                data.FleeAngle = math.random(-45, 45)
            end

            npc.Velocity = npc.Velocity * 0.9 + (npc.Position - npc:GetPlayerTarget().Position):Rotated(data.FleeAngle):Resized(0.6)
        end
    elseif data.State == "ChargePlayer" then
        data.TargetIndices = nil
        REVEL.SandFamilyMove(npc, 0.65, 0.85, sprite, data, " Fast", "Charge")
    end

    sprite.FlipX = npc.Velocity.X > 0
end, REVEL.ENT.SANDBIP.id)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.DEMOBIP.variant then
        return
    end

    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

    npc.SplatColor = REVEL.SandSplatColor

    REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)

    if not data.Init then
        data.Init = true
        data.State = "Appear"
        sprite:Play("Appear", true)
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
    end

    if data.State == "Appear" then
        if not sprite:IsPlaying("Appear") then
            sprite:Play("ChaseStart", true)
            data.State = "Chase"
        end

        npc.Velocity = npc.Velocity * 0.75
    elseif data.State == "Chase" then
        REVEL.SandFamilyMove(npc, 0.65, 0.85, sprite, data, " Fast")
        sprite.FlipX = npc.Velocity.X > 0
    end

    local target = npc:GetPlayerTarget()
    if npc:IsDead() or target.Position:DistanceSquared(npc.Position) < (target.Size + npc.Size + 4) ^ 2 then
        Isaac.Explode(npc.Position, npc, 10)
        if not npc:IsDead() then
            npc:Remove()
        end
    end
end, REVEL.ENT.DEMOBIP.id)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.BLOATBIP.variant then
        return
    end

    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

    npc.SplatColor = REVEL.SandSplatColor

    REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)

    if not data.Init then
        data.Init = true
        data.State = "Appear"
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
    end

    if data.State == "Appear" then
        if not sprite:IsPlaying("Appear") then
            data.State = "Idle"
        end

        npc.Velocity = npc.Velocity * 0.75
    elseif data.State == "Idle" then
        if not sprite:IsPlaying("Idle") then
            sprite:Play("Idle", true)
        end

        REVEL.MoveRandomly(npc, 180, 4, 8, 0.2, 0.8, npc.Position)

        if data.Path then
            sprite:Play("ChaseStart", true)
            data.State = "Chase"
        end

        sprite.FlipX = false
    elseif data.State == "Chase" then
        if data.Path then
            if sprite:IsFinished("ChaseStart") then
                sprite:Play("ChaseLoop", true)
            end

            if sprite:IsPlaying("ChaseLoop") or sprite:WasEventTriggered("Dash") then
                REVEL.FollowPath(npc, 0.65, data.Path, true, 0.85)
            end

            if sprite:IsPlaying("ChaseLoop") and npc.Position:DistanceSquared(npc:GetPlayerTarget().Position) < 100 ^ 2 then
                sprite:Play("Charge", true)
                data.State = "Charge"
            end

            sprite.FlipX = npc.Velocity.X > 0
        else
            data.State = "Idle"
        end
    elseif data.State == "Charge" then
        if sprite:IsFinished("Charge") then
            sprite:Play("ChargeLoop", true)
        end

        if sprite:IsEventTriggered("Charge") then
            data.ChargeVel = ((npc:GetPlayerTarget().Position+npc:GetPlayerTarget().Velocity*2)-npc.Position):Resized(12)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BLACK_POOF, 0.4, 0, false, 3)
        end

        if data.ChargeVel then
            npc.Velocity = REVEL.Lerp(npc.Velocity, data.ChargeVel, 0.2)
            sprite.FlipX = npc.Velocity.X > 0
        end

        data.ChargeTimer = data.ChargeTimer or 15
        if data.ChargeTimer > 0 then
            data.ChargeTimer = data.ChargeTimer - 1
        else
            data.ChargeTimer = nil
            sprite:Play("ChaseStop", true)
            data.State = "Shoot"
        end

    elseif data.State == "Shoot" then
        if sprite:IsFinished("ChaseStop") then
            sprite:Play("Shoot", true)
        end

        if sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.BIP_CRY, 0.6)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BLOODSHOOT)
            for i = 1, math.random(8, 12) do
                local newProjectile = npc:FireBossProjectiles(1, npc:GetPlayerTarget().Position, 4, ProjectileParams())
                newProjectile.Velocity = newProjectile.Velocity * 0.9
                newProjectile.Scale = 0.5
                REVEL.GetData(newProjectile).SandProjectile = true
                REVEL.GetData(newProjectile).IsSandTear = true
                newProjectile:Update()
                newProjectile.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                newProjectile:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel2/sand_bulletatlas.png")
                newProjectile:GetSprite():LoadGraphics()
                newProjectile:GetSprite():Play("RegularTear1", true)
            end
        end

        if sprite:IsFinished("Shoot") then
            data.State = "Idle"
        end

        npc.Velocity = npc.Velocity * 0.85
    end
end, REVEL.ENT.BLOATBIP.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
    if (npc.Variant < REVEL.ENT.SANDBIP.variant or npc.Variant > REVEL.ENT.BLOATBIP.variant) and npc.Variant ~= REVEL.ENT.SANDBOB.variant then
        return
    end

    local gibsAmount = math.random(3,4)
    if npc.Variant == REVEL.ENT.SANDBOB.variant then
        gibsAmount = math.random(5,7)
    end
    for i=1, gibsAmount do
        REVEL.SpawnSandGibs(npc.Position, RandomVector() * 2, npc)
    end
end, REVEL.ENT.SANDBOB.id)

end