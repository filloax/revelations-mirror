REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
----------------
-- MOXIES PAW --
----------------

-- REVEL.AddCustomBar(REVEL.ITEM.MOXIE.id, 110)

revel:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemID, itemRNG, player, useFlags, activeSlot, customVarData)
    local data = player:GetData()
    data.swipe1 = REVEL.SpawnDecoration(player.Position, player.Velocity, "SwipeBelow", "gfx/itemeffects/revelcommon/moxies_paw_swipe.anm2", player)
    data.swipe1.Visible = false
    data.swipe2 = REVEL.SpawnDecoration(player.Position, player.Velocity, "SwipeAbove", "gfx/itemeffects/revelcommon/moxies_paw_swipe.anm2", player)
    data.swipe2.DepthOffset = -50

    REVEL.sfx:Play(SoundEffect.SOUND_SWORD_SPIN)

    local closeEnms = Isaac.FindInRadius(player.Position, 80, EntityPartition.ENEMY)
    for i,e in ipairs(closeEnms) do
        -- REVEL.PushEnt(e, 18, (e.Position - player.Position):Rotated(90), 13, player)
        REVEL.PushEnt(e, 18, (e.Position - player.Position), 13, player)
        e:TakeDamage(player.Damage*2, 0, EntityRef(player), 3)
        REVEL.sfx:Play(SoundEffect.SOUND_WHIP_HIT)

        if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
            player:AddWisp(REVEL.ITEM.MOXIE.id, player.Position)
        end
    end

    local closeProjs = Isaac.FindInRadius(player.Position, 70, EntityPartition.BULLET)
    for i,e in ipairs(closeProjs) do
        ---@type EntityProjectile
        e = e:ToProjectile()
        local l = e.Velocity:Length()
        e.Velocity = (e.Position - player.Position):Resized(l*1.5)
        e.Parent = player
        e.CollisionDamage = e.CollisionDamage*1.5
        e.SpawnerEntity = player
        e:AddProjectileFlags(BitOr(ProjectileFlags.CANT_HIT_PLAYER , ProjectileFlags.ANY_HEIGHT_ENTITY_HIT, ProjectileFlags.HIT_ENEMIES))
    end

    return true
end, REVEL.ITEM.MOXIE.id)

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function(_, p, renderOffset)
    local data = p:GetData()
    if data.swipe2 and data.swipe2:Exists() then
        data.swipe1:GetSprite():Render(Isaac.WorldToScreen(p.Position) + p.SpriteOffset + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
    end
end)


end

REVEL.PcallWorkaroundBreakFunction()