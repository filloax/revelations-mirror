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
            fl:GetData().CurrentMoveSpeed = 0.7
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WHEEZY_COUGH, 1, 0, false, 1)
        end
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, hiceUpdate, REVEL.ENT.HICE.id)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, npc)
    if not REVEL.ENT.HICE:isEnt(npc) then return end

    for i = 1, 2 do
        local fl = Isaac.Spawn(REVEL.ENT.SNOW_FLAKE.id, REVEL.ENT.SNOW_FLAKE.variant, 0, npc.Position, RandomVector() * 6.5, npc)
        fl:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        fl:GetData().CurrentMoveSpeed = math.random(4,10) * 0.1
    end
end, REVEL.ENT.HICE.id)

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