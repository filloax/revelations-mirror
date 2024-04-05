local StageAPICallbacks = require "scripts.revelations.common.enums.StageAPICallbacks"
return function()

-- not boss screen, transition, etc
function REVEL.ShouldRenderHudElements()
    return REVEL.NotBossOrNightmare() 
        and REVEL.game:GetHUD():IsVisible()
end

-- mainly screenshake
function REVEL.GetHudTextOffset()
    return REVEL.game.ScreenShakeOffset
end

--#region Giantbook
--based on piber20helper code

local shouldRenderGiantbook = false
local giantbookUI = REVEL.LazyLoadRunSprite{
    ID = "giantbook",
    Anm2 = "gfx/ui/giantbook/giantbook.anm2",
}
local giantBookAnimationFile = "gfx/ui/giantbook/giantbook.anm2"
local giantBookSpritesheetFile
local giantbookAnimation = "Appear"

function REVEL.AnimateGiantbook(spritesheet, sound, animationToPlay, animationFile, doPause)
    if doPause == nil then
        doPause = true
    end

    --[[
    if doPause and pauseEnabled then
        REVEL.GiantbookPause()
    end
    ]]

    if not animationToPlay then
        animationToPlay = "Appear"
    end

    if not animationFile then
        animationFile = "gfx/ui/giantbook/giantbook.anm2"
        if animationToPlay == "Appear" or animationToPlay == "Shake" then
            animationFile = "gfx/ui/giantbook/giantbook.anm2"
        elseif animationToPlay == "Static" then
            animationToPlay = "Effect"
            animationFile = "gfx/ui/giantbook/giantbook_clicker.anm2"
        elseif animationToPlay == "Flash" then
            animationToPlay = "Idle"
            animationFile = "gfx/ui/giantbook/giantbook_mama_mega.anm2"
        elseif animationToPlay == "Sleep" then
            animationToPlay = "Idle"
            animationFile = "gfx/ui/giantbook/giantbook_sleep.anm2"
        elseif animationToPlay == "AppearBig" or animationToPlay == "ShakeBig" then
            if animationToPlay == "AppearBig" then
                animationToPlay = "Appear"
            elseif animationToPlay == "ShakeBig" then
                animationToPlay = "Shake"
            end
            animationFile = "gfx/ui/giantbook/giantbookbig.anm2"
        end
    end

    giantbookAnimation = animationToPlay
    if giantBookAnimationFile ~= animationFile then
        giantbookUI:Load(animationFile, true)
        giantBookAnimationFile = animationFile
    end
    if spritesheet ~= giantBookSpritesheetFile then
        giantbookUI:ReplaceSpritesheet(0, spritesheet)
        giantbookUI:LoadGraphics()
        giantBookSpritesheetFile = spritesheet
    end
    giantbookUI:Play(animationToPlay, true)
    shouldRenderGiantbook = true

    if sound then
        REVEL.sfx:Play(sound, 1, 0, false, 1)
    end
end

local function giantbookPostRender()
    if shouldRenderGiantbook then
        if Isaac.GetFrameCount() % 2 == 0 then
            giantbookUI:Update()
            if giantbookUI:IsFinished(giantbookAnimation) then
                shouldRenderGiantbook = false
            end
        end
        giantbookUI:Render(StageAPI.GetScreenCenterPosition(), Vector(0,0), Vector(0,0))
    end
end

--#endregion

--#region screensize

function REVEL.GetScreenCenterPosition()
    return Vector(Isaac.GetScreenWidth()  / 2, Isaac.GetScreenHeight() / 2)
end

function REVEL.GetBottomRightNoOffset()
    return Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())
end

function REVEL.GetBottomLeftNoOffset()
    return Vector(0, REVEL.GetBottomRightNoOffset().Y)
end

function REVEL.GetTopRightNoOffset()
    return Vector(REVEL.GetBottomRightNoOffset().X, 0)
end

function REVEL.GetTopLeftNoOffset()
    return Vector.Zero
end

function REVEL.GetHUDOffset()
    return Options.HUDOffset
end

local HudOffsetMult = Vector(20, 12)

---@return Vector
function REVEL.GetScreenBottomRight()
    local offset = REVEL.GetHUDOffset()
    local hudOffset = -HudOffsetMult * offset

    return REVEL.GetBottomRightNoOffset() + hudOffset
end

---@return Vector
function REVEL.GetScreenBottomLeft()
    local offset = REVEL.GetHUDOffset()
    local hudOffset = HudOffsetMult * Vector(1, -1) * offset

    return REVEL.GetBottomLeftNoOffset() + hudOffset
end

---@return Vector
function REVEL.GetScreenTopRight()
    local offset = REVEL.GetHUDOffset()
    local hudOffset = HudOffsetMult * Vector(-1, 1) * offset

    return REVEL.GetTopRightNoOffset() + hudOffset
end

