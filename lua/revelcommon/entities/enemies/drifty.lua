local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
------------
-- DRIFTY --
------------

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant == REVEL.ENT.DRIFTY.variant or npc.Variant == REVEL.ENT.PUCKER.variant then
        npc.Velocity = npc.Velocity * 0.95

        if npc:GetSprite():IsFinished("Appear") or npc:GetSprite():IsFinished("ShootUp") or npc:GetSprite():IsFinished("ShootDown") then
            local dchance = math.random(1, 4)
            if dchance == 1 then
                npc.State = 8
            elseif dchance == 2 then
                npc.State = 9
            elseif dchance == 3 then
                npc.State = 10
            elseif dchance == 4 then
                npc.State = 11
            end
        end

        if npc.State == 8 or npc.State == 9 then
            if not npc:GetSprite():IsPlaying("ShootUp") then
                npc:GetSprite():Play("ShootUp", true)
            end
            if npc.State == 8 then -- Southwest
                npc:GetSprite().FlipX = false
            elseif npc.State == 9 then -- Southeast
                npc:GetSprite().FlipX = true
            end
            elseif npc.State == 10 or npc.State == 11 then
            if not npc:GetSprite():IsPlaying("ShootDown") then
                npc:GetSprite():Play("ShootDown", true)
            end
            if npc.State == 10 then -- Northwest
                npc:GetSprite().FlipX = false
            elseif npc.State == 11 then -- Northeast
                npc:GetSprite().FlipX = true
            end
        end

        if npc:GetSprite():IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_LITTLE_SPIT, 1, 0, false, 1)
            if npc.State == 8 then
                npc.Velocity = Vector.FromAngle(1*315):Resized(8)
                Isaac.Spawn(9, 0, 0, npc.Position, Vector.FromAngle(1*135):Resized(8), npc)
            elseif npc.State == 9 then
                npc.Velocity = Vector.FromAngle(1*225):Resized(8)
                Isaac.Spawn(9, 0, 0, npc.Position, Vector.FromAngle(1*45):Resized(8), npc)
            elseif npc.State == 10 then
                npc.Velocity = Vector.FromAngle(1*45):Resized(8)
                Isaac.Spawn(9, 0, 0, npc.Position, Vector.FromAngle(1*225):Resized(8), npc)
            elseif npc.State == 11 then
                npc.Velocity = Vector.FromAngle(1*135):Resized(8)
                Isaac.Spawn(9, 0, 0, npc.Position, Vector.FromAngle(1*315):Resized(8), npc)
            end
        end
    end
end, REVEL.ENT.DRIFTY.id)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
    if pro.SpawnerType == REVEL.ENT.DRIFTY.id and (pro.SpawnerVariant == REVEL.ENT.DRIFTY.variant or pro.SpawnerVariant == REVEL.ENT.PUCKER.variant) then
        local DriftyInitSpeed  = pro.Velocity
        pro.Velocity = DriftyInitSpeed * 0.90
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.PROJECTILE_UPDATE_INIT, 1, function(pro)
    if pro.SpawnerType == REVEL.ENT.DRIFTY.id and (pro.SpawnerVariant == REVEL.ENT.DRIFTY.variant or pro.SpawnerVariant == REVEL.ENT.PUCKER.variant) then
        pro.FallingSpeed = 10 * -1
    end
end)


end