local RevCallbacks = require "scripts.revelations.common.enums.RevCallbacks"
return function()

--#region Unlocks

------------------------------
-- UNLOCKS AND LOCKED ITEMS --
------------------------------

REVEL.Commands.revunlock = {
    Execute = function (params)
        params = tostring(params)
        if params == "list" or params == "print" then
            print("Listing all unlockables...")
            for name, unlockable in pairs(REVEL.UNLOCKABLES) do
                if name then
                    if REVEL.IsAchievementUnlocked(name) then
                        print(" \"" .. name ..  "\" (unlocked)")
                    else
                        print(" \"" .. name ..  "\" (locked)")
                    end
                end
            end
        elseif params == "*" or params == "all" then
            print("Unlocking all unlockables...")
            for name, unlockable in pairs(REVEL.UNLOCKABLES) do
                if name then
                    if not REVEL.IsAchievementUnlocked(name) then
                        REVEL.UnlockAchievement(name, true)
                        print(" Unlocked \"" .. name ..  "\"")
                    else
                        print(" \"" .. name ..  "\" is already unlocked")
                    end
                end
            end
        elseif REVEL.UNLOCKABLES[params] then
            if not REVEL.IsAchievementUnlocked(params) then
                REVEL.UnlockAchievement(params, true)
                print("Unlocked \"" .. params ..  "\"")
            else
                print("\"" .. params ..  "\" is already unlocked")
            end
        else
            print("Couldnt find valid unlockable matching \"" .. params ..  "\"")
        end
    end,
    Autocomplete = function (params)
        local out = {"list", "print", "*", "all"}
        REVEL.extend(out, table.unpack(REVEL.keys(REVEL.UNLOCKABLES)))
        return out
    end,
    Desc = "Unlock Rev unlockables",
    Usage = "unlockName | <list|print|*|all>",
    Help = "list | print: Prints all unlockables\n* | all: Unlocks all unlockables\nunlockName: Unlocks the unlockable <unlockName>",
    File = "unlocks.lua",
}
REVEL.Commands.revlock = {
    Execute = function (params)
        params = tostring(params)
        if params == "list" or params == "print" then
            print("Listing all unlockables...")
            for name, unlockable in pairs(REVEL.UNLOCKABLES) do
                if name then
                    if REVEL.IsAchievementUnlocked(name) then
                        print(" \"" .. name ..  "\" (unlocked)")
                    else
                        print(" \"" .. name ..  "\" (locked)")
                    end
                end
            end
        elseif params == "*" or params == "all" then
            print("Locking all unlockables...")
            for name, unlockable in pairs(REVEL.UNLOCKABLES) do
                if name then
                    if REVEL.IsAchievementUnlocked(name) then
                        REVEL.LockAchievement(name)
                        print(" Locked \"" .. name ..  "\"")
                    else
                        print(" \"" .. name ..  "\" is already locked")
                    end
                end
            end
        elseif REVEL.UNLOCKABLES[params] then
            if REVEL.IsAchievementUnlocked(params) then
                REVEL.LockAchievement(params)
                print("Locked \"" .. params ..  "\"")
            else
                print("\"" .. params ..  "\" is already locked")
            end
        else
            print("Couldnt find valid unlockable matching \"" .. params ..  "\"")
        end
    end,
    Autocomplete = function (params)
        local out = {"list", "print", "*", "all"}
        REVEL.extend(out, table.unpack(REVEL.keys(REVEL.UNLOCKABLES)))
        return out
    end,
    Desc = "Lock Rev unlockables",
    Usage = "unlockName | <list|print|*|all>",
    Help = "list | print: Prints all unlockables\n* | all: Locks all unlockables\nunlockName: Locks the unlockable <unlockName>",
    File = "unlocks.lua",
}

function REVEL.IsAchievementUnlocked(name)
    return revel.data.unlockValues[name] == true
end

function REVEL.UnlockAchievement(name, hidden, sound)
    revel.data.unlockValues[name] = true
    if not hidden then
        REVEL.AnimateAchievement("gfx/ui/achievement/"..REVEL.UNLOCKABLES[name].img, sound)
    end
    REVEL.DebugToString("Revelations: Unlocked "..name.."!")
end

function REVEL.LockAchievement(name)
    revel.data.unlockValues[name] = false
end

local itemRerollConditions = {}

function REVEL.AddItemRerollCondition(item, func)
    if not itemRerollConditions[item] then
        itemRerollConditions[item] = {func}
    else
        table.insert(itemRerollConditions[item], func)
    end
end

