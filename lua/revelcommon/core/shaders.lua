return function()

------------------------------
-- COLOR CORRECTION SHADERS --
------------------------------
--[[
        We can only use one MC_GET_SHADER_PARAMS callback, so we need special functionality.
]]

local shaderMaskName = ""
local drawLineStage = nil

local MaxDebug = 8
local debugText = {
    [0] = "OFF",
    [1] = "ON",
    [2] = "BEFORE-AFTER",
    [3] = "GRAYSCALE",
    [4] = "DEBUG SHADOWS",
    [5] = "DEBUG MIDTONES",
    [6] = "DEBUG HIGHLIGHTS",
    [7] = "VERSION CHECK",
    [8] = "COLOR BOOST",
}

REVEL.CCShaderOutput = StageAPI.Class("REV CC Shader Output")

function REVEL.CCShaderOutput:Init()
    self.ActiveIn = 1
    self.RGB = {1,1,1}
    self.ShadRGB_Wgt = {1,1,1, 60}
    self.MidRGB_Wgt = {1,1,1, 9}
    self.HighRGB_Wgt = {1,1,1, 3}
    self.ContrLightSat_Legacy = {0,0,0,0}
    self.ColBoostSelection = {0,0,0,1}
    self.ColBoostRGBSat = {1,1,1,0}
    self.Levels = {0,0,0}
end

function REVEL.CCShaderOutput:Reset()
    REVEL.CCShaderOutput.Init(self)
end

REVEL.CCShader = StageAPI.Class("Rev CC Shader")

local CCShaders = {}

function REVEL.CCShader:Init(name)
    self.Name = name

    self.Output = REVEL.CCShaderOutput()

    self.Active = 0
    self.Temperature = 0
    self.Brightness = 0
    self.Exposure = 0
    self.RGB = {1,1,1}
    self.Shadows = {
        RGB = {1,1,1},
        Temperature = 0,
        Brightness = 0,
        Exposure = 0,
        WeightExpMult = 60,
        TintHue = 0,
        TintSat = 0,
        TintAmount = 0
    }
    self.Midtones = {
        RGB = {1,1,1},
        Temperature = 0,
        Brightness = 0,
        Exposure = 0,
        WeightExpMult = 9,
        TintHue = 0,
        TintSat = 0,
        TintAmount = 0
    }
    self.Highlights = {
        RGB = {1,1,1},
        Temperature = 0,
        Brightness = 0,
        Exposure = 0,
        WeightExpMult = 3,
        TintHue = 0,
        TintSat = 0,
        TintAmount = 0
    }
    self.TintHue = 0
    self.TintSat = 0
    self.TintAmount = 0

    self.UseColorBoost = false
    self.ChangeLevelsWeight = false
    self.ForceDebugSetting = -1

    self.OnUpdate = function() end

    local existingIndex = REVEL.findKey(CCShaders, function(shader) return self.Name == shader.Name end)
    if existingIndex then
        CCShaders[existingIndex] = self
        self.ForceRGBUpdate = true
    else
        table.insert(CCShaders, self)
        self.ForceRGBUpdate = false
    end
end

function REVEL.CCShader:SetRGB(r, g, b)
    if r then self.RGB[1] = r end
    if g then self.RGB[2] = g end
    if b then self.RGB[3] = b end
end

function REVEL.CCShader:Set3WayWeight(s, m, h)
    self.Shadows.WeightExpMult = s
    self.Midtones.WeightExpMult = m
    self.Highlights.WeightExpMult = h
    self.ChangeLevelsWeight = true
end

function REVEL.CCShader:SetShadows(tbl)
    for k, _ in pairs(self.Shadows) do
        if tbl[k] then
            self.Shadows[k] = tbl[k]
        end
    end
end

function REVEL.CCShader:SetMidtones(tbl)
    for k, _ in pairs(self.Midtones) do
        if tbl[k] then
            self.Midtones[k] = tbl[k]
        end
    end
end

function REVEL.CCShader:SetHighlights(tbl)
    for k, _ in pairs(self.Highlights) do
        if tbl[k] then
            self.Highlights[k] = tbl[k]
        end
    end
