REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Snipebip

local scopeTimer = 40

local laserMinColor = Color(1, 1, 1, 0.2,conv255ToFloat( 180, 32, 42))
local laserMaxColor = Color(1, 1, 1, 0.6,conv255ToFloat( 180, 32, 42))
local laserFlashColor = Color(1, 1, 1, 1,conv255ToFloat( 255, 0, 0))
local laserInvisibleColor = Color(1, 1, 1, 0,conv255ToFloat( 180, 32, 42))

local Line = REVEL.LazyLoadRoomSprite{
    ID = "snipebip_Line",
    Anm2 = "gfx/effects/revel2/black_line.anm2",
    Scale = Vector(1, 1.5),
    OnCreate = function(sprite)
        sprite:SetFrame("Idle", 0)
    end,
}

local Circle = REVEL.LazyLoadRoomSprite{
    ID = "snipebip_Circle",
    Anm2 = "gfx/effects/revel2/black_circle.anm2",
    Scale = Vector(0.025, 0.025),
    OnCreate = function(sprite)
        sprite:SetFrame("Idle", 0)
    end,
}

local snipebipHeight = -9
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.SNIPEBIP.variant then
        return
    end

    local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()
    if not data.State then
        npc.PositionOffset = Vector(0, snipebipHeight)
        npc.Position = npc.Position + Vector(-2, 0)
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        data.State = "Idle"
        data.SelectedTower = REVEL.room:GetGridIndex(npc.Position)
        REVEL.LockGridIndex(data.SelectedTower)
        data.AttackCooldown = math.random(20, 40)
        npc.SplatColor = REVEL.SandSplatColor
    end

    if npc:IsDead() and data.SelectedTower then
        REVEL.UnlockGridIndex(data.SelectedTower)
    end

    local sandcastles = StageAPI.GetCustomGrids(nil, REVEL.GRIDENT.SAND_CASTLE.Name)
    local towers = {}
    for _, castle in ipairs(sandcastles) do
        local index = castle.GridIndex
        
        local grid = REVEL.room:GetGridEntity(index)
        if (REVEL.IsGridIndexUnlocked(index) or index == data.SelectedTower) and grid and not REVEL.IsGridBroken(grid) then
            local frame = grid:GetSprite():GetFrame()
            if not (frame == 1 or frame == 2 or frame == 4 or frame == 5 or frame == 8 or frame == 9 or frame == 10 or frame == 21 or frame == 22) then
                towers[#towers + 1] = index
            end
        end
    end

    local index = REVEL.room:GetGridIndex(npc.Position)
    if not REVEL.includes(towers, index) then
        if data.State ~= "OffIdle" and data.State ~= "BurrowToTower" and data.State ~= "ShootOff" then
            REVEL.UnlockGridIndex(index)
            data.State = "OffIdle"
        end
    else
        npc.Velocity = Vector.Zero
        npc.Position = REVEL.room:GetGridPosition(index) + Vector(-2, 0)
        npc.PositionOffset = Vector(0, snipebipHeight)
    end

    if data.State == "OffIdle" then
        if not sprite:IsPlaying("Idle") then
            sprite:Play("Idle", true)
        end

        if npc.PositionOffset.Y < 0 then
            data.Falling = true
            data.TimeSinceFallen = nil
            npc.Velocity = Vector.Zero
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        else
            data.TimeSinceFallen = data.TimeSinceFallen or 0
            data.TimeSinceFallen = data.TimeSinceFallen + 1
            npc.Pathfinder:MoveRandomly()
            npc.Velocity = npc.Velocity * 0.8
            if #towers > 0 then
                if data.TimeSinceFallen > 30 then
                    data.SelectedTower = towers[math.random(1, #towers)]
                    REVEL.LockGridIndex(data.SelectedTower)
                    data.State = "BurrowToTower"
                    sprite:Play("DigDown", true)
                    REVEL.sfx:NpcPlay(npc, REVEL.SFX.BIP_BURROW, 0.6, 0, false, 1)
                end
            else
                data.AttackCooldown = data.AttackCooldown - 1
                if data.AttackCooldown <= 0 then
                    data.State = "ShootOff"
                    sprite:Play("ScopeStart", true)
                    REVEL.sfx:NpcPlay(npc, REVEL.SFX.SNIPEBIP_CHARGE, 0.6, 0, false, 0.9+(math.random()*0.2))
                    data.AttackCooldown = math.random(20, 40)
                end
            end
        end
    elseif data.State == "Idle" then
        if not sprite:IsPlaying("Idle2") then
            sprite:Play("Idle2", true)
        end

        data.AttackCooldown = data.AttackCooldown - 1
        if data.AttackCooldown <= 0 then
            data.State = "Shoot"
            sprite:Play("ScopeStart2", true)
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.SNIPEBIP_CHARGE, 0.6, 0, false, 0.9+(math.random()*0.2))
            data.AttackCooldown = math.random(20, 40)
        end
    elseif data.State == "Shoot" or data.State == "ShootOff" then
        npc.Velocity = Vector.Zero
        local suffix = ""
        if data.State == "Shoot" then
            suffix = "2"
        end

        if sprite:IsFinished("ScopeStart" .. suffix) then
            data.ScopeTime = 0
            data.ScopeEnd = nil
            data.ScopeAngle = nil
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.SNIPEBIP_SCOPE, 0.6, 0, false, 1)
            sprite:Play("Scoping" .. suffix, true)
        end

        if sprite:IsPlaying("Scoping" .. suffix) then
            data.ScopeTime = data.ScopeTime + 1
            if data.ScopeTime >= scopeTimer then
                data.ShootTriggered = 0
                data.TimeSinceShoot = 0
                sprite:Play("Shoot" .. suffix, true)
            end
        end

        if data.TimeSinceShoot then
            data.TimeSinceShoot = data.TimeSinceShoot + 1
            if data.TimeSinceShoot > 3 then
                data.TimeSinceShoot = nil
            end
        end

        if sprite:IsEventTriggered("Shoot") then
            data.ShootTriggered = data.ShootTriggered + 1
            if data.ShootTriggered == 1 then
                data.InitialShootAngle = data.ScopeAngle
                data.GoalShootAngle = data.ScopeAngle
                data.ShootAngle = data.GoalShootAngle
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.SNIPEBIP_SHOOT, 1, 0, false, 1+(math.random()*0.2))
            elseif data.ShootTriggered == 2 then
                local addGoal = math.random(1, 2)
                if addGoal == 2 then
                    addGoal = -1
                end

                data.GoalShootAngle = data.InitialShootAngle + 15 * addGoal
            elseif data.ShootTriggered == 3 then
                if data.GoalShootAngle < data.InitialShootAngle then
                    data.GoalShootAngle = data.InitialShootAngle + 15
                else
                    data.GoalShootAngle = data.InitialShootAngle - 15
                end
            end
        end

        if sprite:WasEventTriggered("Shoot") and not sprite:WasEventTriggered("Stop") then
            data.ShootAngle = REVEL.Lerp(data.ShootAngle, data.GoalShootAngle, 0.15)
            local newProjectile = REVEL.SpawnNPCProjectile(npc, Vector.FromAngle(data.ShootAngle + math.random(-2, 2)) * 14)
            newProjectile.Scale = 0.5
            newProjectile.FallingAccel = -0.1
            newProjectile:GetData().SandProjectile = true
            newProjectile:GetData().IsSandTear = true
            newProjectile:Update()
            newProjectile.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
            newProjectile:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel2/sand_bulletatlas.png")
            newProjectile:GetSprite():LoadGraphics()
            newProjectile:GetSprite():Play("RegularTear1", true)
        end

        if sprite:IsFinished("Shoot" .. suffix) then
            if data.State == "ShootOff" then
                data.State = "OffIdle"
            else
                data.State = "Idle"
            end
        end
    elseif data.State == "BurrowToTower" then
        npc.Velocity = Vector.Zero
        if sprite:IsFinished("DigDown") then
            npc.Position = REVEL.room:GetGridPosition(data.SelectedTower) + Vector(-2, 0)
            npc.PositionOffset = Vector(0, snipebipHeight)
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            sprite:Play("DigUp2", true)
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.BIP_EMERGE, 0.6, 0, false, 1)
        end

        if sprite:IsFinished("DigUp2") then
            data.State = "Idle"
            data.AttackCooldown = math.random(20, 40)
        end
    end
