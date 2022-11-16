REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- TODO: replace with REVEL version in other branches too
function REVEL.GetDirectionFromVelocity(velocity)
    if math.abs(velocity.X) < math.abs(velocity.Y) then
        if velocity.Y >= 0 then
            return Direction.DOWN
        else
            return Direction.UP
        end
    else
        if velocity.X >= 0 then
            return Direction.RIGHT
        else
            return Direction.LEFT
        end
    end
end
    
function REVEL.GetFacingDirection(pos, posTwo)
    local diff = posTwo - pos
    local x, y = diff.X, diff.Y

    if math.abs(x) > math.abs(y) then
        if x < 0 then
            return "Left"
        else
            return "Right"
        end
    else
        if y < 0 then
            return "Up"
        else
            return "Down"
        end
    end
end

function REVEL.GetAlignment(pos, posTwo)
    local facing = REVEL.GetFacingDirection(pos, posTwo)
    if facing == "Left" or facing == "Right" then
        return facing, math.abs(pos.Y - posTwo.Y)
    else
        return facing, math.abs(pos.X - posTwo.X)
    end
end

--[[
dirToAngle = {
    [0] = 180,
    [1] = -90,
    [2] = 0,
    [3] = 90
},
]]

function REVEL.GetDirectionFromAngle(angle)
    local mangle = angle % 360
    if mangle < 45 or mangle >= 315 then --90, 270+45
        return Direction.RIGHT
    elseif mangle < 135 then --90+45
        return Direction.DOWN
    elseif mangle < 225 then --180+45
        return Direction.LEFT
    else --270
        return Direction.UP
    end
end

end