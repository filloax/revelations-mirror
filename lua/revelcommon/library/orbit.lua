REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()


function REVEL.GetMultiOrbitAngle(i, numOrbiting, direction)
    numOrbiting, direction = numOrbiting or 1, direction or 1
    return (i * ((math.pi * 2) / numOrbiting)) * direction
end

function REVEL.GetOrbitOffset(angle, distance)
    return Vector( distance * math.cos(angle), distance * math.sin(angle))
end

-- TODO: replace with REVEL.GetOrbitPosition in other branches too
function REVEL.GetOrbitPosition(entity, angle, distance)
    return Vector(entity.Position.X + (distance * math.cos(angle)),entity.Position.Y + (distance * math.sin(angle)))
end

function REVEL.GetOrbitPositionEllipse(pos, angle, distX, distY)
    return Vector(pos.X + (distX * math.cos(angle)),pos.Y + (distY * math.sin(angle)))
end
  
  
end