function REVEL.ShouldRerollUnlock(itemId, name)
    if not REVEL.IsAchievementUnlocked(name) then return true end

    return REVEL.some(itemRerollConditions, function(func)
        for i,p in ipairs(REVEL.players) do
            if func(p) then return true end
        end
    end)
end

function REVEL.ShouldRerollItem(item)
    return REVEL.some(REVEL.UNLOCKABLES, function(a, name)
        if a.item ~= item then return false end

        return REVEL.ShouldRerollUnlock(item, name)
    end)
end

local function rerollLockedItemsPickupInit(pickup)
    local itemID = pickup.SubType
    local unlockEntry = REVEL.UNLOCKABLES_BY_ID[itemID]

    if unlockEntry
    and REVEL.ShouldRerollItem(itemID)
    and not REVEL.GetData(pickup).DisableReroll
    and (
        (unlockEntry.isTrinket and pickup.Variant == PickupVariant.PICKUP_TRINKET)
        or (not unlockEntry.isTrinket and pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE)
    ) then
        if REVEL.DEBUG then
            if pickup.Variant == PickupVariant.PICKUP_TRINKET then
                REVEL.DebugToString(("[REVEL] Trinket '%s' locked, rerolling"):format(REVEL.GetTrinketNameFromID(itemID)))
            else
                REVEL.DebugToString(("[REVEL] Item '%s' locked, rerolling"):format(REVEL.GetCollectibleNameFromID(itemID)))
            end
        end
        pickup:Morph(pickup.Type, pickup.Variant, 0, true)
    end
end

local function disableLockedItems()
    for name,a in pairs(REVEL.UNLOCKABLES) do
        if a.item and not REVEL.IsAchievementUnlocked(name) then
            if a.isTrinket then
                REVEL.pool:RemoveTrinket(a.item)
            else
                REVEL.pool:RemoveCollectible(a.item)
            end
        end
    end
end

----------------------------------
-- UNLOCKED TRINKETS/CARDS MAPS --
----------------------------------

function REVEL.IsTrinketUnlocked(trinketId)
    return not not revel.data.run.unlockedTrinkets[trinketId]
end

function REVEL.IsCardUnlocked(cardId)
    return not not revel.data.run.unlockedCards[cardId]
end

function REVEL.GetMaxTrinketId()
    local itemConfig = Isaac.GetItemConfig()
    local id = TrinketType.NUM_TRINKETS-1
    local step = 16
    while step > 0 do
        if itemConfig:GetTrinket(id+step) ~= nil then
            id = id + step
        else
            step = step // 2
        end
    end

    return id
end

function REVEL.GetAllUnlockedTrinkets()
    revel.data.run.unlockedTrinkets = {}
    
    local itempool = REVEL.game:GetItemPool()
    local maxTrinketId = REVEL.GetMaxTrinketId()
    
    -- there are very few trinkets that can be encountered multiple times, so to combat this it will loop more than otherwise needed
    for i=0, maxTrinketId*2 do
        REVEL.TrinketHistorySkipTrinket = true
        revel.data.run.unlockedTrinkets[itempool:GetTrinket()] = true
    end
    
    itempool:ResetTrinkets()
end

function REVEL.GetMaxCardId()
    local itemConfig = Isaac.GetItemConfig()
    local id = Card.NUM_CARDS-1
    local step = 16
    while step > 0 do
        if itemConfig:GetCard(id+step) ~= nil then
            id = id + step
        else
            step = step // 2
        end
    end

    return id
end

function REVEL.GetAllUnlockedCards()
    revel.data.run.unlockedCards = {}
    
    local itempool = REVEL.game:GetItemPool()
    local maxCardId = REVEL.GetMaxCardId()
    
    local seeds = REVEL.game:GetSeeds()
    
    -- not failure proof as it's possible to not have a card show up with itempool:GetCard(), but good enough for it's purpose
    for i=0, maxCardId*5 do
        local cardId = itempool:GetCard(seeds:GetNextSeed(), true, true, false)
        revel.data.run.unlockedCards[cardId] = true
    end
end

revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isContinued)
    if not isContinued then
        REVEL.GetAllUnlockedTrinkets()
        REVEL.GetAllUnlockedCards()
    end
end)

--#endregion

--#region AchievementUI
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
                REVEL.GetData(player).prevAchCharge = nil
            end
        end
    end

    if shouldRenderAchievement then
        achievementUI:Render(REVEL.GetScreenCenterPosition(), Vector(0,0), Vector(0,0))
    end

    if shouldRenderAchievement then
        for i,player in ipairs(REVEL.players) do
            local data =  REVEL.GetData(player)
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

