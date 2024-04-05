local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local shared            = require("scripts.revelations.characters.dante.shared")

return function()

-- Handle separate items, health, etcetera

-- Some items like dead cat and halo of flies add multiple copies of it
-- TODO: check if it happens in rep
local function AddSingleCollectible(player, id, charge, addCollectibles)
    local startNum = player:GetCollectibleNum(id, true)
    player:AddCollectible(id, charge or 0, addCollectibles or false)
    local newNum = player:GetCollectibleNum(id, true)
    if newNum > startNum + 1 then
        for i = 1, newNum - (startNum + 1) do
            player:RemoveCollectible(id, true)
        end
    end
end

---@enum RevDante.HeartTypes
local HeartTypes = {
    SOUL = 1,
    BLACK = 2,
    BONE = 3,
}

---@class RevDante.Health
---@field types RevDante.HeartTypes[]
---@field maxHearts integer
---@field hearts integer
---@field soulHearts integer
---@field boneHearts integer
---@field goldenHearts integer
---@field eternalHearts integer
---@field rottenHearts integer

---@return RevDante.Health
function REVEL.Dante.GetDefaultHealth()
    return {
        types = {},
        maxHearts = 0,
        hearts = 0,
        soulHearts = 0,
        boneHearts = 0,
        goldenHearts = 0,
        eternalHearts = 0,
        rottenHearts = 0,
    }
end

