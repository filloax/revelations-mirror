local RevCallbacks = require "lua.revelcommon.enums.RevCallbacks"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

function REVEL.NotBossOrNightmare()
    local currentMusic = REVEL.music:GetCurrentMusicID()
    return not StageAPI.IsHUDAnimationPlaying() 
		and currentMusic ~= Music.MUSIC_JINGLE_BOSS 
		and currentMusic ~= Music.MUSIC_JINGLE_NIGHTMARE
end

-- Was originally own system, added to stageapi later
function REVEL.IsPauseMenuOpen()
    return StageAPI.IsPauseMenuOpen()
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

local function bossAnimNoPause_PreUseItem()
	if CurrentlyDoingNoPauseBossAnim then
		return true
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

-- TODO: check here as it's probably false when it shouldn't
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

revel:AddCallback(ModCallbacks.MC_POST_RENDER, fps_postRender)
revel:AddCallback(ModCallbacks.MC_POST_RENDER, bossAnimNoPause_PostRender)
revel:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, bossAnimNoPause_PreUseItem)
revel:AddCallback(ModCallbacks.MC_POST_RENDER, isMapLarge_PostRender)
REVEL.EarlyCallbacks.runLoaded_PostPlayerInit = runLoaded_PostPlayerInit
revel:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, runLoaded_PreGameExit)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 5, runLoaded_PostIngameReload)

end

REVEL.PcallWorkaroundBreakFunction()