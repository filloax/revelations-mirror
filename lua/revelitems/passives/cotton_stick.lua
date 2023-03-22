local RevCallbacks = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
----------------
-- THE TAMPON -- (now COTTON STICK)
----------------

--[[
Clean up creep when you go on it, except ice creep, and gain a tear delay decrease for 1 second when you do.
]]

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if player:GetData().CottonCounter and flag == CacheFlag.CACHE_FIREDELAY then
        player.MaxFireDelay = math.max(player.MaxFireDelay - 2, 1)
    end
end)

-- PLAYER DAMAGE
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, dmg, flag, src, invuln)
    e = e:ToPlayer()
    if HasBit(flag, DamageFlag.DAMAGE_ACID) 
    and REVEL.ITEM.TAMPON:PlayerHasCollectible(e) then 
        return false 
    end
end, 1)

local cottonColor = Color(1, 1, 1, 1, conv255ToFloat(40, 30, 0))

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
    if REVEL.ITEM.TAMPON:PlayerHasCollectible(player) then
        local data = player:GetData()
        local prevCounter = data.CottonCounter

        for i, c in ipairs(REVEL.roomEffects) do
            local cdata = c:GetData()
            if c.Variant >= 22 and c.Variant <= 26 and not cdata.cleaned and
                player.Position:DistanceSquared(c.Position) <=
                (c.Size + player.Size) ^ 2 and
                not (c.Parent and c.Parent.Type == 1) then
                c:Die()
                cdata.cleaned = true
                data.CottonCounter = 150
            end
        end

        if data.CottonCounter and not prevCounter then
            player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
            player:EvaluateItems()
            player:SetColor(cottonColor, 5, 5, true, true)
        end

        if data.CottonCounter then
            data.CottonCounter = data.CottonCounter - 1
            if data.CottonCounter <= 0 then
                data.CottonCounter = nil
            end
            player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
            player:EvaluateItems()
        end
    end
end)

end
