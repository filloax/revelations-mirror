local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

------------------------------
-- UNLOCKS AND LOCKED ITEMS --
------------------------------

revel:AddCallback(ModCallbacks.MC_EXECUTE_CMD, function(_, cmd, params)
    if cmd == "revunlock" then
        params = tostring(params)
        if params == "list" or params == "print" then
            print("Listing all unlockables...")
            for name, unlockable in pairs(REVEL.UNLOCKABLES) do
                if name then
                    if revel.IsAchievementUnlocked(name) then
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
                    if not revel.IsAchievementUnlocked(name) then
                        revel.UnlockAchievement(name, true)
                        print(" Unlocked \"" .. name ..  "\"")
                    else
                        print(" \"" .. name ..  "\" is already unlocked")
                    end
                end
            end
        elseif REVEL.UNLOCKABLES[params] then
            if not revel.IsAchievementUnlocked(params) then
                revel.UnlockAchievement(params, true)
                print("Unlocked \"" .. params ..  "\"")
            else
                print("\"" .. params ..  "\" is already unlocked")
            end
        else
            print("Couldnt find valid unlockable matching \"" .. params ..  "\"")
        end
    elseif cmd == "revlock" then
        params = tostring(params)
        if params == "list" or params == "print" then
            print("Listing all unlockables...")
            for name, unlockable in pairs(REVEL.UNLOCKABLES) do
                if name then
                    if revel.IsAchievementUnlocked(name) then
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
                    if revel.IsAchievementUnlocked(name) then
                        revel.LockAchievement(name)
                        print(" Locked \"" .. name ..  "\"")
                    else
                        print(" \"" .. name ..  "\" is already locked")
                    end
                end
            end
        elseif REVEL.UNLOCKABLES[params] then
            if revel.IsAchievementUnlocked(params) then
                revel.LockAchievement(params)
                print("Locked \"" .. params ..  "\"")
            else
                print("\"" .. params ..  "\" is already locked")
            end
        else
            print("Couldnt find valid unlockable matching \"" .. params ..  "\"")
        end
    end
end)

function revel.IsAchievementUnlocked(name)
    return revel.data.unlockValues[name] == true
end

function revel.UnlockAchievement(name, hidden, sound)
    revel.data.unlockValues[name] = true
    if not hidden then
    -- revel.PlayUnlockAnimation(REVEL.UNLOCKABLES[name].img)
        REVEL.AnimateAchievement("gfx/ui/achievement/"..REVEL.UNLOCKABLES[name].img, sound)
    end
    REVEL.DebugToString("Revelations: Unlocked "..name.."!")
end

function revel.LockAchievement(name)
    revel.data.unlockValues[name] = false
end

revel.itemRerollConditions = {}

function REVEL.AddItemRerollCondition(item, func)
    if not revel.itemRerollConditions[item] then
    revel.itemRerollConditions[item] = {func}
    else
    table.insert(revel.itemRerollConditions[item], func)
    end
end

function REVEL.ShouldRerollUnlock(itemId, name)
    if not revel.IsAchievementUnlocked(name) then return true end

    return REVEL.some(revel.itemRerollConditions, function(func)
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
    and not pickup:GetData().DisableReroll
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
        if a.item and not revel.IsAchievementUnlocked(name) then
            if a.isTrinket then
                REVEL.pool:RemoveTrinket(a.item)
            else
                REVEL.pool:RemoveCollectible(a.item)
            end
        end
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.PICKUP_UPDATE_INIT, 1, rerollLockedItemsPickupInit, PickupVariant.PICKUP_COLLECTIBLE)
StageAPI.AddCallback("Revelations", RevCallbacks.PICKUP_UPDATE_INIT, 1, rerollLockedItemsPickupInit, PickupVariant.PICKUP_TRINKET)
revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, disableLockedItems)

----------------------------------
-- UNLOCKED TRINKETS/CARDS MAPS --
----------------------------------

function REVEL.IsTrinketUnlocked(trinketId)
    return not not revel.data.run.unlockedTrinkets[tostring(trinketId)]
end

function REVEL.IsCardUnlocked(cardId)
    return not not revel.data.run.unlockedCards[tostring(cardId)]
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
        revel.data.run.unlockedTrinkets[tostring(itempool:GetTrinket())] = true
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
        revel.data.run.unlockedCards[tostring(cardId)] = true
    end
end

revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isContinued)
    if not isContinued then
        REVEL.GetAllUnlockedTrinkets()
        REVEL.GetAllUnlockedCards()
    end
end)


end

REVEL.PcallWorkaroundBreakFunction()