end

function REVEL.CCShader:SetLevels(minIn, maxIn, gamma)
    self.Output.Levels = {minIn, -maxIn, gamma} --maxIn is reversed as positive values are supposed to mean how much you shift it inwards
end

function REVEL.CCShader:SetContrast(c)
    self.Output.ContrLightSat_Legacy[1] = c
end

function REVEL.CCShader:SetLightness(l)
    self.Output.ContrLightSat_Legacy[2] = l
end

function REVEL.CCShader:SetUseLegacyCL(useit)
    if useit then
        self.Output.ContrLightSat_Legacy[4] = 1
    else
        self.Output.ContrLightSat_Legacy[4] = 0
    end
end

function REVEL.CCShader:SetSaturation(s)
    self.Output.ContrLightSat_Legacy[3] = s
end

function REVEL.CCShader:SetBrightness(b)
    self.Brightness = b
end

function REVEL.CCShader:SetExposure(e)
    self.Exposure = e
end

function REVEL.CCShader:SetTemp(t)
    self.Temperature = t
end

local function setTint(self,h,s,a)
    self.TintHue = h
    self.TintSat = s
    self.TintAmount = a
end

--Tint works like this, 0 is red http://www.normankoren.com/HSV_Smax_LBL.png

function REVEL.CCShader:SetTint(hue, sat, amount)
    setTint(self, hue, sat, amount)
end
function REVEL.CCShader:SetTintShadows(hue, sat, amount)
    setTint(self.Shadows, hue, sat, amount)
end
function REVEL.CCShader:SetTintMidtones(hue, sat, amount)
    setTint(self.Midtones, hue, sat, amount)
end
function REVEL.CCShader:SetTintHighlights(hue, sat, amount)
    setTint(self.Highlights, hue, sat, amount)
end

function REVEL.CCShader:SetColorBoostSelection(hueStart, hueEnd, feather, minSat)
    self.Output.ColBoostSelection = {hueStart, hueEnd, feather, minSat}
    self.UseColorBoost = true
end

function REVEL.CCShader:SetUseColorBoost(set)
    self.UseColorBoost = set
end

function REVEL.CCShader:SetColBoostRGB(r, g, b)
    if r then self.Output.ColBoostRGBSat[1] = r end
    if g then self.Output.ColBoostRGBSat[2] = g end
    if b then self.Output.ColBoostRGBSat[3] = b end
    self.UseColorBoost = true
end

function REVEL.CCShader:SetColBoostSat(s)
    self.Output.ColBoostRGBSat[4] = s
    self.UseColorBoost = true
end

function REVEL.ColorTempToRGB(kelvin) --color temperature to rgb multiplier, 6600 kelvin is neutral (aka white, aka 1.0,1.0,1.0)
    local r,g,b = 1,1,1
    kelvin = REVEL.Clamp(kelvin, 1000, 40000) / 100
    if kelvin <= 66 then
        r = 1
        g = REVEL.Clamp(0.39008157876901960784 * math.log(kelvin) - 0.63184144378862745098, 0, 1)
    else
        local t = kelvin - 60
        r = REVEL.Clamp(1.29293618606274509804 * t ^ (-0.1332047592), 0, 1)
        g = REVEL.Clamp(1.12989086089529411765 * t ^ (-0.0755148492), 0, 1)
    end

    if kelvin >= 66.0 then
        b = 1.0
    elseif kelvin <= 19.0 then
        b = 0.0
    else
        b = REVEL.Clamp(0.54320678911019607843 * math.log(kelvin - 10.0) - 1.19625408914, 0, 1)
    end

    return r,g,b
end

local Ones = {1,1,1}

local function HSVToRGBMult(h, s, amnt)
    local mul = {hsvToRgb(h, s, 1)}
    for i=1, 3 do
        mul[i] = mul[i] + 0.5
    end
    return REVEL.Lerp(Ones, mul, amnt)
end

