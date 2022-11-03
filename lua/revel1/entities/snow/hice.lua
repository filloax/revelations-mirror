REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
    
----------
-- HICE --
----------
local function hiceUpdate(_, npc)
    if npc.Variant == REVEL.ENT.HICE.variant then
        npc.SplatColor = REVEL.SnowSplatColor

        local sprite = npc:GetSprite()
        if npc:GetSprite():IsOverlayPlaying("HeadAttack") and sprite:GetOverlayFrame() == 4 then -- as sprite:IsOverlayEventTriggered() doesn't exist
            local fl = Isaac.Spawn(REVEL.ENT.SNOW_FLAKE.id, REVEL.ENT.SNOW_FLAKE.variant, 0, npc.Position, Vector.Zero, npc)
            fl:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            fl:GetData().CurrentMoveSpeed = 0.5
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WHEEZY_COUGH, 1, 0, false, 1)
        end
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, hiceUpdate, REVEL.ENT.HICE.id)

revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN , function(_, entityType, variant, subtype, pos, vel, spawner, seed)
    if spawner and spawner.Type == REVEL.ENT.HICE.id and spawner.Variant == REVEL.ENT.HICE.variant
    and (entityType == 18 or entityType == 13 or entityType == 14) then
        return {
            StageAPI.E.DeleteMeNPC.T,
            StageAPI.E.DeleteMeNPC.V,
            0,
            seed
        }
    end
end)

end

REVEL.PcallWorkaroundBreakFunction()