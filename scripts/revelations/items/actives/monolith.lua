return function()

------------------
-- THE MONOLITH --
------------------

revel:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemID, itemRNG, player, useFlags, activeSlot, customVarData)
    local spawnLocation = player.Position
    if HasBit(useFlags, UseFlag.USE_CARBATTERY) then
        spawnLocation = spawnLocation + (RandomVector()*50)
    end
    spawnLocation = REVEL.room:GetClampedPosition(spawnLocation,0)

    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, spawnLocation, Vector.Zero, player)
    local monolith = Isaac.Spawn(EntityType.ENTITY_EFFECT, REVEL.ENT.MONOLITH.variant, 0, spawnLocation, Vector.Zero, player)
    monolith:GetSprite():Play("Active", true)
    monolith.Parent = player

    return true
end, REVEL.ITEM.MONOLITH.id)

local Monolith = {}
local MonolithTimer = 0
Monolith.lasers = {} --getData doesn't seem reliable with lasers, so this is a workaround (list with indexes)
Monolith.lastId = 1
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, e1)
    --[[
    if MonolithTimer<REVEL.player.MaxFireDelay then
        MonolithTimer=MonolithTimer+1
        return
    end]]

    local monolithPlayer = e1.Parent:ToPlayer()

    local data = REVEL.GetData(e1)
    if not data.monoinit then
    REVEL.sfx:Play(SoundEffect.SOUND_GOLD_HEART_DROP, 1, 0, false, 1)
    data.monoinit = true
    end

    -- checks all tears
    for i,e2 in ipairs(REVEL.roomTears) do
        local data = REVEL.GetData(e2)
        -- checks if there is a tear very close to monolith and not spawned by it
        if not e2:HasTearFlags(TearFlags.TEAR_LUDOVICO) and not (data.monolith and data.monolith[GetPtrHash(e1)])
        and e1.Position:DistanceSquared(e2.Position) < (15 + e2.Size) ^ 2 then

            local halt = false
            if data.monolithCount then
                if data.monolithCount > 2 then
                    halt = true
                end
            end

            if halt then
                break
            elseif e2.SpawnerType == EntityType.ENTITY_PLAYER then
                if not data.BurningBush then
                    local player = monolithPlayer
                    if e2.Parent and e2.Parent:ToPlayer() then
                        player = e2.Parent:ToPlayer()
                    end

                    SFXManager():Play(REVEL.SFX.MONOLITH_TEAR_CONVERT, 1, 0, false, 1)
                    MonolithTimer = 0
                    e2.Color = Color(1,1,1,1,conv255ToFloat(150,0,100))
                    data.monolith = data.monolith or {}
                    data.monolith[GetPtrHash(e1)] = true
                    data.monolithCount = data.monolithCount or 0
                    data.monolithCount = data.monolithCount+1

                    for i=-1,1,2 do
                        --local rev = Vector(e2.Velocity.Y,e2.Velocity.X):Clamped(-10,-10,10,10)
                        local t = player:FireTear(e2.Position --[[+rev*i]], e2.Velocity:Rotated(15*i), false, true, false)
                        REVEL.GetData(t).monolith = REVEL.GetData(t).monolith or {}
                        REVEL.GetData(t).monolith[GetPtrHash(e1)] = true
                        REVEL.GetData(t).monolithCount = data.monolithCount or 0
                        REVEL.GetData(t).monolithCount = data.monolithCount+1
                        t.Color = Color(1,1,1,1,conv255ToFloat(150,0,100))
                        t:ToTear().Height = e2:ToTear().Height
                    end
                else --burning bush synergy/optimization
                    data.DmgMult = data.DmgMult*3
                    data.ScaleMult = data.ScaleMult*1.5
                    data.CustomColor = Color(1,1,1,1,conv255ToFloat(150,0,100))
                    data.monolith = data.monolith or {}
                    data.monolith[GetPtrHash(e1)] = true
                end
            elseif e2.SpawnerType == EntityType.ENTITY_FAMILIAR and e2.SpawnerVariant == FamiliarVariant.WISP
            and e2.SpawnerEntity.SubType == REVEL.ITEM.MONOLITH.id then
                -- Book of Virtues Wisp
                local familiar = nil
                if e2.Parent and e2.Parent:ToFamiliar() then
                    familiar = e2.Parent:ToFamiliar()

                    SFXManager():Play(REVEL.SFX.MONOLITH_TEAR_CONVERT, 1, 0, false, 1.1)
                    MonolithTimer = 0
                    e2.Color = Color(1,1,1,1,conv255ToFloat(150,0,100))
                    data.monolith = data.monolith or {}
                    data.monolith[GetPtrHash(e1)] = true
                    data.monolithCount = data.monolithCount or 0
                    data.monolithCount = data.monolithCount+1

                    for i=-1,1,2 do
                        local t = familiar:FireProjectile(e2.Velocity:Normalized())
                        t.Position = e2.Position
                        t.Velocity = e2.Velocity:Rotated(15*i)
                        REVEL.GetData(t).monolith = REVEL.GetData(t).monolith or {}
                        REVEL.GetData(t).monolith[GetPtrHash(e1)] = true
                        REVEL.GetData(t).monolithCount = data.monolithCount or 0
                        REVEL.GetData(t).monolithCount = data.monolithCount+1
                        t.Color = Color(1,1,1,1,conv255ToFloat(150,0,100))
                        t:ToTear().Height = e2:ToTear().Height
                    end
                end
            end
        end
    end

    -- does the same for all lasers
    for i,e2 in ipairs(REVEL.roomLasers) do
        --        REVEL.DebugToString({e2.Index, REVEL.GetData(e2).monolith, e2.SpawnerType})
        local alreadyDuped --check using the ids list, as getData doesn't seem reliable with lasers
        for j,id in ipairs(Monolith.lasers) do
            if id == e2.InitSeed then alreadyDuped = true end
        end

        if not REVEL.GetData(e2).monolith and not alreadyDuped and e2.SpawnerType == 1 then
            local circle = e2:IsCircleLaser()
            if REVEL.CollidesWithLaser(e1.Position, e2, e1.Size / 2) then
                --add id to duped list
                Monolith.lasers[Monolith.lastId] = e2.InitSeed
                if Monolith.lastId < 64 then
                    Monolith.lastId = Monolith.lastId + 1
                else
                    Monolith.lastId = 1
                end

                local maxDist = e2.MaxDistance

                if not circle then
                    e2.Color = Color(1,1,1,1,conv255ToFloat(150,0,100))
                    if e2.Child then
                        e2.Child:GetSprite().Color = Color(1,1,1,1,conv255ToFloat(150,0,100))
                    end
                    REVEL.GetData(e2).monolith = true
                    if e2.Variant == 1 or e2.Variant == 3 or e2.Variant == 9 then
                        for i=-1,1,2 do
                            local t = EntityLaser.ShootAngle (e2.Variant, e1.Position, e2.AngleDegrees+30*i, math.max(1,e2.Timeout), e2.ParentOffset, e1.Parent)
                            t:SetMaxDistance(maxDist)
                            t.Color = Color(1,1,1,1,conv255ToFloat(150,0,100))
                            REVEL.GetData(t).monolith = true
                            t.Parent = e1

                            Monolith.lasers[Monolith.lastId] = t.InitSeed --this is only really necessary with normal lasers, not circle ones
                            if Monolith.lastId < 64 then
                                Monolith.lastId = Monolith.lastId + 1
                            else
                                Monolith.lastId = 1
                            end
                        end
                    elseif e2.Variant == 2 then
                        local player = monolithPlayer
                        if e2.Parent and e2.Parent:ToPlayer() then
                            player = e2.Parent
                        end

                        for i=-1,1,2 do
                            local t = player:ToPlayer():FireTechLaser(e1.Position, LaserOffset.LASER_TECH1_OFFSET, Vector.FromAngle(e2:ToLaser().AngleDegrees+15*i), false, true)
                            t:SetMaxDistance(maxDist)
                            t.Color = Color(1,1,1,1,conv255ToFloat(150,0,100))
                            REVEL.GetData(t).monolith = true
                            t.Parent = e1

                            Monolith.lasers[Monolith.lastId] = t.InitSeed --this is only really necessary with normal lasers, not circle ones
                            if Monolith.lastId < 64 then
                                Monolith.lastId = Monolith.lastId + 1
                            else
                                Monolith.lastId = 1
                            end
                        end
                    end
                else
                    SFXManager():Play(REVEL.SFX.MONOLITH_TEAR_CONVERT, 1, 0, false, 1)
                    MonolithTimer = 0
                    e2.Color = Color(1,1,1,1,conv255ToFloat(150,0,100))
                    REVEL.GetData(e2).monolith = true

                    local player = monolithPlayer
                    if e2.Parent and e2.Parent:ToPlayer() then
                        player = e2.Parent
                    end

                    for i=-1,1,2 do
                        local angle = math.rad(e2.Velocity:GetAngleDegrees()+90*i)
                        local t = player:FireTechXLaser(e1.Position+Vector(math.cos(angle)*15, math.sin(angle)*15), e2.Velocity:Rotated(30*i), e2.Radius)
                        t.Color = Color(1,1,1,1,conv255ToFloat(150,0,100))
                        REVEL.GetData(t).monolith = true
                        t.Parent = e1
                    end
                end
            end
        end
    end

    -- does the same for all knives
    for i,e2 in ipairs(REVEL.roomKnives) do
        if e2.SpawnerType == EntityType.ENTITY_PLAYER then
            if e2:IsFlying() then
                if not REVEL.GetData(e2).monolith and e1.Position:DistanceSquared(e2.Position) < (15 + e2.Size) ^ 2 then
                    MonolithTimer = 0
                    e2.Color = Color(1,1,1,1,conv255ToFloat(150,0,100))
                    REVEL.GetData(e2).monolith = true
                    for i=-1,1,2 do
                        local t = REVEL.FireReturningKnife(e1.Position, 35, e2:ToKnife().Rotation+10*i, 30)
                        t.Color = Color(1,1,1,0.8,conv255ToFloat(150,0,100))
                        REVEL.GetData(t).monolith = true
                    end
                end
            else
                REVEL.GetData(e2).monolith = nil
            end
        end
    end
end, REVEL.ENT.MONOLITH.variant)

end