local function updateShaderRGB(name, sourceTable, targetRGB, force)
    local t = sourceTable
    if force or REVEL.WasChanged(name, t.Temperature, t.Brightness, t.Exposure, t.RGB[1], t.RGB[2], t.RGB[3], t.TintHue, t.TintSat, t.TintAmount) then --optimization, no need to constantly update it
        local tr, tg, tb = REVEL.ColorTempToRGB(6600 + t.Temperature*100)
        local expmul = 2 ^ t.Exposure
        local tint = HSVToRGBMult(t.TintHue, t.TintSat, t.TintAmount)
        targetRGB[1] = t.RGB[1] * (t.Brightness + 1) * tr * tint[1] * expmul
        targetRGB[2] = t.RGB[2] * (t.Brightness + 1) * tg * tint[2] * expmul
        targetRGB[3] = t.RGB[3] * (t.Brightness + 1) * tb * tint[3] * expmul
    end
end

REVEL.UpdateShaderRGB = updateShaderRGB

function REVEL.CCShader:Update()
    updateShaderRGB(self.Name, self, self.Output.RGB, self.ForceRGBUpdate)
    updateShaderRGB(self.Name.."S", self.Shadows, self.Output.ShadRGB_Wgt, self.ForceRGBUpdate)
    updateShaderRGB(self.Name.."M", self.Midtones, self.Output.MidRGB_Wgt, self.ForceRGBUpdate)
    updateShaderRGB(self.Name.."H", self.Highlights, self.Output.HighRGB_Wgt, self.ForceRGBUpdate)
    self.ForceRGBUpdate = false
    self.Output.ShadRGB_Wgt[4] = self.Shadows.WeightExpMult
    self.Output.MidRGB_Wgt[4] = self.Midtones.WeightExpMult
    self.Output.HighRGB_Wgt[4] = self.Highlights.WeightExpMult

    self:OnUpdate()
end

local function lerp2key(k, tbl, src1, src2, t, left, right)
    tbl[k] = REVEL.Lerp2(src1[k], src2[k], t, left, right)
end

function REVEL.LerpCCShaderOutput(shader1, shader2, t, left, right)
    left = left or 0
    right = right or 1
    local out = {}
    lerp2key("ContrLightSat_Legacy", out, shader1, shader2, t, left, right)
    lerp2key("RGB", out, shader1, shader2, t, left, right)
    lerp2key("ShadRGB_Wgt", out, shader1, shader2, t, left, right)
    lerp2key("MidRGB_Wgt", out, shader1, shader2, t, left, right)
    lerp2key("HighRGB_Wgt", out, shader1, shader2, t, left, right)
    lerp2key("ColBoostRGBSat", out, shader1, shader2, t, left, right)
    lerp2key("Levels", out, shader1, shader2, t, left, right)
    out.ContrLightSat_Legacy[4] = shader2.ContrLightSat_Legacy[4]
    out.ActiveIn = 1
    return out
end

---------------------
-- GENERAL SHADERS --
---------------------

local shaders = {}
local shadersNoDebug = {}
function REVEL.AddShader(name, fn, noDebug)
        shaders[name] = fn
        shadersNoDebug[name] = noDebug
end

local effShaders = {}
function REVEL.AddEffectShader(func) --last shader to return something different from nil is used
    effShaders[#effShaders+1] = {func = func}
end

local function tableMult(a, b)
    for i, v in ipairs(a) do
        a[i] = a[i] * b[i]
    end
end

local function tableSum(a,b)
    for i, v in ipairs(a) do
        a[i] = a[i] + b[i]
    end
end

local OffShader = {ActiveIn = 0}

local CC_NEUTRAL_OUT = REVEL.CCShaderOutput()

local PauseLerpDur = 7
local pauseLerp = 0
local pauseLerpWait = 0
revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if REVEL.IsPauseMenuOpen() or DeadSeaScrollsMenu.IsOpen() or REVEL.TempDisableShaders then
        pauseLerp = math.max(pauseLerp - 1, 0)
        pauseLerpWait = 3
    else
        if pauseLerpWait > 0 then
            pauseLerpWait = pauseLerpWait - 1
        else
            pauseLerp = math.min(pauseLerp + 1, PauseLerpDur)
        end
    end
end)

