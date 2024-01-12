local ShrineTypes = require "lua.revelcommon.enums.ShrineTypes"
return function()

local Anm2GlowNull0

-- Wretcher
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.WRETCHER.variant then
        return
    end

    local data, sprite = npc:GetData(), npc:GetSprite()

    if not data.State then
        data.State = "Idle"
        data.AttackCooldown = math.random(30, 60)
        
        REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)
    end

    if data.State == "Idle" and not sprite:IsPlaying("Appear") then
        if not data.Buffed and not sprite:IsOverlayPlaying("Head") then
            sprite:PlayOverlay("Head", true)
        elseif data.Buffed and not sprite:IsOverlayPlaying("HeadBuffed") then
            sprite:PlayOverlay("HeadBuffed", true)
        end

        if data.Path then
            local speed = 0.55
            if data.Buffed then
                speed = 0.75
            end

            REVEL.FollowPath(npc, speed, data.Path, true, 0.8)
        end

        data.AttackCooldown = data.AttackCooldown - 1
        if data.AttackCooldown <= 0 then
            local cancelAttack
            if (Isaac.CountEntities(npc, REVEL.ENT.LOCUST.id, REVEL.ENT.LOCUST.variant, -1) or 0) >= 5 then
                if data.Buffed then
                    data.NoLocusts = true
                else
                    cancelAttack = true
                end
            end

            if not cancelAttack then
                data.State = "Attack"
                if not data.Buffed then
                    sprite:PlayOverlay("Vomit", true)
                else
                    sprite:PlayOverlay("VomitBuffed", true)
                end
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WHEEZY_COUGH, 0.6, 0, false, 0.6)

                data.AttackCooldown = math.random(90, 150)
            end
        end
    elseif data.State == "Attack" then
        local frame = sprite:GetOverlayFrame()
        if frame == 21 then
            if not data.NoLocusts then
                local numLocusts = 3
                REVEL.sfx:Play(SoundEffect.SOUND_SUMMONSOUND, 0.5, 0, false, 1)
                for i = 1, numLocusts do
                    local locust = Isaac.Spawn(REVEL.ENT.LOCUST.id, REVEL.ENT.LOCUST.variant, 0, npc.Position, RandomVector(), npc)
                    locust.SpawnerEntity = npc
                    locust.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
                    locust:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                end
            end

            if data.Buffed then
                local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, npc.Position, npc, false)
                creep.Color = REVEL.CustomColor(146, 39, 143)
                REVEL.UpdateCreepSize(creep, creep.Size * 2, true)
            end
        end

        if data.Buffed and frame > 24 and frame < 34 and math.random(1, 4) == 1 then
            local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, npc.Position + RandomVector() * 40, npc, false)
            creep.Color = REVEL.CustomColor(146, 39, 143)
        end

        npc.Velocity = npc.Velocity * 0.8
        
        if data.StomachBurst then
            sprite:SetFrame("WalkVertBuffed", 0)
        else
            sprite:SetFrame("WalkVert", 0)
        end

        if sprite:IsOverlayFinished("Vomit") or sprite:IsOverlayFinished("VomitBuffed") then
            data.NoLocusts = nil
            data.State = "Idle"
        end
    elseif data.State == "Stomach Burst" then
        if sprite:IsEventTriggered("Shoot") then
            npc:BloodExplode()
            for i = 1, 5 do
                local locust = Isaac.Spawn(REVEL.ENT.LOCUST.id, REVEL.ENT.LOCUST.variant, 0, npc.Position, RandomVector(), npc)
                locust.SpawnerEntity = npc
                locust.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
                locust:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            end

            local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, npc.Position, npc, false)
            creep.Color = REVEL.CustomColor(146, 39, 143)
            REVEL.UpdateCreepSize(creep, creep.Size * 4, true)

            data.StomachBurst = true
        end

        if sprite:IsFinished("StomachBurst") then
            data.State = "Idle"
        end

        npc.Velocity = npc.Velocity * 0.8
    else
        npc.Velocity = npc.Velocity * 0.8
    end

    if data.StomachBurst and npc.FrameCount % 10 == 1 then
        local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, npc.Position, npc, false)
        creep.Color = REVEL.CustomColor(146, 39, 143)
    end

    local isWalking = false
    if data.State == "Idle" and not sprite:IsPlaying("Appear") and npc.FrameCount > 1 then
        if not data.StomachBurst then
            if data.Buffed and npc.HitPoints < npc.MaxHitPoints / 3 then
                sprite:RemoveOverlay()
                sprite:Play("StomachBurst", true)
                data.State = "Stomach Burst"
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SPIDER_COUGH, 0.6, 0, false, 0.6)
            else
                if data.Buffed then
                    REVEL.AnimateWalkFrameSpeed(sprite, npc.Velocity, {Horizontal = "WalkHoriBuffedDefault", Vertical = "WalkVertBuffedDefault"})
                else
                    REVEL.AnimateWalkFrameSpeed(sprite, npc.Velocity, {Horizontal = "WalkHori", Vertical = "WalkVert"})
                end
                isWalking = true
            end
        else
            REVEL.AnimateWalkFrameSpeed(sprite, npc.Velocity, {Horizontal = "WalkHoriBuffed", Vertical = "WalkVertBuffed"})
            isWalking = true
        end
    end
    
    if not isWalking then
        sprite.PlaybackSpeed = 1
    end

    if npc:IsDead() and (not data.Buffed or (REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) and math.random(1, 5) == 1)) then
        REVEL.SpawnRevivalRag(npc)
    end

    if data.Buffed then
        REVEL.EmitBuffedParticles(npc, Anm2GlowNull0)
    end
