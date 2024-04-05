local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()
-----------------
-- WRATHS RAGE --
-----------------

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    for _, player in ipairs(REVEL.players) do
        REVEL.GetData(player).WrathsRageDmgUp = 0
        REVEL.GetData(player).TimesUsedWrathsRage = 0
        REVEL.GetData(player).WrathsRageSBScale = 0
        REVEL.GetData(player).NumRDWRBombs = 0
        REVEL.GetData(player).WrathsRageFireTrails = {}
        if REVEL.ITEM.WRATHS_RAGE:PlayerHasCollectible(player) then
            player:TryRemoveNullCostume(REVEL.COSTUME.WRATHS_RAGE2)
            player:TryRemoveNullCostume(REVEL.COSTUME.WRATHS_RAGE3)
            player:TryRemoveNullCostume(REVEL.COSTUME.WRATHS_RAGE4)
            player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
            player:EvaluateItems()
        end
    end
end)

REVEL.ITEM.WRATHS_RAGE:addPickupCallback(function(player)
    player:AddBombs(5)
end)

StageAPI.AddCallback("Revelations", RevCallbacks.BOMB_UPDATE_INIT, 1, function(bomb)
    local player = REVEL.GetData(bomb).__player
    if not bomb.IsFetus 
    and bomb.Variant ~= BombVariant.BOMB_THROWABLE 
    and player 
    and REVEL.ITEM.WRATHS_RAGE:PlayerHasCollectible(player) then
        bomb.Visible = false
        bomb:ToBomb().ExplosionDamage = 10 + REVEL.GetData(player).WrathsRageSBScale / 2
        bomb:ToBomb().RadiusMultiplier = 1 + REVEL.GetData(player).WrathsRageSBScale / 80
        bomb:ToBomb():SetExplosionCountdown(0)
        REVEL.GetData(bomb).WRInstaBomb = true

        if player:HasCollectible(
            CollectibleType.COLLECTIBLE_REMOTE_DETONATOR) then
            bomb.Visible = true
            REVEL.GetData(player).NumRDWRBombs =
                REVEL.GetData(player).NumRDWRBombs + 1
        else
            --[[local had_holymantle = player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
        if had_holymantle then
        player:GetEffects():RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
        end
        REVEL.GetData(player).WRHadHolyMantle = had_holymantle]]

            REVEL.GetData(player).WrathsRageDmgUp =
                REVEL.GetData(player).WrathsRageDmgUp + 1 /
                    (2 ^ REVEL.GetData(player).TimesUsedWrathsRage)
            player.Damage = player.Damage + 1 /
                                (2 ^ REVEL.GetData(player).TimesUsedWrathsRage)
            REVEL.GetData(player).TimesUsedWrathsRage =
                REVEL.GetData(player).TimesUsedWrathsRage + 1

            if REVEL.GetData(player).TimesUsedWrathsRage == 1 then
                player:AddNullCostume(REVEL.COSTUME.WRATHS_RAGE2)
            elseif REVEL.GetData(player).TimesUsedWrathsRage == 2 then
                player:TryRemoveNullCostume(REVEL.COSTUME.WRATHS_RAGE2)
                player:AddNullCostume(REVEL.COSTUME.WRATHS_RAGE3)
            elseif REVEL.GetData(player).TimesUsedWrathsRage == 3 then
                player:TryRemoveNullCostume(REVEL.COSTUME.WRATHS_RAGE3)
                player:AddNullCostume(REVEL.COSTUME.WRATHS_RAGE4)
            end
        end
    end
end)

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
    if REVEL.ITEM.WRATHS_RAGE:PlayerHasCollectible(player) and
        REVEL.GetData(player).TimesUsedWrathsRage then
        if REVEL.GetData(player).TimesUsedWrathsRage >= 3 then
            REVEL.GetData(player).WrathsRageFireTrails =
                REVEL.GetData(player).WrathsRageFireTrails or {}

            for i, eff in pairs(REVEL.GetData(player).WrathsRageFireTrails) do
                REVEL.GetData(eff).WrathsRageFireHitPoints =
                    REVEL.GetData(eff).WrathsRageFireHitPoints or 45
                REVEL.GetData(eff).WrathsRageFireHitPoints =
                    REVEL.GetData(eff).WrathsRageFireHitPoints - 1
                for _, e in ipairs(REVEL.roomEnemies) do
                    if (e.Position - eff.Position):Length() <= e.Size + 15 then
                        e:TakeDamage(1, DamageFlag.DAMAGE_FIRE,
                                        EntityRef(eff), 0)
                    end
                end

                if REVEL.GetData(eff).WrathsRageFireHitPoints <= 0 then
                    eff:Remove()
                    REVEL.GetData(player).WrathsRageFireTrails[i] = nil
                else
                    eff:GetSprite().Scale = Vector(
                        REVEL.GetData(eff).WrathsRageFireHitPoints / 60,
                        REVEL.GetData(eff).WrathsRageFireHitPoints / 60
                    )
                end
            end

            if (player.Velocity.X ~= 0 or player.Velocity.Y ~= 0) and
                player.FrameCount % 5 == 0 then
                local eff = Isaac.Spawn(EntityType.ENTITY_EFFECT, 8, 0,
                                        player.Position, Vector.Zero, player)
                eff:GetSprite():Load("gfx/033.000_fireplace.anm2", true)
                eff:GetSprite():ReplaceSpritesheet(0,
                                                    "gfx/backdrop/none.png")
                eff:GetSprite():Play("Flickering", true)
                eff:GetSprite():LoadGraphics()
                eff:GetSprite().Scale = Vector(0.75, 0.75)
                eff:Update()
                table.insert(REVEL.GetData(player).WrathsRageFireTrails, eff)
            end
        end

        if REVEL.GetData(player).WrathsRageSBActivated then
            REVEL.GetData(player).WrathsRageSBActivated = false
            player.SpriteScale = Vector(player.SpriteScale.X + 0.4,
                                        player.SpriteScale.Y + 0.4)
        end

        if REVEL.GetData(player).WrathsRageSBScale ~= 0 then
            REVEL.GetData(player).WrathsRageSBScale =
                REVEL.GetData(player).WrathsRageSBScale - 1
            if (REVEL.GetData(player).WrathsRageSBScale + 1) % 2 == 0 then
                player.SpriteScale =
                    Vector(player.SpriteScale.X - 0.01,
                            player.SpriteScale.Y - 0.01)
            end
            if player.FrameCount % 5 == 0 then
                local c = Isaac.Spawn(1000, 54, 0, player.Position,
                                        Vector.Zero, player) -- 54 = holy water creep
                c.CollisionDamage = 0
                c:Update()
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if REVEL.ITEM.WRATHS_RAGE:PlayerHasCollectible(player) then
        if flag == CacheFlag.CACHE_DAMAGE and
            REVEL.GetData(player).WrathsRageDmgUp then
            player.Damage = player.Damage + REVEL.GetData(player).WrathsRageDmgUp
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, player, dmg, flag, src, invuln) -- Spongebombs synergy
    player = player:ToPlayer()
    local srcEnt = REVEL.GetEntFromRef(src)
    if (srcEnt and REVEL.GetData(srcEnt).WRInstaBomb) then
        --[[if REVEL.GetData(player).WRHadHolyMantle then
    player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE, true)
end]]
        return false
    end
    if REVEL.ITEM.WRATHS_RAGE:PlayerHasCollectible(player) and
        REVEL.ITEM.SPONGE:PlayerHasCollectible(player) and src and src.Type ==
        EntityType.ENTITY_PROJECTILE then
        REVEL.GetData(player).WrathsRageSBScale = 81
        REVEL.GetData(player).WrathsRageSBActivated = true
        SFXManager():Play(REVEL.SFX.SPONGE_SUCK, 1, 0, false, 1)
    end
