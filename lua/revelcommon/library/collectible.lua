REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()


function REVEL.OnePlayerHasCollectible(id)
    local ret
    for i,player in ipairs(REVEL.players) do
        ret = ret or player:HasCollectible(id)
    end
    return ret
end

function REVEL.AllPlayersHaveCollectible(id)
    local ret = true
    for i,player in ipairs(REVEL.players) do
        ret = ret and player:HasCollectible(id)
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
        a = a + v:GetCollectibleNum(id)
    end
    return a
end

local function hasItem(p, id)
    return p:HasCollectible(id)
end
  
local function hasAnyItems(p, ...)
    local arg = {...}
    local has = false
    for i,id in ipairs(arg) do
        has = has or p:HasCollectible(id)
    end
    return has
end
  
function REVEL.GetRandomPlayerWithItem(id)
    local t = REVEL.GetFilteredArray(REVEL.players, hasItem, id)
    if #t ~= 0 then
        return t[math.random(#t)]
    end
end
  
function REVEL.GetRandomPlayerWithItems(...)
    local t = REVEL.GetFilteredArray(REVEL.players, hasAnyItems, ...)
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
   
end

REVEL.PcallWorkaroundBreakFunction()