return function()
    
-- Sandshaper

local NpcPathMap = REVEL.NewPathMapFromTable("Sandshaper", {
    GetTargetIndices = function()
        local sandshapers = Isaac.FindByType(REVEL.ENT.SANDSHAPER.id, REVEL.ENT.SANDSHAPER.variant, -1, false, false)
        local addedTargets = {}
        local initialTargetIndices = {}
        local targetIndices = {}
        for _, npc in ipairs(sandshapers) do
            if npc:GetData().TargetIndex then
                if not addedTargets[npc:GetData().TargetIndex] then
                    targetIndices[#targetIndices + 1] = npc:GetData().TargetIndex
                    initialTargetIndices[#initialTargetIndices + 1] = npc:GetData().TargetIndex
                    addedTargets[npc:GetData().TargetIndex] = true
                end
            end
        end

        local width, height = REVEL.room:GetGridWidth(), REVEL.room:GetGridHeight()
        for _, index in ipairs(initialTargetIndices) do
            local indx, indy = REVEL.GridToVector(index, width)
            for x = -2, 2 do
                for y = -2, 2 do
                    local nx, ny = indx + x, indy + y
                    if nx > 0 and ny > 0 and nx <= width and ny <= height then
                        local newindex = REVEL.VectorToGrid(nx, ny, width)
                        if not addedTargets[newindex] then
                            targetIndices[#targetIndices + 1] = newindex
                            addedTargets[newindex] = true
                        end
                    end
                end
            end
        end

        return targetIndices
    end,
    GetInverseCollisions = function()
        local inverseCollisions = {}
        for i = 0, REVEL.room:GetGridSize() do
            if REVEL.room:IsPositionInRoom(REVEL.room:GetGridPosition(i), 0) then
                local grid = REVEL.room:GetGridEntity(i)
                inverseCollisions[i] = REVEL.room:GetGridCollision(i) == 0 and (not grid or grid.Desc.Type ~= GridEntityType.GRID_SPIKES)
            end
        end

        return inverseCollisions
    end,
    OnPathUpdate = function(map)
        local set = map.TargetMapSets[1]
        for _, ent in ipairs(Isaac.FindByType(REVEL.ENT.SANDSHAPER.id, REVEL.ENT.SANDSHAPER.variant, -1, false, false)) do
            local data = ent:GetData()
            data.PathIndex = nil
            data.Path = REVEL.GetPathToZero(REVEL.room:GetGridIndex(ent.Position), set.Map, nil, map)
        end
    end
})

local projectileWaveTime = 20
local twoPi = math.pi * 2

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.SANDSHAPER.variant then
        return
    end

    local sandcastles = StageAPI.GetCustomGrids(nil, REVEL.GRIDENT.SAND_CASTLE.Name)
    local deadCastles = {}
    local liveCastles = {}
    for _, castle in ipairs(sandcastles) do
        local grid = castle.GridEntity
        if grid then
            if REVEL.IsGridBroken(grid) then
                deadCastles[#deadCastles + 1] = castle.GridIndex
            else
                liveCastles[#liveCastles + 1] = castle.GridIndex
            end
        end
    end

    local pathfinder, target, data, sprite = npc.Pathfinder, npc:GetPlayerTarget(), npc:GetData(), npc:GetSprite()
    if not data.State then
        data.State = "Idle"
        data.AttackCooldown = 20
        data.CounterCooldown = 60
        data.CastlesExploded = 0
        REVEL.UsePathMap(NpcPathMap, npc)
        npc.SplatColor = REVEL.SandSplatColor
    end

    data.CounterCooldown = data.CounterCooldown - 1
    if data.State == "Idle" then
        data.AttackCooldown = data.AttackCooldown - 1
        if not sprite:IsPlaying("Idle") and not sprite:IsPlaying("Appear") then
            sprite:Play("Idle", true)
        end

        local nothingToDo = true
        if data.BeenHit then
            if not data.GroundHit then
                data.GroundHit = math.random(1, 2)
            else
                data.GroundHit = data.GroundHit % 2 + 1
            end
            
            sprite:Play("GroundHit" .. tostring(data.GroundHit))
            data.State = "GroundHit"
            npc.Velocity = npc.Velocity * 0.9
            nothingToDo = false
        else
            useCastles = liveCastles
            if data.CastlesExploded >= 3 then
                useCastles = deadCastles
            end
            if #useCastles > 0 then
                local minDist, closestCastle, closestCastlePosition
                for _, castle in ipairs(useCastles) do
                    local pos = REVEL.room:GetGridPosition(castle)
                    local dist = pos:DistanceSquared(target.Position)
                    if not minDist or dist < minDist then
                        closestCastlePosition = pos
                        closestCastle = castle
                        minDist = dist
                    end
                end

                data.TargetIndex = closestCastle
                if data.Path then
                    REVEL.FollowPath(npc, 0.5, data.Path, true, 0.9)
                    nothingToDo = false
                end

                if closestCastlePosition:DistanceSquared(npc.Position) < (120 ^ 2) then
                    if data.AttackCooldown <= 0 then
                        if data.CastlesExploded >= 3 then
                            sprite:Play("Summon", true)
                            data.State = "Summon"
                            data.AttackCooldown = math.random(45, 75)
                            data.CastlesExploded = 0
                            data.UsingCastle = closestCastle
                        else
                            sprite:Play("ProjectileRaise", true)
                            data.State = "ProjectileRaise"
                            data.AttackCooldown = math.random(20, 30)
                            data.UsingCastle = closestCastle
                        end
                    elseif not data.Path then
                        pathfinder:MoveRandomly(false)
                        npc.Velocity = npc.Velocity * 0.9
                    end

                    nothingToDo = false
                end
            end
        end

        if nothingToDo then
            pathfinder:EvadeTarget(target.Position)
            npc.Velocity = npc.Velocity * 1.05 * 0.9
        end
    elseif data.State == "GroundHit" then
        npc.Velocity = npc.Velocity * 0.8
        if sprite:IsEventTriggered("ScreenShake") then
            REVEL.game:ShakeScreen(20)
        end

        if sprite:IsEventTriggered("ShockWave") then
            local waves = {
                round = 2,
                direct = 2,
                --split = 1
            }

            if data.LastShockwave then
                waves[data.LastShockwave] = 0
            end

            local wave = REVEL.WeightedRandom(waves)
            data.LastShockwave = wave

            if wave == "round" then
                --[[
                local shockwave = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SHOCKWAVE, 0, npc.Position, Vector.Zero, npc):ToEffect()
                shockwave.Parent = npc
                shockwave:SetDamageSource(REVEL.ENT.SANDSHAPER.id)]]

                for num = 1, 12 do
                    local dir = Vector.FromAngle(num * 30)
                    if num == 1 then
                        REVEL.SpawnCustomShockwave(npc.Position + dir * 25, dir * 3, "gfx/effects/revel2/tomb_shockwave.png", 20, nil, nil, nil, nil, SoundEffect.SOUND_ROCK_CRUMBLE)
                    else
                        REVEL.SpawnCustomShockwave(npc.Position + dir * 25, dir * 3, "gfx/effects/revel2/tomb_shockwave.png", 20)
                    end
                end
            elseif wave == "direct" then
                --[[
                local shockwave = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACKWAVE, 0, npc.Position, Vector.Zero, npc):ToEffect()
                shockwave.Parent = npc
                shockwave:SetDamageSource(REVEL.ENT.SANDSHAPER.id)
                shockwave.Rotation = (target.Position - npc.Position):GetAngleDegrees()]]
                local dir = (target.Position - npc.Position):Normalized()
                REVEL.SpawnCustomShockwave(npc.Position + dir * 15, dir * 8, "gfx/effects/revel2/tomb_shockwave.png", nil, nil, nil, 7, nil, SoundEffect.SOUND_ROCK_CRUMBLE)
            elseif wave == "split" then
                local dir = (target.Position - npc.Position):Normalized()
                for i = -1, 1, 2 do
                    local rotated = dir:Rotated(30 * i)
                    REVEL.SpawnCustomShockwave(npc.Position + rotated * 15, rotated * 8, "gfx/effects/revel2/tomb_shockwave.png", nil, nil, nil, 7, nil, SoundEffect.SOUND_ROCK_CRUMBLE)
                end
            end

            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
            data.BeenHit = nil
        end

        if sprite:IsFinished("GroundHit" .. tostring(data.GroundHit)) then
            data.State = "Idle"
        end
    elseif data.State == "Summon" then
        npc.Velocity = npc.Velocity * 0.8
        if sprite:IsEventTriggered("Spawn") then
            local grid = REVEL.room:GetGridEntity(data.UsingCastle)
            if grid then
                REVEL.room:RemoveGridEntity(data.UsingCastle, 0, false)
                -- REVEL.room:Update()
                local pos = REVEL.room:GetGridPosition(data.UsingCastle)
                Isaac.Spawn(REVEL.ENT.SANDBOB.id, REVEL.ENT.SANDBOB.variant, 0, pos, Vector.Zero, nil)
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SUMMONSOUND, 1, 0, false, 1)
            end
        end

        if sprite:IsFinished("Summon") then
            data.State = "Idle"
        end
    elseif data.State == "ProjectileRaise" then
        npc.Velocity = npc.Velocity * 0.8
        if sprite:IsFinished("ProjectileRaise") then
            data.RaiseTimer = 0
            sprite:Play("ProjectileRaiseLoop", true)
            if REVEL.room:GetGridEntity(data.UsingCastle) then
                REVEL.room:DamageGrid(data.UsingCastle, 3000)
                -- REVEL.room:Update()
            end
        end

        if sprite:IsPlaying("ProjectileRaiseLoop") then
            data.RaiseTimer = data.RaiseTimer + 1
            if not data.Projectiles then
                data.Projectiles = {}
            else
                for i, projectile in ripairs(data.Projectiles) do
                    if not projectile:Exists() or projectile:IsDead() then
                        table.remove(data.Projectiles, i)
                    end
                end
            end

            if #data.Projectiles < 8 then
                local castlePos = REVEL.room:GetGridPosition(data.UsingCastle)
                local spawnpos = castlePos + RandomVector() * math.random(1, 20)
                local newProjectile = REVEL.SpawnNPCProjectile(npc, (spawnpos - castlePos):Normalized(), spawnpos)
                newProjectile.Scale = 0.5
                newProjectile.Height = -7
                newProjectile.FallingAccel = -0.1
                newProjectile:GetData().SandProjectile = true
                newProjectile:GetData().IsSandTear = true
                newProjectile:GetData().Sandshaper = npc
                newProjectile:Update()
                newProjectile.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                newProjectile:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel2/sand_bulletatlas.png")
                newProjectile:GetSprite():LoadGraphics()
                newProjectile:GetSprite():Play("RegularTear1", true)
                data.Projectiles[#data.Projectiles + 1] = newProjectile
            else
                local allProjectilesAtHeight = true
                for _, projectile in ipairs(data.Projectiles) do
                    if projectile.Height > -25 then
                        allProjectilesAtHeight = false
                    end
                end

                if allProjectilesAtHeight and data.RaiseTimer > 0 then
                    sprite:Play("ProjectileShoot", true)
                end
            end
        end

        if sprite:IsEventTriggered("Shoot") then
            local direction
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_2, 1, 0, false, 1)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_LIGHTBOLT, 1, 0, false, 1.5)
            for _, projectile in ipairs(data.Projectiles) do
                projectile.FallingSpeed = 0
                projectile.Velocity = (target.Position - projectile.Position):Resized(12)
            end
        elseif data.Projectiles and not sprite:WasEventTriggered("Shoot") then
            for _, projectile in ipairs(data.Projectiles) do
                local data = projectile:GetData()
                if projectile.Height > -30 and not data.SineStarted then
                    projectile.FallingSpeed = -2
                elseif projectile.Height < -30 or data.SineStarted then
                    data.SineStarted = true
                    projectile.FallingSpeed = math.sin(twoPi * (projectile.FrameCount / projectileWaveTime))
                end
            end
        end

        if sprite:IsFinished("ProjectileShoot") then
            data.Projectiles = nil
            data.State = "Idle"
            data.CastlesExploded = data.CastlesExploded + 1
        end
    elseif data.State == "Death" then
        npc.Velocity = Vector.Zero
        if sprite:IsFinished("Death") then
            npc:Remove()
        end
    end

    if sprite:IsEventTriggered("Explode") then
        for i=1, math.random(2,3) do
            REVEL.SpawnSandGibs(npc.Position, RandomVector() * 2, npc)
        end
    
        local poof = Isaac.Spawn(1000, EffectVariant.POOF02, 1, npc.Position, Vector.Zero, npc)
        poof.SpriteScale = Vector.One * 0.6
        poof.Color = Color(0.8,0.8,0.65,1)
        REVEL.sfx:Play(SoundEffect.SOUND_DEATH_BURST_LARGE, 1, 0, false, 1)
    end

    if sprite:IsEventTriggered("Roar") then
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_1, 1, 0, false, 1)
    end
end, REVEL.ENT.SANDSHAPER.id)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
    if pro:GetData().SandProjectile and not pro:HasProjectileFlags(ProjectileFlags.NO_WALL_COLLIDE) then
        pro.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

        if pro:GetData().Sandshaper and not pro:GetData().Sandshaper:Exists() then
            pro.FallingAccel = 0.1
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount)
    if ent.Variant == REVEL.ENT.SANDSHAPER.variant then
        if ent:GetData().State == "Death" then
            return false
        end

        if ent:GetData().CounterCooldown <= 0 then
            ent:GetData().BeenHit = true
            ent:GetData().CounterCooldown = 120
        end

        if ent.HitPoints - amount - REVEL.GetDamageBuffer(ent) <= 0 then
            ent:GetData().State = "Death"
            ent:GetSprite():Play("Death", true)
            ent:BloodExplode()
            ent.HitPoints = 1
            ent.Velocity = Vector.Zero
            ent.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            return false
        end
    end
end, REVEL.ENT.SANDSHAPER.id)

end