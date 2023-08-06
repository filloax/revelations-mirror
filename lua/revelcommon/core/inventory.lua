local RevCallbacks = require "lua.revelcommon.enums.RevCallbacks"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-------------------------------------
-- ITEM PICKUP EVENT AND INVENTORY --
-------------------------------------

-- Autocomplete stuff, false so it doesn't actually run
if false then
    ---@type table<integer, table<string, integer>> playerId: {string item id: amount}
    revel.data.run.inventory = {}
end

revel:AddCallback(RevCallbacks.POST_BASE_PLAYER_INIT, function(_, p)
    -- no way to directly get playerID
    for i, v in ipairs(REVEL.players) do
        if not revel.data.run.itemCount[i] then
            revel.data.run.itemCount[i] = 0
            revel.data.run.inventory[i] = {}
            revel.data.run.itemHistory[i] = {}
            revel.data.run.obtainedItemsAll[i] = {}
        end
    end
end)

function REVEL.UpdateInventory(_, force, isD4Effect)
    for i, player in ipairs(REVEL.players) do
        local count = player:GetCollectibleCount()

        if not revel.data.run.inventory[i] then
            revel.data.run.inventory[i] = {}
            revel.data.run.itemCount[i] = 0
            revel.data.run.itemHistory[i] = {}
            revel.data.run.obtainedItemsAll[i] = {}
        end

        if count ~= revel.data.run.itemCount[i] or force then -- OBTAINED/LOST A NEW ITEM
            for id = 1, REVEL.collectiblesSize do
                local sid = tostring(id)
                local item = REVEL.config:GetCollectible(id)
                if item then
                    local num = player:GetCollectibleNum(id, true)
                    local firstTimeObtained = false

                    -- item history
                    if num > 0 then
                        -- remove it from the table and we'll re-add it later to put it at the top of the list
                        if revel.data.run.inventory[i][sid] and revel.data.run.inventory[i][sid] <= 0 then
                            for index, itemID in ipairs(revel.data.run.itemHistory[i]) do
                                if id == itemID then
                                    table.remove(revel.data.run.itemHistory[i], index)
                                    break
                                end
                            end
                        end

                        if not REVEL.includes(revel.data.run.itemHistory[i], id) then
                            -- add it at pos 1 using table insert, this will push all the other values 
                            -- up a number. most recent item picked up will be the lowest number.
                            table.insert(revel.data.run.itemHistory[i], 1, id)
                        end

                        if not revel.data.run.obtainedItemsAll[i][sid] then
                            firstTimeObtained = true
                            revel.data.run.obtainedItemsAll[i][sid] = true
                        end
                    end

                    -- inventory
                    if num > 0 or revel.data.run.inventory[i][sid] then -- only update table if the player has or had the item
                        if not revel.data.run.inventory[i][sid] then
                            revel.data.run.inventory[i][sid] = 0
                        end

                        local prevNum = revel.data.run.inventory[i][sid]
                        revel.data.run.inventory[i][sid] = num

                        if num > prevNum and not REVEL.CharonPickupAdding then
                            StageAPI.CallCallbacksWithParams(RevCallbacks.POST_ITEM_PICKUP, false, id, 
                                player, i, id, isD4Effect, firstTimeObtained)
                        end

                        if REVEL.REGISTERED_ITEMS[item.Name] and
                            REVEL.REGISTERED_ITEMS[item.Name].costume then
                            local shouldRemove = num == 0
                            for _, func in ipairs(REVEL.REGISTERED_ITEMS[item.Name].costumeConditions) do
                                if not func(player, i) then
                                    shouldRemove = true
                                end
                            end

                            if shouldRemove then
                                player:TryRemoveNullCostume(REVEL.REGISTERED_ITEMS[item.Name] .costume)
                            end
                        end
                    end
                end
            end

            revel.data.run.itemCount[i] = count
        end
    end

    REVEL.CharonPickupAdding = nil
end

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, REVEL.UpdateInventory)
revel:AddCallback(ModCallbacks.MC_USE_ITEM, function() REVEL.UpdateInventory(true, true, true) end, CollectibleType.COLLECTIBLE_D4)
revel:AddCallback(ModCallbacks.MC_USE_ITEM, function() REVEL.UpdateInventory(true, true, true) end, CollectibleType.COLLECTIBLE_D100)

-- trinket history --

revel:AddCallback(ModCallbacks.MC_GET_TRINKET, function(trinketType, rng)
    if not REVEL.TrinketHistorySkipTrinket then
        revel.data.run.trinketHistory[trinketType] = true
    else
        REVEL.TrinketHistorySkipTrinket = true
    end
end)

function REVEL.HasTrinketBeenEncounteredThisRun(trinketType)
    return not not revel.data.run.trinketHistory[trinketType]
end

end
