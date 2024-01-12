return function()

-- Sand Worm

local chargeDirections = {
    Left = {AddX = 1, AddY = 0},
    Right = {AddX = -1, AddY = 0},
    Up = {AddX = 0, AddY = 1},
    Down = {AddX = 0, AddY = -1}
}

local oppositeDirectionNames = {
    Left = "Right",
    Right = "Left",
    Up = "Down",
    Down = "Up"
}

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.SAND_WORM.variant then
        return
    end

    local sprite, data, target = npc:GetSprite(), npc:GetData(), npc:GetPlayerTarget()

    if not data.State then
        data.State = "Idle"
        data.Cooldown = math.random(30, 45)
        local index = REVEL.room:GetGridIndex(npc.Position)
        REVEL.LockGridIndex(index)
        data.LockedIndex = index
        npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
    end

    if not data.DashDirection then
        REVEL.ApplyKnockbackImmunity(npc)
        npc.Velocity = npc.Velocity * 0.5
    end

    data.Cooldown = data.Cooldown - 1

    if data.State == "Idle" then
        if not sprite:IsPlaying("Idle") then
            sprite:Play("Idle", true)
        end

        if data.Cooldown <= 0 then
            sprite:Play("DigIn", true)
            data.State = "Dash"
            if data.LockedIndex then
                REVEL.UnlockGridIndex(data.LockedIndex)
            end
        end
    elseif data.State == "Dash" then
        if sprite:IsFinished("DigIn") then
            local width, height = REVEL.room:GetGridWidth(), REVEL.room:GetGridHeight()
            local index = REVEL.room:GetGridIndex(target.Position)
            local dashingOptions = {}
            for dir, xy in pairs(chargeDirections) do
                local lastNonColliding, distance = REVEL.GetLastNonCollidingIndex(index, EntityGridCollisionClass.GRIDCOLL_GROUND, xy.AddX, xy.AddY, width, height)
                if lastNonColliding and distance > 3 then
                    dashingOptions[#dashingOptions + 1] = {
                        Name = dir,
                        From = lastNonColliding,
                        Weight = 10
                    }
                end
            end

            if #dashingOptions > 0 then
                local sandWorms = Isaac.FindByType(REVEL.ENT.SAND_WORM.id, REVEL.ENT.SAND_WORM.variant, -1, false, false)
                for _, option in ipairs(dashingOptions) do
                    for _, worm in ipairs(sandWorms) do
                        if worm:GetData().DashDirection then
                            local dir = worm:GetData().DashDirection
                            if oppositeDirectionNames[dir] == option.Name then
                                if option.Weight == 10 then
                                    if math.random(1, 5) == 1 then
                                        option.Weight = 100
                                    else
                                        option.Weight = 1
                                    end
                                end
                            elseif dir == option.Name and option.Weight == 10 then
                                option.Weight = 3
                            end
                        end
                    end
                end


                local direction = StageAPI.WeightedRNG(dashingOptions, nil, "Weight")
                npc.Position = REVEL.room:GetGridPosition(direction.From)
                data.DashDirectionAnim = direction.Name
                if direction.Name == "Left" or direction.Name == "Right" then
                    if direction.Name == "Right" then
                        sprite.FlipX = true
                    end
                    data.DashDirectionAnim = "Hori"
                end

                sprite:Play("DigOut" .. data.DashDirectionAnim, true)

                data.DashDirection = direction.Name
                data.DashCooldown = 10
                data.DashMoving = nil
            else
                data.State = "Spit"
            end
        end

        if data.DashDirection then
            if sprite:IsFinished("DigOut" .. data.DashDirectionAnim) then
                sprite:Play("Shuffle" .. data.DashDirectionAnim, true)
            end

            if data.DashCooldown then
                data.DashCooldown = data.DashCooldown - 1
                if data.DashCooldown <= 0 then
                    sprite:Play("Dash" .. data.DashDirectionAnim .. "Start", true)
                    data.DashCooldown = nil
                end
            else
                if sprite:IsFinished("Dash" .. data.DashDirectionAnim .. "Start") then
                    sprite:Play("Dash" .. data.DashDirectionAnim .. "Loop", true)
                    data.DashMoving = true
                end

                if sprite:IsEventTriggered("Move") then
                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_YELL_A, 1, 0, false, 1)
                end

                if data.DashMoving or sprite:WasEventTriggered("Move") then
                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
                    if data.DashDirection == "Left" then
                        npc.Velocity = Vector(-12, 0)
                    elseif data.DashDirection == "Right" then
                        npc.Velocity = Vector(12, 0)
                    elseif data.DashDirection == "Up" then
                        npc.Velocity = Vector(0, -12)
                    elseif data.DashDirection == "Down" then
                        npc.Velocity = Vector(0, 12)
                    end

                    local sandWorms = Isaac.FindByType(REVEL.ENT.SAND_WORM.id, REVEL.ENT.SAND_WORM.variant, -1, false, false)
                    for _, worm in ipairs(sandWorms) do
                        local wdata = worm:GetData()
                        if wdata.DashDirection and wdata.DashMoving 
                        and not wdata.DashEnding and oppositeDirectionNames[wdata.DashDirection] == data.DashDirection 
                        and worm.Position:DistanceSquared(npc.Position) < (worm.Size + npc.Size + 16) ^ 2 then
                            for i = -3, 3 do
                                REVEL.SpawnSandGibs(
                                    REVEL.Lerp(npc.Position, worm.Position, 0.5), 
                                    (npc.Velocity * i / 3):Rotated(math.random(-5, 5))
                                )
                            end

                            data.DashMoving = nil
                            data.DashEnding = true
                            data.DashDirection = nil
                            sprite:Play("Collide" .. data.DashDirectionAnim, true)
                            npc.Velocity = Vector.Zero
                            wdata.DashMoving = nil
                            wdata.DashEnding = true
                            wdata.DashDirection = nil
                            worm:GetSprite():Play("Collide" .. data.DashDirectionAnim, true)
                            worm.Velocity = Vector.Zero
                        end
                    end
                end

                if not data.DashEnding then
                    local forwardCollision = REVEL.room:GetGridCollisionAtPos(npc.Position + npc.Velocity * 17)

                    if REVEL.GridCollisionMatch(EntityGridCollisionClass.GRIDCOLL_GROUND, forwardCollision) or npc:CollidesWithGrid() then
                        sprite:Play("Dash" .. data.DashDirectionAnim .. "End", true)
                        data.DashEnding = true
                    end
                end
            end
        else
            npc.Velocity = Vector.Zero
        end

        if data.DashDirectionAnim and (sprite:IsFinished("Dash" .. data.DashDirectionAnim .. "End") or sprite:IsFinished("Collide" .. data.DashDirectionAnim)) then
            sprite.FlipX = false
            data.State = "Spit"
            data.DashDirection = nil
            data.DashEnding = nil
            data.DigOutCooldown = math.random(5, 25)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        end
    elseif data.State == "Spit" then
        if data.DigOutCooldown then
            data.DigOutCooldown = data.DigOutCooldown - 1
            if data.DigOutCooldown <= 0 then
                data.DigOutCooldown = nil
            end
        end

        if not data.EnteredSpit and not data.DigOutCooldown then
            local targetIndex = REVEL.room:GetGridIndex(target.Position)
            local width, height = REVEL.room:GetGridWidth(), REVEL.room:GetGridHeight()
            local targetX, targetY = REVEL.GridToVector(targetIndex, width)
            local validIndices = {}
            for x = -4, 4 do
                for y = -4, 4 do
                    if x == -4 or x == 4 or y == -4 or y == 4 then
                        local newX, newY = targetX + x, targetY + y
                        if newX > 0 and newY > 0 and newX < width and newY < height then
                            local index = REVEL.VectorToGrid(newX, newY, width)
                            if REVEL.room:IsPositionInRoom(REVEL.room:GetGridPosition(index), 0) then
                                local collision = REVEL.room:GetGridCollision(index)
                                if collision == GridCollisionClass.COLLISION_NONE and REVEL.IsGridIndexUnlocked(index) then
                                    validIndices[#validIndices + 1] = index
                                end
                            end
                        end
                    end
                end
            end

            if #validIndices > 0 then
                local index = validIndices[math.random(1, #validIndices)]
                npc.Position = REVEL.room:GetGridPosition(index)
                REVEL.LockGridIndex(index)
                data.LockedIndex = index
            end

            sprite:Play("DigOut", true)
            data.EnteredSpit = true
        end

        if sprite:IsFinished("DigOut") then
            data.Cooldown = math.random(30, 45)
            sprite:Play("Idle2", true)
        end

        if sprite:IsPlaying("Idle2") then
            if data.Cooldown <= 0 then
                sprite:Play("Shoot", true)
            end
        end

        if sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WORM_SPIT, 1, 0, false, 1)
            for i = 1, 10 do
                local pro = npc:FireBossProjectiles(1, target.Position, 0, ProjectileParams())
                pro.Scale = pro.Scale / 2
                pro:GetData().IsSandTear = true
                pro:Update()
                pro:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel2/sand_bulletatlas.png")
                pro:GetSprite():LoadGraphics()
            end
        end

        if sprite:IsFinished("Shoot") then
            data.EnteredSpit = nil
            data.Cooldown = math.random(20, 35)
            data.State = "Idle"
        end
    end
end, REVEL.ENT.SAND_WORM.id)

end