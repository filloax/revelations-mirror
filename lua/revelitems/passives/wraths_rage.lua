local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
-----------------
-- WRATHS RAGE --
-----------------

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    for _, player in ipairs(REVEL.players) do
        player:GetData().WrathsRageDmgUp = 0
        player:GetData().TimesUsedWrathsRage = 0
        player:GetData().WrathsRageSBScale = 0
        player:GetData().NumRDWRBombs = 0
        player:GetData().WrathsRageFireTrails = {}
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
    local player = bomb:GetData().__player
    if not bomb.IsFetus 
    and bomb.Variant ~= BombVariant.BOMB_THROWABLE 
    and player 
    and REVEL.ITEM.WRATHS_RAGE:PlayerHasCollectible(player) then
        bomb.Visible = false
        bomb:ToBomb().ExplosionDamage = 10 + player:GetData().WrathsRageSBScale / 2
        bomb:ToBomb().RadiusMultiplier = 1 + player:GetData().WrathsRageSBScale / 80
        bomb:ToBomb():SetExplosionCountdown(0)
        bomb:GetData().WRInstaBomb = true

        if player:HasCollectible(
            CollectibleType.COLLECTIBLE_REMOTE_DETONATOR) then
            bomb.Visible = true
            player:GetData().NumRDWRBombs =
                player:GetData().NumRDWRBombs + 1
        else
            --[[local had_holymantle = player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
        if had_holymantle then
        player:GetEffects():RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
        end
        player:GetData().WRHadHolyMantle = had_holymantle]]

            player:GetData().WrathsRageDmgUp =
                player:GetData().WrathsRageDmgUp + 1 /
                    (2 ^ player:GetData().TimesUsedWrathsRage)
            player.Damage = player.Damage + 1 /
                                (2 ^ player:GetData().TimesUsedWrathsRage)
            player:GetData().TimesUsedWrathsRage =
                player:GetData().TimesUsedWrathsRage + 1

            if player:GetData().TimesUsedWrathsRage == 1 then
                player:AddNullCostume(REVEL.COSTUME.WRATHS_RAGE2)
            elseif player:GetData().TimesUsedWrathsRage == 2 then
                player:TryRemoveNullCostume(REVEL.COSTUME.WRATHS_RAGE2)
                player:AddNullCostume(REVEL.COSTUME.WRATHS_RAGE3)
            elseif player:GetData().TimesUsedWrathsRage == 3 then
                player:TryRemoveNullCostume(REVEL.COSTUME.WRATHS_RAGE3)
                player:AddNullCostume(REVEL.COSTUME.WRATHS_RAGE4)
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    if REVEL.ITEM.WRATHS_RAGE:PlayerHasCollectible(player) and
        player:GetData().TimesUsedWrathsRage then
        if player:GetData().TimesUsedWrathsRage >= 3 then
            player:GetData().WrathsRageFireTrails =
                player:GetData().WrathsRageFireTrails or {}

            for i, eff in pairs(player:GetData().WrathsRageFireTrails) do
                eff:GetData().WrathsRageFireHitPoints =
                    eff:GetData().WrathsRageFireHitPoints or 45
                eff:GetData().WrathsRageFireHitPoints =
                    eff:GetData().WrathsRageFireHitPoints - 1
                for _, e in ipairs(REVEL.roomEnemies) do
                    if (e.Position - eff.Position):Length() <= e.Size + 15 then
                        e:TakeDamage(1, DamageFlag.DAMAGE_FIRE,
                                        EntityRef(eff), 0)
                    end
                end

                if eff:GetData().WrathsRageFireHitPoints <= 0 then
                    eff:Remove()
                    player:GetData().WrathsRageFireTrails[i] = nil
                else
                    eff:GetSprite().Scale = Vector(
                        eff:GetData().WrathsRageFireHitPoints / 60,
                        eff:GetData().WrathsRageFireHitPoints / 60
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
                table.insert(player:GetData().WrathsRageFireTrails, eff)
            end
        end

        if player:GetData().WrathsRageSBActivated then
            player:GetData().WrathsRageSBActivated = false
            player.SpriteScale = Vector(player.SpriteScale.X + 0.4,
                                        player.SpriteScale.Y + 0.4)
        end

        if player:GetData().WrathsRageSBScale ~= 0 then
            player:GetData().WrathsRageSBScale =
                player:GetData().WrathsRageSBScale - 1
            if (player:GetData().WrathsRageSBScale + 1) % 2 == 0 then
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
            player:GetData().WrathsRageDmgUp then
            player.Damage = player.Damage + player:GetData().WrathsRageDmgUp
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, player, dmg, flag, src, invuln) -- Spongebombs synergy
    player = player:ToPlayer()
    local srcEnt = REVEL.GetEntFromRef(src)
    if (srcEnt and srcEnt:GetData().WRInstaBomb) then
        --[[if player:GetData().WRHadHolyMantle then
    player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE, true)
end]]
        return false
    end
    if REVEL.ITEM.WRATHS_RAGE:PlayerHasCollectible(player) and
        REVEL.ITEM.SPONGE:PlayerHasCollectible(player) and src and src.Type ==
        EntityType.ENTITY_PROJECTILE then
        player:GetData().WrathsRageSBScale = 81
        player:GetData().WrathsRageSBActivated = true
        SFXManager():Play(REVEL.SFX.SPONGE_SUCK, 1, 0, false, 1)
    end
end, EntityType.ENTITY_PLAYER)

revel:AddCallback(ModCallbacks.MC_PRE_USE_ITEM,
                    function(_, itemid, rng, player, useFlags, activeSlot,
                            customVarData) -- remote detonator synergy
    if REVEL.ITEM.WRATHS_RAGE:PlayerHasCollectible(player) then
        for i = 1, player:GetData().NumRDWRBombs do
            player:GetData().WrathsRageDmgUp =
                player:GetData().WrathsRageDmgUp + 1 /
                    (2 ^ player:GetData().TimesUsedWrathsRage)
            player.Damage = player.Damage + 1 /
                                (2 ^ player:GetData().TimesUsedWrathsRage)
            player:GetData().TimesUsedWrathsRage =
                player:GetData().TimesUsedWrathsRage + 1

            if player:GetData().TimesUsedWrathsRage == 1 then
                player:AddNullCostume(REVEL.COSTUME.WRATHS_RAGE2)
            elseif player:GetData().TimesUsedWrathsRage == 2 then
                player:TryRemoveNullCostume(REVEL.COSTUME.WRATHS_RAGE2)
                player:AddNullCostume(REVEL.COSTUME.WRATHS_RAGE3)
            elseif player:GetData().TimesUsedWrathsRage == 3 then
                player:TryRemoveNullCostume(REVEL.COSTUME.WRATHS_RAGE3)
                player:AddNullCostume(REVEL.COSTUME.WRATHS_RAGE4)
            end
        end
        player:GetData().NumRDWRBombs = 0
    end
end, CollectibleType.COLLECTIBLE_REMOTE_DETONATOR)

end