function REVEL.GetShaderActiveMult(effects)
    if StageAPI.IsHUDAnimationPlaying(true) then
        return 0
    end

    return pauseLerp / PauseLerpDur
end

REVEL.AddShader("RevColorCorrection", function()
    local activeMult = REVEL.GetShaderActiveMult()

    if revel.data.shadersOn == 0 or activeMult == 0 then
        return OffShader
    end

    local outShader = REVEL.CCShaderOutput()
    local curOutput = CC_NEUTRAL_OUT
    local activeCCShaders = 0
    local levelWgtCount = 0
    local sWgtSum = 0
    local mWgtSum = 0
    local hWgtSum = 0
    local highestActiveness = 0
    local forceDebug

    for i, shader in ipairs(CCShaders) do
        shader:Update()
        if shader.Active > 0 then
            activeCCShaders = activeCCShaders + 1
            curOutput = REVEL.LerpCCShaderOutput(CC_NEUTRAL_OUT, shader.Output, shader.Active * activeMult)
            if shader.ChangeLevelsWeight then
                sWgtSum = sWgtSum + curOutput.ShadRGB_Wgt[4]
                mWgtSum = mWgtSum + curOutput.MidRGB_Wgt[4]
                hWgtSum = hWgtSum + curOutput.HighRGB_Wgt[4]
                levelWgtCount = levelWgtCount + 1
            end

            tableMult(outShader.RGB, curOutput.RGB)
            outShader.ActiveIn = outShader.ActiveIn * curOutput.ActiveIn
            tableMult(outShader.ShadRGB_Wgt, curOutput.ShadRGB_Wgt)
            tableMult(outShader.MidRGB_Wgt, curOutput.MidRGB_Wgt)
            tableMult(outShader.HighRGB_Wgt, curOutput.HighRGB_Wgt)
            tableSum(outShader.ContrLightSat_Legacy, curOutput.ContrLightSat_Legacy)
            tableSum(outShader.Levels, curOutput.Levels)
            --
            -- if REVEL.WasChanged("temp"..i, shader.Name, shader.Active) then
            --     REVEL.DebugToConsole(shader.Name, REVEL.TableToStringEnter(curOutput))
            -- end
            if shader.Active > highestActiveness then
                highestActiveness = shader.Active
                if shader.ForceDebugSetting >= 0 then
                    forceDebug = shader.ForceDebugSetting
                end
                if revel.data.shaderColorBoostOn2 ~= 0 and shader.UseColorBoost then
                    outShader.ColBoostSelection = shader.Output.ColBoostSelection
                    outShader.ColBoostRGBSat = curOutput.ColBoostRGBSat
                end
            end
        end
    end

    if activeCCShaders > 0 then
        outShader.ActiveIn = forceDebug or revel.data.shadersOn
        if levelWgtCount > 0 then
            outShader.ShadRGB_Wgt[4] = sWgtSum / levelWgtCount
            outShader.MidRGB_Wgt[4] = mWgtSum / levelWgtCount
            outShader.HighRGB_Wgt[4] = hWgtSum / levelWgtCount
        end

        return outShader
    else
        return OffShader
    end
end)

local effShaderOff = {ActiveIn = 0, TypeVariantDebug = {0, 0, 0}}

REVEL.AddShader("RevEffects", function()
    local shader = effShaderOff
    for i,v in ipairs(effShaders) do
        local ret = v.func()
        if ret then
            shader = ret
        end
    end
    -- REVEL.DebugToConsole(shader)
    shader.ActiveIn = shader.ActiveIn * REVEL.GetShaderActiveMult(true)
    shader.TypeVariantDebug[3] = revel.data.shadersOn --debug (only 0,1,2,3 work, else it acts like 0)
    return shader
end)

-- local time1, timeSpentShader, lastRenderTime, timeSpentRender = 0,0,0,0,0

