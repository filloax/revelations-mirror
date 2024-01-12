local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()

------------------
-- BANDAGE BABY --
------------------

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        local data = player:GetData()
        if not data.BandageBabyInRags then
            data.BandageBabyInRags = 0
        end
        local num = (REVEL.ITEM.BANDAGE_BABY:GetCollectibleNum(player) - data.BandageBabyInRags) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
        local rng = REVEL.RNG()
        rng:SetSeed(math.random(10000), 0)
        player:CheckFamiliar(REVEL.ENT.BANDAGE_BABY.variant, num, rng:GetRNG())
    end
end)

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
    local data = player:GetData()
    if data.UpdateBandageBabyAmount and data.UpdateBandageBabyAmount > 0 then
        data.UpdateBandageBabyAmount = data.UpdateBandageBabyAmount -1
        if data.UpdateBandageBabyAmount % 150 == 0 then
            if not data.BandageBabyInRags then
                data.BandageBabyInRags = 0
            end
            data.BandageBabyInRags = data.BandageBabyInRags - 1
            if data.BandageBabyInRags < 0 then
                data.BandageBabyInRags = 0
            end
            player:AddCacheFlags(CacheFlag.CACHE_FAMILIARS)
            player:EvaluateItems()
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    for _, bandageBaby in ipairs(Isaac.FindByType(REVEL.ENT.BANDAGE_BABY.id, REVEL.ENT.BANDAGE_BABY.variant, -1, false, false)) do
        local data = bandageBaby:GetData()
        data.ShootCountdown = math.random(40,80)
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, familiar)
    local data, sprite = familiar:GetData(), familiar:GetSprite()

    if not data.Init then
        familiar:AddToOrbit(0)
        data.Init = true
    end

    if data.WasHit then
        if sprite:IsFinished("Hit") then
            familiar:Remove()
            local ball = Isaac.Spawn(REVEL.ENT.BANDAGE_BABY_BALL.id, REVEL.ENT.BANDAGE_BABY_BALL.variant, 0, familiar.Position, Vector.Zero, familiar)
            ball:GetData().OnGround = true
            ball:GetSprite():Play("Rags", true)
            REVEL.sfx:Play(SoundEffect.SOUND_FETUS_LAND, 0.8, 0, false,1 + math.random() * 0.1)
            local playerData = familiar.Player:GetData()
            if not playerData.UpdateBandageBabyAmount then
                playerData.UpdateBandageBabyAmount = 0
            end
            playerData.UpdateBandageBabyAmount = playerData.UpdateBandageBabyAmount + 150
            if not playerData.BandageBabyInRags then
                playerData.BandageBabyInRags = 0
            end
            playerData.BandageBabyInRags = playerData.BandageBabyInRags + 1
            familiar.Player:AddCacheFlags(CacheFlag.CACHE_FAMILIARS)
            familiar.Player:EvaluateItems()
        end
        if not data.WasHitCountdown then
            data.WasHitCountdown = 150
        end
        if data.WasHitCountdown > 0 then
            data.WasHitCountdown = data.WasHitCountdown - 1
            if data.WasHitCountdown == 0 then
                REVEL.SpawnPurpleThunder(familiar)
                sprite:Play("Idle", true)
            end
        end
    else
        familiar.OrbitDistance = EntityFamiliar.GetOrbitDistance(0)
        familiar.Velocity = familiar:GetOrbitPosition(familiar.Player.Position - familiar.Player.Velocity) - familiar.Position

        if not data.ShootCountdown then
            data.ShootCountdown = math.random(40,80)
        end

        if data.ShootCountdown <= 0 then
            local canShoot = false
            for _, enemy in ipairs(REVEL.roomEnemies) do
                if enemy:IsActiveEnemy(false) and enemy:IsVulnerableEnemy() and not enemy:HasEntityFlags(EntityFlag.FLAG_SLOW) 
                and not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and not enemy:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) then
                    if familiar.Position:Distance(enemy.Position) < 300 then
                        canShoot = true
                    end
                end
            end
            if (Isaac.CountEntities(nil, REVEL.ENT.BANDAGE_BABY_BALL.id, REVEL.ENT.BANDAGE_BABY_BALL.variant, -1) or 0) >= 3 then
                canShoot = false
            end

            if canShoot and not sprite:IsPlaying("Shoot") then
                sprite:Play("Shoot", true)
                data.ShootCountdown = math.random(120,180)
            end
        else
            data.ShootCountdown = data.ShootCountdown - 1
        end

        if sprite:IsPlaying("Shoot") then
            if sprite:IsEventTriggered("Shoot") then
                local ball = Isaac.Spawn(REVEL.ENT.BANDAGE_BABY_BALL.id, REVEL.ENT.BANDAGE_BABY_BALL.variant, 0, familiar.Position, Vector.Zero, familiar)
                REVEL.sfx:Play(SoundEffect.SOUND_FETUS_JUMP, 0.9, 0, false, 1)

                local closestEnemy = nil
                for _, enemy in ipairs(REVEL.roomEnemies) do
                    if enemy:IsActiveEnemy(false) and enemy:IsVulnerableEnemy() 
                    and not (enemy:HasEntityFlags(EntityFlag.FLAG_SLOW) or enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) or enemy:HasEntityFlags(EntityFlag.FLAG_NO_TARGET)) then
                        if familiar.Position:Distance(enemy.Position) < 300 then
                            if not closestEnemy or (closestEnemy and familiar.Position:Distance(enemy.Position) < familiar.Position:Distance(closestEnemy.Position)) then
                                closestEnemy = enemy
                            end
                        end
                    end
                end
                if closestEnemy then
                    local ballData = ball:GetData()
                    ballData.Origin = familiar.Position
                    ballData.Target = closestEnemy.Position
                end
            end
        end
        if sprite:IsFinished("Shoot") then
            sprite:Play("Idle", true)
        end

        for i,proj in ipairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE, -1, -1, true)) do
            if familiar.Position:Distance(proj.Position) < proj.Size + familiar.Size then
                proj:Die()
                REVEL.sfx:Play(SoundEffect.SOUND_DEATH_BURST_SMALL, 0.8, 0, false,1 + math.random() * 0.1)
                data.WasHit = true
                data.WasHitCountdown = 150
                sprite:Play("Hit", true)
                familiar:RemoveFromOrbit()
                familiar.Velocity = Vector.Zero
            end
        end
    end
