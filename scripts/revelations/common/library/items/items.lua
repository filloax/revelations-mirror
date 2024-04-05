local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()


function REVEL.OnePlayerHasCollectible(id, ignoreModifiers)
    local ret
    ignoreModifiers = ignoreModifiers or false
    for i,player in ipairs(REVEL.players) do
        ret = ret or player:HasCollectible(id, ignoreModifiers)
    end
    return ret
end

function REVEL.AllPlayersHaveCollectible(id, ignoreModifiers)
    local ret = true
    ignoreModifiers = ignoreModifiers or false
    for i,player in ipairs(REVEL.players) do
        ret = ret and player:HasCollectible(id, ignoreModifiers)
    end
    return ret
end

function REVEL.OnePlayerHasTrinket(id)
    for i,player in ipairs(REVEL.players) do
        if player:HasTrinket(id) then
            return true
        end
    end
end

function REVEL.GetCollectibleSum(id)
    local a = 0
    for i,v in ipairs(REVEL.players) do
        a = a + v:GetCollectibleNum(id, true)
    end
    return a
end

local function hasItem(p, id, ignoreModifiers)
    ignoreModifiers = ignoreModifiers or false
    return p:HasCollectible(id, ignoreModifiers)
end
    
local function hasAnyItems(p, ...)
    local arg = {...}
    local has = false
    for i,id in ipairs(arg) do
        has = has or p:HasCollectible(id)
    end
    return has
end
    
---@param id CollectibleType
---@return EntityPlayer?
function REVEL.GetRandomPlayerWithItem(id)
    local t = REVEL.GetFilteredArray(REVEL.players, hasItem, id)
    if #t ~= 0 then
        return t[math.random(#t)]
    end
end
    
---@vararg CollectibleType
---@return EntityPlayer?
function REVEL.GetRandomPlayerWithItems(...)
    local t = REVEL.GetFilteredArray(REVEL.players, hasAnyItems, ...)
    if #t ~= 0 then
        return t[math.random(#t)]
    end
end

local function hasAnyTrinkets(p, ...)
    local arg = {...}
    local has = false
    for i,id in ipairs(arg) do
        has = has or p:HasTrinket(id)
    end
    return has
end

---@param id TrinketType
---@return EntityPlayer?
function REVEL.GetRandomPlayerWithTrinket(id)
    local t = REVEL.GetFilteredArray(REVEL.players, hasAnyTrinkets, id)
    if #t ~= 0 then
        return t[math.random(#t)]
    end
end
    
---@vararg TrinketType
---@return EntityPlayer?
function REVEL.GetRandomPlayerWithTrinkets(...)
    local t = REVEL.GetFilteredArray(REVEL.players, hasAnyTrinkets, ...)
    if #t ~= 0 then
        return t[math.random(#t)]
    end
end

function REVEL.HasWeaponTypeInList(player, list)
    for _, wType in ipairs(list) do
        if player:HasWeaponType(wType) then
            return true
        end
    end
    return false
end
    
function REVEL.HasCollectibleInList(player, list)
    for _, itemId in ipairs(list) do
        if player:HasCollectible(itemId) then
            return true
        end
    end
    return false
end

function REVEL.GetCollectibleNameFromID(itemID)
    local cfgItem = REVEL.config:GetCollectible(itemID)
    if not cfgItem then
        error("GetCollectibleNameFromID: id " .. tostring(itemID) .. " not registered", 2)
    end
    return cfgItem.Name
end
    

-- Active items

function REVEL.IsShowingItem(player)
    return REVEL.MultiAnimOnCheck(player:GetSprite(), "LiftItem", "PickupWalkDown", "PickupWalkUp", "PickupWalkLeft", "PickupWalkRight")
end

--Show active until active button is pressed again

function REVEL.ShowActive(player)
    local data = REVEL.GetData(player)

    data.LastShownItem = player:GetActiveItem()
    player:AnimateCollectible(data.LastShownItem, "LiftItem", "PlayerPickup")
    player.FireDelay = 15
end

function REVEL.HideActive(player)
    local data = REVEL.GetData(player)
    local id = player:GetActiveItem()

    player:AnimateCollectible(id, "HideItem", "PlayerPickup")
    data.LastShownItem = nil
    player.FireDelay = player.MaxFireDelay
end

local function showActivePlayerUpdate(_, player)
    local data = REVEL.GetData(player)
    if data.LastShownItem and REVEL.IsShowingItem(player) then
        player.FireDelay = 15
    end
end

function REVEL.RefundActiveCharge(player)
    REVEL.DelayFunction(1, function() 
        player:SetActiveCharge(player:GetActiveCharge() + REVEL.config:GetCollectible(player:GetActiveItem()).MaxCharges) 
    end)
end

function REVEL.ConsumeActiveCharge(player)
    player:SetActiveCharge(player:GetActiveCharge() - REVEL.config:GetCollectible(player:GetActiveItem()).MaxCharges)
end

function REVEL.ToggleShowActive(player, refundCharge)
    local data = REVEL.GetData(player)
    if refundCharge then
        REVEL.RefundActiveCharge(player)
    end
    if data.LastShownItem and REVEL.IsShowingItem(player) then
        REVEL.HideActive(player)
        return false
    else
        REVEL.ShowActive(player)
        return true
    end
end

function REVEL.GetShowingActive(player)
    return REVEL.IsShowingItem(player) and REVEL.GetData(player).LastShownItem
end

-- Trinkets


function REVEL.GetTrinketNameFromID(itemID)
    local cfgItem = REVEL.config:GetTrinket(itemID)
    if not cfgItem then
        error("GetTrinketNameFromID: id " .. tostring(itemID) .. " not registered", 2)
    end
    return cfgItem.Name
end

---removes the player's current trinkets, gives the player the one you provided, uses the smelter, then gives the player back the original trinkets.
-- Credits to kittenchilly
---@param player EntityPlayer
---@param trinket TrinketType
---@param firstTimePickingUp? boolean
function REVEL.AddSmeltedTrinket(player, trinket, firstTimePickingUp)
    --get the trinkets they're currently holding
    local trinket0 = player:GetTrinket(0)
    local trinket1 = player:GetTrinket(1)

    --remove them
    if trinket0 ~= 0 then
        player:TryRemoveTrinket(trinket0)
    end
    if trinket1 ~= 0 then
        player:TryRemoveTrinket(trinket1)
    end

    player:AddTrinket(trinket, firstTimePickingUp == nil and true or firstTimePickingUp) --add the trinket
    player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, false, false, false, false) --smelt it

    --give their trinkets back
    if trinket0 ~= 0 then
        player:AddTrinket(trinket0, false)
    end
    if trinket1 ~= 0 then
        player:AddTrinket(trinket1, false)
    end
end


revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, showActivePlayerUpdate)

end