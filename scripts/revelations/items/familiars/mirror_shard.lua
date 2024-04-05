return function()

------------------
-- MIRROR SHARD --
------------------

--Orbital that reflects projectiles at 2x speed, close orbit. Gives blood collision damage.

local MirrorShard = {
    orbitDist = Vector(25,20),
    bloodiedShards = {} --since EntityRefs don't support :GetData()
}

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE , function(_, player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        player:CheckFamiliar(REVEL.ENT.MIRRORSHARD.variant, REVEL.ITEM.MIRROR:GetCollectibleNum(player) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1), RNG())
        -- Isaac.DebugString(REVEL.ITEM.MIRROR:GetCollectibleNum(player))
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG , function(_,  e, dmg, flag, src, invuln)
    if src.Entity and src.Entity.Type == 3 and src.Entity.Variant == REVEL.ENT.MIRRORSHARD.variant and not e:IsBoss() then
        e:AddEntityFlags(EntityFlag.FLAG_BLEED_OUT)
        MirrorShard.bloodiedShards[src.Entity.InitSeed] = 0
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_,  fam)
    fam:AddToOrbit(0)
end, REVEL.ENT.MIRRORSHARD.variant)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_,  fam)
    fam.OrbitDistance = EntityFamiliar.GetOrbitDistance(0)
--  fam.OrbitSpeed = -fam.OrbitSpeed
    fam.Velocity = fam:GetOrbitPosition(fam.Player.Position - fam.Player.Velocity) - fam.Position

    if MirrorShard.bloodiedShards[fam.InitSeed] == 0 then
        local spr = fam:GetSprite()
        spr:ReplaceSpritesheet(0, "gfx/familiar/revelcommon/mirror_shard_bloody.png")
        spr:LoadGraphics()
        MirrorShard.bloodiedShards[fam.InitSeed] = 1
    end

    for _,e in ipairs(REVEL.roomProjectiles) do
        if not REVEL.GetData(e).MirrorReflected and e.Position:DistanceSquared(fam.Position) < (e.Size+fam.Size+2) ^ 2 then
            e = e:ToProjectile()
            REVEL.GetData(e).MirrorReflected = true

            local normal = (fam.Player.Position - fam.Position):Normalized()
            e.Velocity = e.Velocity - normal * (2 * e.Velocity:Dot(normal))

            e.Parent = fam.Player
            e.SpawnerEntity = fam.Player
            e:AddProjectileFlags(BitOr(ProjectileFlags.CANT_HIT_PLAYER, BitOr(ProjectileFlags.ANY_HEIGHT_ENTITY_HIT, ProjectileFlags.HIT_ENEMIES)))
            e:AddScale(e.Scale)

            if MirrorShard.bloodiedShards[fam.InitSeed] then
                e.CollisionDamage = e.CollisionDamage*10
                e:AddScale(e.Scale * 0.5)
                local projSprite = e:GetSprite()
                projSprite.Color = Color(2,1,1,1,conv255ToFloat(1,1,1)) * projSprite.Color

                local spr = fam:GetSprite()
                spr:ReplaceSpritesheet(0, "gfx/familiar/revelcommon/mirror_shard.png")
                spr:LoadGraphics()
                MirrorShard.bloodiedShards[fam.InitSeed] = nil
            end
        end
    end
end, REVEL.ENT.MIRRORSHARD.variant)


end