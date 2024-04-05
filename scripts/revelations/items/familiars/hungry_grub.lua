local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

-- Hungry Grub
local blacklist = {
    [REVEL.ENT.GLASS_SPIKE.id] = {REVEL.ENT.GLASS_SPIKE.variant}
}

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, cache)
    if cache == CacheFlag.CACHE_FAMILIARS then
        local numHungryGrub = REVEL.ITEM.HUNGRY_GRUB:GetCollectibleNum(player) 
            * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
        player:CheckFamiliar(REVEL.ENT.HUNGRY_GRUB.variant, numHungryGrub, RNG())
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, familiar)
    local data, sprite = REVEL.GetData(familiar), familiar:GetSprite()
    local player = familiar.Player

    if not data.State then
        data.State = "Idle"
        data.Strength = 1
        data.Embedded = nil
        familiar:AddToFollowers()
        familiar.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        data.HPAbsorbed = nil
    end

    local anim
    if data.Strength > 1 then
        anim = tostring(data.Strength)
    else
        anim = ""
    end

    if data.Cooldown then
        data.Cooldown = data.Cooldown - 1
        if data.Cooldown <= 0 then data.Cooldown = nil end
    end

    if data.State == "Idle" then
        if not sprite:IsPlaying("Float" .. anim) then
            sprite:Play("Float" .. anim, true)
        end

        familiar:FollowPosition( (familiar.Parent or familiar.Player).Position)

        if data.ChargeNextFrame then
            data.ChargeNextFrame = nil
            if math.abs(data.ChargeDirection.X) > math.abs(data.ChargeDirection.Y) then
                sprite:Play("ChargeSide" .. anim, true)
                if data.ChargeDirection.X < 0 then
                    sprite.FlipX = true
                end
            else
                if data.ChargeDirection.Y < 0 then
                    sprite:Play("ChargeUp" .. anim, true)
                else
                    sprite:Play("ChargeDown" .. anim, true)
                end
            end

            if familiar:CollidesWithGrid() then
                data.CollidingWithGrid = REVEL.room:GetGridIndex(familiar.Position)
            end

            data.State = "Charge"
            familiar:RemoveFromFollowers()
        else
            familiar.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
            local fireDir = player:GetFireDirection()
            if fireDir ~= Direction.NO_DIRECTION and not data.Cooldown then
                data.ChargeNextFrame = true
                data.ChargeDirection = Vector.FromAngle(fireDir * 90 - 180)
                familiar.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_BULLET
            end
        end
    elseif data.State == "Charge" then
        familiar.Velocity = data.ChargeDirection * 10
        familiar.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_BULLET
        for _, enemy in ipairs(REVEL.roomEnemies) do
            if not REVEL.IsTypeVariantInList(enemy, blacklist) 
            and enemy:IsVulnerableEnemy() 
            and enemy:IsActiveEnemy(false) 
            and enemy.Position:DistanceSquared(familiar.Position) < (enemy.Size + familiar.Size) ^ 2 
            and not enemy:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) 
            and not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) 
            then
                data.Embedded = enemy
                sprite:Play("Embedded" .. anim, true)
                data.State = "Embedded"
                familiar.GridCollisionClass =
                    EntityGridCollisionClass.GRIDCOLL_NONE
                break
            end
        end

        if data.CollidingWithGrid 
        and (
            REVEL.room:GetGridIndex(familiar.Position) ~= data.CollidingWithGrid 
            or not familiar:CollidesWithGrid()
        ) then
            data.CollidingWithGrid = nil
        end

        if familiar:CollidesWithGrid() and not data.Embedded and
            not data.CollidingWithGrid then
            data.State = "Stun"
            familiar.Velocity = Vector.Zero
            data.Cooldown = 15
        end
    elseif data.State == "Stun" then
        familiar.Velocity = Vector.Zero
        if not data.Cooldown then
            data.State = "Idle"
            familiar.GridCollisionClass =
                EntityGridCollisionClass.GRIDCOLL_NONE
            familiar:AddToFollowers()
            sprite.FlipX = false
            data.Cooldown = 30
        end
    elseif data.State == "Embedded" then
        local embedded = data.Embedded
        local useStage = math.max(1, (REVEL.level:GetStage() / 2))
        local damage = useStage / 10
        if data.Strength >= 2 then damage = damage * 2 end

        local powerUpHP = math.max(15, useStage * 15)
        if data.Strength >= 3 then powerUpHP = powerUpHP * 2 end

        if not embedded:Exists() or embedded:IsDead() 
        or not embedded:IsVulnerableEnemy() 
        or embedded:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) 
        or embedded:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) 
        or not embedded:IsActiveEnemy(false) 
        or (data.DamageDealt and data.DamageDealt >= powerUpHP) 
        then
            data.State = "Idle"
            familiar.GridCollisionClass =
                EntityGridCollisionClass.GRIDCOLL_NONE
            familiar:AddToFollowers()
            sprite.FlipX = false
            data.Cooldown = 30
            data.Embedded = nil

            if data.DamageDealt then
                if not data.HPAbsorbed then
                    data.HPAbsorbed = 0
                end

                data.HPAbsorbed = data.HPAbsorbed + data.DamageDealt
                if data.HPAbsorbed and data.HPAbsorbed >= powerUpHP then
                    data.Strength = math.min(3, data.Strength + 1)
                    data.HPAbsorbed = nil
                end

                data.DamageDealt = nil
            end

            data.NPCLastHitPoints = nil
        else
            familiar.Position = embedded.Position + Vector(0, 1)
            familiar.Velocity = embedded.Velocity

            if not data.DamageDealt then data.DamageDealt = 0 end

            if data.NPCLastHitPoints 
            and embedded.HitPoints ~= data.NPCLastHitPoints 
            then
                if embedded.HitPoints < data.NPCLastHitPoints then
                    data.DamageDealt = data.DamageDealt 
                        + ((data.NPCLastHitPoints - embedded.HitPoints) * 2)
                end
            end

            embedded:TakeDamage(damage, 0, EntityRef(familiar), 0)
            if familiar.FrameCount % 6 == 0 then
                local num = math.random(1, 5)
                for i = 1, num do
                    Isaac.Spawn(
                        1000, 
                        EffectVariant.BLOOD_PARTICLE, 
                        0,
                        familiar.Position,
                        RandomVector() * math.random(2, 4),
                        familiar
                    )
                end
            end
            REVEL.sfx:Play(SoundEffect.SOUND_DEATH_BURST_SMALL, 0.5)

            data.DamageDealt = data.DamageDealt + damage
            data.NPCLastHitPoints = embedded.HitPoints
        end
    end

    if data.Strength == 3 then
        local creeps = Isaac.FindByType(
            EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, 0,
            false, false
        )
        local creepTooClose
        for _, creep in ipairs(creeps) do
            if creep.Position:DistanceSquared(familiar.Position) <
                (familiar.Size + 10) ^ 2 then
                creepTooClose = true
                break
            end
        end

        if not creepTooClose then
            Isaac.Spawn(
                EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, 0,
                familiar.Position, Vector.Zero, familiar
            )
        end
    end
end, REVEL.ENT.HUNGRY_GRUB.variant)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    for _, grub in ipairs(REVEL.ENT.HUNGRY_GRUB:getInRoom()) do
        grub:ToFamiliar():RemoveFromFollowers()
        REVEL.GetData(grub).State = nil
    end
end)

end
