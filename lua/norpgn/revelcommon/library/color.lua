return function()


function REVEL.CloneColor(c)
    return Color(c.R, c.G, c.B, c.A, c.RO, c.GO, c.BO)
end

-- returns color with only the specified values changed, every arg you leave nil stays unchanged
function REVEL.ChangeSingleColorVal(color, r,g,b,a,ro,go,bo)
    return Color(r or color.R, g or color.G, b or color.B, a or color.A, ro or color.RO, go or color.GO, bo or color.BO)
end
    
-- either use as REVEL.ClampColor(color, top) to clamp between all zeros and top color, or (color, low, top) to clamp between low and top
function REVEL.ClampColor(color, low, top) 
    if not top then
        top = low
        low = REVEL.NO_COLOR
    end
    return Color(
        REVEL.Clamp(color.R, low.R, top.R),
        REVEL.Clamp(color.G, low.G, top.G), 
        REVEL.Clamp(color.B, low.B, top.B), 
        REVEL.Clamp(color.A, low.A, top.A), 
        REVEL.Clamp(color.RO, low.RO, top.RO), 
        REVEL.Clamp(color.GO, low.GO, top.GO), 
        REVEL.Clamp(color.BO, low.BO, top.BO)
    )
end

function REVEL.ColorEquals(a, b, precision)
    precision = precision or 0.0001
    return REVEL.dist(a.R, b.R) < precision 
        and REVEL.dist(a.G, b.G) < precision 
        and REVEL.dist(a.B, b.B) < precision 
        and REVEL.dist(a.A, b.A) < precision
        and REVEL.dist(a.RO, b.RO) < precision 
        and REVEL.dist(a.GO, b.GO) < precision
        and REVEL.dist(a.BO, b.BO) < precision
end

-- REVEL.ProperGoddarnColorMultiplicationBecauseTheOriginalOneEditsColorAToo
-- In other words, at least pre-Repentance doing colorA * colorB had the sideeffect
-- of storing the result in colorA, on top of returning it
function REVEL.ColorMult(c0, c1)
    return Color(c0.R * c1.R, c0.G * c1.G, c0.B * c1.B, c0.A * c1.A,
        -- base game multiplication sums offsets
        c0.RO + c1.RO, c0.GO + c1.GO, c0.BO + c1.BO)
end

function REVEL.ChangeColorAlpha(color, newAlpha, absolute)
    if absolute then
        return Color(color.R, color.G, color.B, newAlpha, color.RO, color.GO, color.BO)
    else
        return Color(color.R, color.G, color.B, newAlpha * color.A, color.RO, color.GO, color.BO)
    end
end

---@param h number hue between 0 and 1
---@param s number 
---@param v number
---@param a? number
---@param br? number
---@param ro? number
---@param bo? number
---@param go? number
---@return Color
function REVEL.HSVtoColor(h,s,v,a,br,ro,bo,go)
    br = (br or 0) + 1
    local r, g, b = hsvToRgb(h, s, v)
    return Color(r * br, g * br, b * br, a or 1, ro or 0, bo or 0, go or 0)
end
    
--Uses averaged mult instead, meaning grey keeps the color as is
function REVEL.HSVtoColorLight(h,s,v,a,ro,bo,go)
    local rgb = REVEL.HSVToRGBMult(h, s, v)
    return Color(rgb[1], rgb[2], rgb[3], a or 1, ro or 0, bo or 0, go or 0)
end

---@deprecated
function REVEL.ColorMultAddOffsets(c0, c1)
    return REVEL.ColorMult(c0, c1)
end

end