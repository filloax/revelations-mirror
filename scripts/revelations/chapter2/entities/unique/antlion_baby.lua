return function()

do -- Antlion Baby

    revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
        if npc.Variant == REVEL.ENT.ANTLION_BABY.variant then
            local data, sprite = REVEL.GetData(npc), npc:GetSprite()

            if not data.Init then
                --[[
                local fireDelay = 0
                for _, player in ipairs(REVEL.players) do
                    fireDelay = fireDelay + player.MaxFireDelay
                end
                npc.MaxHitPoints = math.ceil(10 / fireDelay)
                npc.HitPoints = npc.MaxHitPoints]]
                if not npc:HasEntityFlags(EntityFlag.FLAG_APPEAR) 
                and not sprite:IsPlaying("Appear") 
                and not sprite:IsPlaying("Emerge") 
                and not sprite:IsPlaying("GroundShake") then
                    data.SetWalking = true
                end
                if sprite:IsPlaying("GroundShake") then
                    data.GroundShakeTimer = data.GroundShakeTimer or 20
                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                end
                data.SpawnPosition = npc.Position
                data.Init = true
            end

            if sprite:IsFinished("Appear") or sprite:IsFinished("Emerge") or sprite:GetAnimation() == "" then
                data.SetWalking = true
            end

            if not data.IsEnraged then
                for _, sandy in ipairs(Isaac.FindByType(REVEL.ENT.SANDY.id, REVEL.ENT.SANDY.variant, -1, false, false)) do
                    local sandyData = REVEL.GetData(sandy)
                    if sandyData.StartedFight then
                        data.IsEnraged = true
                    end
                end
            end

            if sprite:IsPlaying("GroundShake") then
                data.GroundShakeTimer = data.GroundShakeTimer - 1
                if data.GroundShakeTimer <= 0 then
                    sprite:Play("Emerge", true)
                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                end
            elseif data.SetWalking or sprite:IsPlaying("WalkDown") or sprite:IsPlaying("WalkUp") or sprite:IsPlaying("WalkHori") or sprite:IsPlaying("IdleDown") or sprite:IsPlaying("IdleUp") or sprite:IsPlaying("IdleHori") then
                data.SetWalking = false

                local doWalkAnim = false
                if data.IsEnraged then
                    if npc.CollisionDamage < 1 then
                        npc.CollisionDamage = 1
                    end
                    REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)
                    if data.Path then
                        REVEL.FollowPath(npc, 0.5, data.Path, true, 0.9)
                    end
                    doWalkAnim = true
                else
                    if npc.CollisionDamage > 0 then
                        npc.CollisionDamage = 0
                    end
                    if data.IdleTimer then
                        data.IdleTimer = data.IdleTimer - 1
                        if data.IdleTimer <= 0 then
                            data.IdleTimer = nil
                        end
                    else
                        if not data.WalkTimer then
                            data.WalkTo = data.SpawnPosition + Vector(math.random(-100,100),math.random(-100,100))
                            data.WalkTimer = math.random(10,30)
                        end
                        if data.WalkTimer <= 0 or data.WalkTo:Distance(npc.Position) <= 10 then
                            data.WalkTimer = nil
                            data.IdleTimer = math.random(20,40)
                        else
                            npc.Velocity = (npc.Velocity * 0.5) + (data.WalkTo - npc.Position):Resized(0.9)
                            doWalkAnim = true
                            data.WalkTimer = data.WalkTimer - 1
                        end
                    end
                end

                if doWalkAnim then
                    REVEL.AnimateWalkFrame(sprite, npc.Velocity, {Up = "WalkUp", Down = "WalkDown", Horizontal = "WalkHori"})
                else
                    npc.Velocity = npc.Velocity * 0.5
                    if sprite:IsPlaying("WalkDown") then
                        sprite:Play("IdleDown", true)
                    elseif sprite:IsPlaying("WalkUp") then
                        sprite:Play("IdleUp", true)
                    elseif sprite:IsPlaying("WalkHori") then
                        sprite:Play("IdleHori", true)
                    end
                end
            else
                npc.Velocity = npc.Velocity * 0.9
            end

            if sprite:IsFinished("Burrow") then
                npc:Remove()
            end
        end
    end, REVEL.ENT.ANTLION_BABY.id)

    revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, entity)
        if entity.Variant == REVEL.ENT.ANTLION_BABY.variant then
            for _, sandy in ipairs(Isaac.FindByType(REVEL.ENT.SANDY.id, REVEL.ENT.SANDY.variant, -1, false, false)) do
                local sandyData = REVEL.GetData(sandy)
                if sandy:Exists() and not sandy:IsDead()
                and not sandyData.StartedFight then
                    sandyData.StartFightCounter = sandyData.StartFightCounter - 2
                end
            end
        end
    end, REVEL.ENT.ANTLION_BABY.id)

    revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flags, source, countdown)
        if ent:IsActiveEnemy(true) and Isaac.CountEntities(nil, REVEL.ENT.ANTLION_BABY.id, REVEL.ENT.ANTLION_BABY.variant, -1) > 0 then
            local getEnraged = true
            for _, sandy in ipairs(Isaac.FindByType(REVEL.ENT.SANDY.id, REVEL.ENT.SANDY.variant, -1, false, false)) do
                local sandyData = REVEL.GetData(sandy)
                if not sandyData.StartedFight then
                    getEnraged = false
                end
            end
            if getEnraged then
                for _, baby in ipairs(Isaac.FindByType(REVEL.ENT.ANTLION_BABY.id, REVEL.ENT.ANTLION_BABY.variant, -1, false, false)) do
                    REVEL.GetData(baby).IsEnraged = true
                end
            end
        end
    end)

    --[[
    revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flags, source, countdown)
        if ent.Variant == REVEL.ENT.ANTLION_BABY.variant then
            if amount > 1.01 then
                ent:TakeDamage(1.01, flags, source, countdown)
                return false
            end
        end
    end, REVEL.ENT.ANTLION_BABY.id)]]

