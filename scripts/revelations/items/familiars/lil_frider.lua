return function()

---------------------
-- LIL FROST RIDER --
---------------------

--[[
- Moves randomly, staying near the player
- Occasionally stops to spit a friendly ice pooter and knock it toward the nearest enemy to him. Deals high damage on impact and breaks on second impact, spawning a friendly pooter
]]

local LilFrostRider = {
    maxSpeed = 2,
    pooterOffset = Vector(67,-2),
    maxPlayerDistance = 100,
    touchDamage = 1.5,
    blockDamage = 9,
    cooldown = {Min = 150, Max = 300},
}

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE , function(_, player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
    player:CheckFamiliar(REVEL.ENT.LIL_FRIDER.variant, REVEL.ITEM.LIL_FRIDER:GetCollectibleNum(player) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1), RNG())
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_,  fam)
    local spr, data = fam:GetSprite(), REVEL.GetData(fam)
    spr:Play("FloatDown", true)
    data.State = "Float"
    data.StateFrame = 0
    data.MaxTime = math.random(LilFrostRider.cooldown.Min, LilFrostRider.cooldown.Max)
    data.MaxSpeed = LilFrostRider.maxSpeed
    data.TargetPos = Isaac.GetFreeNearPosition(fam.Player.Position + RandomVector() * math.random() * LilFrostRider.maxPlayerDistance, 20)
end, REVEL.ENT.LIL_FRIDER.variant)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_,  fam)
    local spr, data = fam:GetSprite(), REVEL.GetData(fam)

    if data.State == "Float" then
        local farFromPlayer = fam.Position:DistanceSquared(fam.Player.Position) > LilFrostRider.maxPlayerDistance ^ 2

        if data.PauseTimer and not farFromPlayer then
            fam.Velocity = fam.Velocity * 0.9
        else
            fam.Velocity = fam.Velocity + (data.TargetPos - fam.Position)*0.01
        end

        if farFromPlayer then
            data.MaxSpeed = LilFrostRider.maxSpeed * 2
        else
            data.MaxSpeed = LilFrostRider.maxSpeed
        end

        local l = fam.Velocity:Length()
        if l > data.MaxSpeed then
            fam.Velocity = fam.Velocity * (data.MaxSpeed / l)
        end

        if data.PauseTimer then
            data.PauseTimer = data.PauseTimer - 1
            if data.PauseTimer < 0 then
            data.PauseTimer = nil
            end
        end

        if fam.Position:DistanceSquared(data.TargetPos) < 40*40 or farFromPlayer then
            if not farFromPlayer and not data.JustPaused then
                data.JustPaused = true
                data.PauseTimer = 40 + math.random(80)
            elseif farFromPlayer or not data.PauseTimer then
                data.JustPaused = nil
                local targ = REVEL.getClosestEnemy(fam, false, true, true, true)
                if targ then
                    local diff = targ.Position - fam.Player.Position
                    local dist = diff:Length()
                    data.TargetPos = fam.Player.Position + diff * (math.random() * LilFrostRider.maxPlayerDistance / dist)
                else
                    data.TargetPos = Isaac.GetFreeNearPosition(fam.Player.Position + RandomVector() * math.random() * LilFrostRider.maxPlayerDistance, 20)
                end
            end
        end

        if not REVEL.room:IsPositionInRoom(data.TargetPos, 48) then
            data.TargetPos = REVEL.room:GetClampedPosition(data.TargetPos, 48)
        end

        spr.FlipX = fam.Velocity.X < 0

        if data.StateFrame > data.MaxTime then
            local targ = REVEL.getClosestEnemy(fam, true, true, true, true)

            if targ then
                local pos
                local flip = fam.Position.X > targ.Position.X
                if flip then
                    pos = fam.Position + Vector(-LilFrostRider.pooterOffset.X, LilFrostRider.pooterOffset.Y)
                else
                    pos = fam.Position + LilFrostRider.pooterOffset
                end

                if not REVEL.IsGridPosSolid(pos) then
                    data.StateFrame = 0
                    data.State = "Spit"
                    spr.FlipX = flip --unflipped = right
                    data.MaxTime = math.random(LilFrostRider.cooldown.Min, LilFrostRider.cooldown.Max)

                    data.targ = targ

                    local pooters = Isaac.FindByType(EntityType.ENTITY_POOTER, -1, -1, false)
                    local fPooterCnt = 0

                    for i,p in ipairs(pooters) do
                        if p:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                            fPooterCnt = fPooterCnt + 1
                        end
                    end

                    local r = math.random()

                    if fPooterCnt > 1 or r > 1 / (fPooterCnt + 1) then
                        data.noPooter = true
                        spr:Play("AttackBlock", true)
                    else
                        data.noPooter = false
                        spr:Play("AttackPooter", true)
                    end
                else
                    data.StateFrame = data.StateFrame - 20
                end

            else
                data.StateFrame = data.StateFrame - 50
            end
        else
            data.StateFrame = data.StateFrame + 1
        end
    elseif data.State == "Spit" then
        fam.Velocity = Vector.Zero

        if spr:IsEventTriggered("Spawn") then
            REVEL.sfx:Play(38, 1, 0, false, 1.1)
            local pos
            if spr.FlipX then
                pos = fam.Position + Vector(-LilFrostRider.pooterOffset.X,LilFrostRider.pooterOffset.Y)
            else
                pos = fam.Position + LilFrostRider.pooterOffset
            end

            local vel = (data.targ.Position-pos):Resized(10)

            REVEL.SpawnFriendlyIceBlock(pos, vel, fam, not data.noPooter, LilFrostRider.blockDamage)

            local closeEnms = Isaac.FindInRadius(pos, 32, EntityPartition.ENEMY)
            for i,e in ipairs(closeEnms) do
                if not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and e.Type ~= EntityType.ENTITY_SHOPKEEPER then
                        e:TakeDamage(LilFrostRider.blockDamage, 0, EntityRef(fam), 5)
                end
            end

        elseif spr:IsEventTriggered("Spit") then
            REVEL.sfx:Play(SoundEffect.SOUND_WORM_SPIT, 1, 0, false, 1.1)

        elseif spr:IsFinished("AttackPooter") or spr:IsFinished("AttackBlock") then
            data.State = "Float"
            spr:Play("FloatDown", true)

        elseif fam.FrameCount % 3 == 0 then
            spr.FlipX = fam.Position.X > data.targ.Position.X
        end
    end

    if fam.FrameCount % 7 == 0 then
        local closeEnms = Isaac.FindInRadius(fam.Position, fam.Size+32, EntityPartition.ENEMY)
        for i,e in ipairs(closeEnms) do
            if e.Position:Distance(fam.Position) < e.Size + fam.Size + 3 and e.Type ~= 33 then
                if not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and e.Type ~= EntityType.ENTITY_SHOPKEEPER then
                    e:TakeDamage(LilFrostRider.touchDamage, 0, EntityRef(fam), 2)
                end
            end
        end
    end
end, REVEL.ENT.LIL_FRIDER.variant)

end