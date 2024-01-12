return function()

-- Sickie

local function GetOverlayColoration(r, g, b)
    return Color(r / 135, g / 135, b / 135, 1,conv255ToFloat( 0, 0, 0))
end
    
local projectileColor = GetOverlayColoration(52, 93, 89)

local function IsSolidGrid(collision)
    return collision == GridCollisionClass.COLLISION_SOLID
        or collision == GridCollisionClass.COLLISION_OBJECT
        --or collision == GridCollisionClass.COLLISION_WALL
        --or collision == GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER
end

local GridEdgeCenterDifference = Vector(21, 21)
local function GetGridEdges(pos)
    return pos - GridEdgeCenterDifference, pos + GridEdgeCenterDifference
end

-- finds the nearest free edge from the given position clamped to the grid
-- returns free edge position, solid clamped grid position (both can be nil if not applicable)
local function FullClampPosition(pos, margin)
    local clamped = REVEL.room:GetClampedPosition(pos, margin)
    local collision = REVEL.room:GetGridCollisionAtPos(clamped)
    if IsSolidGrid(collision) then
        local topLeftEdge, bottomRightEdge = GetGridEdges(REVEL.room:GetGridPosition(REVEL.room:GetGridIndex(clamped)))
        local checkEdges = {
            Vector(bottomRightEdge.X, pos.Y),
            Vector(pos.X, topLeftEdge.Y),
            Vector(topLeftEdge.X, pos.Y),
            Vector(pos.X, bottomRightEdge.Y),
            Vector(topLeftEdge.X, topLeftEdge.Y),
            Vector(bottomRightEdge.X, bottomRightEdge.Y),
            Vector(topLeftEdge.X, bottomRightEdge.Y),
            Vector(bottomRightEdge.X, topLeftEdge.Y)
        }

        local closestFreePos, minDist
        for _, edge in ipairs(checkEdges) do
            local collisionTwo = REVEL.room:GetGridCollisionAtPos(edge)
            if not IsSolidGrid(collisionTwo) then
                local dist = edge:DistanceSquared(pos)
                if not minDist or dist < minDist then
                    closestFreePos = edge
                    minDist = dist
                end
            end
        end

        return closestFreePos, clamped
    end

    return clamped, nil
end

-- Sickie BT
-- root
--  Selection
--      Sequence
--          Idle
--          TrySneeze
--      Sneeze
---@param npc EntityNPC
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.SICKIE.variant then return end

    local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

    REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)

    data.revelFrostEnemy = true

    npc.SplatColor = REVEL.WaterSplatColor

    if not data.Cooldown then
        data.Cooldown = math.random(45, 60)
    end

    local shouldWalk = true

    if data.TargetAtSneeze then
        local overlayFrame = sprite:GetOverlayFrame()
        npc.Velocity = npc.Velocity * 0.85
        shouldWalk = not (overlayFrame >= 24 and overlayFrame < 71) -- 24 = sneeze, 72 = begin to walk + 1 frame to transition to walking?
        if overlayFrame == 24 and not data.TriggeredSneeze then -- can't check for an event on an overlay thanks nicalis
            data.TriggeredSneeze = true
            
            -- aim for the target with some bias towards their position when the sneeze anim started
            local sneezeTarget = target.Position * 0.75 + data.TargetAtSneeze * 0.25
            -- also nudge the target closer to the npc so it's less likely to sail over the player
            sneezeTarget = sneezeTarget * 0.95 + npc.Position * 0.05

            local params = ProjectileParams()
            params.VelocityMulti = 1.1
            params.FallingSpeedModifier = -0.75
            params.FallingAccelModifier = 0.5
            params.HeightModifier = 8
            params.Scale = 1.25

            -- Reduce falling speed variance
            local avgFallingSpeed = -7.5

            REVEL.SpreadBossProjectiles(npc, 6, sneezeTarget, 0, params, 100, function(proj)
                proj.Friction = 0.9
                proj.Size = proj.Size * proj.Scale
                proj.FallingSpeed = REVEL.Lerp(proj.FallingSpeed, avgFallingSpeed, 0.5)
                --proj.SplatColor = projectileColor

                proj:GetSprite():Load('gfx/projectiles/low_flash_projectile.anm2', true)
                proj:GetSprite().Scale = Vector(1.4,1.4)

                local pdata = proj:GetData()
                pdata.ColoredProjectile = projectileColor
                pdata.IsSickieTear = true
                pdata.SpawnerSeed = npc.InitSeed
            end)

            sprite:PlayOverlay((sneezeTarget.Y < npc.Position.Y) and 'SneezeUp' or 'Sneeze', true)
            REVEL.SkipAnimFrames(sprite, 24)

            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WHEEZY_COUGH, 1, 0, false, 0.8)
        end

        if sprite:IsOverlayFinished('Sneeze') or sprite:IsOverlayFinished('SneezeUp') then data.TargetAtSneeze = nil end
    else
        data.TriggeredSneeze = nil
        
        if data.Path then
            -- entity, speed, path, useDirect, friction
            -- useDirect currently makes it walk into spikes
            REVEL.FollowPath(npc, 0.5, data.Path, false, 0.85)
        else
            npc.Velocity = npc.Velocity * 0.85
            -- shouldWalk = false
        end

        if not sprite:IsOverlayPlaying("Head") then
            sprite:PlayOverlay('Head', true)
        end

        data.Cooldown = data.Cooldown - 1
        if npc.Position:DistanceSquared(target.Position) < 200 ^ 2
            and data.Cooldown <= 0 then
            data.TargetAtSneeze = target.Position
            data.Cooldown = math.random(45, 60)
            sprite:PlayOverlay((data.TargetAtSneeze.Y < npc.Position.Y) and 'SneezeUp' or 'Sneeze', true)
        end
    end

    if shouldWalk then
        if npc.Velocity:LengthSquared() > 2 then
            REVEL.AnimateWalkFrame(sprite, npc.Velocity, {Horizontal = "WalkHori", Vertical = "WalkVert"})
        else
            sprite:Play("Idle", true)
        end
    else
        sprite:SetFrame("None", 0)
    end
