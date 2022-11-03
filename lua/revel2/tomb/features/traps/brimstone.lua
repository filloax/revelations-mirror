REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.TrapTypes.BrimstoneTrap = {
    OnSpawn = function(tile, data, index)
        local rotation = data.TrapData.Rotation
        local pos = tile.Position

        if rotation==90 then pos = Vector(REVEL.room:GetBottomRightPos().X, pos.Y)
        elseif rotation==180 then pos = Vector(pos.X, REVEL.room:GetBottomRightPos().Y)
        elseif rotation==270 then pos = Vector(REVEL.room:GetTopLeftPos().X, pos.Y)
        elseif rotation==0 then pos = Vector(pos.X, REVEL.room:GetTopLeftPos().Y) end

        local alreadyExists
        local spawnPos = pos + (Vector.FromAngle(rotation-90)*5)

        local brimTraps = Isaac.FindByType(REVEL.ENT.BRIM_TRAP.id, REVEL.ENT.BRIM_TRAP.variant, -1, false, false)
        for _, trap in ipairs(brimTraps) do
            if REVEL.room:GetGridIndex(trap.Position) == REVEL.room:GetGridIndex(spawnPos) and trap:GetSprite().Rotation == rotation then
                alreadyExists = trap
                break
            end
        end

        if not alreadyExists then
            local eff = Isaac.Spawn(REVEL.ENT.BRIM_TRAP.id, REVEL.ENT.BRIM_TRAP.variant, 0, spawnPos, Vector.Zero, nil)
            eff:GetData().TrapSpawned = true
            eff:GetSprite().Rotation = rotation
            eff:GetData().TrapDirection = REVEL.GetDirectionFromAngle(rotation)
            data.BrimTrap = eff
        else
            data.BrimTrap = alreadyExists
        end
    end,
    OnTrigger = function(tile, data)
        local fdata = data.BrimTrap:GetData()
        fdata.NoHitPlayer = data.TrapIsPositiveEffect
        fdata.DeactivateAt = data.BrimTrap.FrameCount + 150

        local sprite = data.BrimTrap:GetSprite()
        if not REVEL.MultiPlayingCheck(sprite, "BrimstoneStart", "BrimstoneLoop", "BrimstoneEnd") then
            sprite:Play("BrimstoneStart", true)
        end
    end,
    Cooldown = 150,
    Animation = "Brimstone"
}

local directionOffsets = {
    [Direction.RIGHT] = Vector(0, -15),
    [Direction.DOWN] = Vector(10, 0),
    [Direction.LEFT] = Vector(0, 15),
    [Direction.UP] = Vector(-10, 0)
}

local timedRate = 30 --time between each group's activation, or between offset/non offset activation
local timedTime = 20

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    local sprite = eff:GetSprite()
    if sprite:IsFinished("BrimstoneStart") then
        sprite:Play("BrimstoneLoop", true)
    end

    if sprite:IsFinished("BrimstoneEnd") then
        sprite:Play("Idle", true)
    end

    local data = eff:GetData()
    local frame = eff.FrameCount
    if not data.TrapSpawned then
        if data.DisableOnClear then
            data.Disabled = REVEL.room:IsClear()
        end

        if not data.Disabled then
            if not data.TrapSpawned and not data.TrapType then
                if not REVEL.MultiPlayingCheck(sprite, "BrimstoneStart", "BrimstoneLoop", "BrimstoneEnd") then
                    sprite:Play("BrimstoneStart", true)
                end

                data.DeactivateAt = frame + timedTime
            end

            if data.TrapType == "Timed" and frame % (timedRate * 2) == 0 then
                sprite:Play("BrimstoneStart", true)
                data.DeactivateAt = frame + timedTime
            elseif data.TrapType == "TimedOffset" and (frame + timedRate) % (timedRate * 2) == 0 then
                sprite:Play("BrimstoneStart", true)
                data.DeactivateAt = frame + timedTime
            elseif data.TrapType == "TimedGroup" then
                local activate
                for _, groupId in ipairs(data.MetaGroups) do
                    if (frame + timedRate * groupId) % (timedRate * (data.MaxGroup + 1)) == 0 then
                        activate = true
                        break
                    end
                end
                if activate then
                    sprite:Play("BrimstoneStart", true)
                    data.DeactivateAt = frame + timedTime
                end
            end
        end
    end

    if data.DeactivateAt and frame > data.DeactivateAt then
        data.DeactivateAt = nil
        sprite:Play("BrimstoneEnd", true)
    end

    -- in case we decide to use sounds, max brim sounds could probably be used
    if sprite:IsEventTriggered("Shoot") then
        --The +vector is so that the laser is below, making it render on top
        data.Laser = EntityLaser.ShootAngle(1, eff.Position + Vector(0, 1), sprite.Rotation + 90, 4, directionOffsets[data.TrapDirection], eff)
    end

    local shouldBeShooting = sprite:WasEventTriggered("Shoot") or sprite:IsPlaying("BrimstoneLoop") or (sprite:IsPlaying("BrimstoneEnd") and not sprite:WasEventTriggered("End"))

    if shouldBeShooting and data.Laser then
        data.Laser:SetTimeout(4)
    elseif data.Laser and not data.Laser:Exists() then
        data.Laser = nil
    end

end, REVEL.ENT.BRIM_TRAP.variant)

-- revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, eff)
--     local sprite, data = eff:GetSprite(), eff:GetData()

--     if data.Laser then
--         data.Laser:Render(Isaac.WorldToScreen(data.Laser.Position), Vector.Zero, Vector.Zero)
--     end
-- end, REVEL.ENT.BRIM_TRAP.variant)

end

REVEL.PcallWorkaroundBreakFunction()