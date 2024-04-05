local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

------------------
-- NOT A BULLET --
------------------

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, cacheflag)
    if REVEL.ITEM.NOT_A_BULLET:PlayerHasCollectible(player) then
        if cacheflag == CacheFlag.CACHE_SHOTSPEED then
            player.ShotSpeed = player.ShotSpeed + (0.2 * player:GetCollectibleNum(REVEL.ITEM.NOT_A_BULLET.id))
        elseif cacheflag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage + math.max(0.5, (player.ShotSpeed*0.6)-0.2)
        end
    end
end)

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
    if REVEL.ITEM.NOT_A_BULLET:PlayerHasCollectible(player) then
        local data = REVEL.GetData(player)
        if not data.NotABulletPrevShotSpeed or data.NotABulletPrevShotSpeed ~= player.ShotSpeed then
            data.NotABulletPrevShotSpeed = player.ShotSpeed
            player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
            player:EvaluateItems()
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.ON_TEAR, 0, function(e, data, spr, player)
    if REVEL.ITEM.NOT_A_BULLET:PlayerHasCollectible(player) then
        if e.Variant == TearVariant.BLUE then
            e:ChangeVariant(TearVariant.BLOOD)
        end
        local pos_dif = e.Position - player.Position
        if math.abs(pos_dif.X) > math.abs(pos_dif.Y) then
            e.Position = Vector(e.Position.X, player.Position.Y)
        else
            e.Position = Vector(player.Position.X, e.Position.Y)
        end
        
        if not REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) then
            local eff = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 1, e.Position, Vector.Zero, e)
            if math.abs(pos_dif.Y) > math.abs(pos_dif.X) and pos_dif.Y > 3 then
                eff:GetSprite().Offset = Vector(0, -30)
            else
                eff:GetSprite().Offset = Vector(0, -25)
            end
        end
    end
end)

end