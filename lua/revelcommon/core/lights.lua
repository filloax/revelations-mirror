local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

---------------------------
-- Custom light and dark --
---------------------------

--[[Useful type/vars:
    -Effects:
    BLUE_FLAME: faint blue light, small, flickering
    RED_CANDLE_FLAME: red light, small, flickering
    FIREWORKS (with subtype 4): firework spark, scalable, can be colored and (vanilla behaviour, disabled by default, set data.DecreaseRadius to true to enable) gets smaller with time
]]

local Lights = {}

StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 2, function()
    local e = Isaac.GetRoomEntities()
    for i, ent in ipairs(e) do
        if ent:GetData().CustomLight then
            table.insert(Lights, ent)
        end
    end
end)

function REVEL.SpawnLight(pos, color, size, force, type, variant, subtype)
    if revel.data.cLightSetting > 0 and (REVEL.IsDark() or force) then
        local light = Isaac.Spawn(type or 1000, variant or EffectVariant.FIREWORKS, subtype or 4, pos, Vector.Zero, nil)
        color = REVEL.CloneColor(color)
        light:SetColor(color, -1, 999, false, false) -- maybe not necessary? might've just kept this in when i switched to setting sheet to none
        light:GetSprite():ReplaceSpritesheet(0, "gfx/ui/none.png")
        light:GetData().Color = color
        light:GetSprite():LoadGraphics()
        light.SpriteScale = light.SpriteScale * (size or 1)
        light:GetData().CustomLight = true
        light:GetData().LightColor = color

        if light.Type == 1000 and light.Variant == EffectVariant.FIREWORKS and light.SubType == 4 then
            light:GetData().OrigScale = REVEL.CloneVec(light.SpriteScale)
        end

        table.insert(Lights, light)
        return light
    end
end

function REVEL.SpawnLightFlash(pos, color, size, force, time, fade) --fade is after time, both in frames
    local light = REVEL.SpawnLight(pos, color, size, force)
    if light then
        light:GetData().FlashTime = time + fade
        light:GetData().FlashFade = fade

        return light
    end
end

function REVEL.SpawnLightAtEnt(ent, color, size, offset, followOffset, force, type, variant, subtype)
    local light = REVEL.SpawnLight(ent.Position + (offset or Vector.Zero), color, size or 1, force, type, variant, subtype)
    if light then
        light:GetData().lightSpawnerEntity = ent
        light:GetData().LightOffset = offset
        light:GetData().LightFollowOffset = followOffset --false/true
    end

    return light
end

function REVEL.SetLightSize(light, size)
    light.SpriteScale = light.SpriteScale * size
    if light.Type == 1000 and light.Variant == EffectVariant.FIREWORKS and light.SubType == 4 then
        light:GetData().OrigScale = REVEL.CloneVec(light.SpriteScale)
    end
end

local function updateLight(i, light)
    if not light:Exists() then
        table.remove(Lights, i)
        return
    end

    local data = light:GetData()

    local disable = data.Disable
    data.Disable = false

    if data.FlashTime then
        data.FlashTime = data.FlashTime - 1
        data.Color.A = REVEL.Lerp2Clamp(0, 1, data.FlashTime, 0, data.FlashFade)
        if data.FlashTime <= 0 then
            light:Remove()
            table.remove(Lights, i)
            return
        end
    end

    if data.lightSpawnerEntity then
        if not data.lightSpawnerEntity:Exists() or data.lightSpawnerEntity:IsDead() then
            light:Remove()
            table.remove(Lights, i)
            return
        else
            disable = disable or (not data.lightSpawnerEntity.Visible) or IsAnimOn(data.lightSpawnerEntity:GetSprite(), "NoFire") or IsAnimOn(data.lightSpawnerEntity:GetSprite(), "Dissapear")
            if data.LightFollowOffset then
                data.LightOffset = data.lightSpawnerEntity.SpriteOffset
                if data.lightSpawnerEntity:ToTear() or data.lightSpawnerEntity:ToProjectile() then
                    data.lightSpawnerEntity = data.lightSpawnerEntity:ToTear() or data.lightSpawnerEntity:ToProjectile()
                    data.LightOffset = data.LightOffset + Vector(0, data.lightSpawnerEntity.Height)
                end
            end

            light.Position = data.lightSpawnerEntity.Position + (data.LightOffset or Vector.Zero)
            light.Velocity = data.lightSpawnerEntity.Velocity
        end
    end

    if disable then
        light.Color = REVEL.NO_COLOR
    else
        light.Color = data.Color
    end

    light = light:ToEffect()
    if light and light.Variant == EffectVariant.FIREWORKS and light.SubType == 4 and not data.DecreaseRadius then
        -- light.State = 1 --keep at max radius
        light.SpriteScale = data.OrigScale
    end
end

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    for i, light in ripairs(Lights) do
        updateLight(i, light)
    end
