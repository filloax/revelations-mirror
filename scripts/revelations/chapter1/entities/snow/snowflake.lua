return function()
---------------
-- SNOWFLAKE --
---------------
function REVEL.SpawnOrbitingFlake(npc, big, hpmult, pos, topspeed, moveto, radius, dontfillgaps, fullcycletime)
    local data = REVEL.GetData(npc)
    data.Orbiters = data.Orbiters or {}
    data.NumOrbiters = data.NumOrbiters and data.NumOrbiters + 1 or 1
    data.OrbitDontFillGaps = dontfillgaps
    data.FullCycleTime = fullcycletime or 20

    pos = pos or npc.Position
    local flake
    if big then
        flake = Isaac.Spawn(REVEL.ENT.SNOW_FLAKE_BIG.id, REVEL.ENT.SNOW_FLAKE_BIG.variant, 0, pos, Vector.Zero, npc)
    else
        flake = Isaac.Spawn(REVEL.ENT.SNOW_FLAKE.id, REVEL.ENT.SNOW_FLAKE.variant, 0, pos, Vector.Zero, npc)
    end

    if hpmult then
        flake.MaxHitPoints = flake.MaxHitPoints * hpmult
        flake.HitPoints = flake.MaxHitPoints
    end

    flake:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

    local fdata = REVEL.GetData(flake)
    fdata.Orbiting = npc
    if moveto then
        fdata.MoveState = "MoveToOrbit"
    else
        fdata.MoveState = "Orbit"
        data.Orbiters[#data.Orbiters + 1] = flake
    end

    fdata.CannotMerge = true
    fdata.TopSpeed = topspeed
    fdata.OrbitRadius = radius
    fdata.State = "Normal"
    return flake
end

revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, function(_, npc)

    local variant = npc.Variant
    if variant ~= REVEL.ENT.SNOW_FLAKE.variant and variant ~= REVEL.ENT.SNOW_FLAKE_BIG.variant then
        return
    end

    local data, sprite = REVEL.GetData(npc), npc:GetSprite()

    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
    npc.SplatColor = REVEL.SnowSplatColor

    sprite.Rotation = 0 + math.random(1, 360)
    sprite.Offset = Vector(0, -20)

    data.MaxMoveSpeed = 1.5
    if variant == REVEL.ENT.SNOW_FLAKE_BIG.variant then
        data.MaxMoveSpeed = 1.25
    end

    data.CurrentMoveSpeed = 0
    data.MaxMarginOutsideRoom = -256

end, REVEL.ENT.SNOW_FLAKE.id)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)

    local variant = npc.Variant
    if variant ~= REVEL.ENT.SNOW_FLAKE.variant and variant ~= REVEL.ENT.SNOW_FLAKE_BIG.variant then
        return
    end

    local data, sprite = REVEL.GetData(npc), npc:GetSprite()

    if not data.MaxMoveSpeed then
        data.MaxMoveSpeed = 2
        if variant == REVEL.ENT.SNOW_FLAKE_BIG.variant then
            data.MaxMoveSpeed = 1.5
        end
    end

    data.CurrentMoveSpeed = data.CurrentMoveSpeed or 0
    if data.CurrentMoveSpeed < data.MaxMoveSpeed then
        data.CurrentMoveSpeed = math.min(data.CurrentMoveSpeed + (data.MaxMoveSpeed * 0.025), data.MaxMoveSpeed)
    end

    sprite.Rotation = sprite.Rotation + (data.CurrentMoveSpeed * 1.5)

    if REVEL.IsUsingPathMap(REVEL.GenericFlyingChaserPathMap, npc) and data.MoveState ~= "TargetPlayer" then
        data.Path = nil
        data.PathIndex = nil
        REVEL.StopUsingPathMap(REVEL.GenericFlyingChaserPathMap, npc)
    end

    if data.MoveState == "TargetPlayer" then
        REVEL.UsePathMap(REVEL.GenericFlyingChaserPathMap, npc)

        if data.Path then
            REVEL.FollowPath(npc, data.CurrentMoveSpeed, data.Path, true, 0.7, false, true)
        else
            local direction = npc:GetPlayerTarget().Position - npc.Position
            npc.Velocity = npc.Velocity * 0.7 + direction:Resized(data.CurrentMoveSpeed)
        end
    elseif data.MoveState == "Projectile" then
        if not REVEL.room:IsPositionInRoom(npc.Position, data.MaxMarginOutsideRoom) then
            npc:Remove()
        end
    elseif data.MoveState == "MoveToOrbit" then
        if data.Orbiting and data.Orbiting:Exists() and not data.Orbiting:IsDead() then
            npc.Velocity = data.Orbiting.Position - npc.Position
            local tspeed = data.TopSpeed or 10
            local length = npc.Velocity:Length()
            if length < 100 then
                data.MoveState = "Orbit"
            end

            if npc.Velocity:Length() > tspeed then
                npc.Velocity = npc.Velocity:Resized(tspeed)
            end
        else
            data.MoveState = "TargetPlayer"
            data.Orbiting = nil
        end
    elseif data.MoveState == "Orbit" then
        if not npc:IsDead() and data.Orbiting and data.Orbiting:Exists() and not data.Orbiting:IsDead() then
            local odata = REVEL.GetData(data.Orbiting)
            if not odata.Orbiters then
                odata.Orbiters = {}
                odata.NumOrbiters = 0
                odata.FullCycleTime = 20
            end

            --[[for i,orbiter in ripairs(odata.Orbiters) do
                if orbiter and orbiter:Exists() and not orbiter:IsDead() then
                    odata.NumOrbiters = math.max(odata.NumOrbiters, i)
                end
            end]]

            for i=1, odata.NumOrbiters do
                local orbiter = odata.Orbiters[i]
                if not orbiter or not orbiter:Exists() or orbiter:IsDead() then
                    if odata.OrbitDontFillGaps then
                        odata.Orbiters[i] = nil

                    elseif orbiter then
                        table.remove(odata.Orbiters, i)
                        REVEL.GetData(orbiter).Orbiting = false
                        odata.NumOrbiters = #odata.Orbiters
                    end
                end
            end
            local ind
            for i=1, odata.NumOrbiters do
                local orbiter = odata.Orbiters[i]
                if orbiter and GetPtrHash(orbiter) == GetPtrHash(npc) then
                    ind = i
                end
            end

            if not ind then
                ind = #odata.Orbiters + 1
                odata.Orbiters[ind] = npc
                odata.NumOrbiters = odata.NumOrbiters + 1
            end

            local angle = REVEL.GetMultiOrbitAngle(ind, odata.NumOrbiters) + (data.Orbiting.FrameCount / odata.FullCycleTime)
            local offset = REVEL.GetOrbitOffset(angle, data.OrbitRadius or 50)
            local targetPos = data.Orbiting.Position + data.Orbiting.Velocity * 2 + offset
            npc.Velocity = npc.Velocity*0.6 + (targetPos - npc.Position) * 0.2
            -- IDebug.RenderLine(npc.Position, targetPos)
            local tspeed = data.TopSpeed or 10
            local l = npc.Velocity:Length()
            if l > tspeed then
                npc.Velocity = npc.Velocity * (tspeed / l)
            end
            -- IDebug.RenderLine(npc.Position, npc.Position + npc.Velocity, IDebug.Color.Green, 10)
        else
            data.MoveState = "TargetPlayer"
            data.Orbiting = nil
        end
    end

    if not data.State then
        data.MoveState = "TargetPlayer"
        data.State = "Normal"
    end

    if data.State == "Normal" then
        if data.MoveState ~= "Orbit" then
            local cloudies = Isaac.FindByType(REVEL.ENT.CLOUDY.id, REVEL.ENT.CLOUDY.variant, -1, true, true)
            if #cloudies > 0 then
                local closest = REVEL.getClosestInTable(cloudies, npc)
                data.MoveState = "Orbit"
                data.Orbiting = closest
            end
        end

        if data.MoveState ~= "Orbit" and npc.FrameCount > 20 and not data.CannotMerge then
            local flakes = Isaac.FindByType(REVEL.ENT.SNOW_FLAKE.id, -1, -1, true, true)
            for _, flake in ipairs(flakes) do
                if not REVEL.GetData(flake).CannotMerge and REVEL.GetData(flake).MoveState ~= "Orbit" and GetPtrHash(flake) ~= GetPtrHash(npc) and flake.Variant == variant then
                    if flake.Position:Distance(npc.Position) <= npc.Size + flake.Size + 10 then
                        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BLACK_POOF, 1, 0, false, 1.8)
                        local eff = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, flake.Position+Vector(0,3), Vector.Zero, nil)
                        eff:SetColor(Color(0.73,0.81,0.99,1,conv255ToFloat(0,0,0)), -1, 1, false, false)

                        ---@type EntityNPC
                        flake = flake:ToNPC()

                        if variant == REVEL.ENT.SNOW_FLAKE.variant then
                            flake:Morph(REVEL.ENT.SNOW_FLAKE_BIG.id, REVEL.ENT.SNOW_FLAKE_BIG.variant, 0, -1)
                        else
                            flake:Morph(REVEL.ENT.CLOUDY.id, REVEL.ENT.CLOUDY.variant, 0, -1)
                            flake.State = 4
                            flake.StateFrame = 0
                            flake:GetSprite().Rotation = 0
                            flake:GetSprite().Offset = Vector.Zero
                        end

                        flake.HitPoints = flake.MaxHitPoints

                        npc:Remove()
                    end
                end
            end
        end
    end

    local bombs = Isaac.FindByType(4, -1, -1, true) --workaround for bomb collision

    for i,b in ipairs(bombs) do
        if b.SpawnerType == 1 and (b.Position + b.Velocity):Distance(npc.Position) < npc.Size + b.Size + 3 then
            b.Velocity = npc.Velocity
        end
    end

