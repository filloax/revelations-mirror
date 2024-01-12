local ShrineTypes = require "lua.revelcommon.enums.ShrineTypes"
return function()

-- Necragmancer

local function necragmancer_NpcUpdate(_, npc)
    local isNoShutDoors = npc.Variant == REVEL.ENT.NECRAGMANCER_NO_SHUT_DOORS.variant
    if not (isNoShutDoors or npc.Variant == REVEL.ENT.NECRAGMANCER.variant) then
        return
    end

    npc.SplatColor = REVEL.PurpleRagSplatColor

    local data, sprite = npc:GetData(), npc:GetSprite()

    if not data.Init then
        if REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) then
            npc.MaxHitPoints = npc.MaxHitPoints * 1.2
            npc.HitPoints = npc.HitPoints * 1.2
        end
        data.PushData = {
            ForceMult = 0.1,
            TimeMult = 0.4,
        }
        data.Init = true
    end

    if not data.PtrHash then
        data.PtrHash = GetPtrHash(npc)
    end

    if sprite:IsFinished("Appear") or sprite:IsFinished("Idle") or sprite:IsFinished("Wrap") then
        sprite:Play("Idle", true)
    end

    if sprite:IsPlaying("Idle") then
        npc.CollisionDamage = 0
    else
        npc.CollisionDamage = 1
    end

    if sprite:IsFinished("Unwrap") or not data.AttackCooldown then
        data.AttackCooldown = math.random(25, 45)
        if REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) then
            data.AttackCooldown = math.floor(data.AttackCooldown * 0.8)
        end
    end

    --[[
        Shrines don't give positive effects anymore
    if npc:IsDead() and REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) then
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, 0, npc.Position, Vector.Zero, nil)
    end
    ]]

    if data.RevivalBall and (not data.RevivalBall:Exists() or data.RevivalBall:IsDead()) then
        data.RevivalBall = nil
    end

    if npc:HasEntityFlags(EntityFlag.FLAG_CHARM) or npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
        npc:ClearEntityFlags(EntityFlag.FLAG_CHARM)
        npc:ClearEntityFlags(EntityFlag.FLAG_FRIENDLY)
    end

    local rags = Isaac.FindByType(REVEL.ENT.REVIVAL_RAG.id, REVEL.ENT.REVIVAL_RAG.variant, -1, false, false)

    if #rags == 0 and not isNoShutDoors and sprite:IsPlaying("Idle") then
        npc:Morph(REVEL.ENT.NECRAGMANCER_NO_SHUT_DOORS.id, REVEL.ENT.NECRAGMANCER_NO_SHUT_DOORS.variant, 0, 0)
        isNoShutDoors = true
        npc:GetSprite():Play("Idle", true)
    elseif #rags > 0 and isNoShutDoors then
        npc:Morph(REVEL.ENT.NECRAGMANCER.id, REVEL.ENT.NECRAGMANCER.variant, 0, 0)
        isNoShutDoors = nil
        npc:GetSprite():Play("Unwrap", true)
    end

    local isWalking = false
    if #rags > 0 then
        if sprite:IsPlaying("Wrap") or sprite:IsPlaying("Unwrap") or sprite:IsPlaying("Idle") or sprite:IsPlaying("Appear") or sprite:IsPlaying("Revive") then
            if sprite:IsPlaying("Idle") then
                sprite:Play("Unwrap", true)
                data.PushData = {
                    ForceMult = 0.5,
                    TimeMult = 0.8,
                }
            end
        else
            local targetRag
            local closestDist
            for _, rag in ipairs(rags) do
                local dist = rag.Position:DistanceSquared(npc.Position)
                if not closestDist or dist < closestDist then
                    targetRag = rag
                    closestDist = dist
                end
            end

            REVEL.MoveRandomly(npc, 90, 15, 25, 0.5, 0.85, targetRag.Position)
            REVEL.AnimateWalkFrameSpeed(sprite, npc.Velocity, {Horizontal = "WalkHori", Vertical = "WalkVert"})
            isWalking = true

            local revivedPersonally = 0
            for _, otherNPC in ipairs(REVEL.roomNPCs) do
                if otherNPC:GetData().Necragmancer == data.PtrHash then
                    revivedPersonally = revivedPersonally + 1
                end
            end

            if not data.RevivalBall and revivedPersonally < 3 then
                data.AttackCooldown = data.AttackCooldown - 1

                if data.AttackCooldown <= 0 then
                    sprite:Play("Revive", true)
                    data.AttackCooldown = math.random(35, 55)
                    if REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) then
                        data.AttackCooldown = math.floor(data.AttackCooldown * 0.8)
                    end
                end
            end
        end
    elseif not (sprite:IsPlaying("Wrap") or sprite:IsPlaying("Unwrap") or sprite:IsPlaying("Idle") or sprite:IsPlaying("Appear")) then
        sprite:Play("Wrap", true)
        data.PushData = {
            ForceMult = 0.1,
            TimeMult = 0.4,
        }
    end
    
    if not isWalking then
        sprite.PlaybackSpeed = 1
    end

    if not (sprite:IsPlaying("WalkHori") or sprite:IsPlaying("WalkVert")) then
        npc.Velocity = npc.Velocity * 0.85
    end

    if sprite:IsEventTriggered("Shoot") then
        local targetRag
        local closestDist
        for _, rag in ipairs(rags) do
            local dist = rag.Position:DistanceSquared(npc.Position)
            if not closestDist or dist < closestDist then
                targetRag = rag
                closestDist = dist
            end
        end

        local diff = (targetRag.Position - npc.Position)
        local dist = diff:Length()
        local normal = diff / dist

        local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, 0, npc.Position, normal * math.min(5, dist / 8), nil):ToProjectile()
        proj:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        proj.Size = proj.Size * 4
        --proj:GetSprite():Load("gfx/bosses/revel2/aragnid/aragnid_magicball.anm2", true)
        --proj:GetSprite():Play("Idle", true)
        proj.Color = Color(1,1,1,1,0.5,0,0.3)
        proj.Scale = 2.5
        proj.Height = -20
        proj.FallingSpeed = 0
        proj.FallingAccel = -0.1
        proj.RenderZOffset = 100001
        proj.ProjectileFlags = ProjectileFlags.SMART
        proj:GetData().Necragmancer = data.PtrHash
        proj:Update()
        proj.ProjectileFlags = 0
        proj:GetData().PurpleColor = proj.Color
        --proj.Color = Color(1, 1, 1, 1,conv255ToFloat( 0, 0, 0))
        data.RevivalBall = proj

        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SKIN_PULL, 0.8, 0, false, 1)
    end
