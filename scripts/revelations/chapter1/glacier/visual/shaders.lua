local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local RevSettings       = require("scripts.revelations.common.enums.RevSettings")
local Dimension         = require("scripts.revelations.common.enums.Dimension")

return function()

-- Color shaders
REVEL.GlacierShader = REVEL.CCShader("Glacier")
REVEL.GlacierShader:SetRGB(0.9444, 0.9444, 1.01)
REVEL.GlacierShader:SetShadows{
    RGB = {0.75, 0.9, 0.9914},
    Temperature = 2.5,
    Brightness = 0.3
}
REVEL.GlacierShader:SetMidtones{
    RGB = {1.015, 1.005, 0.9997},
    Brightness = 0.1
}
REVEL.GlacierShader:SetHighlights{
    RGB = {0.97, 1.0027, 1.0563}
}

REVEL.GlacierShader:SetContrast(0.06)
REVEL.GlacierShader:SetLightness(0.01)
REVEL.GlacierShader:SetSaturation(-0.03)
REVEL.GlacierShader:SetBrightness(0.2)
REVEL.GlacierShader:SetTemp(1)


REVEL.GlacierChillShader = REVEL.CCShader("Glacier Chill")
REVEL.GlacierChillShader:SetRGB(0.93, 0.95, 1.05)
REVEL.GlacierChillShader:SetShadows{
    RGB = {0.87, 0.89, 0.9914},
    Temperature = 2,
}
REVEL.GlacierChillShader:SetMidtones{
    RGB = {1.015, 1.005, 1},
    Temperature = -1,
}
REVEL.GlacierChillShader:SetHighlights{
    RGB = {1.05, 1.0527, 1.0163},
    Temperature = 2,
}

REVEL.GlacierChillShader:SetSaturation(-0.17)
REVEL.GlacierChillShader:SetBrightness(0.1)
REVEL.GlacierChillShader:SetTemp(8)

REVEL.GlacierChillShader:SetColorBoostSelection(0.83, 0.4, 0.15, 0.03)

local chillShaderLerp = 0
local chillShaderLerpDir = -1

function REVEL.GetChillShaderPct()
    return chillShaderLerp / REVEL.DEFAULT_CHILL_FADE_TIME
end

function REVEL.SetChillShaderDir(a)
    chillShaderLerpDir = a
end

function REVEL.GlacierShader:OnUpdate()
    if REVEL.STAGE.Glacier:IsStage() 
    and REVEL.includes(REVEL.GlacierGfxRoomTypes, StageAPI.GetCurrentRoomType()) 
    and StageAPI.GetDimension() ~= Dimension.DEATH_CERTIFICATE
    then
        self.Active = 1 - (chillShaderLerp / REVEL.DEFAULT_CHILL_FADE_TIME)
    else
        self.Active = 0
    end
end

-- local t = 0
-- local w = 0.2
-- local s = 0

function REVEL.GlacierChillShader:OnUpdate()
    if REVEL.STAGE.Glacier:IsStage() 
    and REVEL.includes(REVEL.GlacierGfxRoomTypes, StageAPI.GetCurrentRoomType()) 
    and StageAPI.GetDimension() ~= Dimension.DEATH_CERTIFICATE
    then
        if REVEL.WasChanged("GlShCursed", REVEL.IsThereCurse(LevelCurse.CURSE_OF_DARKNESS)) then
            if REVEL.IsThereCurse(LevelCurse.CURSE_OF_DARKNESS) then
                REVEL.GlacierChillShader:SetContrast(0)
                REVEL.GlacierChillShader:SetLightness(0)
                REVEL.GlacierChillShader:SetColBoostRGB(1.001, 0.998, 0.99)
                REVEL.GlacierChillShader:SetColBoostSat(0.01)
            else
                REVEL.GlacierChillShader:SetContrast(0.7)
                REVEL.GlacierChillShader:SetLightness(0.25)
                REVEL.GlacierChillShader:SetColBoostRGB(1.005, 0.997, 0.985)
                REVEL.GlacierChillShader:SetColBoostSat(0.015)
            end
        end
        self.Active = chillShaderLerp / REVEL.DEFAULT_CHILL_FADE_TIME
    else
        self.Active = 0
    end
