local Dimension = require "lua.revelcommon.enums.Dimension"
return function()
    -- Base shaders
    
    REVEL.TombShader = REVEL.CCShader("Tomb")
    REVEL.TombShader:SetRGB(1.01, 0.955, 0.87)
    -- REVEL.TombShader:SetShadows{
    --   RGB = {0.98, 1.008, 1.04},
    --   Temperature = 2.5,
    --   Brightness = 0
    -- }
    REVEL.TombShader:SetMidtones{
        RGB = {1.002, 1.001, 1},
        Temperature = -3.5,
        Brightness = 0.15
    }
    REVEL.TombShader:SetHighlights{
        RGB = {0.93, 0.97, 1.004},
        Temperature = -5.5,
        Brightness = 0
    }

    REVEL.TombShader:Set3WayWeight(100, 8, 3)
    REVEL.TombShader:SetSaturation(-0.02)
    REVEL.TombShader:SetBrightness(0.3)
    -- REVEL.TombShader:SetBrightness(0.3)
    -- REVEL.TombShader:SetTemp(-13.5)
    -- REVEL.TombShader:SetContrast(-0.015)
    -- REVEL.TombShader:SetLightness(-0.05)
    REVEL.TombShader:SetUseLegacyCL(true)

    local extraRoomShaderTypes = {
        RoomType.ROOM_SHOP,
        RoomType.ROOM_ARCADE,
        RoomType.ROOM_CURSE,
        RoomType.ROOM_CHALLENGE,
        RoomType.ROOM_BOSSRUSH
    }

    function REVEL.TombShader:OnUpdate()
        local rtype = REVEL.room:GetType()
        if (
            REVEL.includes(REVEL.TombGfxRoomTypes, StageAPI.GetCurrentRoomType()) 
            or REVEL.includes(extraRoomShaderTypes, rtype) or rtype == RoomType.ROOM_SECRET
        ) 
        and REVEL.STAGE.Tomb:IsStage() 
        and StageAPI.GetDimension() ~= Dimension.DEATH_CERTIFICATE
        then
            if REVEL.WasChanged("TSUpdDark", REVEL.IsThereCurse(LevelCurse.CURSE_OF_DARKNESS)) then
                if REVEL.IsThereCurse(LevelCurse.CURSE_OF_DARKNESS) then
                    REVEL.TombShader:SetLightness(-0.01)
                    REVEL.TombShader:SetShadows{
                    RGB = {1.02, 0.985, 0.975},
                    Temperature = 1,
                    Brightness = 0.1
                    }
                    REVEL.TombShader:SetTemp(-16.5)
                    REVEL.TombShader:SetContrast(0.005)
                else
                    REVEL.TombShader:SetLevels(0,0, 0.08)
                    REVEL.TombShader:SetLightness(-0.05)
                    REVEL.TombShader:SetShadows{
                    RGB = {0.98, 1.008, 1.04},
                    Temperature = 4.5,
                    Brightness = 0.1
                    }
                    REVEL.TombShader:SetTemp(-19.5)
                    REVEL.TombShader:SetContrast(0.01)
                end
            end
            self.Active = 1
        else
            self.Active = 0
        end
    end

    --Masked shaders

    REVEL.TombMaskAdjust = { --pasted from config, that's why it's disarrayed
        RGB = {1.009, 1.075, 0.976},
        Temperature = -18,
        Brightness = 0.21,
        Exposure = 0,
        TintHue = 0,
        TintSat = 0,
        TintAmount = 0,
        Output = {
            ActiveIn = 0,
            TypeVariantDebug = {1,0,0},
            RGB = {1,1,1},
            ContrLightSat = {
                0.032,
                0.053,
                0.353
            },
            nTlBr = {
                0.14791665971279, 0.16296295821667,
                0.85208332538605, 0.83703702688217
            },
        },
        Name = "TombMaskAdjust" --for debug
    }

    REVEL.TombMaskAdjustSand = { --pasted from config, that's why it's disarrayed
        Hue = 0,
        RGB = {1.007, 1.011, 0.976},
        Temperature = -12,
        Brightness = 0.23,
        Exposure = 0,
        TintHue = 0,
        TintSat = 0,
        TintAmount = 0,
        Output = {
            ActiveIn = 0,
            TypeVariantDebug = {1,0,0},
            RGB = {1,1,1},
            ContrLightSat = {
                0.042,
                0.091,
                0.383
            },
            nTlBr = {
                0.14791665971279, 0.16296295821667,
                0.85208332538605, 0.83703702688217
            },
        },
        Name = "TombMaskAdjustSand" --for debug
    }

    local numShaders = 10
    local noShaderWgt = 5 --chance, out of this + numShaders, for the room to have no mask shader

    local CachedSeed = -1
    local CachedShader = -1

    local masktest --
    local getShaderFromSeed = function()
        if masktest then return masktest end
        local s = REVEL.room:GetDecorationSeed()
        if s ~= CachedSeed then
            local r = REVEL.RNG()
            r:SetSeed(s, 0)
            CachedShader = 1 + r:RandomInt(noShaderWgt + numShaders)
            CachedSeed = s
        end
        return CachedShader
    end
    REVEL.GetTombShader = getShaderFromSeed

    local currentShader = 0

    local pauseCount = 0
    local wasPaused
    revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if REVEL.STAGE.Tomb:IsStage() then
            pauseCount = pauseCount + 1
            if wasPaused ~= REVEL.game:IsPaused() then
                if REVEL.game:IsPaused() then 
                    pauseCount = 0
                end
                wasPaused = REVEL.game:IsPaused()
            end
            if pauseCount > 8 then --dont update it immediately on room change
                currentShader = getShaderFromSeed()
            end
        end
    end)

    if Isaac.GetPlayer(0) then currentShader = getShaderFromSeed() end

    local alphaMult = 1
    local alphaMultChangedFrame = 0

    -- Needs to be done each update
    function REVEL.SetTombLightShaderAlpha(alpha)
        alphaMult = alpha
        alphaMultChangedFrame = REVEL.game:GetFrameCount()
    end

    local function maskShaderFunc(name, shadersOn)
        local shader = currentShader
        local currentRoomType = StageAPI.GetCurrentRoomType()
        local t
        local rtype = REVEL.room:GetType()
        if (REVEL.includes(REVEL.TombGfxRoomTypes, currentRoomType) or REVEL.includes(extraRoomShaderTypes, rtype)) 
        and REVEL.STAGE.Tomb:IsStage() and REVEL.NotBossOrNightmare() 
        and StageAPI.GetDimension() ~= Dimension.DEATH_CERTIFICATE
        and not REVEL.IsThereCurse(LevelCurse.CURSE_OF_DARKNESS) 
        and (REVEL.GetRoomTransitionProgress() < 1 or pauseCount < 8 or not REVEL.game:IsPaused())
        and shader <= numShaders 
        then
            if REVEL.includes(REVEL.TombSandGfxRoomTypes, currentRoomType) then
                t = REVEL.TombMaskAdjustSand.Output
            else
                t = REVEL.TombMaskAdjust.Output
            end

            local br, tl = REVEL.room:GetBottomRightPos(), REVEL.room:GetTopLeftPos()
            local nbr, ntl = REVEL.NormScreenVector(Isaac.WorldToScreen(br)), REVEL.NormScreenVector(Isaac.WorldToScreen(tl))

            t.nTlBr[1] = ntl.X
            t.nTlBr[2] = ntl.Y
            t.nTlBr[3] = nbr.X
            t.nTlBr[4] = nbr.Y
            -- opacity/active
            t.ActiveIn = REVEL.Saturate(
                (math.max(0, -1 + REVEL.GetRoomTransitionProgress() * 2) 
                    + (1-REVEL.LinearStep(pauseCount, 0, 7)))
                * alphaMult
                * REVEL.Saturate(1 - REVEL.GetRelativeDarkness())
            )
            t.TypeVariantDebug[2] = shader --selected mask
        end
        return t
    end

    REVEL.AddEffectShader(maskShaderFunc)

    REVEL.UpdateShaderRGB("TombMaskAdjust", REVEL.TombMaskAdjust, REVEL.TombMaskAdjust.Output.RGB)
    REVEL.UpdateShaderRGB("TombMaskAdjustSand", REVEL.TombMaskAdjustSand, REVEL.TombMaskAdjustSand.Output.RGB)

    revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        local frameCount = REVEL.game:GetFrameCount()
        if frameCount ~= alphaMultChangedFrame then
            alphaMult = 1
        end
    end)
end