end

local twoPi = math.pi * 2
local waveTime = 30

local function reviveClose(pro, rags, data)
    for _, rag in ipairs(rags) do
        if rag.Position:Distance(pro.Position) < 30 then
            local npc = REVEL.BuffEntity(rag)
            if npc then
                npc:GetData().Necragmancer = data.Necragmancer
            end
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
    local data = pro:GetData()
    if data.Necragmancer or data.RevivalShrineTear or data.LustBall then
        pro.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        local rags = Isaac.FindByType(REVEL.ENT.REVIVAL_RAG.id, REVEL.ENT.REVIVAL_RAG.variant, -1, false, false)
        if pro:IsDead() then
            pro.Color = data.PurpleColor
            reviveClose(pro, rags, data)
        else
            if not REVEL.room:IsPositionInRoom(pro.Position, -16) and not (data.RevivalShrineTear or data.LustBall) then
                pro:Die()
            end

            local target
            local closestDist
            local targetIsRag = false
            if data.LustBall and data.RevivedLust then
                target, closestDist = REVEL.getClosestInTable(REVEL.players, pro)

                if target and closestDist < 500 then
                target:TakeDamage(1, 0, EntityRef(pro), 15)
                end

                local lusts = Isaac.FindByType(EntityType.ENTITY_LUST, -1, -1, false, false)
                lusts = REVEL.GetFilteredArray(lusts, function(e) return e.HitPoints > 0 end) --ignore 0 health lusts
                if #lusts == 0 then
                pro:Die()
                end

                local t2, dist2 = REVEL.getClosestInTable(lusts, pro)
                if t2 and dist2 < (t2.Size + pro.Size)^2 then
                pro.Velocity = (pro.Position - t2.Position):Resized(10)
                end
                target = target or t2
            end

            if not target then
                for _, rag in ipairs(rags) do
                    local dist = rag.Position:DistanceSquared(pro.Position)
                    if (not closestDist or dist < closestDist) and (rag:GetData().SpawnID == EntityType.ENTITY_LUST or not data.LustBall) then
                        target = rag
                        closestDist = dist
                        targetIsRag = true
                    end
                end
            end

            if target and not data.Falling then
                local wave = math.sin(twoPi * (pro.FrameCount / waveTime))
                if not data.MaxAmp or math.abs(wave) < 0.1 then
                    data.MaxAmp = math.random(25, 35)
                end

                local diff = target.Position - pro.Position
                local diffLen = diff:Length()

                if not data.RevivedLust then
                    if targetIsRag and diffLen < 30 then
                        data.Falling = true
                        pro.FallingAccel = 0.25
                    else
                        -- aerotoma wave movement with a smaller amplitude
                        local amplitude = REVEL.SwitchRanges(diffLen, 200, 1000, data.MaxAmp, 0)
                        local dir = diff / diffLen

                        dir = dir:Rotated(wave * amplitude)
                        pro.Velocity = dir * 5
                        if REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) then
                            pro.Velocity = pro.Velocity * 1.35
                        end
                    end
                else
                    pro.Velocity = pro.Velocity * 0.95 + diff * (0.9 / diffLen)
                end
            elseif not target and not data.Falling then
                data.Falling = true
                pro.FallingAccel = 0.25
            elseif data.Falling then
                pro.Velocity = pro.Velocity * 0.85
            end

            if data.LustBall then
                pro.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                if pro.Height >= -10.2 then
                pro.FallingAccel = -0.35
                reviveClose(pro, rags, data)
                data.RevivedLust = true
                data.Falling = false
                end
                if pro.FallingAccel < -0.12 and pro.Height <= -20 then
                pro.FallingAccel = -0.1
                pro.FallingSpeed = 0
                end
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e)
    if (e.Variant == REVEL.ENT.NECRAGMANCER.variant or e.Variant == REVEL.ENT.NECRAGMANCER_NO_SHUT_DOORS.variant) 
    and (
        e:GetSprite():IsPlaying("Idle") 
        or e:GetSprite():IsFinished("Idle") 
        or e:GetSprite():IsPlaying("Appear") 
        or e:GetSprite():IsFinished("Appear")
    ) then
        return false
    end
end, REVEL.ENT.NECRAGMANCER.id)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, necragmancer_NpcUpdate, REVEL.ENT.NECRAGMANCER.id)

end