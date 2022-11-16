local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
--------------------
-- SCRATCHED SACK --
--------------------


local roomClearCountdown = nil
local doRewardDupe = false
revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if doRewardDupe and REVEL.room:IsClear() then
        if not roomClearCountdown then
            roomClearCountdown = 5
        end
        roomClearCountdown = roomClearCountdown - 1
        if roomClearCountdown > 0 then
            for _, pickup in ipairs(REVEL.roomPickups) do
                if pickup.FrameCount <= 1 then
                    local variant = pickup.Variant
                    if variant ~= PickupVariant.PICKUP_COLLECTIBLE and variant ~= PickupVariant.PICKUP_SHOPITEM and variant ~= PickupVariant.PICKUP_BIGCHEST and variant ~= PickupVariant.PICKUP_TROPHY and variant ~= PickupVariant.PICKUP_BED then
                        local subType = pickup.SubType
                        if variant == PickupVariant.PICKUP_TRINKET then
                            subType = REVEL.pool:GetTrinket()
                        end
                        local freePos = REVEL.room:FindFreePickupSpawnPosition(pickup.Position, 0, true)
                        Isaac.Spawn(pickup.Type, variant, subType, freePos, Vector.Zero, nil)
                        doRewardDupe = false
                        roomClearCountdown = nil
                    end
                end
            end
        else
            doRewardDupe = false
            roomClearCountdown = nil
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    roomClearCountdown = nil
    for i, player in ipairs(REVEL.players) do
        if player:HasTrinket(REVEL.ITEM.SCRATCHED_SACK.id) then
            if not REVEL.room:IsClear() then
                local percentChance = 20
                percentChance = percentChance + (player.Luck * 2)
                if percentChance > 50 then percentChance = 50 end
                if percentChance < 10 then percentChance = 10 end
                if math.random(1,100) <= percentChance then
                    doRewardDupe = true
                end
            end
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, function(entity, amount, flags, source)
    local player = entity:ToPlayer()
    if player:HasTrinket(REVEL.ITEM.SCRATCHED_SACK.id) then
        doRewardDupe = false
    end
end, EntityType.ENTITY_PLAYER)

end