end

do -- Antlion Egg
    function REVEL.BreakEgg(egg)
        local eggData = REVEL.GetData(egg)
        eggData.ShouldBreak = true
    end

    revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
        if npc.Variant == REVEL.ENT.ANTLION_EGG.variant then
            local data, sprite = REVEL.GetData(npc), npc:GetSprite()

            if not data.Init then
                npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
                data.Hits = 0
                data.Init = true
                if data.IsThrownEgg then
                    sprite:Play("Flying", true)

                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

                    data.Origin = data.Origin or npc.Position
                    data.Target = data.Target or REVEL.room:FindFreePickupSpawnPosition(Isaac.GetRandomPosition(), 60, true)

                    data.Gravity = data.Gravity or 0.15
                    data.ZVelocity = data.ZVelocity or math.ceil(data.Origin:Distance(data.Target) * 0.015)
                    data.ZPosition = data.ZPosition or 10
                    data.AirRotation = data.AirRotation or math.random(-30,30) * 0.1
                    npc.SpriteRotation = math.random(-180,180)
                end
            end

            REVEL.ApplyKnockbackImmunity(npc)

            if data.IsThrownEgg then
                if data.Origin and data.Target then
                    if not REVEL.LerpEntityPosition(npc, data.Origin, data.Target, data.Origin:Distance(data.Target) * 0.2) then
                        npc.Position = data.Target
                        npc.Velocity = Vector.Zero
                        data.Origin = nil
                        data.Target = nil
                    end
                end

                if data.PoofMe then
                    local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector.Zero, npc)
                    npc:Remove()
                elseif data.LandMe then
                    for i=1, math.random(2,3) do
                        REVEL.SpawnSandGibs(npc.Position, RandomVector() * 2, npc)
                    end
                    data.IsThrownEgg = nil
                    sprite:Play("Land", true)
                    npc.SpriteOffset = Vector(0,0)
                    npc.SpriteRotation = 0
                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                    npc.Position = REVEL.room:GetClampedPosition(npc.Position, 40)
                end
            else
                npc.Velocity = Vector.Zero

                if not data.SpawnedAntlions then
                    if data.Angered and math.random(1, 150) <= data.Angered then
                        data.ShouldBreak = true
                    end

                    if data.TimedBreak then
                        data.TimedBreakTimer = data.TimedBreakTimer or math.random(50,80)
                        data.TimedBreakTimer = data.TimedBreakTimer - 1
                        if data.TimedBreakTimer < 0 then
                            data.ShouldBreak = true
                            data.TimedBreakTimer = nil
                        end
                    end

                    if data.ShouldBreak and not sprite:IsPlaying("Break") then
                        sprite:Play("Break", true)
                        for i,sandy in ipairs(Isaac.FindByType(REVEL.ENT.SANDY.id, REVEL.ENT.SANDY.variant, -1, false, false)) do
                            local sandyData = REVEL.GetData(sandy)
                            if not sandyData.StartedFight then
                                sandyData.StartFightCounter = sandyData.StartFightCounter - 2
                            end
                        end
                    end

                    if sprite:IsEventTriggered("Spawn") then
                        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOIL_HATCH, 0.7, 0, false, 1)

                        if math.random(1,10) == 1 and not revel.data.run.jeffreySeen and not data.NoJeffrey then
                            local jeffrey = Isaac.Spawn(REVEL.ENT.JEFFREY_BABY.id, REVEL.ENT.JEFFREY_BABY.variant, 0, npc.Position + RandomVector() * 30, Vector.Zero, npc)
                            jeffrey:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                            jeffrey:GetSprite():Play("Appear", true)
                            revel.data.run.jeffreySeen = true
                        else
                            local amountBabies = Isaac.CountEntities(nil, REVEL.ENT.ANTLION_BABY.id, REVEL.ENT.ANTLION_BABY.variant, -1) or 0
                            local babiesToSpawn = math.random(2,3)
                            if amountBabies > 2 then
                                babiesToSpawn = babiesToSpawn - 1
                            end
                            if amountBabies > 4 then
                                babiesToSpawn = babiesToSpawn - 1
                            end
                            if amountBabies > 6 then
                                babiesToSpawn = 1
                            end
                            for i=1, babiesToSpawn do
                                local baby = Isaac.Spawn(REVEL.ENT.ANTLION_BABY.id, REVEL.ENT.ANTLION_BABY.variant, 0, npc.Position + RandomVector() * 30, Vector.Zero, npc)
                                baby:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                                baby:GetSprite():Play("Appear", true)
                                baby.Velocity = RandomVector() * 7.5
                                REVEL.GetData(baby).IsEnraged = true
                            end
                        end
                        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector.Zero, nil)
                        data.SpawnedAntlions = true
                        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                    end
                end
            end

            local inSandyFight = false
            for i,sandy in ipairs(Isaac.FindByType(REVEL.ENT.SANDY.id, REVEL.ENT.SANDY.variant, -1, false, false)) do
                local sandyData = REVEL.GetData(sandy)
                if sandyData.StartedFight then
                    inSandyFight = true
                end
            end

            local idleAnim = "Idle"
            if data.Angered or data.TimedBreak or inSandyFight then
                idleAnim = "IdleAngered"
                if sprite:IsPlaying("Idle") then
                    sprite:Play(idleAnim, true)
                end
            end
            if sprite:IsFinished("Land") or sprite:IsFinished("Emerge") then
                sprite:Play(idleAnim, true)
            end
            if sprite:IsFinished("Break") then
                npc:Remove()
            end
        end
    end, REVEL.ENT.ANTLION_EGG.id)

    revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc, offset)
        if not REVEL.game:IsPaused() and REVEL.IsRenderPassNormal() then
            if npc.Variant ~= REVEL.ENT.ANTLION_EGG.variant then
                return
            end

            local data = REVEL.GetData(npc)

            --some of this throwing code should probably be moved into a general-use thing in the future
            if data.Init and data.IsThrownEgg then
                if data.ZPosition <= 0 then
                    data.ZVelocity = 0
                    data.ZPosition = 0
                    local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(npc.Position))
                    if grid and grid.CollisionClass == GridCollisionClass.COLLISION_PIT then
                        data.PoofMe = true
                    else
                        data.LandMe = true
                    end
                elseif data.ZPosition <= 40 then
                    if npc.GridCollisionClass ~= EntityGridCollisionClass.GRIDCOLL_BULLET then
                        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_BULLET
                    end
                    if npc.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_PLAYERONLY then
                        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
                    end

                    local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(npc.Position + npc.Velocity))
                    if grid and grid.CollisionClass ~= GridCollisionClass.COLLISION_NONE and grid.CollisionClass ~= GridCollisionClass.COLLISION_PIT then
                        data.LandMe = true
                    end
                else
                    if npc.GridCollisionClass ~= EntityGridCollisionClass.GRIDCOLL_WALLS then
                        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
                    end
                    if npc.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE then
                        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                    end

                    local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(npc.Position + npc.Velocity))
                    if grid and grid.CollisionClass == GridCollisionClass.COLLISION_WALL then
                        data.LandMe = true
                    end
                end

                if data.ZPosition > 0 then
                    data.ZVelocity = data.ZVelocity - data.Gravity
                    data.ZPosition = data.ZPosition + data.ZVelocity
                    if data.ZPosition < 0 then
                        data.ZVelocity = 0
                        data.ZPosition = 0
                    end
                end

                local offset = 20
                npc.SpriteOffset = Vector(0,-(data.ZPosition+offset))
                npc.SpriteRotation = npc.SpriteRotation + data.AirRotation
            end
        end
    end, REVEL.ENT.ANTLION_EGG.id)

    revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flags, source, countdown)
        if ent:IsActiveEnemy(true) and Isaac.CountEntities(nil, REVEL.ENT.ANTLION_EGG.id, REVEL.ENT.ANTLION_EGG.variant, -1) > 0 then
            local getAngered = true
            for _, sandy in ipairs(Isaac.FindByType(REVEL.ENT.SANDY.id, REVEL.ENT.SANDY.variant, -1, false, false)) do
                local sandyData = REVEL.GetData(sandy)
                if not sandyData.StartedFight then
                    getAngered = false
                end
            end
            if getAngered then
                for _, egg in ipairs(Isaac.FindByType(REVEL.ENT.ANTLION_EGG.id, REVEL.ENT.ANTLION_EGG.variant, -1, false, false)) do
                    local eggData = REVEL.GetData(egg)
                    if not (eggData.OnlyBreak or eggData.IsThrownEgg) then
                        eggData.Angered = 1
                    end
                end
            end
            if ent.Type == REVEL.ENT.ANTLION_EGG.id and ent.Variant == REVEL.ENT.ANTLION_EGG.variant then
                if ent.HitPoints - amount - REVEL.GetDamageBuffer(ent) <= 0 then
                    local data = REVEL.GetData(ent)
                    data.ShouldBreak = true
                    return false
                end
            end
        end
    end)

end
    
end