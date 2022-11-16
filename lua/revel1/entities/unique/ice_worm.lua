REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-------------
-- ICE WORM --
--------------
local IceWormBalance = {
    DesiredRange = 340,
}

local function iceWorm_NpcUpdate(_, npc)
    if npc.Variant ~= REVEL.ENT.ICE_WORM.variant then return end

    npc.Velocity = Vector.Zero

    -- Locals
    local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

    if not data.AllIce then
        npc.Position = REVEL.room:GetGridPosition(REVEL.room:GetGridIndex(npc.Position))
    end

    if data.InvulnerableWithEntity and not data.InvulnerableWithEntity:Exists() then
        data.InvulnerableWithEntity = nil
    end

    if data.ForceNextPosition and npc.Position:DistanceSquared(data.ForceNextPosition) > 40 ^ 2 
    and (data.State == "Arise" or data.State == "Idle" or data.State == "Shoot") 
    and not sprite:WasEventTriggered("Shoot") then
        sprite:Play("Dive", true)
        data.State = "Dive"
        data.MustHide = true
    end

    -- Initialization
    if data.Init == nil then
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
        npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        npc.SplatColor = REVEL.WaterSplatColor
        data.TriedToTeleport = false
        data.AttackFrames = 0

        data.ShotSpeed = data.ShotSpeed or 10
        if REVEL.game.Difficulty ~= Difficulty.DIFFICULTY_HARD then
            data.ShotSpeed = 8
        end

        if not data.State then
            data.State = "Hide Idle"
            data.Invulnerable = true
        end

        data.Init = true
    end
    REVEL.ApplyKnockbackImmunity(npc)

    -- Animation ending triggers
    if sprite:IsFinished("TeleportEnd") or sprite:IsFinished("Dive") then
        if sprite:IsFinished("TeleportEnd") then
            data.AttackFrames = 0
        end
        if data.MustHide == true then
            data.MustHide = false
            data.State = "Teleport"
        else
            data.State = "Hide Idle"
        end
    elseif sprite:IsFinished("Hide Shoot") then
        data.State = "Teleport"
    elseif sprite:IsFinished("Teleport") then
        data.TriedToTeleport = false
        data.State = "Teleport Idle"
    elseif sprite:IsFinished("Arise") then
        data.State = "Idle"
    elseif sprite:IsFinished("Shoot") then
        data.MustHide = true
        data.State = "Dive"
    end

    -- Animation player
    if data.State ~= nil then
        if not sprite:IsPlaying(data.State) then
            sprite:Play(data.State, true)
        end
    end

    -- Event triggers
    if sprite:IsEventTriggered("Shoot") then
        if data.State == "Hide Shoot" then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            data.Invulnerable = false
            local playSound = false
            for _, player in ipairs(REVEL.players) do
                if player.Position:DistanceSquared(npc.Position) < (20 + player.Size) ^ 2 then
                    REVEL.SpringPlayer(player)
                    playSound = true
                end
            end

            if playSound then
                REVEL.sfx:Play(REVEL.SFX.ICE_WORM_BOUNCE, 1.8, 0, false, 1.1)
            end
        else
            data.TimesShot = data.TimesShot + 1
            if data.TimesShot == 1 then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WORM_SPIT, 1, 0, false, 1)
            end
            local p = Isaac.Spawn(9, 0, 0, npc.Position, (target.Position - npc.Position):Resized(data.ShotSpeed), npc):ToProjectile()
            p.FallingSpeed = -1.5
        end
    elseif sprite:IsEventTriggered("Invulnerable") then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        data.Invulnerable = true
    elseif sprite:IsEventTriggered("Vulnerable") then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        data.Invulnerable = false
        if data.State == "Arise" then
            local playSound = false
            for _, player in ipairs(REVEL.players) do
                if not player:GetData().TotalFrozen and player.Position:DistanceSquared(npc.Position) < (20 + player.Size) ^ 2 then
                    REVEL.SpringPlayer(player)
                    playSound = true
                end
            end
            if playSound then
                REVEL.sfx:Play(REVEL.SFX.ICE_WORM_BOUNCE, 1.8, 0, false, 1.1)
            end
        end
    end

    -- Sprite faces the player
    sprite.FlipX = npc.Position.X < target.Position.X

    -- Attack timer
    if data.State == "Idle" then
        data.AttackFrames = data.AttackFrames + 1
        if data.AttackFrames >= 25 then
            data.TimesShot = 0
            data.State = "Shoot"
        end
    end

    local onIce
    local wormOnIce
    local icePitFrames
    local icePits = {}
    local currentRoom = StageAPI.GetCurrentRoom()
    if currentRoom then
        icePitFrames = currentRoom.PersistentData.IcePitFrames
        local snowedTiles = currentRoom.PersistentData.SnowedTiles or {}
        if icePitFrames then
            for strindex, _ in pairs(icePitFrames) do
                local ind = tonumber(strindex)
                if REVEL.IsGridIndexUnlocked(ind) and not REVEL.IsBigBlowyTrack(ind, true) and not snowedTiles[strindex] then
                    icePits[#icePits + 1] = ind
                end

                wormOnIce = wormOnIce or ind == REVEL.room:GetGridIndex(npc.Position)
                onIce = onIce or ind == REVEL.room:GetGridIndex(target.Position)
            end
        end
    end

    if not data.AllIce and not wormOnIce and npc.FrameCount > 1 then
        npc:Kill()
    end

    -- AI states
    if data.State == "Teleport Idle" then
        REVEL.UnlockGridIndex(REVEL.room:GetGridIndex(npc.Position))

        if not data.AllIce then
            local farthest, farthestDist, closest, closestDist, farthestInRange, farthestInRangeDist
            local targetPos = target.Position + target.Velocity * 26
            for _, pit in ipairs(icePits) do
                local pos = REVEL.room:GetGridPosition(pit)
                local dist = pos:DistanceSquared(targetPos)
                if (not farthestDist or farthestDist < dist) and REVEL.room:CheckLine(pos, targetPos, 3, 0, false, false) then
                    farthest = pit
                    farthestDist = dist
                end

                if (not closest or dist < closestDist) then
                    closest = pit
                    closestDist = dist
                end

                if dist <= IceWormBalance.DesiredRange^2 and (not farthestInRange or dist > farthestInRangeDist) then
                    farthestInRange = pit
                    farthestInRangeDist = dist
                end
            end

            local usePit

            if closestDist and closestDist < (20 + target.Size) ^ 2 then
                usePit = closest
            elseif farthestInRange then
                usePit = farthestInRange
            else
                usePit = farthest
            end

            if not usePit and #icePits > 0 then
                usePit = icePits[math.random(1, #icePits)]
            end

            if not usePit then
                npc:Kill()
                return
            end

            REVEL.LockGridIndex(usePit)
            npc.Position = REVEL.room:GetGridPosition(usePit)
        else
            if data.ForceNextPosition then
                npc.Position = data.ForceNextPosition
            else
                npc.Position = Isaac.GetFreeNearPosition(Isaac.GetRandomPosition(), 20) + RandomVector() * math.random(0, 20)
            end

            REVEL.LockGridIndex(REVEL.room:GetGridIndex(npc.Position))
        end

        data.State = "TeleportEnd"
    elseif data.State == "Hide Idle" then
        local nearbyPlayer
        for _, player in ipairs(REVEL.players) do
            if player.Position:DistanceSquared(npc.Position) < (20 + player.Size) ^ 2 then
                nearbyPlayer = true
                break
            end
        end

        if nearbyPlayer and not data.AllIce then
            data.State = "Hide Shoot"
        else
            data.State = "Arise"
            data.AttackFrames = 0
        end
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, iceWorm_NpcUpdate, REVEL.ENT.ICE_WORM.id)

local function iceWorm_EntityTakeDmg(_, ent, dmg, flag, source, frames)
    if ent.Variant == REVEL.ENT.ICE_WORM.variant and (ent:GetData().Invulnerable == true or (ent:GetData().InvulnerableWithEntity and ent:GetData().InvulnerableWithEntity:Exists())) then
        return false
    end
end
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, iceWorm_EntityTakeDmg, REVEL.ENT.ICE_WORM.id)


end