end, REVEL.ENT.SICKIE.id)

local function GridStickTimeout()
    return math.random(540, 600)
end

local function StickTo(pro, data, ent, period)
    data.Stick = {
        Parent = ent,
        Scale = pro.Scale * 1.2,
        Offset = (pro.Position - ent.Position) * 0.65, -- pull it in tighter
        Height = pro.Height * 0.4, -- make it lower to the ground
        FallingAccel = pro.FallingAccel,
        Timer = period
    }
    pro.Size = pro.Size * 1.25 -- make it more likely to actually hit things
    pro.DepthOffset = ent.DepthOffset + 20
    pro.Velocity = Vector.Zero
    pro.FallingAccel = -0.1
    pro.FallingSpeed = 0
end

local function TryStickToEntity(pro, ent)
    if ent.EntityCollisionClass == EntityCollisionClass.ENTCOLL_NONE
    or ent.Type == EntityType.ENTITY_PLAYER
    or ent.Type == EntityType.ENTITY_PROJECTILE
    or ent.Type == EntityType.ENTITY_TEAR
    or ent.Type == EntityType.ENTITY_FAMILIAR
    or ent.Type == EntityType.ENTITY_LASER
    or ent.Type == EntityType.ENTITY_KNIFE
    then return end

    local data = pro:GetData()
    if data.Stick or data.SpawnerSeed == ent.InitSeed then return end

    local timeout
    if ent:IsEnemy() then
        local npcData = ent:GetData()
        npcData.SickieCount = npcData.SickieCount or 0

        if npcData.SickieCount >= 3 then return end
        npcData.SickieCount = npcData.SickieCount + 1

        -- sticks for 10 minutes, effectively sticks forever
        timeout = 60 * 60 * 10
    else
        timeout = GridStickTimeout()
    end

    StickTo(pro, data, ent, timeout)
    return true
end

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, ent)
    local data = ent:GetData()
    if data.IsSickieTear and data.Stick and data.Stick.Parent then
        local npcData = data.Stick.Parent:GetData()
        if npcData.SickieCount then
            npcData.SickieCount = npcData.SickieCount - 1
        end
    end
end)

-- creates a basic fake grid entity required for handling grid ent parents the same as regular ents
local function FakeGridParent(pos)
    pos = REVEL.room:GetGridPosition(REVEL.room:GetGridIndex(pos))
    local dat = {}
    return {
        Position = pos,
        DepthOffset = 10000,
        GetData = function() return dat end,
        IsEnemy = function() return false end,
        Exists = function() return REVEL.room:GetGridCollisionAtPos(pos) ~= GridCollisionClass.COLLISION_NONE end
    }
end

-- Projectile BT
-- root
--  Selection
--      Sequence
--          MaintainStick
--          TryUnstick
--      Selection
--          StickToEnemy
--          StickToGrid
revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
    local data = pro:GetData()
    if not data.IsSickieTear then return end

    -- MaintainStick
    if data.Stick then
        local stick = data.Stick
        stick.Timer = stick.Timer - 1
        pro.Scale = REVEL.Lerp(pro.Scale, stick.Scale, 0.4)
        pro.FallingAccel = -0.1
        pro.FallingSpeed = 0
        pro.Position = stick.Parent.Position + stick.Offset
        pro.Velocity = Vector.Zero
        pro.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
        -- return true
        -- return false

        -- TryUnstick
        if stick.Timer <= 0 or not stick.Parent:Exists() then
            local npcData = stick.Parent:GetData()
            if npcData.SickieCount then
                npcData.SickieCount = npcData.SickieCount - 1
            end

            -- shoot off enemies on death
            local speed = (not stick.Parent:Exists() and stick.Parent:IsEnemy()) and 15 or 2
            pro.Velocity = stick.Offset:Resized(speed)

            pro.FallingSpeed = -2
            pro.FallingAccel = stick.FallingAccel
            stick.Parent = nil
            stick.Timer = nil
            data.IsSickieTear = nil
            -- return true
        end
        return --false
    end

    -- StickToEntity
    for k,ent in pairs(REVEL.roomEntities) do
        if pro.Position:DistanceSquared(ent.Position) < (pro.Size + ent.Size) ^ 2 then
            if TryStickToEntity(pro, ent) then
                return --true
            end
        end
    end
    -- return false

    -- StickToGrid
    local clamped, gridPos = FullClampPosition(pro.Position, 4)
    if gridPos and clamped and (clamped.X ~= pro.Position.X or clamped.Y ~= pro.Position.Y) then
        pro.Position = clamped
        StickTo(pro, data, FakeGridParent(gridPos), GridStickTimeout())
        return --true
    end
    -- return false

end)

end