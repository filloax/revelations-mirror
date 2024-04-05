return function()

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

-- Lerp

---@generic T : (number | Vector)
---@param first T
---@param second T
---@param percent number
---@return T
function REVEL.Lerp(first, second, percent)
    if not first or not second or not percent then
        error("Lerp: Tried lerping nil values: " 
            .. REVEL.ToStringMulti(first, second, percent), 2)
    end

    if type(first) == 'table' then
        local out = {}
        for k, v in pairs(first) do
            out[k] = REVEL.Lerp(v, second[k], percent)
        end
        return out
    else
        return first * (1 - percent) + second * percent
    end
end

function REVEL.LerpTable(tbl1, tbl2, percent)
    if not tbl1 or not tbl2 or not percent then
        error("LerpTable: Tried lerping nil values: " .. REVEL.ToStringMulti(tbl1, tbl2, percent), 2)
    end

    local out = {}
    for k, v in pairs(tbl1) do
        if type(v) == "table" then
            out[k] = REVEL.LerpTable(v, tbl2[k], percent)
        else
            out[k] = REVEL.Lerp(v, tbl2[k], percent)
        end
    end

    return out
end

---@param entity Entity
---@param pos Vector
---@param tar Vector
---@param time integer
---@return boolean completed
function REVEL.LerpEntityPosition(entity, pos, tar, time)
    local data = REVEL.GetData(entity)

    if not data.LerpFrames then data.LerpFrames = 0 end

    data.LerpFrames = data.LerpFrames + 1

    local nextPosition = REVEL.Lerp(pos, tar, data.LerpFrames / time)
    entity.Velocity = (nextPosition - entity.Position) / 2

    -- More lerpentitiypositions being started by mistake and overriding times
    if data.LerpFrames >= time then
        data.LerpFrames = nil
        return false
    end

    return true
end

function REVEL.ClampedLerp(first, second, percent)
    if not first or not second or not percent then
        error("ClampedLerp: Tried lerping nil values: " .. REVEL.ToStringMulti(first, second, percent), 2)
    end
    
    return REVEL.Lerp(first, second, REVEL.Saturate(percent))
end

function REVEL.InvLerp(x, left, right) -- returns 0 when x is == left, interpolates to 1 on right
    if not x or type(x) ~= "number" then
        error("InvLerp: Tried lerping invalid values: " .. REVEL.ToStringMulti(x, left, right), 2)
    end
    
    return (x - (left or 0)) / ((right or 1) - (left or 0))
end

function REVEL.Step(x, step)
    if not x or not step then
        error("Step: Tried using nil values: " .. REVEL.ToStringMulti(x, step), 2)
    end

    if x < step then
        return 0
    else
        return 1
    end
end

function REVEL.Clamp(x, min, max) 
    if not x or not min or not max then
        error("Clamp: Tried using nil values: " .. REVEL.ToStringMulti(x, min, max), 2)
    end

    return math.max(min, math.min(x, max)) 
end

function REVEL.Saturate(x) 
    if not x then
        error("Saturate: x nil", 2)
    end

    return REVEL.Clamp(x, 0, 1) 
end

function REVEL.LinearStep(x, left, right) -- returns 0 when x is <= left, interpolates to 1 on right
    if not x or not left or not right then
        error("LinearStep: Tried lerping nil values: " .. REVEL.ToStringMulti(x, left, right), 2)
    end
    
    return REVEL.Saturate(REVEL.InvLerp(x, left, right))
end

function REVEL.Lerp2(a, b, x, left, right)
    if not a or not b or not x then
        error("Lerp2: Tried lerping nil values: " .. REVEL.ToStringMulti(a, b, x, left, right), 2)
    end
    
    return REVEL.Lerp(a, b, REVEL.InvLerp(x, left or 0, right or 1))
end

function REVEL.ColorLerp2(a, b, x, left, right)
    if not a or not b or not x then
        error("ColorLerp2: Tried lerping nil values: " .. REVEL.ToStringMulti(a, b, x, left, right), 2)
    end
    
    return Color.Lerp(a, b, REVEL.InvLerp(x, left or 0, right or 1))
end

function REVEL.SmoothLerp2(a, b, x, left, right)
    if not a or not b or not x then
        error("SmoothLerp2: Tried lerping nil values: " .. REVEL.ToStringMulti(a, b, x, left, right), 2)
    end

    left = left or 0
    right = right or 1

    if left <= right then
        return REVEL.Lerp2Clamp(a, b, REVEL.SmoothStep(x, left, right) )
    else
        return REVEL.Lerp2Clamp(b, a, REVEL.SmoothStep(x, right, left) )
    end
end
  
function REVEL.Lerp2Clamp(a, b, x, left, right)
    if not a or not b or not x then
        error("Lerp2Clamp: Tried lerping nil values: " .. REVEL.ToStringMulti(a, b, x, left, right), 2)
    end
    
    return REVEL.Lerp(a, b, REVEL.LinearStep(x, left or 0, right or 1))
end

