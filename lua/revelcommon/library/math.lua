REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

function REVEL.GetAngleDifference(a1, a2)
    local sub = a1 - a2
    return (sub + 180) % 360 - 180
end

function REVEL.ClampNumberSize(num, size)
    if math.abs(num) > size then
        if num < 0 then
            num = -size
        else
            num = size
        end
    end

    return num
end

function REVEL.IsWithinRangeOf(value, value2, range)
    local min, max = value2 - range, value2 + range
    return value >= min and value <= max
end

-- TODO: replace with REVEL.atan2 in other branches
function REVEL.atan2(Y,X) --lua's is nil for some reason
    local product = 0

    if X == 0 and Y == 0 then
        return 0
    end

    if X == 0 then
        product = math.pi / 2
        if Y < 0 then
            product = product * 3
        end
    else
        product = math.atan(Y / X)
        if X < 0 then
            product = product + math.pi
        end
    end
    return product
end

function REVEL.dist(a,b)
    return math.abs(a-b)
end
    
    
--[[
adapted from https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua
]]
---@diagnostic disable-next-line: lowercase-global
function rgbToHsv(r, g, b)
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v
    v = max
    
    local d = max - min
    if max == 0 then s = 0 else s = d / max end
    
    if max == min then
        h = 0 -- achromatic
    else
        if max == r then
            h = (g - b) / d
            if g < b then h = h + 6 end
        elseif max == g then h = (b - r) / d + 2
        elseif max == b then h = (r - g) / d + 4
        end
        h = h / 6
    end
    
    return h, s, v
end
    
---@diagnostic disable-next-line: lowercase-global
function hsvToRgb(h, s, v)
    local r, g, b
    
    local i = math.floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);
    
    i = i % 6
    
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    
    return r, g, b
end

function REVEL.HSVToRGBMult(h, s, v, amnt)
    local mul = {hsvToRgb(h, s, v)}
    for i=1, 3 do
        mul[i] = mul[i] + 0.5
    end
    return REVEL.Lerp({1,1,1}, mul, amnt or 1)
end

---@generic T : ( number | Vector )
---@param x T
---@return T
function REVEL.Round(x)
    if type(x) == "number" then
        return (x % 1 > 0.5) and math.ceil(x) or math.floor(x)
    else
        return Vector(REVEL.Round(x.X), REVEL.Round(x.Y))
    end
end

function REVEL.GetAccelFromFrictionSpeed(friction, maxSpeed)
    return maxSpeed * (1 - friction)
end

---@diagnostic disable-next-line: lowercase-global
function toBits(num)
    -- returns a table of bits, least significant first.
    local t={} -- will contain the bits
    
    while num>0 do
        local rest=math.fmod(num,2)
        t[#t+1]=rest
        num=math.floor((num-rest)/2)
    end
    local significantFirst = {}
    for i = 1, #t do
        significantFirst[i] = t[#t + 1 - i]
    end
    return significantFirst
end
    
---@diagnostic disable-next-line: lowercase-global
function toBitString(num)
    return table.concat(toBits(num))
end
    

function REVEL.Xor(a, b)
    return a and b or (not a and not b)
end

end