---@param player EntityPlayer
---@return RevDante.Health
function REVEL.Dante.StoreHealth(player)
    local heartTypes = {}
    local maxHearts, hearts = player:GetMaxHearts(), player:GetHearts()
    local soulHearts = player:GetSoulHearts()
    local boneHearts = player:GetBoneHearts()
    local goldenHearts = player:GetGoldenHearts()
    local eternalHearts = player:GetEternalHearts()
    local rottenHearts = player:GetRottenHearts()
    hearts = hearts - rottenHearts * 2 -- rotten hearts are counted among hearts

    -- This is the number of individual hearts shown in the HUD, minus heart containers
    local extraHearts = math.ceil(soulHearts / 2) + boneHearts

    -- Since bone hearts can be inserted anywhere between soul hearts, we need a separate counter to track which soul heart we're currently at
    local currentSoulHeart = 0

    for i=0, extraHearts-1 do
        if player:IsBoneHeart(i) then
            heartTypes[#heartTypes + 1] = HeartTypes.BONE
        else
            local isBlackHeart = player:IsBlackHeart(currentSoulHeart + 1) -- +1 because only the second half of a black heart is considered black
            if isBlackHeart then
                heartTypes[#heartTypes + 1] = HeartTypes.BLACK
            else
                heartTypes[#heartTypes + 1] = HeartTypes.SOUL
            end

            -- Move to the next heart
            currentSoulHeart = currentSoulHeart + 2
        end
    end

    return {
        types = heartTypes,
        maxHearts = maxHearts,
        hearts = hearts,
        soulHearts = soulHearts,
        boneHearts = boneHearts,
        goldenHearts = goldenHearts,
        eternalHearts = eternalHearts,
        rottenHearts = rottenHearts,
    }
end

---@param hearts RevDante.Health
---@param redHeartPrioritizeFirst? boolean
---@return RevDante.Health first
---@return RevDante.Health second
function REVEL.Dante.SplitHealth(hearts, redHeartPrioritizeFirst)
    -- Before doing anything, remove hearts inside bone containers (aka above max hearts)
    -- as they have to be given to the same character that has the bone containers
    local rottenNoBone = math.floor(math.max(
        math.min(hearts.hearts + hearts.rottenHearts * 2, hearts.maxHearts) 
            - hearts.hearts, 
        0
    ) / 2)
    local heartsNoBone = math.min(hearts.hearts, hearts.maxHearts)

    local rottenInBone = hearts.rottenHearts - rottenNoBone
    local heartsInBone = hearts.hearts - heartsNoBone

    local maxHeartsDiff = (hearts.maxHearts / 2) % 2
    local heartsDiff = (heartsNoBone / 2) % 2
    local maxNum = (hearts.maxHearts / 2)
    local redHearts = (heartsNoBone / 2)

    local goldenNum = hearts.goldenHearts / 2
    local eternalNum = hearts.eternalHearts / 2
    local rottenNum = rottenNoBone / 2

    local max = {}
    local red = {}
    local golden = {}
    local eternal = {}
    local rotten = {}

    if redHeartPrioritizeFirst then
        max = {maxNum + maxHeartsDiff, maxNum - maxHeartsDiff}
        red = {redHearts + heartsDiff, redHearts - heartsDiff}
        golden = {math.ceil(goldenNum), math.floor(goldenNum)}
        eternal = {math.ceil(eternalNum), math.floor(eternalNum)}
        rotten = {math.ceil(rottenNum), math.floor(rottenNum)}
    else
        max = {maxNum - maxHeartsDiff, maxNum + maxHeartsDiff}
        red = {redHearts - heartsDiff, redHearts + heartsDiff}
        golden = {math.floor(goldenNum), math.ceil(goldenNum)}
        eternal = {math.floor(eternalNum), math.ceil(eternalNum)}
        rotten = {math.floor(rottenNum), math.ceil(rottenNum)}
    end

    local soulHearts = hearts.soulHearts + hearts.boneHearts * 2

    local types = {{}, {}}

    local halfTypes = #hearts.types / 2
    local soul = {0,0}
    local bone = {0,0}
    for i, heartType in ipairs(hearts.types) do
        local amountAdd = 2
        if heartType == HeartTypes.BONE or i * 2 > soulHearts then
            amountAdd = 1
        end

        local goesTo
        if redHeartPrioritizeFirst then
            goesTo = (i > math.ceil(halfTypes)) and 1 or 2
        else
            goesTo = (i > math.floor(halfTypes)) and 1 or 2
        end

        table.insert(types[goesTo], heartType)
        if heartType == HeartTypes.BONE then
            bone[goesTo] = bone[goesTo] + amountAdd
            if heartsInBone > 0 then
                local toAssign = math.min(heartsInBone, 2)
                red[goesTo] = red[goesTo] + toAssign
                heartsInBone = heartsInBone - toAssign
            elseif rottenInBone > 0 then
                rotten[goesTo] = rotten[goesTo] + 1
                rottenInBone = rottenInBone - 1
            end
        else
            soul[goesTo] = soul[goesTo] + amountAdd
        end
    end

    for i = 1, 2 do
        if max[i] == 0 and soul[i] + bone[i] == 0 then
            table.insert(types[i], HeartTypes.SOUL)
            soul[i] = 1
            if red[i] > 1 then
                red[i] = 1
            end

            if soul[i]> 1 then
                soul[i] = 1
            end
        end
    end

    return {
        types = types[1],
        maxHearts = max[1],
        hearts = red[1],
        soulHearts = soul[1],
        boneHearts = bone[1],
        goldenHearts = golden[1],
        eternalHearts = eternal[1],
        rottenHearts = rotten[1],
    },
    {
        types = types[2],
        maxHearts = max[2],
        hearts = red[2],
        soulHearts = soul[2],
        boneHearts = bone[2],
        goldenHearts = golden[2],
        eternalHearts = eternal[2],
        rottenHearts = rotten[2],
    }
end

function REVEL.Dante.SubtractHealth(hearts1, hearts2)
    local differentTypes = {}
    for i, heartType in ipairs(hearts1.types) do
        if not hearts2.types[i] then
            differentTypes[#differentTypes + 1] = heartType
        end
    end

    return {
        types = differentTypes,
        maxHearts = hearts1.maxHearts - hearts2.maxHearts,
        hearts = hearts1.hearts - hearts2.hearts,
        soulHearts = hearts1.soulHearts - hearts2.soulHearts,
        boneHearts = hearts1.boneHearts - hearts2.boneHearts,
        goldenHearts = hearts1.goldenHearts - hearts2.goldenHearts,
        eternalHearts = hearts1.eternalHearts - hearts2.eternalHearts,
        rottenHearts = hearts1.rottenHearts - hearts2.rottenHearts,
    }
end

function REVEL.Dante.AddHealth(hearts1, hearts2)
    local types = hearts1.types
    for _, heartType in ipairs(hearts2.types) do
        types[#types + 1] = heartType
    end

    return {
        types = types,
        maxHearts = hearts1.maxHearts + hearts2.maxHearts,
        hearts = hearts1.hearts + hearts2.hearts,
        soulHearts = hearts1.soulHearts + hearts2.soulHearts,
        boneHearts = hearts1.boneHearts + hearts2.boneHearts,
        goldenHearts = hearts1.goldenHearts + hearts2.goldenHearts,
        eternalHearts = hearts1.eternalHearts + hearts2.eternalHearts,
        rottenHearts = hearts1.rottenHearts + hearts2.rottenHearts,
    }
end

function REVEL.Dante.RemoveHealth(player)
    player:AddGoldenHearts(-player:GetGoldenHearts())
    player:AddRottenHearts(-player:GetRottenHearts())
    player:AddEternalHearts(-player:GetEternalHearts())
    player:AddMaxHearts(-player:GetMaxHearts())
    player:AddSoulHearts(-player:GetSoulHearts())
    player:AddBoneHearts(-player:GetBoneHearts())
end

---@param player EntityPlayer
---@param hearts RevDante.Health
function REVEL.Dante.LoadHealth(player, hearts)
    player:AddMaxHearts(hearts.maxHearts)
    for i, heartType in ipairs(hearts.types) do
        local isHalf = (hearts.soulHearts + hearts.boneHearts * 2) < i * 2
        local addAmount = 2
        if isHalf or heartType == HeartTypes.BONE then
            addAmount = 1
        end

        if heartType == HeartTypes.SOUL then
            player:AddSoulHearts(addAmount)
        elseif heartType == HeartTypes.BLACK then
            player:AddBlackHearts(addAmount)
        else
            player:AddBoneHearts(addAmount)
        end
    end

    player:AddEternalHearts(hearts.eternalHearts)
    player:AddHearts(hearts.hearts)
    player:AddGoldenHearts(hearts.goldenHearts)
    player:AddRottenHearts(hearts.rottenHearts)

    -- Rotten hearts + bone hearts can mess new total of red hearts
    -- by losing half a normal red heart, check again
    local heartsNumNew = player:GetHearts() - player:GetRottenHearts() * 2
    if heartsNumNew < hearts.hearts then
        player:AddHearts(hearts.hearts - heartsNumNew)
    end
end

function REVEL.Dante.CapHealth(player, cap)
    local max = player:GetMaxHearts() / 2
    local addMax
    if max > cap then
        addMax = (cap - max) * 2
        max = max + addMax
    end

    local soul = math.floor(player:GetSoulHearts() / 2)
    local bone = player:GetBoneHearts()
    local totalExtra = soul + bone
    local removingSoul

    if max + totalExtra > cap then
        removingSoul = true
    end

    if addMax or removingSoul then
        local golden = player:GetGoldenHearts()
        player:AddGoldenHearts(-golden)
        local rotten = player:GetRottenHearts()
        player:AddRottenHearts(-rotten)

        if addMax then
            player:AddMaxHearts(addMax)
        end

        if removingSoul then
            local over = (max + totalExtra) - cap
            for i = totalExtra - 1, totalExtra - over, -1 do
                if player:IsBoneHeart(i) then
                    if player:GetSoulHearts() > 0 then
                        player:AddSoulHearts(-2)
                    else
                        player:AddBoneHearts(-1)
                    end
                else
                    if i == totalExtra - over - 1 and player:GetSoulHearts() % 2 ~= 0 then
                        player:AddSoulHearts(-1)
                    else
                        player:AddSoulHearts(-2)
                    end
                end
            end
        end

        player:AddGoldenHearts(golden)
    end
end

function REVEL.Dante.IsInventoryManagedItem(id, item)
    if item and not id then
        id = item.ID
    end

    item = item or REVEL.config:GetCollectible(id)
    return item and item.Type ~= ItemType.ITEM_ACTIVE and item.Type ~= ItemType.ITEM_TRINKET 
        and not REVEL.CharonBlacklist[id]
end

function REVEL.Dante.StoreItems(player, remove, whitelist)
    local items = {}
    for sid, num in pairs(revel.data.run.inventory[REVEL.GetPlayerID(player)]) do
        local id = tonumber(sid)
        if REVEL.Dante.IsInventoryManagedItem(id) then
            -- "This does not work for modded actives, so actives are handled entirely separately"
            -- this was here when using GetCollectibleNum, still true? needs checking
            if num > 0 then
                local numRemove = num
                if whitelist and whitelist[sid] then
                    numRemove = numRemove - 1
                    -- REVEL.DebugLog("Not storing", sid, "do remove:", not not remove)
                end
                
                if numRemove > 0 then
                    items[sid] = numRemove

                    if remove then
                        for i = 1, numRemove do
                            player:RemoveCollectible(id, true)
                        end
                    end
                end
            end
        end
    end

    return items
end

function REVEL.Dante.RemoveSpecificItems(player, items)
    for sid, count in pairs(items) do
        for i = 1, count do
            player:RemoveCollectible(tonumber(sid), true)
        end
    end
end


local combinedItems = {
    CollectibleType.COLLECTIBLE_POLYDACTYLY,
    CollectibleType.COLLECTIBLE_MOMS_PURSE
}

local justAddedCharonItems
function REVEL.Dante.LoadItems(player, items, addSchoolbag, addCombinedItems, noRemoveCharonItems)
    justAddedCharonItems = true
    REVEL.CharonPickupAdding = true
    for sid, count in pairs(items) do
        for i = 1, count do
            AddSingleCollectible(player, tonumber(sid))
        end
    end

    if addSchoolbag and not player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, true) then
        player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
        player:RemoveCostume(REVEL.config:GetCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG))
    end

    if addCombinedItems then
        for _, item in ipairs(combinedItems) do
            if not player:HasCollectible(item, true) then
                player:AddCollectible(item, 0, false)
                player:RemoveCostume(REVEL.config:GetCollectible(item))
            end
        end
    end

    if not noRemoveCharonItems then
        if not addSchoolbag then
            player:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, true)
        end

        if not addCombinedItems then
            for _, item in ipairs(combinedItems) do
                player:RemoveCollectible(item, true)
            end
        end
    end

    justAddedCharonItems = nil
end

revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, t, v, s, po, ve, sp, se)
    if justAddedCharonItems then
        if sp and sp.Type == EntityType.ENTITY_PLAYER and (t == EntityType.ENTITY_PICKUP or t == EntityType.ENTITY_BOMBDROP) then
            return {
                StageAPI.E.DeleteMePickup.T,
                StageAPI.E.DeleteMePickup.V,
                0,
                se
            }
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, savestate)
    local player = REVEL.player
    if REVEL.IsDanteCharon(player) and not savestate then
        player:AddKeys(1)
        player:AddBombs(1)
        player:AddBlackHearts(3)
        local isGreed = REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREED or REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREEDIER
        if not isGreed then
            REVEL.Dante.SetPhylactery(player, REVEL.ITEM.PHYLACTERY.id)
        else
            REVEL.Dante.SetPhylactery(player, REVEL.ITEM.PHYLACTERY_MERGED.id)
        end

        REVEL.pool:RemoveCollectible(REVEL.ITEM.PHYLACTERY.id)
        for item, _ in pairs(REVEL.CharonFullBan) do
            REVEL.pool:RemoveCollectible(item)
        end

        REVEL.Dante.SwitchCostume(player, false)

        -- No schoolbag needed unless merged
        if not REVEL.PHYLACTERY_POCKET then
            player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
            player:RemoveCostume(REVEL.config:GetCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG))
        end

        -- Initialize save data

        revel.data.run.dante.IsDante = true
        revel.data.run.dante.OtherInventory.hearts = REVEL.Dante.GetDefaultHealth()
        revel.data.run.dante.OtherInventory.hearts.maxHearts = 2
        revel.data.run.dante.OtherInventory.hearts.hearts = 2
        revel.data.run.dante.OtherInventory.hearts.types = {HeartTypes.BLACK, HeartTypes.BLACK}
        revel.data.run.dante.OtherInventory.hearts.soulHearts = 3
        revel.data.run.dante.IsInitialized = true
    end
	if REVEL.HasBrokenOarEffect(player) then
        for item, _ in pairs(REVEL.OarFullBan) do
            REVEL.pool:RemoveCollectible(item)
        end
	end
