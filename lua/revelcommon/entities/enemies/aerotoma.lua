REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Aerotoma

function REVEL.SwitchRanges(value, low1, high1, low2, high2)
    return low2 + (value - low1) * (high2 - low2) / (high1 - low1)
end

local waveTime = 60
local twoPi = math.pi * 2
local sideOffset = Vector(40, 0)
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.AEROTOMA.variant then
        return
    end

    local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

    if not data.State then
        data.State = "Idle"
        data.Offset = math.random()
    end

    if data.State == "Idle" then
        if not sprite:IsPlaying("Idle") then
            sprite:Play("Idle", true)
        end

        local wave = math.sin(twoPi * (data.Offset + npc.FrameCount / waveTime))

        if not data.MaxAmp or math.abs(wave) < 0.1 then
            if not data.MaxAmp or not data.ChangedAmp then
                data.MaxAmp = math.random(70, 100)
                data.ChangedAmp = true
            end
        elseif data.MaxAmp then
            data.ChangedAmp = nil
        end

        local dist = target.Position:Distance(npc.Position)
        if npc.FrameCount > 30 and dist <= 150 then
            data.ChargeDirection = (target.Position - npc.Position):Resized(1)
            local checkPos = npc.Position + data.ChargeDirection * 40 * REVEL.room:GetGridWidth()
            if REVEL.room:GetClampedPosition(checkPos, 0).Y == checkPos.Y then
                npc.Velocity = Vector.Zero
                npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                sprite:Play("ChargeStart", true)
                data.State = "Charge"
            end
        end

        if data.State == "Idle" then
            local targPos, distSquared
            for i = -1, 1, 2 do
                local targ = target.Position + sideOffset * i
                local dist = npc.Position:DistanceSquared(targ)
                if (not distSquared or dist < distSquared) and REVEL.room:IsPositionInRoom(targ, 0) then
                    targPos = targ
                end
            end

            local diff = targPos - npc.Position
            local diffLen = diff:Length()

            -- sin wave movement that gets smaller the closer aerotoma is to the target, with a little rng thrown in via changing max amplitude whenever the wave resets.
            local amplitude = REVEL.SwitchRanges(diffLen, 200, 1000, data.MaxAmp, 0)
            local dir = diff / diffLen

            dir = dir:Rotated(wave * amplitude)
            npc.Velocity = dir * 5
        end

        sprite.FlipX = target.Position.X > npc.Position.X
    elseif data.State == "Charge" then
        if sprite:IsEventTriggered("Charge") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_CHILD_ANGRY_ROAR, 1, 0, false, 1)
            for i = 1, 4 do
                REVEL.SpawnNPCProjectile(npc, Vector.FromAngle(i * 90 + 45) * 10).FallingSpeed = -2
            end
        end

        if sprite:WasEventTriggered("Charge") or sprite:IsPlaying("Charge") then
            npc.Velocity = data.ChargeDirection * 20
            local clamp = REVEL.GetClampOffset(npc.Position, 0)
            if clamp then
                npc.Velocity = Vector.Zero
                npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_JUMPS, 1, 0, false, 1)
                sprite:Play("ChargeHit", true)
            end
        else
            if sprite:IsPlaying("ChargeStart") then
                npc.Velocity = npc.Velocity * 0.9 + -data.ChargeDirection * 0.5
            elseif sprite:IsPlaying("ChargeHit") and not sprite:WasEventTriggered("Pop") then
                npc.Velocity = Vector.Zero
            else
                npc.Velocity = npc.Velocity * 0.95
            end
        end

        if sprite:IsFinished("ChargeStart") then
            sprite:Play("Charge", true)
        end

        if sprite:IsEventTriggered("Pop") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_PLOP, 1, 0, false, 1)
            npc.Velocity = -data.ChargeDirection * 8
        end

        if sprite:IsFinished("ChargeHit") then
            data.State = "Idle"
        end
    end

    if npc:IsDead() then
        local spiderVel = (target.Position - npc.Position):Resized(15)
        local spider = Isaac.Spawn(EntityType.ENTITY_SPIDER_L2, 0, 0, npc.Position, spiderVel, npc):ToNPC()
        spider:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        local ssprite = spider:GetSprite()
        ssprite:Play("Jump", true)
        for i = 1, 11 do
            ssprite:Update()
        end

        spider.State = 50
        spider:GetData().AerotomaData = spiderVel
    end
end, REVEL.ENT.AEROTOMA.id)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    local data = npc:GetData()
    if data.AerotomaData then
        local sprite = npc:GetSprite()
        if sprite:IsFinished("Jump") then
            sprite:Play("Idle", true)
            npc.State = NpcState.STATE_MOVE
            data.AerotomaData = nil
        elseif not sprite:WasEventTriggered("Land") then
            npc.Velocity = data.AerotomaData
        else
            npc.Velocity = Vector.Zero
        end
    end
end, EntityType.ENTITY_SPIDER_L2)

end