end, REVEL.ENT.SNIPEBIP.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc, renderOffset)
    if npc.Variant ~= REVEL.ENT.SNIPEBIP.variant then
        return
    end

    local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()
    local isRenderPassNormal = REVEL.IsRenderPassNormal()

    if data.Falling and isRenderPassNormal then
        npc.PositionOffset = Vector(0, math.min(npc.PositionOffset.Y + 1, 0))
        if npc.PositionOffset.Y >= 0 then
            data.Falling = nil
        end
    end

    local isScoping = sprite:IsPlaying("Scoping") or sprite:IsPlaying("Scoping2")
    local isShooting = sprite:IsPlaying("Shoot") or sprite:IsPlaying("Shoot2")
    if isScoping or (isShooting and data.TimeSinceShoot) then
        local worldStartPos = npc.Position + npc.PositionOffset + Vector(-8, -19)
        local worldEndPos = target.Position + Vector(0, -40)
        if not REVEL.game:IsPaused() and isRenderPassNormal then
            if not data.ScopeAngle then
                data.ScopeAngle = 90
            end

            local targetAngle = (worldEndPos - worldStartPos):GetAngleDegrees()
            local shortestAngle = ((targetAngle - data.ScopeAngle) + 180) % 360 - 180
            if isScoping then
                data.ScopeAngle = REVEL.Lerp(data.ScopeAngle, data.ScopeAngle + shortestAngle, 0.1)
            end

            local endPos = worldStartPos + (Vector.FromAngle(data.ScopeAngle) * worldEndPos:Distance(worldStartPos))
            if math.abs(shortestAngle) < 4 then
                data.ScopeEnd = endPos
            else
                data.ScopeEnd = worldStartPos + Vector.FromAngle(data.ScopeAngle) * 1000
            end
        end

        if data.ScopeEnd then
            if isRenderPassNormal then
                local useColor
                if data.TimeSinceShoot then
                    useColor = Color.Lerp(laserFlashColor, laserInvisibleColor, data.TimeSinceShoot / 3)
                else
                    if data.ScopeTime <= scopeTimer - 3 then
                        useColor = Color.Lerp(laserMinColor, laserMaxColor, data.ScopeTime / (scopeTimer - 3))
                    else
                        useColor = Color.Lerp(laserMaxColor, laserFlashColor, (data.ScopeTime - (scopeTimer - 3)) / 3)
                    end
                end

                Line.Color = useColor
                Circle.Color = useColor
            end

            local endPos = Isaac.WorldToScreen(data.ScopeEnd) + renderOffset - REVEL.room:GetRenderScrollOffset()
            local startPos = Isaac.WorldToScreen(worldStartPos) + renderOffset - REVEL.room:GetRenderScrollOffset()
            REVEL.DrawRotatedTilingSprite(Line, startPos, endPos, 512)
            Circle:Render(endPos, Vector.Zero, Vector.Zero)
        end
    end
end, REVEL.ENT.SNIPEBIP.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
    if npc.Variant == REVEL.ENT.SNIPEBIP.variant then
        for i=1, math.random(3,4) do
            REVEL.SpawnSandGibs(npc.Position, RandomVector() * 2, npc)
        end
    end
end, REVEL.ENT.SNIPEBIP.id)


end