end, REVEL.ENT.WRETCHER.id)

Anm2GlowNull0 = {
    HeadBuffed = {
        Offset = {Vector(0, -16), Vector(0, -16), Vector(0, -16), Vector(0, -16), Vector(0, -17), Vector(0, -17), Vector(0, -17), Vector(0, -16), Vector(0, -14), Vector(0, -14), Vector(0, -15), Vector(0, -15), Vector(0, -15), Vector(0, -15), Vector(0, -15), Vector(0, -15), Vector(0, -16), Vector(0, -16), Vector(0, -16), Vector(0, -16), Vector(0, -17), Vector(0, -17), Vector(0, -17), Vector(0, -16), Vector(0, -14), Vector(0, -14), Vector(0, -15), Vector(0, -15), Vector(0, -15), Vector(0, -15), Vector(0, -15), Vector(0, -15)},
        Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
    VomitBuffed = {
        Offset = {Vector(0, -16), Vector(0, -16), Vector(0, -17), Vector(0, -16), Vector(0, -14), Vector(0, -14), Vector(0, -14), Vector(0, -14), Vector(0, -14), Vector(0, -14), Vector(0, -14), Vector(0, -14), Vector(0, -14), Vector(0, -14), Vector(0, -14), Vector(0, -14), Vector(0, -14), Vector(0, -14), Vector(0, -14), Vector(0, -14), Vector(0, -14), Vector(1, -22), Vector(-1, -18), Vector(-3, -15), Vector(0, -19), Vector(-2, -17), Vector(0, -19), Vector(-2, -18), Vector(0, -19), Vector(-2, -18), Vector(-1, -19), Vector(-1, -19), Vector(-1, -20), Vector(-1, -19), Vector(0, -16), Vector(0, -16), Vector(0, -16), Vector(0, -16)},
        Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
    StomachBurst = {
        Offset = {Vector(0, -16), Vector(0, -14), Vector(0, -11), Vector(0, -11), Vector(0, -19), Vector(0, -17), Vector(0, -16), Vector(0, -17), Vector(0, -16), Vector(0, -16), Vector(0, -16), Vector(0, -16), Vector(0, -16), Vector(0, -16)},
        Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },    
}

end