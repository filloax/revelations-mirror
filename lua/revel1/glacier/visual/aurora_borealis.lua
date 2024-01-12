local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()
    
-- Aurora Borealis

-- At this time of year? In this part of the country?
-- Localised entirely within some spaghetti code?
-- Yes.

-- Adapted from https://gist.github.com/brookesi/6593166
local function getPointsAndSlopeOnSpline(points, tension, numOfSegments)
    -- use input value if provided, or use a default value
    tension = tension or 0.5
    numOfSegments = numOfSegments or 16

    local res = {}
    local slopes = {}
    local y					--/ our x,y coords
    local t1x
    local t2x
    local t1y
    local t2y		--/ tension vectors
    local c1, c2, c3, c4			--/ cardinal points
    local st, t, i				--/ steps based on num. of segments
    local pow3, pow2				--/ cache powers
    local pow32, pow23
    local p0, p1, p2, p3			--/ cache points
    local resIdx
    local nPoints = #points
    local x, y

    for i=1, nPoints do
        local next = points[i + 1] or points[i]
        local next2 = (points[i + 2] or points[i + 1]) or points[i]
        local prev = points[i - 1] or points[i]

        p0 = points[i].X
        p1 = points[i].Y
        p2 = next.X
        p3 = next.Y

        --/ calc tension vectors
        t1x = (p2 - prev.X)* tension
        t2x = (next2.X - p0)* tension

        t1y = (p3 - prev.Y)* tension
        t2y = (next2.Y - p1) * tension

        for t=0, numOfSegments do
            --/ calc step
            st = t / numOfSegments

            pow2 = st * st
            pow3 = pow2 * st
            pow23 = pow2 * 3
            pow32 = pow3 * 2

            --/ calc cardinals
            c1 = pow32 - pow23 + 1
            c2 = pow23 - pow32
            c3 = pow3 - 2 * pow2 + st
            c4 = pow3 - pow2

            --/ calc x and y cords with common control vectors
            x = c1 * p0 + c2 * p2 + c3 * t1x + c4 * t2x
            y = c1 * p1 + c2 * p3 + c3 * t1y + c4 * t2y

            --/ store points in array
            resIdx = #res + 1
            res[resIdx] = Vector(x, y)

            if res[resIdx - 1] then
                slopes[resIdx - 1] = (res[resIdx] - res[resIdx - 1]):GetAngleDegrees()
            end
        end
    end
    slopes[#res] = slopes[#res - 1]

    return res, slopes
end

local Settings = {
    NumSegments = 12, --between each point
    SplineTension = 0.8,
    BaseAlpha = 0.09,
    AuroraRoomChance = 0.04,
    AuroraRoomChanceCoD = 0.2,
    AuroraRoomChanceBoss = 0.33,
    DisableOnChill = false,
    AuroraTypes = {"green", "purple", "teal", "green_teal"},
    RoomTypes = REVEL.GlacierGfxRoomTypes,
}

local AuroraOn = 0
local AuroraAlpha = 0
local AuroraType
local AuroraPoints = {}
local AuroraPointsBase = {}
local AuroraPointsTargets = {}
local AuroraPointsSpline = {}
local AuroraSlopes = {}

local AuroraSpriteColors = {"green", "purple", "teal"}
---@type table<string, RevSpriteCache.Params>
local AuroraSpriteParams = {}

for i, color in ipairs(AuroraSpriteColors) do
    AuroraSpriteParams[color] = {
        ID = "aurora" .. color,
        Anm2 = "gfx/effects/revel1/aurora.anm2",
        Scale = Vector.One * 1.5,
        OnCreate = function(sprite)
            sprite:ReplaceSpritesheet(0, "gfx/effects/revel1/glacier_aurora" .. color .. ".png")
            sprite:LoadGraphics()
            sprite:SetFrame("idle1", 0)
        end
    }
end

local function getPointTarget(pt)
    return pt + (RandomVector() * math.random(5, 40)) * Vector(1, 0.25)
end

local function vecCompareX(vecA, vecB)
    return vecA.X < vecB.X
end

local function sortVectorsByX(vecArray)
    table.sort(vecArray, vecCompareX)
end

local function aurora_PostNewRoom()
    local rng = REVEL.RNG()
    rng:SetSeed(REVEL.room:GetDecorationSeed(), 0)
    local codChance = REVEL.IsThereCurse(LevelCurse.CURSE_OF_DARKNESS) and Settings.AuroraRoomChanceCoD or 0
    local bossChance = REVEL.room:GetType() == RoomType.ROOM_BOSS and Settings.AuroraRoomChanceBoss or 0
    local chance = math.max(Settings.AuroraRoomChance, codChance, bossChance)

    if REVEL.STAGE.Glacier:IsStage() and REVEL.includes(Settings.RoomTypes, StageAPI.GetCurrentRoomType())
    and not (REVEL.IsChillRoom() and Settings.DisableOnChill)
    and revel.data.auroraOn > 0
    and (
        rng:RandomFloat() < chance
        or Isaac.CountEntities(nil, EntityType.ENTITY_PRIDE) > 0
    ) 
    then
        AuroraOn = 1
    else
        AuroraOn = 0
    end

    if AuroraOn > 0 then
        local idx = rng:RandomInt(#Settings.AuroraTypes) + 1
        AuroraType = Settings.AuroraTypes[idx]

        if AuroraType ~= "purple" then
            REVEL.AuroraShader:SetRGB(1, 1.01, 1.012)
            REVEL.AuroraShader:SetBrightness(0.05)
            REVEL.AuroraShader:SetTint(158/365, 1, 0.2)
            REVEL.AuroraShader:SetLevels(0.005, 0, 0)
        else
            REVEL.AuroraShader:SetRGB(1.012, 1, 1.012)
            REVEL.AuroraShader:SetBrightness(0.05)
            REVEL.AuroraShader:SetTint(279/365, 1, 0.2)
            REVEL.AuroraShader:SetLevels(0.005, 0, 0)
        end

        AuroraPointsBase = {}
        AuroraPoints = {}
        AuroraPointsTargets = {}
        local tl, br = REVEL.GetRoomCorners()

        local numTwists = math.random(0, 1)
        local twistDisplaceMax = 90
        local numBends = math.random(3, 7)
        local lowDist = -25
        local highDist = -15
        local center = (lowDist + highDist) / 2
        local roomOffsetX = 40

        local left = tl + REVEL.VEC_LEFT * roomOffsetX + REVEL.VEC_DOWN * lowDist
        local right = Vector(br.X + roomOffsetX, tl.Y) + REVEL.VEC_DOWN * lowDist

        AuroraPointsBase[#AuroraPointsBase + 1] = left + REVEL.VEC_DOWN * lowDist

        for i = 1, numBends do --minor bends in spline
            local t = i / (numBends + 1)
            local posBase = REVEL.Lerp(left, right, t)
            local off = REVEL.Lerp(center, math.random(lowDist, highDist), 0.5)
            AuroraPointsBase[#AuroraPointsBase + 1] = posBase + REVEL.VEC_DOWN * off
        end

        local lastTwistDown = false --twists in spline
        for i = 1, numTwists do
            local t = i / (numTwists + 1)
            local posBase = REVEL.Lerp(left, right, t)
            if lastTwistDown then
                AuroraPointsBase[#AuroraPointsBase + 1] = posBase + REVEL.VEC_DOWN * highDist + REVEL.VEC_LEFT * math.random(twistDisplaceMax * 0.1, twistDisplaceMax)
                AuroraPointsBase[#AuroraPointsBase + 1] = posBase + REVEL.VEC_DOWN * lowDist + REVEL.VEC_RIGHT * math.random(twistDisplaceMax * 0.1, twistDisplaceMax)
            else
                AuroraPointsBase[#AuroraPointsBase + 1] = posBase + REVEL.VEC_DOWN * lowDist + REVEL.VEC_LEFT * math.random(twistDisplaceMax * 0.1, twistDisplaceMax)
                AuroraPointsBase[#AuroraPointsBase + 1] = posBase + REVEL.VEC_DOWN * highDist + REVEL.VEC_RIGHT * math.random(twistDisplaceMax * 0.1, twistDisplaceMax)
            end
            lastTwistDown = not lastTwistDown
        end

        --as bends and twists aren't added in correct x order, sort that
        sortVectorsByX(AuroraPointsBase)

        AuroraPointsBase[#AuroraPointsBase + 1] = right + REVEL.VEC_DOWN * lowDist

        for i, pt in ipairs(AuroraPointsBase) do
            AuroraPointsTargets[i] = getPointTarget(pt)
            AuroraPoints[i] = getPointTarget(pt) --this will be updated to oscillate
        end

        AuroraPointsSpline, AuroraSlopes = getPointsAndSlopeOnSpline(AuroraPoints, Settings.SplineTension, Settings.NumSegments)
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 0, aurora_PostNewRoom)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, aurora_PostNewRoom)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if AuroraOn > 0 then
        local doResetTargets = REVEL.game:GetFrameCount() % 30 == 0
        if doResetTargets then
            AuroraPointsTargets = {}
        end

        for i, pt in ipairs(AuroraPointsBase) do
            if doResetTargets then
                AuroraPointsTargets[i] = getPointTarget(pt)
            end
            AuroraPoints[i] = REVEL.Lerp(AuroraPoints[i], AuroraPointsTargets[i], 0.02)
        end

        AuroraPointsSpline, AuroraSlopes = getPointsAndSlopeOnSpline(AuroraPoints, Settings.SplineTension, Settings.NumSegments)
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if AuroraOn > 0 and not StageAPI.IsHUDAnimationPlaying(true) then
        AuroraAlpha = AuroraOn * REVEL.Saturate(math.max(0, -1 + REVEL.GetRoomTransitionProgress() * 2))
        if AuroraType == "green_teal" then
            local auroraSprite_Green = REVEL.RoomSprite(AuroraSpriteParams.green)
            local auroraSprite_Teal = REVEL.RoomSprite(AuroraSpriteParams.teal)
            auroraSprite_Green.Color = Color(1, 1, 1, AuroraAlpha * Settings.BaseAlpha,conv255ToFloat( 0, 0, 0))
            auroraSprite_Teal.Color = Color(1, 1, 1, AuroraAlpha * Settings.BaseAlpha,conv255ToFloat( 0, 0, 0))
            local r = REVEL.RNG()
            local seed = REVEL.room:GetDecorationSeed()
            seed = (seed == 0) and seed + 125 or seed
            r:SetSeed(seed, 38)
            for i, pt in ipairs(AuroraPointsSpline) do
                -- local pt1 = pt + REVEL.VEC_UP:Rotated(AuroraSlopes[i]) * 13
                -- local pt2 = pt + REVEL.VEC_DOWN:Rotated(AuroraSlopes[i]) * 13
                -- IDebug.RenderLine(pt1, pt2, true)
                local pct = i / #AuroraPointsSpline
                local doGreen = r:RandomFloat() < pct
                if doGreen then
                    auroraSprite_Green.Rotation = AuroraSlopes[i]
                    auroraSprite_Green:RenderLayer(0, Isaac.WorldToScreen(pt))
                else
                    auroraSprite_Teal.Rotation = AuroraSlopes[i]
                    auroraSprite_Teal:RenderLayer(0, Isaac.WorldToScreen(pt))
                end
            end
        else
            local auroraSprite = REVEL.RoomSprite(AuroraSpriteParams[AuroraType])
            auroraSprite.Color = Color(1, 1, 1, AuroraAlpha * Settings.BaseAlpha,conv255ToFloat( 0, 0, 0))

            for i, pt in ipairs(AuroraPointsSpline) do
                -- local pt1 = pt + REVEL.VEC_UP:Rotated(AuroraSlopes[i]) * 13
                -- local pt2 = pt + REVEL.VEC_DOWN:Rotated(AuroraSlopes[i]) * 13
                -- IDebug.RenderLine(pt1, pt2, true)
                auroraSprite.Rotation = AuroraSlopes[i]
                auroraSprite:RenderLayer(0, Isaac.WorldToScreen(pt))
            end
        end

        -- for _, pt in pairs(AuroraPoints) do
            -- IDebug.RenderCircle(pt, true)
        -- end
    else
        AuroraAlpha = 0
    end
end)

REVEL.AuroraShader = REVEL.CCShader("GlacierAurora") --changed above
-- REVEL.AuroraShader:SetRGB(1, 1.01, 1.012)
-- REVEL.AuroraShader:SetBrightness(0.05)
-- REVEL.AuroraShader:SetTint(158/365, 1, 0.2)
-- REVEL.AuroraShader:SetLevels(0.005, 0, 0)

function REVEL.AuroraShader:OnUpdate()
    self.Active = AuroraAlpha
end

end