end

local wasChilled
revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    local chilled = REVEL.IsChilly()

    if chilled ~= wasChilled then
        if chilled then
            chillShaderLerpDir = 1
        else
            chillShaderLerpDir = -1
        end
        wasChilled = chilled
    end
    chillShaderLerp = REVEL.Clamp(chillShaderLerp + chillShaderLerpDir, 0, REVEL.DEFAULT_CHILL_FADE_TIME)

    --Chill wind ambient sound
    if chillShaderLerp > 0 then
        local vol = 0.75 * chillShaderLerp / REVEL.DEFAULT_CHILL_FADE_TIME
        if not REVEL.sfx:IsPlaying(REVEL.SFX.SNOWSTORM_LOOP) then
            REVEL.sfx:Play(REVEL.SFX.SNOWSTORM_LOOP, vol, 0, true, 1)
        else
            REVEL.sfx:AdjustVolume(REVEL.SFX.SNOWSTORM_LOOP, vol)
        end
    elseif REVEL.sfx:IsPlaying(REVEL.SFX.SNOWSTORM_LOOP) then
        REVEL.sfx:Stop(REVEL.SFX.SNOWSTORM_LOOP)
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    if REVEL.IsChilly() then
        chillShaderLerp = REVEL.DEFAULT_CHILL_FADE_TIME
        chillShaderLerpDir = 1
    else
        chillShaderLerpDir = -1
        chillShaderLerp = 0
    end
end)

