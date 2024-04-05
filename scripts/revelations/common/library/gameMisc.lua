local RevCallbacks = require "scripts.revelations.common.enums.RevCallbacks"

return function()

function REVEL.NotBossOrNightmare()
    local currentMusic = REVEL.music:GetCurrentMusicID()
    return not StageAPI.IsHUDAnimationPlaying() 
		and currentMusic ~= Music.MUSIC_JINGLE_BOSS 
		and currentMusic ~= Music.MUSIC_JINGLE_NIGHTMARE
end

if REPENTOGON then

function REVEL.IsPauseMenuOpen()
	return REVEL.game:IsPauseMenuOpen() --added by Repentogon
end

else

function REVEL.IsPauseMenuOpen()
	return StageAPI.IsPauseMenuOpen()
end

end

-- Play StageAPI boss anim to check for menu confirm but not pause

local CurrentlyDoingNoPauseBossAnim = false
local OnSkip

function REVEL.PlayBossAnimationNoPause(boss, onSkip)
	StageAPI.PlayBossAnimation(boss, true)
	CurrentlyDoingNoPauseBossAnim = true
	OnSkip = onSkip
	for _, player in ipairs(REVEL.players) do
		REVEL.LockPlayerControls(player, "PlayBossAnimationNoPause")
	end
end

local function bossAnimNoPause_PostRender()
	if CurrentlyDoingNoPauseBossAnim then
		if not StageAPI.PlayingBossSprite then
			CurrentlyDoingNoPauseBossAnim = false

			for _, player in ipairs(REVEL.players) do
				REVEL.UnlockPlayerControls(player, "PlayBossAnimationNoPause")
			end

			return
		end

		local menuConfirmTriggered
        for _, player in ipairs(REVEL.players) do
            if Input.IsActionTriggered(ButtonAction.ACTION_MENUCONFIRM, player.ControllerIndex) then
                menuConfirmTriggered = true
                break
            end
        end

		if menuConfirmTriggered then
			StageAPI.UnskippableBossAnim = nil
			if OnSkip then 
				OnSkip()
			end
		end
	end
end

-- Champion chances

local Chances = {
	Normal = {
		Base = 5,
		ChampionBelt = 20,
	},
	Hard = {
		Base = 20,
		ChampionBelt = 35,
	},
	Void = {
		Base = 70,
		ChampionBelt = 70,
	}
}

function REVEL.GetChampionChance(boss)
	local difficulty = REVEL.game.Difficulty
	local chancesTbl = Chances.Normal
	if difficulty == Difficulty.DIFFICULTY_HARD 
	or difficulty == Difficulty.DIFFICULTY_GREEDIER then
		chancesTbl = Chances.Hard
	end
	if REVEL.level:GetStage() == LevelStage.STAGE7 then
		chancesTbl = Chances.Void
	end

	local hasBelt = REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_CHAMPION_BELT)
	local hasPurpleHeart = REVEL.OnePlayerHasTrinket(TrinketType.TRINKET_PURPLE_HEART)

	local chance100 = chancesTbl.Base
	if hasBelt and not boss then
		chance100 = chancesTbl.ChampionBelt
	end

	if hasPurpleHeart then
		chance100 = chance100 * 2
	end

	return REVEL.Saturate(chance100 / 100)
end

local LoadedRun = false
local RanFirstUpdate = false

-- game:GetFrameCount isn't reliable as it keeps increasing
-- even after the run is reloaded, this works on save loading too
function REVEL.WasRunLoaded()
	return LoadedRun
end

-- Needed for some features
function REVEL.RanFirstUpdate()
	return RanFirstUpdate
end

local function runLoaded_PostUpdate()
	RanFirstUpdate = true
	revel:RemoveCallback(ModCallbacks.MC_POST_UPDATE, runLoaded_PostUpdate)
end

local function runLoaded_PostPlayerInit()
	LoadedRun = true
	revel:AddCallback(ModCallbacks.MC_POST_UPDATE, runLoaded_PostUpdate)