end)

-- Measured with videos, might be incorrect/depend on time somehow
local DarkenFadeinDur = 21
local DarkenFadeoutDur = 30 --Starts after game:Darken time runs out, so its 30 frames on top of that
local Dark = 0
local DarkLerp = 0
local DarkLerpDir = 0
local TargetDarkness = 0 -- using our own one, since using the game's one while not keeping track of the game's calls of the function wouldn't really work

REVEL.BaseGameDarkness = 0.5

local LerpStart
local LerpTarget = 0
local TargetLerpTime = 5
local TargetLerp = 0
local LastTargetTime = 0
-- since the base game has a GetTargetDarkness funciton but it returns the last :Darken call value, regardless of the game being currently dark or not
-- we use a custom one to keep track
-- The way vanilla Game:Darken(v, t) works is, it sets the target darkness to v, and either interpolates to it if its not already doing so, or
-- changes the target darkness its interpolating to if it is already doing so
function REVEL.Darken(v, t)
    REVEL.game:Darken(v, t)
    Dark = t + DarkenFadeoutDur
    DarkLerpDir = 1
    TargetDarkness = v
end

function REVEL.DarkenSmooth(v, t) --intended for frequently changing the target darkness
    if TargetDarkness == 0 or LerpStart == v then
        REVEL.Darken(v, t)
    else
        if LerpStart then
            TargetLerp = REVEL.Lerp2Clamp(0, TargetLerpTime, TargetDarkness, LerpStart, v)
        else
            LerpStart = TargetDarkness
        end
        LerpTarget = v
        REVEL.Darken(TargetDarkness, t)
        LastTargetTime = t
    end
end
--
-- local d = 0
-- revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
--   if Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_1) then
--     d = math.min(1, d + 0.01)
--     REVEL.DarkenSmooth(d, 60)
--   elseif Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_2) then
--     d = math.max(0, d - 0.01)
--     REVEL.DarkenSmooth(d, 60)
--   end
-- end)
--
-- revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
--   local pos = Input.GetMousePosition(true)
--   pos = Isaac.WorldToRenderPosition(pos)
--   Isaac.RenderText(d, pos.X + 10, pos.Y+10, 255, 255, 255, 255)
--   Isaac.RenderText(REVEL.ToStringMulti("Current::", "TL:",TargetLerp, "LS:", LerpStart, "LT:", LerpTarget, "TD:", TargetDarkness), pos.X + 10, pos.Y+20, 255, 255, 255, 255)
-- end)

function REVEL.GetDarkness()
    return REVEL.room:GetLightingAlpha()

    -- if REVEL.IsThereCurse(LevelCurse.CURSE_OF_DARKNESS) then
    --     return 1
    -- elseif TargetDarkness then
    --     if DarkLerpDir >= 0 then
    --         return REVEL.Lerp2Clamp(REVEL.BaseGameDarkness, TargetDarkness, DarkLerp, 0, DarkenFadeinDur)
    --     else
    --         return REVEL.Lerp2Clamp(REVEL.BaseGameDarkness, TargetDarkness, DarkLerp, 0, DarkenFadeoutDur)
    --     end
    -- else
    --     return REVEL.BaseGameDarkness
    -- end
end

--0 at REVEL.BaseGameDarkness, 1 at 1
function REVEL.GetRelativeDarkness()
    return REVEL.InvLerp(REVEL.GetDarkness(), REVEL.BaseGameDarkness, 1)
end

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if LerpStart and LastTargetTime > 1 then
        LastTargetTime = LastTargetTime - 1
        TargetLerp = math.min(TargetLerp + 1, TargetLerpTime)
        REVEL.Darken(REVEL.Lerp2(LerpStart, LerpTarget, TargetLerp, 0, TargetLerpTime), LastTargetTime)
        if TargetLerp == TargetLerpTime then
            TargetLerp = 0
            LerpStart = nil
        end
    else
        LerpStart = nil
        TargetLerp = 0
    end

    DarkLerp = REVEL.Clamp(DarkLerp + DarkLerpDir, 0, math.max(DarkenFadeinDur, DarkenFadeoutDur))
    if (DarkLerp == 0 or DarkLerp == math.max(DarkenFadeinDur, DarkenFadeoutDur)) and REVEL.WasChanged("DarkenLerp", DarkLerp) then
        DarkLerpDir = 0
    end
    if Dark > 0 then
        Dark = Dark - 1
        if Dark == DarkenFadeoutDur then
            DarkLerpDir = -1
        end
    end
    if REVEL.WasChanged("DarkenCnt", Dark) and Dark == 0 then
        TargetDarkness = REVEL.BaseGameDarkness
    end
end)

function REVEL.IsDark()
    return REVEL.GetRelativeDarkness() > 0
end
    --Size is a multiplier
  
end