-- Snowflake Shader
do

    local twoPi = math.pi * 2
    local snowPeriod = 120
    local cosMod = twoPi / snowPeriod
    
    local snowPositions = {
        {Vector(0, 0), 0, 0, 0},
        {Vector(0, 0), 0, 0, 0},
        {Vector(0, 0), 0, 0, 0}
    }
    
    local windTypes = {
        Standard = {
            Name = "Standard",
            RandAngle = 10,
            Speed = 0.001,
            Angle = -90,
            Noise = 50,
            Threshold = 0.95
        },
        HighRight = {
            Name = "HighRight",
            RandAngle = 5,
            Angle = 200,
            Speed = 0.02,
            Noise = 50,
            Threshold = 0.925
        },
        HighLeft = {
            Name = "HighLeft",
            RandAngle = 5,
            Angle = -20,
            Speed = 0.02,
            Noise = 50,
            Threshold = 0.925
        },
        Current = {
            Name = "Current",
            Equal = "Standard"
        },
        CurrentOld = {
            Name = "Current",
            Equal = "Standard"
        }
    }
    
    for k, v in pairs(windTypes.Standard) do
        if not windTypes.Current[k] then
            windTypes.Current[k] = v
        end
    end
    
    local isGlacierGfxRoomType = false

    local function SnowShaderEnabled()
        return (revel.data.snowflakesMode == RevSettings.SNOW_MODE_BOTH or revel.data.snowflakesMode == RevSettings.SNOW_MODE_SHADER) 
            and isGlacierGfxRoomType
    end
    
    local transitionLength = 60
    local transitioningFrom, transitioningTo, transitionTime
    local inputTime = 0
    
    local function GetAngleDifference(a1, a2)
        local sub = a1 - a2
        return (sub + 180) % 360 - 180
    end
    
    local snowflakeLerp
    snowflakeLerp = function(first, second, percent)
      if type(first) == 'table' then
        local out = {}
        for k,v in pairs(first) do
            if type(v) == "number" then
                if k:find("Angle") then
                    out[k] = REVEL.LerpAngleDegrees(v, second[k], percent)
                else
                    out[k] = snowflakeLerp(v, second[k], percent)
                end
            else
                out[k] = v
            end
        end
        return out
      else
        return first * (1 - percent) + second * percent
      end
    end
    
    local function changeWind(to, instant)
        if windTypes.Current.Equal ~= to then
            windTypes.Current.Equal = to
            for k, v in pairs(windTypes.Current) do
                windTypes.CurrentOld[k] = v
            end
    
            transitioningFrom, transitioningTo = windTypes.CurrentOld, windTypes[to]
            transitionTime = 0
    
            if instant then
                transitionTime = transitionLength - 1
            end
        end
    end
    
    local ForceChillSnow

    ---@param forceTo boolean
    function REVEL.ForceSnowChillShader(forceTo)
        ForceChillSnow = forceTo
    end

    function REVEL.ResetForceSnowChillShader()
        ForceChillSnow = nil
    end

    revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
        if REVEL.STAGE.Glacier:IsStage() then
            changeWind("Standard", true)
    
            for i = 1, 3 do
                snowPositions[i][1] = Isaac.GetRandomPosition()
                snowPositions[i][4] = math.random(1, snowPeriod)
            end
        end
    end)
    

    revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        isGlacierGfxRoomType = REVEL.STAGE.Glacier:IsStage() 
            and REVEL.includes(REVEL.GlacierGfxRoomTypes, StageAPI.GetCurrentRoomType())
            and StageAPI.GetDimension() ~= Dimension.DEATH_CERTIFICATE

        if SnowShaderEnabled() and not StageAPI.IsHUDAnimationPlaying() then
            if (ForceChillSnow == nil and REVEL.IsChilly())
            or ForceChillSnow then
                if windTypes.Current.Equal ~= "HighLeft" and windTypes.Current.Equal ~= "HighRight" then
                    local slot = REVEL.level.LeaveDoor
                    if slot == DoorSlot.LEFT0 or slot == DoorSlot.LEFT1 then
                        changeWind("HighRight")
                    elseif slot == DoorSlot.RIGHT0 or slot == DoorSlot.RIGHT1 then
                        changeWind("HighLeft")
                    else
                        if math.random(1, 2) == 1 then
                            changeWind("HighRight")
                        else
                            changeWind("HighLeft")
                        end
                    end
                end
            else
                changeWind("Standard")
            end
    
            if transitionTime then
                transitionTime = transitionTime + 1
                windTypes.Current = snowflakeLerp(transitioningFrom, transitioningTo, transitionTime / transitionLength)
                if transitionTime >= transitionLength then
                    transitionTime = nil
                    transitioningFrom = nil
                    transitioningTo = nil
                end
            end
    
            local screenScaleX, screenScaleY = StageAPI.GetScreenScale()
            local speed = 0.001
            local frame = Isaac.GetFrameCount()
            local roomTopLeft = Isaac.WorldToScreen(REVEL.room:GetTopLeftPos())
            for i = 1, 3 do
                local snowPos = snowPositions[i]
                local offset = math.cos(cosMod * (frame + snowPos[4])) * windTypes.Current.RandAngle
                local direction = Vector.FromAngle(windTypes.Current.Angle + offset) * windTypes.Current.Speed
    
                snowPos[1] = snowPos[1] + direction
    
                snowPos[2], snowPos[3] = (snowPos[1].X - roomTopLeft.X * 0.002) * screenScaleX, (snowPos[1].Y - roomTopLeft.Y * 0.002) * screenScaleY
                -- snowPos[2], snowPos[3] = snowPos[1].X * screenScaleX, snowPos[1].Y * screenScaleY
            end
        end
    end)
    
    REVEL.AddShader("Snowflakes", function()
        local active = (revel.data.shadersOn == 0 and 0) or REVEL.GetShaderActiveMult()
        if SnowShaderEnabled() then
            local l1X, l1Y, l2X, l2Y, l3X, l3Y = snowPositions[1][2], snowPositions[1][3], 
                snowPositions[2][2], snowPositions[2][3], 
                snowPositions[3][2], snowPositions[3][3]
    
            return {
                ActiveIn = active,
                DirectionNoiseThresholdIn = {l1X, l1Y, windTypes.Current.Noise, windTypes.Current.Threshold},
                AltDirectionsIn = {l2X, l2Y, l3X, l3Y},
            }
        else
            return {
                ActiveIn = active,
                DirectionNoiseThresholdIn = {0, 0, 0, 0},
                AltDirectionsIn = {0, 0, 0, 0},
            }
        end
    end)
end


end