return function()

REVEL.DEBUG_LINE_COLLISION = false


---@param position Vector
---@param lineStart Vector
---@param lineEnd Vector
---@return number
function REVEL.LineDistance(position, lineStart, lineEnd)
    local lineDir = lineEnd - lineStart
    local perpDir = Vector(lineDir.Y, -lineDir.X)
    local dirToPt1 = lineStart - position
    return math.abs(dirToPt1:Dot(perpDir:Normalized()))
end

---Check collision between a position or an entity, and a line. If an entity is passed,
---check against its size too.
---@param position Vector
---@param lineStart Vector
---@param lineEnd Vector
---@param lineWidth number
---@return boolean
---@overload fun(entity: Entity, lineStart: Vector, lineEnd: Vector, lineWidth: number): boolean
function REVEL.CollidesWithLine(position, lineStart, lineEnd, lineWidth)
    if REVEL.DEBUG_LINE_COLLISION and IDebug then
        IDebug.RenderUntilNextUpdate(IDebug.RenderLine, lineStart, lineEnd, false, Color(0, 0, 1, 0.8), lineWidth * REVEL.SCREEN_TO_WORLD_RATIO)
    end

    if position.Type then
        ---@type Entity
        local entity = position
        position = entity.Position
        -- x2 to "expand" in both directions
        lineWidth = lineWidth + entity.Size * 2
    end

    -- /2 as width is total width, we're checking distance from line center
    return REVEL.LineDistance(position, lineStart, lineEnd) < lineWidth / 2
end

---NOTE: This will NOT work for homing lasers. Likely unresolvable unless :GetSamples() is functional.
---@param position Vector
---@param laser EntityLaser
---@param add? number
---@return boolean
function REVEL.CollidesWithLaser(position, laser, add)
    if laser:IsCircleLaser() then
        local distanceFromCenter = position:Distance(laser.Position)
        if math.abs(distanceFromCenter - laser.Radius) < laser.Size then
            return true
        end
    else
        if REVEL.CollidesWithLine(position, laser.Position, laser:GetEndPoint(), (laser.Size / 2) + (add or 0)) then
            return true
        end
    end

    return false
end

---returns closest point of collision (as in, closest point on square to circle's center) 
---relative to center (so, vector from center to closest) if colliding, nil if not
---@param circlePos Vector
---@param squarePos Vector
---@param circleRad? number Defaults to 0
---@param squareRad number Half-side of the square
---@return Vector?
function REVEL.GetCollisionCircleSquare(circlePos, squarePos, circleRad, squareRad)
    circleRad = circleRad or 0
  
    local diff = circlePos - squarePos
    local closest = diff:Clamped(-squareRad, -squareRad, squareRad, squareRad)
    local absDiff = REVEL.AbsVector(diff)
  
  --  IDebug.RenderUntilNext("Circle square coll", IDebug.RenderCircle, sPos + closest, 5, nil, nil, Color(0,1,0,1,conv255ToFloat(0,0,0)))
  
    if absDiff.X > circleRad + squareRad or absDiff.Y > circleRad + squareRad then return nil end
    if absDiff.X <= squareRad or absDiff.Y <= squareRad then return closest end --center inside square
  
    local closestDistSquared = (diff.X - closest.X) ^ 2 + (diff.Y - closest.Y) ^ 2
  
    if closestDistSquared <= circleRad ^ 2 then
        return closest
    else
        return nil
    end
end

---Simpler check than [REVEL.GetCollisionCircleSquare] as it only checks whether it collides without
---returning collision point
---@param circleCenter Vector
---@param circleRadius number
---@param rectCorner1 Vector
---@param rectCorner2 Vector
---@return Vector?
function REVEL.GetCollisionCircleRect(circleCenter, circleRadius, rectCorner1, rectCorner2)
    local minx, miny = math.min(rectCorner1.X, rectCorner2.X), math.min(rectCorner1.Y, rectCorner2.Y)
    local maxx, maxy = math.max(rectCorner1.X, rectCorner2.X), math.max(rectCorner1.Y, rectCorner2.Y)
    -- local sizex, sizey = maxx - minx, maxy - miny

    local closestPoint = circleCenter:Clamped(minx, miny, maxx, maxy)
    
    if (circleCenter - closestPoint):LengthSquared() < circleRadius ^ 2 then
        return closestPoint
    end
end


-- checks if a EntityGridCollisionClass should collide with a GridCollisionClass
---@param eColClass EntityGridCollisionClass
---@param gColClass GridCollisionClass
---@param isPlayer? EntityPlayer
---@return boolean
function REVEL.CanCollideWithGrid(eColClass, gColClass, isPlayer)
    if gColClass == GridCollisionClass.COLLISION_PIT then
        return eColClass == EntityGridCollisionClass.GRIDCOLL_GROUND
    elseif gColClass == GridCollisionClass.COLLISION_SOLID or gColClass == GridCollisionClass.COLLISION_OBJECT then
        return eColClass == EntityGridCollisionClass.GRIDCOLL_GROUND or eColClass == EntityGridCollisionClass.GRIDCOLL_NOPITS or eColClass == EntityGridCollisionClass.GRIDCOLL_BULLET
    elseif gColClass == GridCollisionClass.COLLISION_WALL then
        return eColClass ~= EntityGridCollisionClass.GRIDCOLL_NONE
    elseif gColClass == GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER then
        return eColClass ~= EntityGridCollisionClass.GRIDCOLL_NONE and not isPlayer
    end
    return false
end

---@deprecated
REVEL.LineDistance2 = REVEL.LineDistance

end