end, REVEL.ENT.BANDAGE_BABY.variant)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    local data = effect:GetData()

    if not data.Init then
        if not data.OnGround then
            REVEL.ZPos.SetData(effect, {
                ZVelocity = 5,
                ZPosition = 10,
                Gravity = 0.25,
                Bounce = 0,
                DoRotation = true,
                RotationOffset = 56,
                DisableCollision = false,
                EntityCollisionMode = REVEL.ZPos.EntityCollisionMode.DONT_HANDLE,
                BounceFromGrid = false,
                LandFromGrid = false
            })
            REVEL.ZPos.UpdateEntity(effect)
        end
        data.Init = true
    end

    if data.OnGround and REVEL.ZPos.GetPosition(effect) > 0 then
        REVEL.ZPos.SetPosition(effect, 0)
        REVEL.ZPos.UpdateEntity(effect)
    end

    if not data.OnGround then
        if data.Origin and data.Target then
            if not REVEL.LerpEntityPosition(effect, data.Origin, data.Target, 20) then
            effect.Position = data.Target
            effect.Velocity = Vector.Zero
            data.Origin = nil
            data.Target = nil
            end
        else
            local clampedPosition = REVEL.room:GetClampedPosition(effect.Position, 0)
            if effect.Position ~= clampedPosition then
            --make it bounce off walls
            if effect.Position.X ~= clampedPosition.X then
                effect.Velocity = Vector((effect.Velocity.X * -0.5), effect.Velocity.Y)
            end
            if effect.Position.Y ~= clampedPosition.Y then
                effect.Velocity = Vector(effect.Velocity.X, (effect.Velocity.Y * -0.5))
            end
            effect.Position = clampedPosition
            end
        end
    end

    for _, enemy in ipairs(REVEL.roomEnemies) do
        if enemy:IsActiveEnemy(false) and enemy:IsVulnerableEnemy() and not (enemy:HasEntityFlags(EntityFlag.FLAG_SLOW) or enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) or enemy:HasEntityFlags(EntityFlag.FLAG_NO_TARGET)) then
            if effect.Position:Distance(enemy.Position) <= (enemy.Size * 2) and (data.OnGround or REVEL.ZPos.GetPosition(effect) <= 20 + (enemy.Size * 2)) then
            local enemyData = enemy:GetData()
            enemyData.LastBandageSlowFrame = enemyData.LastBandageSlowFrame or 0
            local doSlow = false
            local slowPower = 0.2
            local waitFrames = 150
            local slowFrames = 60
            if enemy:IsBoss() then
                slowPower = 0.1
                waitFrames = 250
                slowFrames = 40
            end
            if REVEL.game:GetFrameCount() - enemyData.LastBandageSlowFrame >= waitFrames then
                doSlow = true
            end
            if doSlow then
                enemyData.LastBandageSlowFrame = REVEL.game:GetFrameCount()
                enemy:AddSlowing(EntityRef(effect), slowFrames, slowPower, Color(0.5,0.5,0.5,1,conv255ToFloat(100,75,50)))
                effect:Remove()
            end
            REVEL.sfx:Play(SoundEffect.SOUND_FETUS_LAND, 0.8, 0, false,1 + math.random() * 0.1)
            end
        end
    end

    if effect.FrameCount >= 300 then
    effect:Remove()
    end
end, REVEL.ENT.BANDAGE_BABY_BALL.variant)

revel:AddCallback(RevCallbacks.POST_ENTITY_ZPOS_LAND, function(_, ent, airMovementData, fromPit)
    if ent.Variant == REVEL.ENT.BANDAGE_BABY_BALL.variant then
        ent:GetData().OnGround = true
        ent:GetSprite():Play("Rags", true)
        ent.Velocity = Vector.Zero
        REVEL.sfx:Play(SoundEffect.SOUND_FETUS_LAND, 0.8, 0, false,1 + math.random() * 0.1)
    end
end, REVEL.ENT.BANDAGE_BABY_BALL.id)

end