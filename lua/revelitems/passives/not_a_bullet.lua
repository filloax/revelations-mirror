local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

------------------
-- NOT A BULLET --
------------------

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, cacheflag)
    if REVEL.ITEM.NOT_A_BULLET:PlayerHasCollectible(player) then
        if cacheflag == CacheFlag.CACHE_SHOTSPEED then
            player.ShotSpeed = player.ShotSpeed + (0.5 * player:GetCollectibleNum(REVEL.ITEM.NOT_A_BULLET.id))
        elseif cacheflag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage * math.max(player.ShotSpeed * 0.85, 1)
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    if REVEL.ITEM.NOT_A_BULLET:PlayerHasCollectible(player) then
        local data = player:GetData()
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

REVEL.PcallWorkaroundBreakFunction()