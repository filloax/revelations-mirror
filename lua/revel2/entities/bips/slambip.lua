REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Slambip
function REVEL.GetIntactSandCastles()
    local sandcastles = StageAPI.GetCustomGrids(nil, REVEL.GRIDENT.SAND_CASTLE.Name)
    local sandcastlesIntact = {}
    for _, castle in ipairs(sandcastles) do
        local castleGrid = REVEL.room:GetGridEntity(castle.GridIndex)
        if castleGrid and not REVEL.IsGridBroken(castleGrid) then
            sandcastlesIntact[#sandcastlesIntact] = castle.GridIndex
        end
    end
    return sandcastlesIntact
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.SLAMBIP.variant then
        return
    end

    local data, sprite, player = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

    if not data.Init then
        sprite:Play("Idle", true)
        data.State = "Idle"
        npc.SplatColor = REVEL.SandSplatColor
        data.Init = true
        REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)
    end

    data.UsePlayerMap = true

    if data.State == "Burrowing" then
        if data.SlamPos then
            sprite.FlipX = npc.Position.X < data.SlamPos.X
        end

        npc.Velocity = npc.Velocity * 0.5
        if sprite:IsFinished("DigDown") then
            sprite:Play("Burrowed", true)
            data.BurrowedTime = 10
        end

        if sprite:IsPlaying("Burrowed") then
            if data.BurrowedTime and data.BurrowedTime > 0 then
                data.BurrowedTime = data.BurrowedTime - 1
            else
                sprite:Play("DigUp", true)
                if data.BurrowTo then
                    npc.Position = data.BurrowTo
                end
            end
        end

        if sprite:IsFinished("DigUp") then
            sprite:Play("Idle", true)
            if data.SlamPos then
                data.State = "Slam"
            else
                data.State = "Idle"
            end
        end
    elseif data.State == "Idle" then
        if sprite:IsFinished("SlamSide") or sprite:IsFinished("SlamDown") or sprite:IsFinished("SlamUp") then
            sprite:Play("Idle", true)
        end

        if data.DoPath and data.DoPath > 0 then
            data.TargetPosition = nil
            sprite.FlipX = npc.Velocity.X > 0
            data.DoPath = data.DoPath - 1

            if data.Path and #REVEL.GetIntactSandCastles() > 0 then
                REVEL.FollowPath(npc, 2, data.Path, true, 0.5)
            else
                if not data.FleeAngle or math.random() < 0.1 then
                    data.FleeAngle = math.random(-45, 45)
                end
                npc.Velocity = npc.Velocity * 0.9 + (npc.Position - npc:GetPlayerTarget().Position):Rotated(data.FleeAngle):Resized(0.6)
            end
        elseif data.TargetPosition then
            if not data.GoingToTargetTime then
                data.GoingToTargetTime = 0
            end

            data.BurrowTo = nil
            data.GoingToTargetTime = data.GoingToTargetTime + 1
            sprite.FlipX = npc.Position.X <	data.TargetPosition.X
            local targetDir = (data.TargetPosition - npc.Position)
            local targetDist = targetDir:Length()
            local targetDirNormal = targetDir / targetDist
            if targetDir.X == 0 and targetDir.Y == 0 then
                targetDist = 0
                targetDirNormal = Vector.Zero
            end
            npc.Velocity = npc.Velocity * 0.85 + targetDirNormal * 1
            local distanceFromTargetPos = npc.Position:Distance(data.TargetPosition)
            if distanceFromTargetPos <= 20 then
                data.State = "Slam"
                data.SlamPos = data.TargetPosition
                data.TargetPosition = nil
                data.GoingToTargetTime = 0
            else
                local nextCollision = REVEL.room:GetGridCollisionAtPos(npc.Position + (npc.Velocity*4))
                if nextCollision ~= GridCollisionClass.COLLISION_NONE then
                    data.State = "Burrowing"
                    data.BurrowTo = data.TargetPosition
                    sprite:Play("DigDown", true)
                end
            end

            if data.GoingToTargetTime > 100 then
                data.DoPath = 40
                data.TargetPosition = nil
                data.GoingToTargetTime = 0
            end
        else
            data.SlamPos = nil
            data.TargetPosition = nil
            data.SlamDirection = nil
            data.SlamVelocity = nil
            data.TargetPositionOpposite = nil
            data.TargetGrid = nil

            local validCastlesIndexes = {}
            local validCastlesData = {}

            local checkPos = player.Position
            local modPos = Vector(-30,0)

            for direction=0, 3 do

                for j=1, 100 do --raycast from player pos to find valid castles

                    local gridIndex = REVEL.room:GetGridIndex(checkPos)
                    local grid = REVEL.room:GetGridEntity(gridIndex)
                    local gridCollision = REVEL.room:GetGridCollisionAtPos(checkPos)

                    if gridCollision ~= GridCollisionClass.COLLISION_NONE then
                        if gridCollision == GridCollisionClass.COLLISION_WALL or gridCollision == GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER then --end this raycast if we hit a wall
                            break
                        elseif grid and StageAPI.IsCustomGrid(gridIndex, REVEL.GRIDENT.SAND_CASTLE.Name) and not REVEL.IsGridBroken(grid) then
                            local frontSide = grid.Position - modPos
                            local frontSideCollision = REVEL.room:GetGridCollisionAtPos(frontSide)
                            local backSide = grid.Position + modPos
                            local backSideCollision = REVEL.room:GetGridCollisionAtPos(backSide)

                            --check if there is an open area behind the castle and in front of it
                            --pit is allowed in front because thats where the rockwave goes
                            if (frontSideCollision == GridCollisionClass.COLLISION_NONE or frontSideCollision == GridCollisionClass.COLLISION_PIT) and backSideCollision == GridCollisionClass.COLLISION_NONE then
                                validCastlesIndexes[#validCastlesIndexes+1] = gridIndex
                                validCastlesData[#validCastlesData+1] = {Index = gridIndex, Position = backSide, Direction = direction, Opposite = grid.Position - (modPos*0.2)}
                            end
                        end
                    end

                    checkPos = checkPos + modPos
                end

                checkPos = player.Position
                modPos = modPos:Rotated(90)
            end

            if #validCastlesIndexes > 0 then
                local closestIndex = REVEL.GetClosestGridIndexToPosition(player.Position, validCastlesIndexes)
                for _, castleData in ipairs(validCastlesData) do
                    if castleData.Index == closestIndex then
                        data.TargetGrid = REVEL.room:GetGridEntity(castleData.Index)
                        data.TargetPosition = castleData.Position
                        data.TargetPositionOpposite = castleData.Opposite
                        data.SlamVelocity = (castleData.Opposite - castleData.Position):Normalized()
                        data.SlamDirection = castleData.Direction
                    end
                end
            end

            if not data.TargetPosition then
                data.DoPath = 40
            end
        end
    elseif data.State == "Slam" then
        data.BurrowTo = nil
        npc.Velocity = npc.Velocity * 0.5
        if data.SlamPos and data.TargetGrid and not REVEL.IsGridBroken(data.TargetGrid) then
            if not (sprite:IsPlaying("SlamSide") or sprite:IsPlaying("SlamDown") or sprite:IsPlaying("SlamUp") or sprite:IsFinished("SlamSide") or sprite:IsFinished("SlamDown") or sprite:IsFinished("SlamUp")) then

                --we animate the opposite of the direction here
                if data.SlamDirection == Direction.LEFT then
                    sprite:Play("SlamSide", true)
                    sprite.FlipX = true
                elseif data.SlamDirection == Direction.UP then
                    sprite:Play("SlamDown", true)
                elseif data.SlamDirection == Direction.RIGHT then
                    sprite:Play("SlamSide", true)
                elseif data.SlamDirection == Direction.DOWN then
                    sprite:Play("SlamUp", true)
                else
                    data.SlamPos = nil
                end

            end

            if sprite:IsEventTriggered("Slam") then
                REVEL.game:ShakeScreen(10)
                REVEL.SpawnCustomShockwave(data.TargetPositionOpposite, data.SlamVelocity * 8, "gfx/effects/revel2/tomb_shockwave.png", nil, nil, nil, 7, nil, SoundEffect.SOUND_ROCK_CRUMBLE)
            end

            if sprite:IsFinished("SlamSide") or sprite:IsFinished("SlamDown") or sprite:IsFinished("SlamUp") then
                data.SlamPos = nil
            end
        else
            data.State = "Idle"
            data.DoPath = 40
            sprite.FlipX = false
        end
    end
end, REVEL.ENT.SLAMBIP.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
    if npc.Variant == REVEL.ENT.SLAMBIP.variant then
        for i=1, math.random(3,4) do
            REVEL.SpawnSandGibs(npc.Position, RandomVector() * 2, npc)
        end
    end
end, REVEL.ENT.SLAMBIP.id)

end