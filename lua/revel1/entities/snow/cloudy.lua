return function()

------------
-- CLOUDY --
------------
local function cloudy_NpcUpdate(_, npc)
    if npc.Variant == REVEL.ENT.CLOUDY.variant then

        npc.SplatColor = REVEL.SnowSplatColor
        local player = npc:GetPlayerTarget()

        if (player.Position - npc.Position).X > 0 then -- Left
            npc:GetSprite().FlipX = false
        else
            npc:GetSprite().FlipX = true
        end

        if npc.FrameCount <= 5 or npc:GetSprite():IsFinished("Attack") then
            npc.State = NpcState.STATE_MOVE
            npc.StateFrame = 0
        end

        if npc.State == NpcState.STATE_MOVE then
            local data = npc:GetData()

            REVEL.UsePathMap(REVEL.GenericFlyingChaserPathMap, npc)
            
            if not npc:GetSprite():IsPlaying("Idle") then
                npc:GetSprite():Play("Idle", true)
            end

            if data.Path then
                REVEL.FollowPath(npc, 0.7, data.Path, true, 0.7, false, true)
            end
            npc.StateFrame = npc.StateFrame + 1
            if npc.StateFrame == 75 then
                npc.State = NpcState.STATE_ATTACK
            end
        elseif npc.State == NpcState.STATE_ATTACK then
            if not npc:GetSprite():IsPlaying("Attack") then
                npc:GetSprite():Play("Attack", true)
            end
        end

        if npc:GetSprite():IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WHEEZY_COUGH, 1, 0, false, 1)
            for i=1, 4 do
                local p = Isaac.Spawn(9, 0, 0, npc.Position, Vector.FromAngle(-45+(90*i)):Resized(4), npc):ToProjectile()
                p:GetData().PlayerTarget = player
                p:AddProjectileFlags(ProjectileFlags.CURVE_LEFT)
                p:GetData().CloudyBullet = true
                p:GetData().RedirectTimer = 35
                p.Parent = npc
            end
        end
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, cloudy_NpcUpdate, REVEL.ENT.CLOUDY.id)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
    if pro.SpawnerType == REVEL.ENT.CLOUDY.id and pro.SpawnerVariant == REVEL.ENT.CLOUDY.variant
    and pro:GetData().CloudyBullet then
        local data = pro:GetData()
        data.RedirectTimer = data.RedirectTimer or 35
        data.RedirectTimer = data.RedirectTimer - 1
        if data.RedirectTimer >= 0 then
            if data.RedirectTimer == 0 then
                local player = pro:GetData().PlayerTarget
                if player then
                    pro.Velocity = (player.Position - pro.Position):Resized(8)
                end
                REVEL.sfx:Play(SoundEffect.SOUND_BLOODSHOOT, 0.6, 0, false, 0.98 + math.random() * 0.04)
                pro.ProjectileFlags = pro.ProjectileFlags - ProjectileFlags.CURVE_LEFT
                pro.FallingSpeed = -1

                local proj2 = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, pro.Position + pro.Velocity, Vector.Zero, pro):ToProjectile()
                proj2:SetColor(REVEL.WaterSplatColor, -1, 1, false, false)
                proj2:Die()
            else
                pro.FallingAccel = 0
                pro.FallingSpeed = -0.01
            end

            data.RedirectTimer = data.RedirectTimer - 1
        end
    end
end)

end