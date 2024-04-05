return function()
----------------
-- Gag Reflex --
----------------

--give ipecac for room on pill use
revel:AddCallback(ModCallbacks.MC_USE_PILL, function(_, pillEffect, player, useFlags)
    if player:HasTrinket(REVEL.ITEM.GAGREFLEX.id) then
        REVEL.AddCollectibleEffect(CollectibleType.COLLECTIBLE_IPECAC, player)
        SFXManager():Play(REVEL.SFX.TUMMY_BUG_VOMIT, 1, 0, false, 1)
    end
end)

end