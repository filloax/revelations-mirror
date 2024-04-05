local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()
------------------
-- SPARE CHANGE --
------------------

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    if REVEL.room:IsFirstVisit() then
        for _, player in ipairs(REVEL.players) do
            if player:HasTrinket(REVEL.ITEM.SPARE_CHANGE.id) then
                if REVEL.room:GetType() == RoomType.ROOM_DEVIL then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, 3, Isaac.GetFreeNearPosition(player.Position, 50), Vector.Zero, nil)
                elseif REVEL.room:GetType() == RoomType.ROOM_SHOP then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 2, Isaac.GetFreeNearPosition(player.Position, 50), Vector.Zero, nil)
                elseif REVEL.room:GetType() == RoomType.ROOM_ARCADE then
                    for i=1, 3 do Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 1, Isaac.GetFreeNearPosition(player.Position, 50), Vector.Zero, nil) end
                end
            end
        end
    end
end)

end