end)

shared.PreviouslyEnteredOtherCharRoom = false
shared.SkippedOtherChar = false
function REVEL.Dante.InventorySwitch(player)
    local coins, keys, bombs = player:GetNumCoins(), player:GetNumKeys(), player:GetNumBombs()
    local currentHP = REVEL.Dante.StoreHealth(player)
    local birthrightWhitelist = REVEL.Dante.GetBirthrightWhitelist(player)
    local currentItems = REVEL.Dante.StoreItems(player, true, birthrightWhitelist)
    local currentScale, currentSize = player.SpriteScale, player.SizeMulti
    local currentScaleX, currentScaleY = currentScale.X, currentScale.Y
    local currentSizeX, currentSizeY = currentSize.X, currentSize.Y

    local secondActive
    if revel.data.run.dante.IsDante and not REVEL.PHYLACTERY_POCKET then
        local active = player:GetActiveItem()
        if active ~= REVEL.ITEM.PHYLACTERY.id then
            player:SwapActiveItems()
        end

        if player:GetActiveItem(ActiveSlot.SLOT_SECONDARY) > 0 then
            secondActive = {
                id = player:GetActiveItem(ActiveSlot.SLOT_SECONDARY),
                charge = player:GetActiveCharge(ActiveSlot.SLOT_SECONDARY) + player:GetBatteryCharge(ActiveSlot.SLOT_SECONDARY)
            }
            player:RemoveCollectible(player:GetActiveItem(ActiveSlot.SLOT_SECONDARY))
        end
    else
        local active = player:GetActiveItem(ActiveSlot.SLOT_PRIMARY)

        if active > 0 then
            secondActive = {
                id = active,
                charge = player:GetActiveCharge(ActiveSlot.SLOT_PRIMARY) + player:GetBatteryCharge(ActiveSlot.SLOT_PRIMARY)
            }
            player:RemoveCollectible(active)
        end
    end

    local trinket = player:GetTrinket(0)
    local card, pill
    local cardSlot, pillSlot = 0, 0
    if not REVEL.PHYLACTERY_POCKET then
        card, pill = player:GetCard(0), player:GetPill(0)

        if card > 0 then
            player:SetCard(0, Card.CARD_NULL)
        end

        if pill > 0 then
            player:SetPill(0, PillColor.PILL_NULL)
        end
    else
        local phylacterySlot = REVEL.Dante.GetPocketActiveSlot(player)
        cardSlot = 1 - phylacterySlot
        pillSlot = cardSlot
        card, pill = player:GetCard(cardSlot), player:GetPill(pillSlot)

        if card > 0 then
            player:SetCard(cardSlot, Card.CARD_NULL)
        end

        if pill > 0 then
            player:SetPill(pillSlot, PillColor.PILL_NULL)
        end
    end

    if trinket > 0 then
        player:TryRemoveTrinket(trinket)
    end

    REVEL.Dante.LoadItems(player, revel.data.run.dante.OtherInventory.items, not REVEL.PHYLACTERY_POCKET and not revel.data.run.dante.IsDante, false)
    revel.data.run.dante.OtherInventory.items = currentItems

    REVEL.Dante.RemoveHealth(player)
    REVEL.Dante.LoadHealth(player, revel.data.run.dante.OtherInventory.hearts)
    revel.data.run.dante.OtherInventory.hearts = currentHP

    -- this will work once ab++ is removed or fixed.
    player.SpriteScale = Vector(revel.data.run.dante.OtherInventory.spriteScale.X, revel.data.run.dante.OtherInventory.spriteScale.Y)
    revel.data.run.dante.OtherInventory.spriteScale.X = currentScaleX
    revel.data.run.dante.OtherInventory.spriteScale.Y = currentScaleY

    player.SizeMulti = Vector(revel.data.run.dante.OtherInventory.sizeMulti.X, revel.data.run.dante.OtherInventory.sizeMulti.Y)
    revel.data.run.dante.OtherInventory.sizeMulti.X = currentSizeX
    revel.data.run.dante.OtherInventory.sizeMulti.Y = currentSizeY

    if REVEL.PHYLACTERY_POCKET or not revel.data.run.dante.IsDante then
        local secondary = revel.data.run.dante.OtherInventory.secondActive
        if secondary.id and secondary.id > 0 then
            player:AddCollectible(secondary.id, secondary.charge, false)
            if not REVEL.PHYLACTERY_POCKET then
                player:SwapActiveItems()
            end
        end
    end

    if secondActive then
        revel.data.run.dante.OtherInventory.secondActive = secondActive
    else
        revel.data.run.dante.OtherInventory.secondActive = {}
    end

    if revel.data.run.dante.OtherInventory.trinket > 0 then
        player:AddTrinket(revel.data.run.dante.OtherInventory.trinket)
    end

    if revel.data.run.dante.OtherInventory.card > 0 then
        player:SetCard(cardSlot, revel.data.run.dante.OtherInventory.card)
    end

    if revel.data.run.dante.OtherInventory.pill > 0 then
        player:SetPill(pillSlot, revel.data.run.dante.OtherInventory.pill)
    end

    revel.data.run.dante.OtherInventory.card = card
    revel.data.run.dante.OtherInventory.pill = pill
    revel.data.run.dante.OtherInventory.trinket = trinket

    player:AddCoins(coins - player:GetNumCoins())
    player:AddKeys(keys - player:GetNumKeys())
    player:AddBombs(bombs - player:GetNumBombs())

    revel.data.run.dante.IsDante = not revel.data.run.dante.IsDante

    REVEL.Dante.SwitchCostume(player, not revel.data.run.dante.IsDante)

	shared.PreviouslyEnteredOtherCharRoom = false
	shared.SkippedOtherChar = false

    player:DischargeActiveItem(REVEL.Dante.GetPhylacteryActiveSlot())
    player:AddCacheFlags(CacheFlag.CACHE_ALL)
    player:EvaluateItems()
