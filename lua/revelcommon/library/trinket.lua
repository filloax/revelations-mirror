REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

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
   
end

REVEL.PcallWorkaroundBreakFunction()