end, EntityType.ENTITY_PLAYER)

revel:AddCallback(ModCallbacks.MC_PRE_USE_ITEM,
                    function(_, itemid, rng, player, useFlags, activeSlot,
                            customVarData) -- remote detonator synergy
    if REVEL.ITEM.WRATHS_RAGE:PlayerHasCollectible(player) then
        for i = 1, REVEL.GetData(player).NumRDWRBombs do
            REVEL.GetData(player).WrathsRageDmgUp =
                REVEL.GetData(player).WrathsRageDmgUp + 1 /
                    (2 ^ REVEL.GetData(player).TimesUsedWrathsRage)
            player.Damage = player.Damage + 1 /
                                (2 ^ REVEL.GetData(player).TimesUsedWrathsRage)
            REVEL.GetData(player).TimesUsedWrathsRage =
                REVEL.GetData(player).TimesUsedWrathsRage + 1

            if REVEL.GetData(player).TimesUsedWrathsRage == 1 then
                player:AddNullCostume(REVEL.COSTUME.WRATHS_RAGE2)
            elseif REVEL.GetData(player).TimesUsedWrathsRage == 2 then
                player:TryRemoveNullCostume(REVEL.COSTUME.WRATHS_RAGE2)
                player:AddNullCostume(REVEL.COSTUME.WRATHS_RAGE3)
            elseif REVEL.GetData(player).TimesUsedWrathsRage == 3 then
                player:TryRemoveNullCostume(REVEL.COSTUME.WRATHS_RAGE3)
                player:AddNullCostume(REVEL.COSTUME.WRATHS_RAGE4)
            end
        end
        REVEL.GetData(player).NumRDWRBombs = 0
    end
end, CollectibleType.COLLECTIBLE_REMOTE_DETONATOR)

end