end

local function runLoaded_PreGameExit()
	LoadedRun = false
	RanFirstUpdate = false
end

local function runLoaded_PostIngameReload()
	LoadedRun = true
	RanFirstUpdate = true
end

-- Is Map Large
-- Source: MinimapAPI

-- If MinimapAPI is present, just use its function
-- delay checking to game_start so all mods are loaded

local IsMapLarge = false
local MapHeldFrames = 0

function REVEL.IsMapLarge()
	if MinimapAPI then
		return MinimapAPI:IsLarge()
	else
		return IsMapLarge or MapHeldFrames > 16
	end
end

local function isMapLarge_PostRender()
	if MinimapAPI then
		revel:RemoveCallback(ModCallbacks.MC_POST_RENDER, isMapLarge_PostRender)
		return
	end

	local mapPressed = false
	for _, player in ipairs(REVEL.players) do
		mapPressed = mapPressed or Input.IsActionPressed(ButtonAction.ACTION_MAP, player.ControllerIndex)
	end
	if mapPressed then
		MapHeldFrames = MapHeldFrames + 1
	elseif MapHeldFrames > 0 then
		if MapHeldFrames <= 16 then
			IsMapLarge = not IsMapLarge
		end
		MapHeldFrames = 0
	end
end

-- Estimate fps

local LastFrame = -1
local CurrentAverage = 30
local LastTime = -1
local FirstFrame = -1

local SMOOTHING = 0.25

---Average of fps (not exact)
---@return number
function REVEL.GetFpsEstimate()
	return CurrentAverage
end

local function fps_postRender()
	local frames = REVEL.game:GetFrameCount()
	if frames ~= LastFrame then
		if LastTime >= 0 and FirstFrame >= 0 then
			local timeSinceLast = Isaac.GetTime() - LastTime
			local framesSinceLast = frames - LastFrame

			local instantFps = framesSinceLast / (timeSinceLast / 1000)

			-- avg = prev avg * last total / new total + new value / new total
			CurrentAverage = instantFps * SMOOTHING + CurrentAverage * (1 - SMOOTHING)
		end
		if FirstFrame < 0 then
			FirstFrame = frames
		end
		LastFrame = frames
		LastTime = Isaac.GetTime()
	elseif REVEL.game:IsPaused() then
		LastTime = Isaac.GetTime()
	end
end

function REVEL.IsRenderPassNormal()
    local renderMode = REVEL.room:GetRenderMode()

    return renderMode == RenderMode.RENDER_NORMAL 
        or renderMode == RenderMode.RENDER_WATER_ABOVE
        or renderMode == RenderMode.RENDER_NULL -- MC_POST_RENDER
end

function REVEL.IsRenderPassReflection()
    local renderMode = REVEL.room:GetRenderMode()
    return renderMode == RenderMode.RENDER_WATER_REFLECT
end

-- Normal in normal rooms, 
-- below water in water rooms
function REVEL.IsRenderPassFloor(fakeFloor)
    local renderMode = REVEL.room:GetRenderMode()

    if fakeFloor then
        return renderMode == RenderMode.RENDER_NORMAL 
            or renderMode == RenderMode.RENDER_WATER_REFLECT
    else
        return renderMode == RenderMode.RENDER_NORMAL 
            or renderMode == RenderMode.RENDER_WATER_REFRACT
    end
end


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

revel:AddCallback(ModCallbacks.MC_POST_RENDER, fps_postRender)
revel:AddCallback(ModCallbacks.MC_POST_RENDER, bossAnimNoPause_PostRender)
revel:AddCallback(ModCallbacks.MC_POST_RENDER, isMapLarge_PostRender)
revel:AddPriorityCallback(ModCallbacks.MC_POST_PLAYER_INIT, CallbackPriority.IMPORTANT, runLoaded_PostPlayerInit)
revel:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, runLoaded_PreGameExit)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 5, runLoaded_PostIngameReload)

end