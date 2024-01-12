return function()

    
function REVEL.LineDistance(position, lineStart, lineEnd)
    return ((position.X - lineStart.X) * (lineEnd.Y - lineStart.Y)) 
        - ((position.Y - lineStart.Y) * (lineEnd.X - lineStart.X))
end

-- distance of p from line p1p2  vec2 lineDir = p2 - p1;
function REVEL.LineDistance2(p, p1, p2)
    local lineDir = p2 - p1
    local perpDir = Vector(lineDir.Y, -lineDir.X)
    local dirToPt1 = p1 - p
    return math.abs(dirToPt1:Dot(perpDir:Normalized()))
end
  
function REVEL.CollidesWithLine(position, lineStart, lineEnd, lineWidth)
    return lineStart:Distance(position) + lineEnd:Distance(position) - lineStart:Distance(lineEnd) < lineWidth
end

-- NOTE: This will NOT work for homing lasers. Likely unresolvable unless :GetSamples() is functional.
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

--returns closest point of collision (as in, closest point on square to circle's center) relative to center (so, vector from center to closest) if colliding, nil if not
function REVEL.GetCollisionCircleSquare(cPos, sPos, cRad, sRad) --cRad will default to 0 (ie a dot)
    cRad = cRad or 0
  
    local diff = cPos - sPos
    local closest = diff:Clamped(-sRad, -sRad, sRad, sRad)
    local absDiff = REVEL.AbsVector(diff)
  
  --  IDebug.RenderUntilNext("Circle square coll", IDebug.RenderCircle, sPos + closest, 5, nil, nil, Color(0,1,0,1,conv255ToFloat(0,0,0)))
  
    if absDiff.X > cRad + sRad or absDiff.Y > cRad + sRad then return nil end
    if absDiff.X <= sRad or absDiff.Y <= sRad then return closest end --center inside square
  
    local closestDistSquared = (diff.X - closest.X) ^ 2 + (diff.Y - closest.Y) ^ 2
  
    if closestDistSquared <= cRad ^ 2 then
        return closest
    else
        return nil
    end
end

end