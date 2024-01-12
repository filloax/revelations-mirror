return function()

------------------
--ACHIEVEMENT UI--
------------------
--based on piber20helper code

local AchievementDur = 60

local shouldRenderAchievement = false
local pauseEnabled = false
local achievementUI = Sprite()
local currentSprite = ""
achievementUI:Load("gfx/ui/achievement/achievements.anm2", true)
local achievementUIDelay = 0
function REVEL.AnimateAchievement(spritesheet, sound, doPause, time)
    if doPause == nil then
        doPause = true
    end

    if shouldRenderAchievement or ((doPause and not pauseEnabled) and not REVEL.RoomIsSafe()) then
        REVEL.DelayFunction(REVEL.AnimateAchievement, 12, {spritesheet, sound, doPause}, false, true)
        return
    end

    if doPause and not pauseEnabled then
        for _,proj in pairs(REVEL.roomProjectiles) do
            proj:Die()
        end
    end

    --[[
    if doPause and pauseEnabled then
        REVEL.GiantbookPause()
        REVEL.DelayFunction(REVEL.GiantbookPause, 50, nil, false, true)
        REVEL.DelayFunction(REVEL.GiantbookPause, 88, nil, false, true)
    end
    ]]

    if spritesheet then
        currentSprite = spritesheet
        achievementUI:ReplaceSpritesheet(3, spritesheet)
        achievementUI:LoadGraphics()
    else
        currentSprite = ""
    end

    achievementUI:Play("Appear", true)
    shouldRenderAchievement = true
    achievementUIDelay = time or AchievementDur

    if not sound then
        sound = SoundEffect.SOUND_CHOIR_UNLOCK
    end
    REVEL.sfx:Play(sound, 1, 0, false, 1)
end

function REVEL.GetShowingAchievement()
    return shouldRenderAchievement, currentSprite
end

local function achievementUIPostRender()
    if Isaac.GetFrameCount() % 2 == 0 then
        achievementUI:Update()
        if achievementUI:IsFinished("Appear") then
            achievementUI:Play("Idle", true)
        end
        if achievementUI:IsPlaying("Idle") then
            if achievementUIDelay > 0 then
                achievementUIDelay = achievementUIDelay - 1
            elseif achievementUIDelay == 0 then
                achievementUI:Play("Dissapear", true)
            end
        end
        if achievementUI:IsFinished("Dissapear") then
            shouldRenderAchievement = false

            for i,player in ipairs(REVEL.players) do
                player:GetData().prevAchCharge = nil
            end
        end
    end

    if shouldRenderAchievement then
        achievementUI:Render(REVEL.GetScreenCenterPosition(), Vector(0,0), Vector(0,0))
    end

    if shouldRenderAchievement then
        for i,player in ipairs(REVEL.players) do
            local data =  player:GetData()
            data.prevAchCharge = data.prevAchCharge or player:GetActiveCharge()
            if data.prevAchCharge > player:GetActiveCharge() then
                player:SetActiveCharge(data.prevAchCharge)

                if not IsAnimOn(achievementUI, "Dissapear") then
                    achievementUI:Play("Dissapear", true)
                end
            end

            if (Input.IsActionTriggered(ButtonAction.ACTION_MENUCONFIRM, player.ControllerIndex) or
                    Input.IsActionTriggered(ButtonAction.ACTION_MENUBACK, player.ControllerIndex)) and
                    not IsAnimOn(achievementUI, "Dissapear") and not achievementUI:IsPlaying("Appear") then
                achievementUI:Play("Dissapear", true)
            end
        end
    end
end

local function achievementUIPreUseItem()
    if shouldRenderAchievement then
        return true
    end
end

local function achievementUITakeDamage(_, e)
    if e.Type == 1 and shouldRenderAchievement then
        return false
    end
end

revel:AddCallback(ModCallbacks.MC_POST_RENDER, achievementUIPostRender)
revel:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, achievementUIPreUseItem)
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, achievementUITakeDamage)

end