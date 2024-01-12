return function()

--------------------
-- WINDOW CLEANER --
--------------------

--[[
Tears clean enemy creep.
]]

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE , function(_, player, flag)
    if REVEL.ITEM.CLEANER:PlayerHasCollectible(player) then
        if flag == CacheFlag.CACHE_TEARCOLOR then
            player.TearColor = Color(player.TearColor.R-0.1, player.TearColor.G, player.TearColor.B-0.1, player.TearColor.A, player.TearColor.RO, player.TearColor.GO+30/255, player.TearColor.BO) --using settint etc directly don't work
        elseif flag == CacheFlag.CACHE_FIREDELAY then
            player.MaxFireDelay = player.MaxFireDelay - 1
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    if tear.Parent and tear.Parent:ToPlayer() and tear.Parent:ToPlayer():HasCollectible(REVEL.ITEM.CLEANER.id) then
        for j,c in ipairs(REVEL.roomEffects) do
            if c.Variant >= 22 and c.Variant <= 26 and tear.Position:DistanceSquared(c.Position) < (tear.Size + c.Size + 48) ^ 2 and not (c.Parent and c.Parent.Type == 1) then
                c:Die()
            end
        end
    end
end)


end