return function()

--Shy Fly
-- alt of boom fly

local radius = 60

local RemoveShyFlyProjectiles

revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
    if not REVEL.ENT.SHY_FLY:isEnt(npc) then return end
    local sprite = npc:GetSprite()
    if sprite:IsFinished("Appear") then
        npc.Velocity = Vector.FromAngle(45 + math.random(0,3)*90)
    end
end, REVEL.ENT.SHY_FLY.id)

-- NPC data is wonky in death post NPC render, so
-- handle it separately
---@type table<integer, table>
local DeathData = {}

---@param npc EntityNPC
revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if not REVEL.ENT.SHY_FLY:isEnt(npc) or not REVEL.IsRenderPassNormal() then return end

    local sprite = npc:GetSprite()
    local deathData = DeathData[GetPtrHash(npc)]
    if not deathData then
        deathData = {}
        DeathData[GetPtrHash(npc)] = deathData
    end

    if not deathData.Exploded and sprite:IsEventTriggered("Explode") then
        deathData.Exploded = true
        for _, player in ipairs(REVEL.players) do
            if player.EntityCollisionClass >= EntityCollisionClass.ENTCOLL_ENEMIES and player.Position:DistanceSquared(npc.Position) < radius^2 then
                player:TakeDamage(2, DamageFlag.DAMAGE_EXPLOSION, EntityRef(npc), 10)
            end
        end
        REVEL.Glacier.SnowExplosion(npc.Position, radius, 0)

        -- Spawn effect so that npc already counts as dead, and shadow doesn't show
        local effect = REVEL.ENT.DECORATION:spawn(npc.Position, Vector.Zero, nil)
        local esprite = effect:GetSprite()
        esprite:Load(sprite:GetFilename(), true)
        esprite:Play(sprite:GetAnimation(), true)
        esprite:SetFrame(sprite:GetFrame())

        --REVEL.TriggerChumBucket(npc)
        npc:Remove()
        return
    end

    if IsAnimOn(sprite, "Explode") then
        npc.Velocity = Vector.Zero
        return
    end

    if not deathData.Dying and npc:HasMortalDamage() then
        deathData.Dying = true
        npc.SplatColor = REVEL.NO_COLOR
        npc.HitPoints = 0
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        npc:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
        sprite:Play("Explode", true)
        npc:RemoveStatusEffects()
        REVEL.sfx:Play(SoundEffect.SOUND_SKIN_PULL, 0.9, 0, false, 1)
        npc.State = NpcState.STATE_UNIQUE_DEATH
    end

    if deathData.Dying and not IsAnimOn(sprite, "Explode") then
        if not deathData.Retried then
            sprite:Play("Explode", true)
            deathData.Retried = true
        end
    end
end, REVEL.ENT.SHY_FLY.id)

revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, Type, variant, subtype, pos, vel, spawner, seed)
    if RemoveShyFlyProjectiles and Type == EntityType.ENTITY_PROJECTILE and spawner and spawner.Type == REVEL.ENT.SHY_FLY.id and spawner.Variant == REVEL.ENT.SHY_FLY.variant then
        return {
            StageAPI.E.DeleteMeProjectile.T,
            StageAPI.E.DeleteMeProjectile.V,
            0,
            seed
        }
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if RemoveShyFlyProjectiles then
        RemoveShyFlyProjectiles = false
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    DeathData = {}
end)

end