--#endregion

--#region Vanilla Advancements
-- Some workarounds for not being able to access achievement data
-- dumb way being to just consider them unlocked if they have been
-- found vanilla at least once

-- REP FLOOR UNLOCK DETECTION

local StageToData = {
    [LevelStage.STAGE1_1] = "unlockedDross",
    [LevelStage.STAGE1_2] = "unlockedDross",
    [LevelStage.STAGE2_1] = "unlockedAshpit",
    [LevelStage.STAGE2_2] = "unlockedAshpit",
    [LevelStage.STAGE3_1] = "unlockedGehenna",
    [LevelStage.STAGE3_2] = "unlockedGehenna",
}

function REVEL.HasUnlockedRepentanceAlt(levelStage)
    if StageToData[levelStage] then
        return revel.data[StageToData[levelStage]]
    end
    error(("HasUnlockedRepentanceAlt: no rep alt for stage '%d'"):format(levelStage), 2)
end


local function repAltDetectPostNewLevel()
    local levelStage, stageType = REVEL.level:GetStage(), REVEL.level:GetStageType()

    if stageType == StageType.STAGETYPE_REPENTANCE_B
    and StageToData[levelStage]
    and not revel.data[StageToData[levelStage]] then
        revel.data[StageToData[levelStage]] = true
    end
end


-- HORSE PILL UNLOCK DETECTION

function REVEL.HasUnlockedHorsePills()
    return revel.data.unlockedHorsePills
end

local function horsepilldetectPostPickupInit(_, pickup)
    if not revel.data.unlockedHorsePills
    and pickup.SubType > PillColor.PILL_GIANT_FLAG then
        revel.data.unlockedHorsePills = true
    end
end
--#endregion

--#region Character Unlocks

local CharacterUnlocks = {}

function REVEL.AddCharacterUnlock(playerType, unlock, stage, stageIfXL, stageType, isGreed, isPlayerCheck)
    if not CharacterUnlocks[playerType] then
        CharacterUnlocks[playerType] = {}
    end

    local unlock = {
        Unlock = unlock,
        Stage = stage,
        StageType = stageType,
        StageIfXL = stageIfXL,
        IsGreed = isGreed,
        IsPlayerCheck = isPlayerCheck
    }

    CharacterUnlocks[playerType][#CharacterUnlocks[playerType] + 1] = unlock

    return unlock
end

local function characterUnlockPlayerUpdate(_, player)
    if REVEL.room:IsClear() and REVEL.room:GetType() == RoomType.ROOM_BOSS then
        local ptype = player:GetPlayerType()
        local unlocks = CharacterUnlocks[ptype]
        if not unlocks then
            for _, unlockSet in pairs(CharacterUnlocks) do
                if unlockSet.IsPlayerCheck and unlockSet.IsPlayerCheck(player) then
                    unlocks = unlockSet
                    break
                end
            end
        end

        if unlocks then
            local stage, stageType = REVEL.level:GetStage(), REVEL.level:GetStageType()
            for _, unlock in ipairs(unlocks) do
                if not REVEL.IsAchievementUnlocked(unlock.Unlock)
                and (not unlock.IsGreed or REVEL.game:IsGreedMode())
                and (
                    stage == unlock.Stage 
                    or (
                        unlock.StageIfXL 
                        and HasBit(REVEL.level:GetCurses(), LevelCurse.CURSE_OF_LABYRINTH) 
                        and stage == unlock.StageIfXL 
                        and REVEL.room:IsCurrentRoomLastBoss()
                    )
                ) 
                and (not unlock.StageType or stageType == unlock.StageType)
                then
                    REVEL.DebugLog(unlock)
                    REVEL.UnlockAchievement(unlock.Unlock)
                end
            end
        end
    end
end

--#endregion

revel:AddCallback(ModCallbacks.MC_POST_RENDER, achievementUIPostRender)
revel:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, achievementUIPreUseItem)
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, achievementUITakeDamage)

revel:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, horsepilldetectPostPickupInit, PickupVariant.PICKUP_PILL)
revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, repAltDetectPostNewLevel)
revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, characterUnlockPlayerUpdate)

StageAPI.AddCallback("Revelations", RevCallbacks.PICKUP_UPDATE_INIT, 1, rerollLockedItemsPickupInit, PickupVariant.PICKUP_COLLECTIBLE)
StageAPI.AddCallback("Revelations", RevCallbacks.PICKUP_UPDATE_INIT, 1, rerollLockedItemsPickupInit, PickupVariant.PICKUP_TRINKET)
revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, disableLockedItems)

end