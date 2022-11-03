REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-----------------
-- BRAINFREEZE --
-----------------
local function brainfreeze_NpcUpdate(_, npc)
    if npc.Variant == REVEL.ENT.BRAINFREEZE.variant then

        npc.SplatColor = REVEL.WaterSplatColor
        local player = npc:GetPlayerTarget()
        npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
        npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
        --log(player.Position:Distance(npc.Position))

        if npc.FrameCount <= 5 or npc:GetSprite():IsFinished("Freeze End") then
            if npc.FrameCount <= 2 then
                npc:GetData().AuraOn = 0
                npc:GetData().freezeTimer = math.random(40,70)
            end
            npc.State = NpcState.STATE_MOVE
            npc.StateFrame = 0
        elseif npc:GetSprite():IsFinished("Freeze Start") then
            npc.State = NpcState.STATE_ATTACK2
            npc:GetData().FreezeFrame = 0
        end

        if npc.State == NpcState.STATE_MOVE then
            if not npc:GetSprite():IsPlaying("Idle") then
                npc:GetSprite():Play("Idle", true)
            end

            if not REVEL.IsUsingPathMap(REVEL.GenericFlyingChaserPathMap, npc) then
                REVEL.UsePathMap(REVEL.GenericFlyingChaserPathMap, npc)
            end
            npc:GetData().UsePlayerFlyingMap = true
            if npc:GetData().Path then
                REVEL.FollowPath(npc, 0.6, npc:GetData().Path, true, 0.7, false, true)
            end
            
            npc.StateFrame = npc.StateFrame + 1
            if npc.StateFrame >= npc:GetData().freezeTimer then
                npc.State = NpcState.STATE_ATTACK
                npc.Velocity = Vector.Zero
                npc:GetData().freezeTimer = math.random(40,70)
            end

        elseif npc.State == NpcState.STATE_ATTACK then
            if not npc:GetSprite():IsPlaying("Freeze Start") then
                npc:GetSprite():Play("Freeze Start", true)
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.BRAINFREEZE.CHARGE, 1, 0, false, 1)
            end
            npc.Velocity = npc.Velocity * 0.7

        elseif npc.State == NpcState.STATE_ATTACK2 then
            if not npc:GetSprite():IsPlaying("Freeze Loop") then
                npc:GetSprite():Play("Freeze Loop", true)
            end
            npc.Velocity = npc.Velocity * 0.7
            npc:GetData().FreezeFrame = npc:GetData().FreezeFrame + 1
            if npc:GetData().FreezeFrame == 100 then
                npc.State = NpcState.STATE_ATTACK3
            end

        elseif npc.State == NpcState.STATE_ATTACK3 then
            if not npc:GetSprite():IsPlaying("Freeze End") then
                npc:GetSprite():Play("Freeze End", true)
            end
        end

        local data = npc:GetData()
        if data.Aura then
            REVEL.FreezeAura(npc:GetData().Aura, true)
        end

        if npc:GetSprite():IsEventTriggered("Effect") then
            local aura = REVEL.SpawnFreezeAura(114, npc.Position, npc)
            data.Aura = aura
        elseif npc:GetSprite():IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.BRAINFREEZE.ATTACK, 1, 0, false, 1)
            REVEL.ShootAura(data.Aura, player, npc)
            -- data.Aura:Remove()
            data.Aura = nil
        end
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, brainfreeze_NpcUpdate, REVEL.ENT.BRAINFREEZE.id)

REVEL.AddDeathEventsCallback(function(npc)
    local data = npc:GetData()
    if data.Aura then
        data.Aura:Remove()
        data.Aura = nil
    end
    REVEL.sfx:NpcPlay(npc, REVEL.SFX.BRAINFREEZE.DEAD, 1, 0, false, 1)
end,
function (npc, triggeredEventThisFrame)
    local sprite, data = npc:GetSprite(), npc:GetData()
    if sprite:IsFinished("Death") and not triggeredEventThisFrame then
        npc:Kill()
        npc:BloodExplode()
        return true
    end
end, REVEL.ENT.BRAINFREEZE.id, REVEL.ENT.BRAINFREEZE.variant)

end

REVEL.PcallWorkaroundBreakFunction()