revel:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, function(_, name)
        if shaders[name] then --is rev shader
                if revel.data.shadersOn == 0 then
                        return OffShader
                else
                        -- time1 = Isaac.GetTime()
                        -- local ret = shaders[name](name, revel.data.shadersOn)
                        -- timeSpentShader = timeSpentShader + Isaac.GetTime() - time1
                        -- return ret
                        return shaders[name](name, revel.data.shadersOn)
                end
        end
end)

-- revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
--         timeSpentRender = timeSpentRender + Isaac.GetTime() - lastRenderTime

--         lastRenderTime = Isaac.GetTime()
-- end)

-- revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
--     if REVEL.game:GetFrameCount() % 30 == 0 then
--             REVEL.DebugLog("Time spent rendering these 30 updates:")
--             REVEL.DebugLog(timeSpentRender .. "ms", "shaders: " .. timeSpentShader .. "ms (" .. (100 * timeSpentShader / timeSpentRender) .. "%)")

--             timeSpentRender = 0
--             timeSpentShader = 0
--     end
-- end)

local renderColorDebug = false
local cdebug

REVEL.Commands.shaderdebug = {
    Execute = function (params)
        if tonumber(params) then
            revel.data.shadersOn = tonumber(params)
            REVEL.DebugToString("Turned shaders to "..debugText[revel.data.shadersOn])
            REVEL.DebugToConsole("Turned shaders to "..debugText[revel.data.shadersOn])
        else
            REVEL.LogError("shaderdebug param must be an integer")
        end
    end,
    Autocomplete = function (params)
        return REVEL.flatmap(debugText, function (val, key) return {key, val} end)
    end,
    Usage = "debugMode",
    Desc = "Set shader debug mode",
    Aliases = {"shddebug", "shddbg"},
    Help = "Set shader debug mode. Available modes:\n" 
        .. table.concat(REVEL.flatmap(debugText, function (val, key) return key .. ": " .. val end), "\n"),
    File = "shaders.lua",
}
REVEL.Commands.drawshadermask = {
    Execute = function (params)
        if tonumber(params) then
            revel.data.shadersOn = tonumber(params)
            REVEL.DebugToString("Turned shaders to "..debugText[revel.data.shadersOn])
            REVEL.DebugToConsole("Turned shaders to "..debugText[revel.data.shadersOn])
        else
            REVEL.LogError("shaderdebug param must be an integer")
        end
    end,
    Desc = "Shader mask tool",
    Aliases = {"drawsm"},
    Help = "Used to draw tomb masks to later save (needs specific shaders enabled in xml)",
    File = "shaders.lua",
}
REVEL.Commands.colordebug = {
    Execute = function (params)
        if not renderColorDebug or not cdebug then --remove debug entity
            cdebug = REVEL.SpawnDecoration(REVEL.room:GetCenterPos(), Vector.Zero, "Idle", "gfx/effects/revel2/color_test.anm2", nil, -1000)
            cdebug.SpriteScale = Vector.One * 0.2
            cdebug.RenderZOffset = 40000
            renderColorDebug = true
        elseif cdebug then
            cdebug:Remove()
            cdebug = nil
            renderColorDebug = false
        end
    end,
    Desc = "Color correction testing",
    Aliases = {"clrdbg"},
    Help = "Render color palette for color correction testing",
    File = "shaders.lua",
}

-----------------------
-- DRAW MASK SHADERS --
-----------------------
do

-- Were used to draw the masks used in the tomb light shaft shaders
-- since in current API there's no way to load images as masks for shaders

local drawTarget = REVEL.LazyLoadRoomSprite{
    ID = "drawShaderTarget",
    Anm2 = "gfx/1000.030_dr. fetus target.anm2",
    Animation = "Idle",
    PlaybackSpeed = 0.25,
}

local font = Font()
font:Load("font/pftempestasevencondensed.fnt")
local color = KColor(1,1,1,0.5)

local dTargBlink = -1

local drawnMasks = {{lines={},circles={}}}

REVEL.LinePreviewShader = {
    Active = 0,
    Expansion = 0.001,
    Feather = 0.09,
    x1 = 0.0,
    y1 = 0.0,
    x2 = 0.0,
    y2 = 0.0
}