---@return Vector
function REVEL.GetScreenTopLeft()
    local offset = REVEL.GetHUDOffset()
    local hudOffset = HudOffsetMult * offset

    return REVEL.GetTopLeftNoOffset() + hudOffset
end

function REVEL.NormScreenVector(v) --normalize render position vector based on screensize, so that 0;0 is top left, 1;1 is bottom right
    local screenSize = REVEL.GetScreenCenterPosition()*2
    return Vector(v.X / screenSize.X, v.Y / screenSize.Y)
end
  
function REVEL.NormScreenVectorX(v) --normalize render position vector based on screensize X, so that 0 is left and 1 is right, while top is 0 and bottom is height/width (useful for things where you want the same measure unit on x and y)
    local screenSize = REVEL.GetScreenCenterPosition()*2
    return Vector(v.X / screenSize.X, v.Y / screenSize.X)
end

function REVEL.GetScreenCenterPositionWorld() --credits to alphaapi
    --TODO: make it properly work in non-square rooms
    local room = Game():GetRoom()
    local shape = room:GetRoomShape()
    local centerOffset = (room:GetCenterPos()) - room:GetTopLeftPos()
    local pos = room:GetCenterPos()
    if centerOffset.X > 260 then
        pos.X = pos.X - 260
    end
    if shape == RoomShape.ROOMSHAPE_LBL or shape == RoomShape.ROOMSHAPE_LTL then
        pos.X = pos.X - 260
    end
    if centerOffset.Y > 140 then
        pos.Y = pos.Y - 140
    end
    if shape == RoomShape.ROOMSHAPE_LTR or shape == RoomShape.ROOMSHAPE_LTL then
        pos.Y = pos.Y - 140
    end
    return pos
end

function REVEL.GetScreenTopLeftWorld()
    return Isaac.ScreenToWorld(REVEL.GetTopLeftNoOffset())
end

--Isaac,ScreenToWorld currently works _very_ weirdly (likely a bug) and only transforms coords properly in (0,0) (aka, the only vector that properly gets transformed is that one)
--So, top left screen corner works, bottom right will have to make do without it
--This right now only works in normal rooms
function REVEL.GetScreenBottomRightWorld()
    local TL = REVEL.GetScreenTopLeftWorld()
    return TL + (REVEL.GetScreenCenterPositionWorld() - TL) * 2
end

--return TL, BR
function REVEL.GetScreenCornersWorld()
    return REVEL.GetScreenTopLeftWorld(), REVEL.GetScreenBottomRightWorld()
end

-- Also see position.lua/REVEL.IsPositionInScreen

--#endregion

--#region FadeToColor

local FadeAboveHud = false
local Fade = REVEL.LazyLoadLevelSprite{
    ID = "lib_Fade",
    Anm2 = "gfx/backdrop/Black.anm2",
}
local DoingScreenFade = false

local function fade_PostUpdate()
    if REVEL.DoingScreenFade() then
        Fade:Update()
        if Fade:IsFinished("FadeIn") then
            Fade:Play("Default", false)
        end
        if Fade:IsFinished("FadeOut") then
            DoingScreenFade = false
        end
    end
end

local function fade_PostRender()
    if not FadeAboveHud and
    REVEL.DoingScreenFade() then
        Fade:RenderLayer(0, Vector.Zero)
    end
end

local function fade_PostRenderHud()
    if FadeAboveHud and
    REVEL.DoingScreenFade() then
        Fade:RenderLayer(0, Vector.Zero)
    end
end

---Fade screen to a color (below hud)
---@param length number in frames
---@param aboveHud? boolean
---@param r? number
---@param g? number
---@param b? number
---@overload fun(length: number, aboveHud?: boolean, lightness?: number)
function REVEL.FadeOut(length, aboveHud, r, g, b)
    if not r then
        Fade.Color = Color.Default
    elseif not g or not b then
        Fade.Color = Color(1,1,1,1, r, r, r)
    else
        Fade.Color = Color(1,1,1,1, r, g, b)
    end

    Fade:Play("FadeIn", true)
    Fade.PlaybackSpeed = 30/length
    FadeAboveHud = not not aboveHud
    DoingScreenFade = true
end

---Fade from `REVEL.FadeOut`
---@param length number in frames
function REVEL.FadeIn(length)
    Fade:Play("FadeOut", true)
    Fade.PlaybackSpeed = 30/length
end

function REVEL.IsFullyFaded()
    return DoingScreenFade and Fade:GetAnimation() == "Default"
end

function REVEL.DoingScreenFade()
    return DoingScreenFade
end

--#region FadeToColor

-- Callbacks

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, fade_PostUpdate)
revel:AddCallback(ModCallbacks.MC_POST_RENDER, fade_PostRender)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_HUD_RENDER, 9999, fade_PostRenderHud)

revel:AddCallback(ModCallbacks.MC_POST_RENDER, giantbookPostRender)

end