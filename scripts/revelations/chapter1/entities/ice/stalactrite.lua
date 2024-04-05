return function()

-----------------
-- STALACTRITE --
-----------------
local TriggeredByDistance = false
local TriggeredByExplosions = true

local function stalactrite_NpcUpdate(_, npc)
    if npc.Variant == REVEL.ENT.STALACTRITE.variant then

        -- Locals
        local data, sprite, player = REVEL.GetData(npc), npc:GetSprite(), npc:GetPlayerTarget()

        -- Initialization
        if data.Init == nil then
            npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
            npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            npc.SplatColor = REVEL.WaterSplatColor
            data.Invulnerable = true
            data.State = "ShadowIdle"
            data.Init = true
        end

        -- Animation ending triggers
        if sprite:IsFinished("JumpDown") then
            data.State = nil
            npc:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
            npc:ClearEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
            npc:Morph(EntityType.ENTITY_HOPPER, 1, 0, -1) -- Morph into a Trite
            npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            REVEL.ForceReplacement(npc, "Glacier")
        end

        REVEL.ApplyKnockbackImmunity(npc)

        -- AI States
        if data.State == "ShadowIdle" then
            local fall = TriggeredByDistance and player.Position:Distance(npc.Position) <= 50

            if not fall and TriggeredByExplosions then
                fall = (Isaac.CountEntities(nil, 1000, EffectVariant.BOMB_EXPLOSION, -1) or 0) > 0
            end

            if fall or data.StalactriteTriggered then
                StageAPI.RemovePersistentEntity(npc)
                data.State = "JumpDown"

                if REVEL.WasRoomClearFromStart() then
                    data.KeepDoorsClosed = true
                    if not REVEL.GlacierDoorCloseDoneThisRoom then
                        REVEL.room:SetClear(false)
                        REVEL.ShutDoors()
                        REVEL.GlacierDoorCloseDoneThisRoom = true
                    end
                end
            end
        end

        if data.KeepDoorsClosed then
            REVEL.room:KeepDoorsClosed()
        end

        -- Event triggers
        if sprite:IsEventTriggered("Land") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEATY_DEATHS, 1, 0, false, 1)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        elseif sprite:IsEventTriggered("Break") then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.MINT_GUM_BREAK, 1, 0, false, 1)
            data.Invulnerable = false
        end

        -- Animation
        if data.State ~= nil then
            if not sprite:IsPlaying(data.State) then
                sprite:Play(data.State, true)
            end
        end
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, stalactrite_NpcUpdate, REVEL.ENT.STALACTRITE.id)

local function stalactrite_Stalactrite_EntTakeDmg(_, ent, dmg, flag, source, frames)
    if ent.Variant == REVEL.ENT.STALACTRITE.variant and REVEL.GetData(ent).Invulnerable == true then
        return false
    end
end
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, stalactrite_Stalactrite_EntTakeDmg, REVEL.ENT.STALACTRITE.id)


end