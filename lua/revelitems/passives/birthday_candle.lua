REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

---------------------
-- BIRTHDAY CANDLE --
---------------------


REVEL.ITEM.BIRTHDAY_CANDLE:addPickupCallback(function(player)
    if player:GetSoulHearts() == 0 and player:GetPlayerType() ~= PlayerType.PLAYER_KEEPER then
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, 3, Isaac.GetFreeNearPosition(player.Position, 50), Vector.Zero, player)
    elseif player:GetNumKeys() == 0 then
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, 0, Isaac.GetFreeNearPosition(player.Position, 50), Vector.Zero, player)
    elseif player:GetNumBombs() == 0 then
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, 0, Isaac.GetFreeNearPosition(player.Position, 50), Vector.Zero, player)
    elseif player:GetNumCoins() < 15 then
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 3, Isaac.GetFreeNearPosition(player.Position, 50), Vector.Zero, player)
    else
        revel.data.run.birthdayCandleStats[REVEL.GetPlayerID(player)] = revel.data.run.birthdayCandleStats[REVEL.GetPlayerID(player)] + 1
        player:AddCacheFlags(CacheFlag.CACHE_ALL)
        player:EvaluateItems()
    end
end)

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE , function(_, player, cacheFlag)
    -- updating stats
    if REVEL.ITEM.BIRTHDAY_CANDLE:PlayerHasCollectible(player) then
        local stats = revel.data.run.birthdayCandleStats[REVEL.GetPlayerID(player)]
        if stats > 0 then
            if cacheFlag == CacheFlag.CACHE_DAMAGE then
                player.Damage = player.Damage+stats
            elseif cacheFlag == CacheFlag.CACHE_FIREDELAY then
                    player.MaxFireDelay = math.ceil(player.MaxFireDelay * (0.9 ^ stats))
            elseif cacheFlag == CacheFlag.CACHE_LUCK then
                player.Luck = player.Luck+stats
            elseif cacheFlag == CacheFlag.CACHE_SHOTSPEED then
                player.ShotSpeed = player.ShotSpeed*(1.1^stats)
            elseif cacheFlag == CacheFlag.CACHE_SPEED then
                player.MoveSpeed = player.MoveSpeed*(1.1^stats)
            elseif cacheFlag == CacheFlag.CACHE_RANGE then
                player.TearRange = player.TearRange/(1.1^stats)
            end
        end
    end
end)

end

REVEL.PcallWorkaroundBreakFunction()