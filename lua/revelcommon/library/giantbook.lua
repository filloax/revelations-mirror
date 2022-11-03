REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
----------------
--GIANTBOOK UI--
----------------
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

revel:AddCallback(ModCallbacks.MC_POST_RENDER, giantbookPostRender)

    
end

REVEL.PcallWorkaroundBreakFunction()