end, REVEL.ENT.SNOW_FLAKE.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
    if npc.Variant ~= REVEL.ENT.SNOW_FLAKE.variant and npc.Variant ~= REVEL.ENT.SNOW_FLAKE_BIG.variant then return end

    local size = npc.Variant == REVEL.ENT.SNOW_FLAKE.variant and 0.25 or 0.75
    local e = Isaac.Spawn(
        1000, 
        EffectVariant.DUST_CLOUD, 
        0, 
        npc.Position + RandomVector() * math.random(1, 10) + Vector(0, -20), 
        Vector.Zero, 
        npc
    ):ToEffect()
    e.Timeout = math.random(15, 30)
    e.LifeSpan = e.Timeout
    local color = Color(1,1,1,0.5)
    color:SetColorize(3,3,3,1)
    e.Color = color
    e.SpriteScale = Vector.One * size

    REVEL.sfx:Stop(SoundEffect.SOUND_DEATH_BURST_SMALL)
    REVEL.sfx:Play(REVEL.SFX.BREAKING_SNOWFLAKE, 1, 0, false, 1)
    REVEL.sfx:Play(SoundEffect.SOUND_DEATH_BURST_SMALL, 0.5, 0, false, 1.2)
end, REVEL.ENT.SNOW_FLAKE.id)


end