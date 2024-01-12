local RevCallbacks = require("lua.revelcommon.enums.RevCallbacks")

return function()
----------------
-- Death Mask --
----------------
local deathMaskJustKilled
revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, e)
    if e:IsActiveEnemy(true) and not e:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) and not e:GetData().__manuallyRemoved and REVEL.OnePlayerHasCollectible(REVEL.ITEM.DEATH_MASK.id) and not deathMaskJustKilled then
        revel.data.run.deathmaskCharge = revel.data.run.deathmaskCharge + 1
    end
end)

local deathMaskBonuses = {
    CollectibleType.COLLECTIBLE_DEATHS_TOUCH,
    CollectibleType.COLLECTIBLE_DEATH_LIST,
    CollectibleType.COLLECTIBLE_BOOK_OF_THE_DEAD,
    CollectibleType.COLLECTIBLE_BOOK_OF_THE_DEAD --counts twice so it removes 2
}

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
    if REVEL.ITEM.DEATH_MASK:PlayerHasCollectible(player) then
        local neededCharge = 10
        for _, coll in ipairs(deathMaskBonuses) do
            if player:HasCollectible(coll) then
                neededCharge = neededCharge - 1
            end
        end

        if revel.data.run.deathmaskCharge >= neededCharge then
            local validEnemies = {}
            for _, enemy in ipairs(REVEL.roomEnemies) do
                if enemy:IsActiveEnemy(false) and enemy:IsVulnerableEnemy() and not enemy:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) and not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and not enemy:IsBoss() then
                    validEnemies[#validEnemies + 1] = enemy
                end
            end

            if #validEnemies > 0 then
                local kill = validEnemies[math.random(1, #validEnemies)]
                deathMaskJustKilled = true
                REVEL.SpawnDecoration(kill.Position, Vector.Zero, "Shock", "gfx/itemeffects/revelcommon/death_mask_lightning.anm2", nil, -1000)
                REVEL.sfx:Play(REVEL.SFX.BUFF_LIGHTNING, 1, 0, false, 1)
                local friendBony = Isaac.Spawn(EntityType.ENTITY_BONY, 0, 0, kill.Position, Vector.Zero, player)
                friendBony:AddCharmed(EntityRef(player), -1)
                local data = friendBony:GetData()
                data.IsDeathMaskBony = true
                local sprite = friendBony:GetSprite()
                sprite:ReplaceSpritesheet(0, "gfx/familiar/revelcommon/death_mask_bony_body.png")
                sprite:ReplaceSpritesheet(1, "gfx/familiar/revelcommon/death_mask_bony_head.png")
                sprite:LoadGraphics()
                kill:Kill()
                deathMaskJustKilled = nil
                revel.data.run.deathmaskCharge = 0
            end
        end
    end
end)

--book of the dead synergy
revel:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemID, itemRNG, player, useFlags, activeSlot, customVarData)
    if REVEL.ITEM.DEATH_MASK:PlayerHasCollectible(player) then
        for _, bony in ipairs(Isaac.FindByType(EntityType.ENTITY_BONY, 0, -1, false, false)) do
            if bony.FrameCount <= 2 and bony:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                local data = bony:GetData()
                data.IsDeathMaskBony = true
                local sprite = bony:GetSprite()
                sprite:ReplaceSpritesheet(0, "gfx/familiar/revelcommon/death_mask_bony_body.png")
                sprite:ReplaceSpritesheet(1, "gfx/familiar/revelcommon/death_mask_bony_head.png")
                sprite:LoadGraphics()
            end
        end
        for _, bone in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BONE_ORBITAL, -1, false, false)) do
            if bone.FrameCount <= 2 then
                local sprite = bone:GetSprite()
                sprite:ReplaceSpritesheet(0, "gfx/familiar/revelcommon/death_mask_bookofthedead.png")
                sprite:LoadGraphics()
                bone.CollisionDamage = bone.CollisionDamage * 1.5
            end
        end
    end
end, CollectibleType.COLLECTIBLE_BOOK_OF_THE_DEAD)

--bony projectiles
revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, function(_, pro)
    if pro.Variant == ProjectileVariant.PROJECTILE_BONE and pro.SpawnerType == EntityType.ENTITY_BONY and pro.SpawnerVariant == 0 then
        local closeEnemy = REVEL.getClosestEnemy(pro, false, false, false, false)
        if closeEnemy and closeEnemy:GetData().IsDeathMaskBony then
            local data = pro:GetData()
            data.IsDeathMaskBone = true
            local sprite = pro:GetSprite()
            sprite:ReplaceSpritesheet(0, "gfx/familiar/revelcommon/death_mask_bony_projectile.png")
            sprite:LoadGraphics()
            pro:Update()
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, ent)
    if ent.Variant == ProjectileVariant.PROJECTILE_BONE then
        local data = ent:GetData()
        if data.IsDeathMaskBone then
            for _, eff in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.TOOTH_PARTICLE, -1, false, false)) do
                if eff.Position:Distance(ent.Position) < 5 and eff.FrameCount <= 1 then
                    local effSprite = eff:GetSprite()
                    effSprite:ReplaceSpritesheet(0, "gfx/familiar/revelcommon/death_mask_bony_projectile_gibs.png")
                    effSprite:LoadGraphics()
                end
            end
        end
    end
end, EntityType.ENTITY_PROJECTILE)

end