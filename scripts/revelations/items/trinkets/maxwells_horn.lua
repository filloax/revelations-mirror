local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()
--MAXWELL'S HORN

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    for _, player in ipairs(REVEL.players) do
        REVEL.GetData(player).PerilSpawnedSandBoulder = nil
    end
end)

local perilBoulderSpecialItemDamageMap = {
    [CollectibleType.COLLECTIBLE_IV_BAG] = 11
}

local perilItemBlacklist = {
    [REVEL.ITEM.PHYLACTERY.id] = true,
    [REVEL.ITEM.PHYLACTERY_MERGED.id] = true,
    [REVEL.ITEM.PHYLACTERY_PICKUP_ITEM.id] = true,
    [REVEL.ITEM.PHYLACTERY_PICKUP_ITEM_CHARGE.id] = true
}

revel:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemID, itemRNG, player, useFlags, activeSlot, customVarData)
    if player:HasTrinket(REVEL.ITEM.MAX_HORN.id) and (not REVEL.GetData(player).PerilNextBoulderTime or player.FrameCount > REVEL.GetData(player).PerilNextBoulderTime) and not perilItemBlacklist[itemID] then
        local config = REVEL.config:GetCollectible(itemID)
        local damage = 0
        if config.MaxCharges > 0 and config.MaxCharges <= 12 then
            damage = (config.MaxCharges * 5) + 11
        elseif config.MaxCharges > 12 then --recharging
            damage = 11
        else
            if config.MaxCooldown > 0 then
                damage = 11
            elseif perilBoulderSpecialItemDamageMap[itemID] then
                damage = perilBoulderSpecialItemDamageMap[itemID]
            elseif not REVEL.GetData(player).PerilSpawnedSandBoulder then
                damage = 11
                REVEL.GetData(player).PerilSpawnedSandBoulder = true
            end
        end

        REVEL.GetData(player).PerilNextBoulderTime = player.FrameCount + 30

        if damage > 0 then
            local randomEnemy = REVEL.getRandomEnemy(true, true)
            if randomEnemy then
                local boulder = Isaac.Spawn(REVEL.ENT.SAND_BOULDER.id, REVEL.ENT.SAND_BOULDER.variant, 0, randomEnemy.Position, Vector.Zero, player)
                boulder:GetSprite():Play("Crush", true)
                REVEL.GetData(boulder).IsCrushingBoulder = damage
            end
        end
    end
end)

end