REVEL.CirclePreviewShader = {
    Active = 0,
    Radius = 0.001,
    Feather = 0.09,
    x = 0.0,
    y = 0.0
}

local dTargUpdate

revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if Input.IsButtonTriggered(Keyboard.KEY_END, 0) and not (REVEL.player:GetData().seqProg and REVEL.player:GetData().seqProg > 1) and REVEL.DEBUG and not REVEL.game:IsPaused() then
        revel.data.shadersOn = (revel.data.shadersOn+1)%(MaxDebug+1)
        REVEL.DebugToString({"Turned shaders to "..debugText[revel.data.shadersOn]})
    end

    if revel.data.shadersOn >= 2 then
        local br = REVEL.GetScreenBottomRight()
        Isaac.RenderText("Shader debug: "..debugText[revel.data.shadersOn], br.X-180, br.Y-40, 1, 1, 1, 0.5)
        Isaac.RenderText("Press ENTER or use shddebug", br.X-180, br.Y-30, 1, 1, 1, 0.5)
        Isaac.RenderText("command to change", br.X-180, br.Y-20, 1, 1, 1, 0.5)
    end

    if drawLineStage then
        local pos = Isaac.WorldToScreen(Input.GetMousePosition(true)) --false was wonky for some reason
        local normPos = REVEL.NormScreenVector(pos)
        local normPosX = REVEL.NormScreenVectorX(pos)
        local P1 = Vector(REVEL.LinePreviewShader.x1, REVEL.LinePreviewShader.y1);
        local P2 = Vector(REVEL.LinePreviewShader.x2, REVEL.LinePreviewShader.y2);
        local C = Vector(REVEL.CirclePreviewShader.x, REVEL.CirclePreviewShader.y);
        local current = drawnMasks[#drawnMasks]

        local rtr = REVEL.GetScreenTopRight()
        local str = "Use LMB to draw lines, RMB to draw circles"
        local w = font:GetStringWidth(str)
        font:DrawStringScaled(str, rtr.X-50-w*0.9, rtr.Y-9*0.9+20, 0.9, 0.9, color, 0, false)
        str = "Use Middle Mouse Button to save the mask (up to the last finished shape), and G to save the shader"
        w = font:GetStringWidth(str)
        font:DrawStringScaled(str, rtr.X-50-w*0.9, rtr.Y+20, 0.9, 0.9, color, 0, false)
        str = "Lines drawn: "..#current.lines.."; Circles drawn: "..#current.circles
        w = font:GetStringWidth(str)
        font:DrawStringScaled(str, rtr.X-50-w*0.9, rtr.Y+9*0.9+20, 0.9, 0.9, color, 0, false)
        str = "Masks drawn: "..#drawnMasks.."; Shader name: "..shaderMaskName
        w = font:GetStringWidth(str)
        font:DrawStringScaled(str, rtr.X-50-w*0.9, rtr.Y+18*0.9+20, 0.9, 0.9, color, 0, false)
        str = "Please do not change screen size while editing"
        w = font:GetStringWidth(str)
        font:DrawStringScaled(str, rtr.X-50-w*0.9, rtr.Y+27*0.9+20, 0.9, 0.9, color, 0, false)

        if dTargUpdate then
            drawTarget:Update()
        end
        dTargUpdate = not dTargUpdate

        if dTargBlink > 0 then
            if dTargBlink % 2 == 0 then
                drawTarget:Update()
            end
            dTargBlink = dTargBlink -1
        elseif dTargBlink == 0 then
            dTargBlink = dTargBlink - 1
            drawTarget:Play("Idle", true)
        end

        drawTarget:Render(pos, Vector.Zero, Vector.Zero)

        --line preview
        if drawLineStage == 1 then
            REVEL.LinePreviewShader.x2 = normPos.X
            REVEL.LinePreviewShader.y2 = normPos.Y
        elseif drawLineStage == 2 then
            REVEL.LinePreviewShader.Expansion = REVEL.LineDistance2(normPos, P1, P2)
        elseif drawLineStage == 3 then
            REVEL.LinePreviewShader.Feather = REVEL.LineDistance2(normPos, P1, P2) - REVEL.LinePreviewShader.Expansion
        end

        --circle preview
        if drawLineStage == 4 then
            REVEL.CirclePreviewShader.Radius = C:Distance(normPosX)
        elseif drawLineStage == 5 then
            REVEL.CirclePreviewShader.Feather = C:Distance(normPosX) - REVEL.CirclePreviewShader.Radius
        end

        if REVEL.IsMouseBtnTriggered(Mouse.MOUSE_BUTTON_LEFT) and drawLineStage < 4 then
            if drawLineStage == 0 then
                REVEL.LinePreviewShader.Active = 1
                REVEL.LinePreviewShader.x1 = normPos.X
                REVEL.LinePreviewShader.y1 = normPos.Y
                drawLineStage = drawLineStage + 1
            elseif drawLineStage == 3 then
                table.insert(current.lines, REVEL.CopyTable(REVEL.LinePreviewShader))
                REVEL.DebugToConsole("Completed line for "..shaderMaskName.."!")
                drawLineStage = 0
                REVEL.LinePreviewShader.Active = 0
            elseif drawLineStage > 0 then
                drawLineStage = drawLineStage + 1
            end

        elseif REVEL.IsMouseBtnTriggered(Mouse.MOUSE_BUTTON_RIGHT) and (drawLineStage > 3 or drawLineStage == 0) then
            if drawLineStage == 0 then
                REVEL.CirclePreviewShader.Active = 1
                REVEL.CirclePreviewShader.x = normPosX.X
                REVEL.CirclePreviewShader.y = normPosX.Y
                drawLineStage = 4
            elseif drawLineStage == 4 then
                drawLineStage = drawLineStage + 1
            elseif drawLineStage == 5 then
                table.insert(current.circles, REVEL.CopyTable(REVEL.CirclePreviewShader))
                drawLineStage = 0
                REVEL.CirclePreviewShader.Active = 0
                REVEL.DebugToConsole("Completed circle for "..shaderMaskName.."!")
            end

        elseif REVEL.IsMouseBtnTriggered(Mouse.MOUSE_BUTTON_MIDDLE) then
            drawnMasks[#drawnMasks+1] = {lines = {}, circles = {}}
            drawLineStage = 0
            REVEL.LinePreviewShader.Active = 0
            REVEL.CirclePreviewShader.Active = 0
            REVEL.DebugToConsole("Completed mask for "..shaderMaskName.."!")
        elseif Input.IsButtonTriggered(Keyboard.KEY_G, 0) then
            local br, tl = REVEL.room:GetBottomRightPos(), REVEL.room:GetTopLeftPos()
            local nbr, ntl = REVEL.NormScreenVector(Isaac.WorldToScreen(br)), REVEL.NormScreenVector(Isaac.WorldToScreen(tl))

            drawLineStage = nil
            REVEL.DebugToConsole("Outputting shader "..shaderMaskName.." to log, to use copypaste in shaders.xml")

            local output = REVEL.BaseMaskShader --this is located in resources/shaders
            output = output:gsub("INSERTNAMEHERE", shaderMaskName)

            output = output:gsub("//ROOMBOUNDS", [[
    const vec2 Tl = vec2(]]..ntl.X..", "..ntl.Y..[[);
    const vec2 Br = vec2(]]..nbr.X..", "..nbr.Y..");\n")

            local lineData = ""
            local circleData = ""
            for i, mask in ipairs(drawnMasks) do
                for j,v in ipairs(mask.lines) do
                    lineData = lineData .. REVEL.GenerateLineData(v, i.."_"..j.."_L")
                end
                for j,v in ipairs(mask.circles) do
                    circleData = circleData .. REVEL.GenerateCircleData(v, i.."_"..j.."_C")
                end
            end
            output = output:gsub("//LINES", lineData)
            output = output:gsub("//CIRCLES", circleData)

            local maskMod = ""
            for i, mask in ipairs(drawnMasks) do
                maskMod = maskMod .. [[
        if (selec == ]]..i..") {\n"
                for j,v in ipairs(mask.lines) do
                    maskMod = maskMod .. REVEL.GenerateLineFunc(v, i.."_"..j.."_L")
                end
                for j,v in ipairs(mask.circles) do
                    maskMod = maskMod .. REVEL.GenerateCircleFunc(v, i.."_"..j.."_C")
                end
                maskMod = maskMod .. [[
        }
        ]]
            end
            output = output:gsub("//MASKMODS", maskMod)

            drawnMasks = {{lines={},circles={}}}
            REVEL.DebugToString("Mask drawing output:\n\n"..output.."\n\n")
        end
    end
end)

function REVEL.GenerateLineData(line, id) --line is a table structured like the LinePreviewShader table
    local output = [[
    const vec2 P]]..id.."1 = vec2("..line.x1..", "..line.y1..[[);
    const vec2 P]]..id.."2 = vec2("..line.x2..", "..line.y2..[[);
    const float Expansion]]..id.." = "..line.Expansion..[[;
    const float Feather]]..id.." = "..line.Feather..";\n\n"
    return output
