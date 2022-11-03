local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

------------------------------
-- DYNAMIC REV ITEM WEIGHTS --
------------------------------


--[[
items have 5 times their "default" weight to start off with, with an 80% chance to be rerolled
this chance gets lowered based on certain circumstances:
20% less chance to get rerolled if this item has not been picked up at least once (%40 chance if this is an unlockable)
7.5% less chance to get rerolled if this item has not been won with at least once

this gives the player the chance to experience rev items without needing to get very lucky, more so with items they just unlocked
]]

local Cfg = {
    ConfigWeight = 5,
    BaseTargetWeight = 1,
    ChanceIncrease = {
        NeverPickedUp = {
            Normal = 0.2,
            Unlockable = 0.4,
        },
        NeverWonWith = {
            Normal = 0.05,
            Unlockable = 0.05,
        },
    }
}

local function dynamicWeightsOnItemPickup(player, playerID, itemID, isD4Effect)
    if REVEL.REGISTERED_ITEM_IDS[itemID] then
        local item = REVEL.REGISTERED_ITEM_IDS[itemID]
        revel.data.pickedUpItems[item.name] = true
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ITEM_PICKUP, 1, dynamicWeightsOnItemPickup)

revel:AddCallback(ModCallbacks.MC_POST_GAME_END, function(_, gameOver)
    if not gameOver then
        for name, item in pairs(REVEL.REGISTERED_ITEMS) do
            if not revel.data.wonWithItems[name] then
                for _, player in ipairs(REVEL.players) do
                    if player:HasCollectible(item.id) then
                        revel.data.wonWithItems[name] = true
                    end
                end
            end
        end
    end
end)

function REVEL.WasItemPickedUp(name)
    return revel.data.pickedUpItems[name] == true
end
function REVEL.WasItemWonWith(name)
    return revel.data.wonWithItems[name] == true
end

local C_INT_MAX = 2147483647

local recursionLevel = 0
local maxRecursion = 0
local forceAtGameStart = false

-- Call before using pool:GetCollectible() at game start 
-- to force the check to run even if it normally wouldn't in the first frame. 
-- Normal behavior has this only check for locked items at game start
function REVEL.ForceItemRerollCheck()
    forceAtGameStart = true
end

local function dynamicWeightsPostGetCollectible(_, itemID, pool, decrease, seed)
    local itemData = nil
    local itemName = nil
    for name, item in pairs(REVEL.REGISTERED_ITEMS) do
        if item.id == itemID then
            itemName = name
            itemData = item
        end
    end

    local unlockableItemData = nil
    local unlockableName = nil
    for name, unlockable in pairs(REVEL.UNLOCKABLES) do
        if unlockable.item and itemID == unlockable.item then
            unlockableName = name
            unlockableItemData = unlockable
            break
        end
    end

    if itemName or unlockableName then
        -- Various mod do item pool checks at game start, so avoid messing with those
        -- as it might cause infinite recursions or longer than needed
        local onlyCheckLocked = not (REVEL.game:GetFrameCount() > 1 or forceAtGameStart)
        forceAtGameStart = false

        local doReroll = false
        local chanceToReroll = (Cfg.ConfigWeight - Cfg.BaseTargetWeight) / Cfg.ConfigWeight
        local pickedUp, wonWith = REVEL.WasItemPickedUp(itemName), REVEL.WasItemWonWith(itemName)

        if not onlyCheckLocked then
            if revel.data.dynamicItemWeights ~= 0 then
                if not pickedUp then
                    if unlockableItemData and revel.IsAchievementUnlocked(unlockableName) then
                        chanceToReroll = chanceToReroll - Cfg.ChanceIncrease.NeverPickedUp.Unlockable
                    else
                        chanceToReroll = chanceToReroll - Cfg.ChanceIncrease.NeverPickedUp.Normal
                    end
                end

                if not wonWith then
                    if unlockableItemData and revel.IsAchievementUnlocked(unlockableName) then
                        chanceToReroll = chanceToReroll - Cfg.ChanceIncrease.NeverWonWith.Unlockable
                    else
                        chanceToReroll = chanceToReroll - Cfg.ChanceIncrease.NeverWonWith.Normal
                    end
                end
            end
        else
            chanceToReroll = 0
        end

        if unlockableItemData and not revel.IsAchievementUnlocked(unlockableName) then
            chanceToReroll = 1
            REVEL.pool:AddRoomBlacklist(itemID) --prevent from being rolled again, to prevent infinite recursion
        end

        if recursionLevel == 0 and REVEL.game:GetFrameCount() > 1 then
            REVEL.DebugStringMinor(
                ("Choosing collectible '%s', chance to reroll: %2.2f%% (picked up: %s, won with: %s) seed %d")
                :format(REVEL.GetCollectibleNameFromID(itemID), chanceToReroll * 100, pickedUp, wonWith, seed)
            )
        end

        if chanceToReroll >= 1 then
            doReroll = true
        elseif chanceToReroll > 0 and chanceToReroll < 1 then
            local rng = REVEL.RNG()
            rng:SetSeed(seed, 35)
            local rand = rng:RandomFloat()

            if rand <= chanceToReroll then
                doReroll = true
            end
        end

        if doReroll then
            if recursionLevel == 0 then
                REVEL.DebugStringMinor("Rerolling...")
            end
        
            recursionLevel = recursionLevel + 1
            maxRecursion = recursionLevel
            local newItem
            if recursionLevel == 1 then
                -- Handle possible stack overflows from other mod interactions to prevent
                -- messing up recursion level resetting
                local success, out = pcall(REVEL.pool.GetCollectible, REVEL.pool, pool, false, (seed * 50 + 195) % C_INT_MAX)
                if success then
                    newItem = out
                else
                    REVEL.DebugLog(out)
                    REVEL.DebugLog("[REVEL] Got stack overflow in dynamic item weights, defaulting to original item", itemID)
                    newItem = itemID
                end
            else
                newItem = REVEL.pool:GetCollectible(pool, false, (seed * 50 + 195) % C_INT_MAX)
            end
            recursionLevel = recursionLevel - 1
            if recursionLevel == 0 then
                REVEL.DebugStringMinor(("Did %d recursions"):format(maxRecursion))
                maxRecursion = 0
            end

            return newItem
        end
    end
end
revel:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE, dynamicWeightsPostGetCollectible)

-----------------------------------
--- FIRST ITEM FOUND TO MOD ITEM --
-----------------------------------

local firstRunSwitchList = {
    REVEL.ITEM.MINT_GUM,
    REVEL.ITEM.FECAL_FREAK,
    REVEL.ITEM.LIL_BELIAL,
    REVEL.ITEM.DYNAMO,
    REVEL.ITEM.BURNBUSH,
    REVEL.ITEM.PATIENCE,
    REVEL.ITEM.CABBAGE_PATCH,
    REVEL.ITEM.SMBLADE,
    REVEL.ITEM.ROBOT,
    REVEL.ITEM.CHUM,
    REVEL.ITEM.WAKA_WAKA,
}

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    if REVEL.room:GetType() == RoomType.ROOM_TREASURE and not revel.data.firstRunSwitch and REVEL.room:IsFirstVisit() then 
        for i, e in ipairs(REVEL.roomPickups) do
            if e.Variant == 100 then
                revel.data.firstRunSwitch = true
                e:Morph(e.Type, 100, firstRunSwitchList[math.random(#firstRunSwitchList)].id, true)
                return
            end
        end
    end
end)

end
REVEL.PcallWorkaroundBreakFunction()