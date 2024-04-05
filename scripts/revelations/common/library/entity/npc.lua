return function()

-- do each update, ideally before doing velocity updates 
-- (which is why this isn't a one off function that registers a callback) 
-- undoVelocityChanges: if true, undoes velocity changes due to knockback
-- Returns: knockback velocity if it was undone, nil otherwise
function REVEL.ApplyKnockbackImmunity(npc, undoVelocityChanges)
    local data = REVEL.GetData(npc)

    if not data.__InitKnockbackImmunity then
        data.__InitKnockbackImmunity = true
        data.__PrevKnockbackVelocity = npc.Velocity
        npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
        npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
        -- REVEL.DebugStringMinor("[Knockback immunity] applied to ", npc)
    end

    if npc:HasEntityFlags(EntityFlag.FLAG_KNOCKED_BACK) then
        npc:ClearEntityFlags(EntityFlag.FLAG_KNOCKED_BACK)
        if undoVelocityChanges then
            local velocityDiff = npc.Velocity - data.__PrevKnockbackVelocity
            -- REVEL.DebugStringMinor("[Knockback immunity] Resetting velocity to", data.__PrevKnockbackVelocity, "from", npc.Velocity, "for npc", npc)
            npc.Velocity = data.__PrevKnockbackVelocity
            return velocityDiff
        end
    end

    data.__PrevKnockbackVelocity = npc.Velocity
end

function REVEL.UpdateStateFrame(npc)
    local data = REVEL.GetData(npc)
    if npc.State ~= data.LastState then 
        npc.StateFrame = 0
        data.LastState = npc.State
    else
        npc.StateFrame = npc.StateFrame + 1
    end
end


function REVEL.MoveRandomly(npc, variance, reangleMinTime, reangleMaxTime, speed, reduce, tarPos, checkGridCollide)
    local dir = Vector.FromAngle(REVEL.GetMoveRandomlyAngle(npc, variance, reangleMinTime, reangleMaxTime, tarPos, checkGridCollide))
    npc.Velocity = (npc.Velocity * reduce) + (dir * speed)
end

function REVEL.GetMoveRandomlyAngle(npc, variance, reangleMinTime, reangleMaxTime, tarPos, checkGridCollide)
    local data = REVEL.GetData(npc)
    if not tarPos then
        tarPos = npc:GetPlayerTarget().Position
    end

    if not data.MoveRandomlyAngle then
        data.MoveRandomlyAngle = (tarPos - npc.Position):GetAngleDegrees() + math.random(-variance, variance)
        data.ReangleTime = math.random(reangleMinTime, reangleMaxTime) + 1
    end

    data.ReangleTime = data.ReangleTime - 1
    if data.ReangleTime <= 0 or (checkGridCollide and npc:CollidesWithGrid()) then
        data.MoveRandomlyAngle = (tarPos - npc.Position):GetAngleDegrees() + math.random(-variance, variance)
        data.ReangleTime = math.random(reangleMinTime, reangleMaxTime) + 1
    end

    return data.MoveRandomlyAngle
end

---@param npc EntityNPC
---@param reangleMinTime integer
---@param reangleMaxTime integer
---@param speed number acceleration in movement (speed if friction is 0)
---@param reduce number friction to apply
---@param checkGridCollide? boolean
---@return Direction moveRandomlyDirection
---@return boolean justChanged
function REVEL.MoveRandomlyAxisAligned(npc, reangleMinTime, reangleMaxTime, speed, reduce, checkGridCollide)
    local data = REVEL.GetData(npc)
    local justChanged = false

    if not data.MoveRandomlyDirection then
        ---@type Direction
        data.MoveRandomlyDirection = math.random(0, 3)
        data.ReangleTime = math.random(reangleMinTime, reangleMaxTime) + 1
        justChanged = true
    end

    data.ReangleTime = data.ReangleTime - 1
    if data.ReangleTime <= 0 or (checkGridCollide and npc:CollidesWithGrid()) then
        data.MoveRandomlyDirection = math.random(0, 3)
        data.ReangleTime = math.random(reangleMinTime, reangleMaxTime) + 1
        justChanged = true
    end

    local dir = REVEL.dirToVel[data.MoveRandomlyDirection]
    -- IDebug.RenderUntilNextUpdate(IDebug.RenderLine, npc.Position, npc.Position + dir * 25, nil, Color(1, 0, 0, 1,conv255ToFloat( 0, 0, 0)))
    npc.Velocity = (npc.Velocity * reduce) + (dir * speed)
    -- IDebug.RenderUntilNextUpdate(IDebug.RenderLine, npc.Position, npc.Position + npc.Velocity * 25, nil, Color(0, 1, 0, 1,conv255ToFloat( 0, 0, 0)))

    return data.MoveRandomlyDirection, justChanged
end

---@param npc EntityNPC
---@param pauseMinTime integer
---@param pauseMaxTime integer
---@param walkMinTime integer
---@param walkMaxTime integer
---@param reangleMinTime integer
---@param reangleMaxTime integer
---@param speed number acceleration in movement (speed if friction is 0)
---@param reduce number friction to apply
---@param checkGridCollide? boolean
---@return Direction moveRandomlyDirection
---@return boolean justChanged
function REVEL.MoveRandomlyAxisAlignedPausing(npc, 
    pauseMinTime, pauseMaxTime, walkMinTime, walkMaxTime,
    reangleMinTime, reangleMaxTime, speed, reduce, checkGridCollide
    )

    -- data.MoveRandomlyPauseTime > 0: stopped
    -- data.MoveRandomlyPauseTime < 0: walking

    local data = REVEL.GetData(npc)
    local justChanged = false

    if not data.MoveRandomlyPauseTime then
        local startPausedChance = pauseMaxTime / (pauseMaxTime + walkMaxTime)
        if math.random() < startPausedChance then
            data.MoveRandomlyPauseTime = math.random(pauseMinTime, pauseMaxTime)
        else
            data.MoveRandomlyPauseTime = - math.random(walkMinTime, walkMaxTime)
        end
    -- paused counter
    elseif data.MoveRandomlyPauseTime > 0 then
        data.MoveRandomlyPauseTime = data.MoveRandomlyPauseTime - 1
        if data.MoveRandomlyPauseTime <= 0 then
            justChanged = true
            data.MoveRandomlyPauseTime = - math.random(walkMinTime, walkMaxTime)
        end
    -- walking counter
    else
        data.MoveRandomlyPauseTime = data.MoveRandomlyPauseTime + 1
        if data.MoveRandomlyPauseTime >= 0 then
            justChanged = true
            data.MoveRandomlyPauseTime = math.random(pauseMinTime, pauseMaxTime)
        end
    end

    -- paused
    if data.MoveRandomlyPauseTime > 0 then
        data.MoveRandomlyDirection = nil
        data.ReangleTime = nil
        npc.Velocity = npc.Velocity * reduce

        return Direction.NO_DIRECTION, justChanged
    -- walking
    else
        return REVEL.MoveRandomlyAxisAligned(npc, reangleMinTime, reangleMaxTime, speed, reduce, checkGridCollide)
    end
end

function REVEL.CurvedPathAngle(npc, data, pos, maxAngle, reangleTimeMax, reangleStep, friction, speed)
    if not data.cTime then
      data.cTime = 0
    end
  
    local angle = math.max(0, (maxAngle or 45) - data.cTime * reangleStep)
  
    if npc.Position:DistanceSquared(pos) < 1600 then --40^2 = 1600; 40 = 1 tile
        angle = 0
    end
  
    data.cTime = data.cTime + 1
  
    if data.cTime >= reangleTimeMax then
        data.cTime = nil
    end
  
    npc.Velocity = npc.Velocity * (friction or npc.Friction) + (pos-npc.Position):Rotated(angle):Resized(speed or 5)
end

function REVEL.MoveAt(npc, pos, speed, reduce)
    npc.Velocity = (npc.Velocity *  reduce) + (pos - npc.Position):Resized(speed)
end

function REVEL.LerpEntityPositionSmooth(entity, pos, tar, time)
    local data = REVEL.GetData(entity)
  
    if not data.LerpFrames then
        data.LerpFrames = 0
    end
  
    data.LerpFrames = data.LerpFrames + 1
  
    local nextPosition = REVEL.SmoothLerp2(pos, tar, data.LerpFrames, 0, time)
    entity.Velocity = (nextPosition - entity.Position)  / 2
  
    if data.LerpFrames >= time then
        data.LerpFrames = nil
        return false
    end
  
    return true
end

end