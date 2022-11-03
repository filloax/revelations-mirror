REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()


--If vector's inclinations/tangents/<number that is relative to angle> are different by x percent, return true, also takes signs into consideration
--Faster than calculating angles
function REVEL.IsVecTanDifferent(vec1, vec2, percentDiff)
    local x1, x2 = vec1.X, vec2.X --divide by 0 prevention
    if x1 == 0 then x1 = 0.0001 end
    if x2 == 0 then x2 = 0.0001 end
  
    return (vec1.Y/x1)/(vec2.Y/x2) > (1+percentDiff) --vec1 is steeper than vec2 by percentDiff
      or (vec2.Y/x2)/(vec1.Y/x1) > (1+percentDiff) --vec2 is steeper than vec1 by percentDiff
      or x1*x2 < 0 or vec1.Y*vec2.Y < 0 --different signs
end

function REVEL.GetXVector(v)
    if type(v) ~= "number" then v = v.X end
    return Vector(v, 0)
end

function REVEL.GetYVector(v)
    if type(v) ~= "number" then v = v.Y end
    return Vector(0, v)
end

function REVEL.SquareVec(a)
    return Vector(a,a)
end

--Get the components of a vector relative to another vector, first return is parallel 2nd is perpendicular, then respective lengths
--You can pass length as an arg if it was already calculated to save time
--Might look weird but I put some stuff that is split into functions here to avoid repeating calculations, its meant for being repeated p often in short times
---@param v Vector
---@param ref Vector
---@param lv? number
---@param lref? number
---@return Vector parallelVec
---@return Vector perpendicularVec
---@return number parallelLength
---@return number perpendicularLength
function REVEL.GetVectorComponents(v, ref, lv, lref)
    lv = lv or v:Length()
    lref = lref or ref:Length()
  
    local dotProd = v.X * ref.X + v.Y * ref.Y
    local angleCos = dotProd / (lv * lref) --cosine of the angle between the 2 vectors
  
    if dotProd and dotProd ~= 0 and tonumber(angleCos) and lv ~= 0 and lref ~= 0 then
        local angleSin = math.sqrt( 1 -  angleCos * angleCos ) * sign(-v.Y)
        local parL = lv*angleCos --length of par. vec
    
        local parallelVec = ref * (parL / lref) --parallel to ref but with vs length
    
        local perpendicularVec = v - parallelVec
    
        --TODO: remove after lua extension adds operators
        ---@diagnostic disable-next-line: return-type-mismatch
        return parallelVec, perpendicularVec, parL, lv*angleSin
  
    else
        return v, Vector.Zero, lv, 0
    end
end
  
function REVEL.CloneVec(v)
    return Vector(v.X, v.Y)
end
  
function REVEL.AbsVector(v)
    return Vector(math.abs(v.X), math.abs(v.Y))
end
  
function REVEL.VecEquals(v1,v2)
    return v1.X == v2.X and v1.Y == v2.Y
end

function REVEL.GetCardinal(vec)
    if math.abs(vec.X) > math.abs(vec.Y) then
        return Vector(sign(vec.X), 0)
    else
        return Vector(0, sign(vec.Y))
    end
end

function REVEL.GetPointOnRectFromAngle(angle, w, h)
    local sin, cos = math.sin(angle * math.pi / 180), math.cos(angle * math.pi / 180)
    local outy = (sin > 0) and h/2 or -h/2
    local outx = (cos > 0) and w/2 or -w/2

    if math.abs(outx * sin) < math.abs(outy * cos) then
        outy = (outx * sin) / cos
    else
        outx = (outy * cos) / sin
    end

    return Vector(outx, outy)
end

-- DEPRECATED
-- REMOVE WHEN 100% SURE NO LONGER USED
-- ANYWHERE ELSE
function REVEL.ScaleVec(a, b)
    error("REVEL.ScaleVec is deprecated\n", 2)
    return a * b
end

function REVEL.UnpackVectors(...)
    local arg = {...}
    local out = {}
  
    for _, vec in ipairs(arg) do
      out[#out+1] = vec.X
      out[#out+1] = vec.Y
    end
  
    return table.unpack(out)
end

---@param vector Vector
---@param amount? number
function REVEL.AxisAlignVector(vector, amount)
    local newX, newY = vector.X, vector.Y
    if math.abs(vector.X) > math.abs(vector.Y) then
        newY = vector.Y * (1 - (amount or 1))
    else
        newX = vector.X * (1 - (amount or 1))
    end
  
    return Vector(newX, newY)
end

end

REVEL.PcallWorkaroundBreakFunction()