end

function REVEL.Dante.Merge(player, isGreed)
    local coins, keys, bombs = player:GetNumCoins(), player:GetNumKeys(), player:GetNumBombs()
    local birthrightWhitelist = REVEL.Dante.GetBirthrightWhitelist(player)
    local currentItems = REVEL.Dante.StoreItems(player, false, birthrightWhitelist)
    local currentHealth = REVEL.Dante.StoreHealth(player)

    -- No schoolbag needed unless merged
    if REVEL.PHYLACTERY_POCKET then
        player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
        player:RemoveCostume(REVEL.config:GetCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG))
    end

    REVEL.Dante.LoadItems(player, revel.data.run.dante.OtherInventory.items, true, true)

    REVEL.Dante.RemoveHealth(player)
    REVEL.Dante.LoadHealth(player, currentHealth)
    REVEL.Dante.LoadHealth(player, revel.data.run.dante.OtherInventory.hearts)

    if not revel.data.run.dante.IsDante then
        revel.data.run.dante.OtherInventory.items = currentItems
        local scaleX, scaleY = player.SpriteScale.X, player.SpriteScale.Y
        player.SpriteScale = Vector(revel.data.run.dante.OtherInventory.spriteScale.X, revel.data.run.dante.OtherInventory.spriteScale.Y)
        revel.data.run.dante.OtherInventory.spriteScale = {X = scaleX, Y = scaleY}

        -- Is charon: check if own active is going to be the only one, and if so prepare
        -- to give it back to charon on split
        if REVEL.PHYLACTERY_POCKET and player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) > 0
        and not (revel.data.run.dante.OtherInventory.secondActive.id and revel.data.run.dante.OtherInventory.secondActive.id > 0) then
            revel.data.run.dante.ActiveComesFromCharon = true
            REVEL.DebugStringMinor("Dante | Setting comes from charon (charon)", revel.data.run.dante.ActiveComesFromCharon)
        end
    end
    if not revel.data.run.dante.IsDante or REVEL.PHYLACTERY_POCKET then
        local secondary = revel.data.run.dante.OtherInventory.secondActive
        if secondary.id and secondary.id > 0 then
            -- Passes in phylactery pocket mode, if is dante: check if the active item
            -- came from charon
            if revel.data.run.dante.IsDante and player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) <= 0 then
                revel.data.run.dante.ActiveComesFromCharon = true
                REVEL.DebugStringMinor("Dante | Setting comes from charon (dante)", revel.data.run.dante.ActiveComesFromCharon)
            end

            player:AddCollectible(secondary.id, secondary.charge, false)

            if not REVEL.PHYLACTERY_POCKET then
                player:SwapActiveItems() -- Swap to make phylactery the main active
            end
        end
        revel.data.run.dante.OtherInventory.secondActive = {}
    end

    if revel.data.run.dante.OtherInventory.trinket > 0 then
        player:AddTrinket(revel.data.run.dante.OtherInventory.trinket)
    end

    if revel.data.run.dante.OtherInventory.card > 0 then
        local phylacterySlot = REVEL.Dante.GetPocketActiveSlot(player)
        local addToSlot = phylacterySlot + 1
        while REVEL.Dante.SlotHasCardOrPill(player, addToSlot) do
            addToSlot = addToSlot + 1
        end

        player:SetCard(addToSlot, revel.data.run.dante.OtherInventory.card)
    end

    if revel.data.run.dante.OtherInventory.pill > 0 then
        local phylacterySlot = REVEL.Dante.GetPocketActiveSlot(player)
        local addToSlot = phylacterySlot + 1
        while REVEL.Dante.SlotHasCardOrPill(player, addToSlot) do
            addToSlot = addToSlot + 1
        end

        player:SetPill(addToSlot, revel.data.run.dante.OtherInventory.pill)
    end

    revel.data.run.dante.OtherInventory.trinket = -1
    revel.data.run.dante.OtherInventory.card = -1
    revel.data.run.dante.OtherInventory.pill = -1
    revel.data.run.dante.OtherInventory.position = {X = false, Y = false}

    player:AddCoins(coins - player:GetNumCoins())
    player:AddKeys(keys - player:GetNumKeys())
    player:AddBombs(bombs - player:GetNumBombs())

    if not revel.data.run.dante.IsDante then
        REVEL.Dante.SwitchCostume(player, false)
    end

    if not isGreed then
        REVEL.Dante.SetPhylactery(player, REVEL.ITEM.PHYLACTERY_MERGED.id)
    end

    REVEL.Dante.MergeMap()

    if not revel.data.run.dante.FirstMerge then
		REVEL.DelayFunction(Isaac.Spawn, 1, {
            EntityType.ENTITY_PICKUP, 
            PickupVariant.PICKUP_COIN, 
            CoinSubType.COIN_DIME, 
            REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true), 
            Vector.Zero, player
        }, false)
        revel.data.run.dante.FirstMerge = true
    end

    revel.data.run.dante.IsDante = true
    revel.data.run.dante.IsCombined = true

	shared.PreviouslyEnteredOtherCharRoom = false
	shared.SkippedOtherChar = false

    player:AddCacheFlags(CacheFlag.CACHE_ALL)
    player:EvaluateItems()
