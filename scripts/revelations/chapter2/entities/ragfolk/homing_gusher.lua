local ShrineTypes = require "scripts.revelations.common.enums.ShrineTypes"
return function()

-------------------
-- HOMING GUSHER --
-------------------

local function homingGusher_NpcUpdate(_, npc)
    if npc.Variant == REVEL.ENT.RAG_GUSHER.variant then
        local data, sprite = REVEL.GetData(npc), npc:GetSprite()

        if data.Init == nil then
            npc.SplatColor = REVEL.PurpleRagSplatColor
            data.GushTimer = math.random(45, 55)

            sprite:ReplaceSpritesheet(0, "gfx/monsters/revel2/rag_gusher/rag_gusher_buffed.png")
            sprite:LoadGraphics()
            
            data.Init = 1
        end

        if not sprite:IsOverlayPlaying("Blood") then
            sprite:PlayOverlay("Blood", true)
        end

        npc.StateFrame = npc.StateFrame + 1

        if npc.StateFrame >= data.GushTimer then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
            local p = Isaac.Spawn(9, 0, 0, npc.Position, ( npc.Velocity * 2 ), npc)
            p:ToProjectile().Height = -15
            p:ToProjectile().FallingSpeed = -10
            p:ToProjectile().FallingAccel = 0.5

            p:ToProjectile():AddProjectileFlags(ProjectileFlags.SMART)

            data.GushTimer = math.random(45, 55)

            npc.StateFrame = 0
        end

        if data.Buffed and npc.FrameCount > 135 then
            local gaper = Isaac.Spawn(REVEL.ENT.RAG_GAPER.id, REVEL.ENT.RAG_GAPER.variant, 0, npc.Position, Vector.Zero, npc)
            gaper.HitPoints = npc.HitPoints
            gaper:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            REVEL.GetData(gaper).Buffed = true
            REVEL.GetData(gaper).RearedHead = true
            gaper:GetSprite():Play("Regen", true)
            REVEL.GetData(gaper).State = "Regen"
            REVEL.GetData(gaper).Necragmancer = data.Necragmancer
            if data.Anima then
                REVEL.GetData(gaper).Anima = data.Anima
                REVEL.GetData(data.Anima).targ = gaper
            end
            npc:Remove()
        elseif npc:IsDead() and data.Buffed and REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) and math.random(1, 5) == 1 then
            REVEL.SpawnRevivalRag(nil, REVEL.ENT.RAG_GAPER.id, REVEL.ENT.RAG_GAPER.variant, 0, npc.Position)
        end
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, homingGusher_NpcUpdate, REVEL.ENT.RAG_GUSHER.id)

end