function REVEL.ColorLerp2Clamp(a, b, x, left, right)
    if not a or not b or not x then
        error("ColorLerp2Clamp: Tried lerping nil values: " .. REVEL.ToStringMulti(a, b, x, left, right), 2)
    end
    
    return Color.Lerp(a, b, REVEL.LinearStep(x, left or 0, right or 1))
end

function REVEL.EaseIn(t, pow)
    if not t then
        error("EaseIn: t nil", 2)
    end
    
    t = REVEL.Saturate(t)
    return t ^ (pow or 2)
end

function REVEL.EaseOut(t, pow)
    if not t then
        error("EaseOut: t nil", 2)
    end
    
    t = REVEL.Saturate(t)
    return 1 - (1 - t) ^ (pow or 2)
end

function REVEL.EaseInOut(t, pow, balance)
    if not t then
        error("EaseInOut: t nil", 2)
    end
    
    t = REVEL.Saturate(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end

    if not balance then
        return REVEL.Lerp(
            REVEL.EaseIn(t, pow), 
            REVEL.EaseOut(t, pow), 
            t
        )
    elseif balance > 0 then
        return REVEL.Lerp(
            REVEL.EaseIn(t, pow), 
            REVEL.EaseOut(t, pow),
            t ^ balance
        )
    elseif balance < 0 then
        return REVEL.Lerp(
            REVEL.EaseIn(t, pow), 
            REVEL.EaseOut(t, pow),
            1 - (1 - t) ^ -balance
        )
    end
end

---@param x number
---@param left? number
---@param right? number
---@return number
function REVEL.SmoothStep(x, left, right) -- returns 0 when x is <= left, smoothly interpolates to 1 on right
    if not x then
        error("SmoothStep: Tried lerping nil values: " .. REVEL.ToStringMulti(x, left, right), 2)
    end
    
    left = left or 0
    right = right or 1
    if x <= left then return 0 end
    if x >= right then return 1 end
    x = REVEL.InvLerp(x, left, right)
    return (x * x * (3 - 2 * x))
end

function REVEL.LerpRoundtrip(a, b, x) -- interpolates from a to b with x included in [0,0.5], from b to a with x in [0.5,0]
    if not a or not b or not x then
        error("LerpRoundtrip: Tried lerping nil values: " 
            .. REVEL.ToStringMulti(a, b, x), 2)
    end

    if x <= 0.5 then
        return REVEL.Lerp(a, b, x * 2)
    else
        return REVEL.Lerp(b, a, (x - 0.5) * 2)
    end
end

function REVEL.LerpRoundtripColor(a, b, x) --interpolates from a to b with x included in [0,0.5], from b to a with x in [0.5,0]
    if not a or not b or not x then
        error("LerpRoundtripColor: Tried lerping nil values: " 
            .. REVEL.ToStringMulti(a, b, x), 2)
    end

    if x <= 0.5 then
        return Color.Lerp(a, b, x*2)
    else
        return Color.Lerp(b, a, (x-0.5)*2)
    end
end
  
local function isColor(v)
    if type(v) == "userdata" then
        local meta = getmetatable(v)
        if meta == nil then
            return false
        else
            return meta.__type == "Color"
        end
    end
    return false
end
  
  
function REVEL.Lerp3Point(a, b, c, x, left, mid, right)
    if not a or not b or not c or not x then
        error("Lerp3Point: Tried lerping nil values: " 
        .. REVEL.ToStringMulti(a, b, c, x, left, mid, right), 2)
    end

    left = left or 0
    mid = mid or 0.5
    right = right or 1
    if mid > right and left > mid then
        local tmp = left
        left = right
        right = tmp
    elseif not ((mid > left) == (right > mid)) then
        error("Lerp3Point error: left, mid, right not in ascending or descending order\n" 
        .. REVEL.ToStringMulti(left, mid, right), 2)
    end

    local lerp2 = isColor(a) and REVEL.ColorLerp2 or REVEL.Lerp2

    if x <= mid then
        return lerp2(a, b, x, left, mid)
    else
        return lerp2(b, c, x, mid, right)
    end
end
  
function REVEL.Lerp3PointClamp(a, b, c, x, left, mid, right)
    left = left or 0
    mid = mid or 0.5
    right = right or 1

    if not a or not b or not c or not x then
        error("Lerp3PointClamp: Tried lerping nil values: " 
        .. REVEL.ToStringMulti(a, b, c, x, left, mid, right), 2)
    elseif not ((mid > left) == (right > mid)) then
        error("Lerp3PointClamp error: left, mid, right not in ascending or descending order\n" 
        .. REVEL.ToStringMulti(left, mid, right), 2)
    end
    
    return REVEL.Lerp3Point(
        a, b, c, 
        REVEL.Clamp(x, math.min(left, right),
        math.max(left, right)), left, mid, right
    )
end

function REVEL.LerpAngleDegrees(aStart, aEnd, percent)
    if not aStart or not aEnd or not percent then
        error("LerpAngleDegrees: Tried lerping nil values: " .. REVEL.ToStringMulti(aStart, aEnd, percent), 2)
    end

    return aStart + REVEL.GetAngleDifference(aEnd, aStart) * percent
end


end