end

local LevelPathFromStart = REVEL.NewPathMapFromTable("LevelPathFromStart", {
    GetTargetIndices = function()
        return {REVEL.level:GetStartingRoomIndex()}
    end,
    GetInverseCollisions = function()
        local valid = {}
        local roomsList = REVEL.level:GetRooms()
        for i = 0, roomsList.Size - 1 do
            local roomDesc = roomsList:Get(i)
            if roomDesc and roomDesc.Data.Type == RoomType.ROOM_DEFAULT then
                local room = roomDesc.Data
                local ind = roomDesc.GridIndex
                local shape = room.Shape
                if shape == RoomShape.ROOMSHAPE_2x2 or shape == RoomShape.ROOMSHAPE_LBL or shape == RoomShape.ROOMSHAPE_LBR or shape == RoomShape.ROOMSHAPE_LTL or shape == RoomShape.ROOMSHAPE_LTR then
                    if shape ~= RoomShape.ROOMSHAPE_LTL then
                        valid[ind] = true
                    end

                    if shape ~= RoomShape.ROOMSHAPE_LTR then
                        valid[ind + 1] = true
                    end

                    if shape ~= RoomShape.ROOMSHAPE_LBL then
                        valid[ind + 13] = true
                    end

                    if shape ~= RoomShape.ROOMSHAPE_LBR then
                        valid[ind + 14] = true
                    end
                elseif shape == RoomShape.ROOMSHAPE_1x2 or shape == RoomShape.ROOMSHAPE_IIV then
                    valid[ind] = true
                    valid[ind + 13] = true
                elseif shape == RoomShape.ROOMSHAPE_2x1 or shape == RoomShape.ROOMSHAPE_IIH then
                    valid[ind] = true
                    valid[ind + 1] = true
                else
                    valid[ind] = true
                end
            end
        end

        return valid
    end,
    NoAutoHandle = true,
    Width = 13
})

