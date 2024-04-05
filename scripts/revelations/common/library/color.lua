return function()


function REVEL.CloneColor(c)
    local tint = c:GetTint()
    local offset = c:GetOffset()
    local newColor = Color(
        tint.R, tint.G, tint.B, tint.A, 
        offset.R, offset.G, offset.B
    )
    local colorize = c:GetColorize()
    newColor:SetColorize(colorize.R, colorize.G, colorize.B, colorize.A)
    return newColor
end

-- returns color with only the specified values changed, every arg you leave nil stays unchanged
function REVEL.ChangeSingleColorVal(color, r,g,b,a,ro,go,bo, rc,gc,bc,ac)
    local newColor = REVEL.CloneColor(color)
    if r then newColor.R = r end
    if g then newColor.G = g end
    if b then newColor.B = b end
    if a then newColor.A = a end
    if ro then newColor.RO = ro end
    if go then newColor.GO = go end
    if bo then newColor.BO = bo end

    if rc or gc or bc or ac then
        local colorize = newColor:GetColorize()
        local newColR = rc or colorize.R
        local newColG = gc or colorize.G
        local newColB = bc or colorize.B
        local newColA = ac or colorize.A
        newColor:SetColorize(newColR, newColG, newColB, newColA)
    end

    return newColor
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
    precision = precision or 0.00001
    local tintA, offsetA, colorizeA = a:GetTint(), a:GetOffset(), a:GetColorize()
    local tintB, offsetB, colorizeB = b:GetTint(), b:GetOffset(), b:GetColorize()
    precision = precision or 0.0001
    return  REVEL.dist(tintA.R, tintB.R) < precision 
        and REVEL.dist(tintA.G, tintB.G) < precision 
        and REVEL.dist(tintA.B, tintB.B) < precision 
        and REVEL.dist(tintA.A, tintB.A) < precision
        and REVEL.dist(colorizeA.R, colorizeB.R) < precision 
        and REVEL.dist(colorizeA.G, colorizeB.G) < precision 
        and REVEL.dist(colorizeA.B, colorizeB.B) < precision 
        and REVEL.dist(colorizeA.A, colorizeB.A) < precision
        and REVEL.dist(offsetA.RO, offsetB.RO) < precision 
        and REVEL.dist(offsetA.GO, offsetB.GO) < precision
        and REVEL.dist(offsetA.BO, offsetB.BO) < precision
end

-- REVEL.ProperGoddarnColorMultiplicationBecauseTheOriginalOneEditsColorAToo
-- In other words, at least pre-Repentance doing colorA * colorB had the sideeffect
-- of storing the result in colorA, on top of returning it
function REVEL.ColorMult(a, b)
    local tintA, offsetA, colorizeA = a:GetTint(), a:GetOffset(), a:GetColorize()
    local tintB, offsetB, colorizeB = b:GetTint(), b:GetOffset(), b:GetColorize()
    -- base game multiplies tint, sums offsets, and averages colorize
    local result = Color(
        tintA.R * tintB.R, tintA.G * tintB.G, tintA.B * tintB.B, tintA.A * tintB.A,
        offsetA.RO + offsetB.RO, offsetA.GO + offsetB.GO, offsetA.BO + offsetB.BO
    )
    result:SetColorize(
        (colorizeA.R + colorizeB.R) / 2,
        (colorizeA.G + colorizeB.G) / 2,
        (colorizeA.B + colorizeB.B) / 2,
        (colorizeA.A + colorizeB.A) / 2
    )
    return result
end

function REVEL.ChangeColorAlpha(color, newAlpha, absolute)
    if absolute then
        return REVEL.ChangeSingleColorVal(color, nil,nil,nil, newAlpha)
    else
        return REVEL.ChangeSingleColorVal(color, nil,nil,nil, newAlpha * color.A)
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