end

function REVEL.GenerateCircleData(circle, id) --circle is a table structured like the CirclePreviewShader table
    local output = [[
    const vec2 Cnt]]..id.." = vec2("..circle.x..", "..circle.y..[[);
    const float Radius]]..id.." = "..circle.Radius..[[;
    const float Feather]]..id.." = "..circle.Feather..";\n\n"
    return output
end

function REVEL.GenerateLineFunc(line, id)
    local output = [[
            if (mask < 1.)
                mask += plotLine(st, P]]..id.."1, P"..id.."2, Expansion"..id..", Feather"..id..", Br, Tl);\n"
    return output
end

function REVEL.GenerateCircleFunc(line, id)
    local output = [[
            if (mask < 1.)
                mask += plotCircle(st, Cnt]]..id..", Radius"..id..", Feather"..id..", Br, Tl);\n"
    return output
end

REVEL.AddShader("LineMaskPreview", function()
    return REVEL.LinePreviewShader
end)
REVEL.AddShader("CircleMaskPreview", function()
    return REVEL.CirclePreviewShader
end)

local function vecToGLSL(v)
    return "vec2("..v.X..","..v.Y..")"
end

-- Uses the name specified in the drawsm command
--The end function returns true/false, meant to be used in a single function with other shapes functions that returns 1. when inside at least 1 shape and 0. when not
--This is needed as GLSL doesn't support array looping, as its meand to be done in C++ (which we cannot access from here)
--Algorithm used is: draw line from test point to the right (that spans the whole screen); if it intersects sides of the polygon an even number of times, it's out; else, it's in.
--This needs the intersect etc funcitons declared before it, see QuadMaskTest.glsl for example
function REVEL.GenerateShaderIsInsideFunc(shape, name)
    local output = "//COPYPASTE THIS IN THE SHADER\n\n//Shape \""..name.."\", autogenerated code\n"

    local gShape = {}
    for i,v in ipairs(shape) do
        gShape[i] = "p"..name..i
        output = output .. "vec2 "..gShape[i].." = "..vecToGLSL(v[2])..";\n"
    end

    output = output ..[[

        bool isInsideShape]]..name..[[Bool(vec2 p)
        {
            vec2 far = vec2(2.0, p.y);
            int count = 0;
        ]]

    for i, cur in ipairs(gShape) do
        local next = gShape[(i% #gShape) + 1]
        output = output ..[[

        if (isIntersecting(]]..cur..[[, ]]..next..[[, p, far))
        {
            if (ori(]]..cur..[[, p, ]]..next..[[) == 0)
                    return isOnSegment(]]..cur..[[, p, ]]..next..[[);
            count++;
        }
        ]]
    end

    output = output ..[[

        return mod(count, 2) == 1;
    }
    //End shape ]]..name
    return output
end

end

Isaac.DebugString("Revelations: Loaded Shader Core!")

end