local CHARON_STARTING_ROOM_LAYOUT = "Charon Soul Starting Room"
local emptyLayout = StageAPI.CreateEmptyRoomLayout()
StageAPI.RegisterLayout(CHARON_STARTING_ROOM_LAYOUT, emptyLayout)

function REVEL.Dante.Reset(player, noSetRoom, isGreed)
    local coins, keys, bombs = player:GetNumCoins(), player:GetNumKeys(), player:GetNumBombs()

    REVEL.DebugStringMinor("Dante | Resetting charon & dante...")

    if revel.data.run.dante.IsCombined then
        local health1, health2 = REVEL.Dante.SplitHealth(REVEL.Dante.StoreHealth(player), revel.data.run.dante.RedHeartPrioritizeDante)

        local prevBirthrightWhitelist = REVEL.Dante.GetBirthrightWhitelist(player)

        -- Add shared items back to charon, since they don't get 
        -- added to the inventory
        for sid, owner in pairs(prevBirthrightWhitelist) do
            if owner == 2 then
                local num = (revel.data.run.dante.OtherInventory.items[sid] or 0) + 1
                revel.data.run.dante.OtherInventory.items[sid] = num
            end
        end

        local birthrightWhitelist = REVEL.Dante.GenerateBirthrightWhitelist(player, revel.data.run.dante.OtherInventory.items)
        REVEL.DebugStringMinor(
            "Dante | prev birthright whitelist:", prevBirthrightWhitelist, 
            "\nnew birthright whitelist:", birthrightWhitelist
        )
        revel.data.run.dante.BirthrightWhitelist = birthrightWhitelist

        for sid, owner in pairs(prevBirthrightWhitelist) do
            if owner == 2 then
                revel.data.run.dante.OtherInventory.items[sid] = revel.data.run.dante.OtherInventory.items[sid] - 1
                if revel.data.run.dante.OtherInventory.items[sid] == 0 then
                    revel.data.run.dante.OtherInventory.items[sid] = nil
                end
            end
        end
        
        REVEL.Dante.RemoveSpecificItems(player, revel.data.run.dante.OtherInventory.items)

        -- Split actives
        if REVEL.PHYLACTERY_POCKET then
            local charonActive
            local hasSecondActive = player:GetActiveItem(ActiveSlot.SLOT_SECONDARY) > 0
            -- primary to dante, secondary to charon, allows swapping between floors
            if hasSecondActive then
                charonActive = {
                    id = player:GetActiveItem(ActiveSlot.SLOT_SECONDARY),
                    charge = player:GetActiveCharge(ActiveSlot.SLOT_SECONDARY) + player:GetBatteryCharge(ActiveSlot.SLOT_SECONDARY)
                }
            -- If the pair only had one item, and it was charon's, give it to him
            elseif revel.data.run.dante.ActiveComesFromCharon then
                charonActive = {
                    id = player:GetActiveItem(ActiveSlot.SLOT_PRIMARY),
                    charge = player:GetActiveCharge(ActiveSlot.SLOT_PRIMARY) + player:GetBatteryCharge(ActiveSlot.SLOT_PRIMARY)
                }
                REVEL.DebugStringMinor("Dante | Giving original active to charon")
            end

            if charonActive then
                REVEL.DebugStringMinor("Dante | Giving second active to charon", charonActive.id)
                player:RemoveCollectible(charonActive.id)
                revel.data.run.dante.OtherInventory.secondActive = charonActive
            else
                revel.data.run.dante.OtherInventory.secondActive = {}
            end

            revel.data.run.dante.ActiveComesFromCharon = false
        end

        local trinket = player:GetTrinket(1)
        if trinket > 0 then
            player:TryRemoveTrinket(trinket)
            revel.data.run.dante.OtherInventory.trinket = trinket
        end

        -- Split cards and pills
        if REVEL.PHYLACTERY_POCKET then
            local phylacterySlot = REVEL.Dante.GetPocketActiveSlot(player)
            local secondSlot = 0
            local counted = 0

            while REVEL.Dante.SlotHasCardOrPill(player, secondSlot) or secondSlot == phylacterySlot do
                if REVEL.Dante.SlotHasCardOrPill(player, secondSlot) then
                    counted = counted + 1

                    --get second card/pill
                    if counted >= 2 then
                        break
                    end
                end
                secondSlot = secondSlot + 1
            end

            local card, pill = player:GetCard(secondSlot), player:GetPill(secondSlot)

            if card > 0 then
                player:SetCard(secondSlot, Card.CARD_NULL)
                revel.data.run.dante.OtherInventory.card = card
            end

            if pill > 0 then
                player:SetPill(secondSlot, PillColor.PILL_NULL)
                revel.data.run.dante.OtherInventory.pill = pill
            end
        else
            local trinket, card, pill = player:GetTrinket(1), player:GetCard(1), player:GetPill(1)
            if trinket > 0 then
                player:TryRemoveTrinket(trinket)
                revel.data.run.dante.OtherInventory.trinket = trinket
            end

            if card > 0 then
                player:SetCard(1, Card.CARD_NULL)
                revel.data.run.dante.OtherInventory.card = card
            end

            if pill > 0 then
                player:SetPill(1, PillColor.PILL_NULL)
                revel.data.run.dante.OtherInventory.pill = pill
            end
        end

        for _, item in ipairs(combinedItems) do
            player:RemoveCollectible(item, true)
        end
        -- Important: must be done after removing actives, else doing it before would spawn the active on the ground
        if REVEL.PHYLACTERY_POCKET then
            player:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, true)
        end

        REVEL.Dante.RemoveHealth(player)
        REVEL.Dante.LoadHealth(player, health1)

        if not isGreed then
            REVEL.Dante.SetPhylactery(player, REVEL.ITEM.PHYLACTERY.id)
        end

        revel.data.run.dante.OtherInventory.hearts = health2
    elseif not revel.data.run.dante.IsDante and revel.data.run.dante.IsInitialized then
        REVEL.Dante.InventorySwitch(player)
    end

    player:AddCoins(coins - player:GetNumCoins())
    player:AddKeys(keys - player:GetNumKeys())
    player:AddBombs(bombs - player:GetNumBombs())

    revel.data.run.dante.IsCombined = false
    revel.data.run.dante.IsDante = true
    revel.data.run.dante.OtherInventory.position = {X = false, Y = false}

    player:AddCacheFlags(CacheFlag.CACHE_ALL)
    player:EvaluateItems()

    if not noSetRoom and REVEL.level:GetStage() < 13 then
        REVEL.UpdatePathMap(LevelPathFromStart, true)
        local farthestDists = {}
        for index, dist in pairs(LevelPathFromStart.TargetMapSets[1].Map) do
            local roomDesc = REVEL.level:GetRoomByIdx(index)
            if roomDesc.Data then
                if roomDesc and (not farthestDists[#farthestDists] or dist >= farthestDists[#farthestDists][1]) and roomDesc.Data.Shape == RoomShape.ROOMSHAPE_1x1 then
                    if farthestDists[#farthestDists] and dist > farthestDists[#farthestDists][1] then
                        farthestDists = {}
                    end

                    farthestDists[#farthestDists + 1] = {dist, index}
                end
            end
        end

        if #farthestDists > 0 then
            local index = farthestDists[math.random(1, #farthestDists)][2]
            revel.data.run.dante.OtherRoom = index
            local roomDesc = REVEL.level:GetRoomByIdx(index)
            local newRoom = StageAPI.LevelRoom(CHARON_STARTING_ROOM_LAYOUT)
            StageAPI.SetLevelRoom(newRoom, roomDesc.ListIndex)
            revel.data.run.level.dante.StartingRoomIndex = roomDesc.ListIndex
            REVEL.DebugStringMinor("Dante | Set new charon starting room index to", revel.data.run.level.dante.StartingRoomIndex)
        end
    end
end

function REVEL.Dante.AddCollectibleToOtherPlayer(player, isInQueue, item, pos)
    local startMaxHearts, startHearts, startSoulHearts = player:GetMaxHearts(), player:GetHearts(), player:GetSoulHearts()

    local goldenHearts = player:GetGoldenHearts()
    player:AddGoldenHearts(-goldenHearts)

    local startNum = player:GetCollectibleNum(item.ID, true)

    if isInQueue then
        player:FlushQueueItem()
    else
        player:AddCollectible(item.ID, 999, true)
    end

    local newNum = player:GetCollectibleNum(item.ID, true)

    if not revel.data.run.dante.IsCombined then
        for i = 1, newNum - startNum do
            player:RemoveCollectible(item.ID, true)
        end

        if item.AddMaxHearts then
            revel.data.run.dante.OtherInventory.hearts.maxHearts = revel.data.run.dante.OtherInventory.hearts.maxHearts + item.AddMaxHearts
            local currentMaxHearts = player:GetMaxHearts()
            if currentMaxHearts ~= startMaxHearts then
                player:AddMaxHearts(startMaxHearts - currentMaxHearts)
            end
        end

        if item.AddHearts then
            revel.data.run.dante.OtherInventory.hearts.hearts = revel.data.run.dante.OtherInventory.hearts.hearts + item.AddHearts

            local currentHearts = player:GetHearts()
            if currentHearts ~= startHearts then
                player:AddHearts(startHearts - currentHearts)
            end
        end

        local soulAdd = item.AddSoulHearts or item.AddBlackHearts
        if soulAdd then
            revel.data.run.dante.OtherInventory.hearts.soulHearts = revel.data.run.dante.OtherInventory.hearts.soulHearts + soulAdd

            if item.AddSoulHearts then
                for i = 1, math.ceil(item.AddSoulHearts / 2) do
                    revel.data.run.dante.OtherInventory.hearts.types[#revel.data.run.dante.OtherInventory.hearts.types + 1] = 1
                end
            end

            if item.AddBlackHearts then
                for i = 1, math.ceil(item.AddBlackHearts / 2) do
                    revel.data.run.dante.OtherInventory.hearts.types[#revel.data.run.dante.OtherInventory.hearts.types + 1] = 2
                end
            end

            local currentSoulHearts = player:GetSoulHearts()
            if currentSoulHearts ~= startSoulHearts then
                player:AddSoulHearts(startSoulHearts - currentSoulHearts)
            end
        end
    end

    player:AddGoldenHearts(goldenHearts)

    local sid = tostring(item.ID)
    revel.data.run.dante.OtherInventory.items[sid] = revel.data.run.dante.OtherInventory.items[sid] or 0
    revel.data.run.dante.OtherInventory.items[sid] = revel.data.run.dante.OtherInventory.items[sid] + newNum - startNum

    local phylactery = Isaac.FindByType(REVEL.ENT.PHYLACTERY.id, REVEL.ENT.PHYLACTERY.variant, -1, false, false)[1]
    if phylactery then
        REVEL.Dante.AddAbsorbingItem(phylactery, item.GfxFileName, pos or player.Position)
    end
end

end