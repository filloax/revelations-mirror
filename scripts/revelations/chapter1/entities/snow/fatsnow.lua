return function()

--------------------
-- FATSNOW --
--------------------
local FatsnowGroundTime = {Min = 6, Max = 12}
local FatSnowJumpTime = 17 --creep frame - jump frame
local FatSnowLargeJumpTime = 14 --move end - jump

local function fatSnow_NpcUpdate(_, npc)
    if npc.Variant == REVEL.ENT.FATSNOW.variant then
        local sprite, data, target = npc:GetSprite(), REVEL.GetData(npc), npc:GetPlayerTarget()

        npc.SplatColor = REVEL.SnowSplatColor

        if not data.JumpsTilAttack then
            data.JumpsTilAttack = math.random(6) + 2
        end

        if (sprite:IsPlaying("Idle") or sprite:IsFinished("Idle")) and target then
            if (data.NextJumpFrame and npc.FrameCount >= data.NextJumpFrame) or (not data.NextJumpFrame and math.random(1, 4) == 1) then
                data.JumpsTilAttack = data.JumpsTilAttack - 1
                if data.JumpsTilAttack > 0 then
                    local index = REVEL.room:GetGridIndex(npc.Position)
                    local validIndexes = REVEL.GetNearFreeGridIndexes(index, 2, 32, nil, nil, {EntityType.ENTITY_FIREPLACE}) --find near indexes free from entities (except fires)
                    local closestToTarget = REVEL.GetClosestGridIndexToPosition(target.Position, validIndexes)
                    if closestToTarget then
                        local position = REVEL.room:GetGridPosition(closestToTarget)
                        data.Jumping = true
                        data.Start = npc.Position
                        data.End = position
                        data.JumpTime = FatSnowJumpTime
                        data.LockedIndex = closestToTarget
                        REVEL.LockGridIndex(closestToTarget)
                        sprite:Play("Jump", true)
                        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
                        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
                    end
                else
                    local index = REVEL.room:GetGridIndex(npc.Position)
                    local validIndexes = REVEL.GetNearFreeGridIndexes(index, 60, 32, nil, nil, {EntityType.ENTITY_FIREPLACE})
                    local closestToTarget = REVEL.GetClosestGridIndexToPosition(target.Position, validIndexes)
                    if closestToTarget then
                        local position = REVEL.room:GetGridPosition(closestToTarget)
                        data.Jumping = true
                        data.Start = npc.Position
                        data.End = position
                        data.JumpTime = FatSnowLargeJumpTime
                        data.LockedIndex = closestToTarget
                        data.IsBigJump = true
                        REVEL.LockGridIndex(closestToTarget)
                        sprite:Play("Attack", true)
                        -- npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
                        data.JumpsTilAttack = 2 + math.random(6)
                    end
                end
            end
        end

        if sprite:IsEventTriggered("Shoot") then
            if sprite:IsPlaying("Death") then
                for i = 1, 4 do
                    npc:FireProjectiles(npc.Position, Vector.FromAngle(i * 90):Resized(8), 0, ProjectileParams())
                end
            else
                npc:FireBossProjectiles(math.random(8, 14), Vector.Zero, 10, ProjectileParams())
            end
            REVEL.sfx:Play(SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
        end

        if sprite:IsEventTriggered("Creep") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_JUMPS, 0.8, 0, false, 1)
            for i, e in ipairs(REVEL.roomFires) do
                if e.Position:Distance(npc.Position) <= npc.Size+e.Size+5 then
                    e:TakeDamage(500, DamageFlag.DAMAGE_EXPLOSION, EntityRef(npc), 0) --extinguish fire it lands on
                end
            end

            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

            local creep = REVEL.SpawnIceCreep(npc.Position, npc)
            if sprite:IsPlaying("Attack") then
                REVEL.UpdateCreepSize(creep, creep.Size * 4, true)
            end
        end

        npc.Velocity = npc.Velocity*0.7

        if data.Jumping and sprite:WasEventTriggered("Jump") then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            if not REVEL.LerpEntityPosition(npc, data.Start, data.End, data.JumpTime) or sprite:WasEventTriggered("MoveEnd") then
                data.Jumping = nil
                data.IsBigJump = nil
                if data.LockedIndex then
                    REVEL.UnlockGridIndex(data.LockedIndex)
                    data.LockedIndex = nil
                end
            end
        end

        if REVEL.MultiFinishCheck(sprite, "Jump", "Attack", "Appear", "Idle") then
            if REVEL.MultiFinishCheck(sprite, "Jump", "Attack") then
                data.NextJumpFrame = npc.FrameCount + REVEL.GetFromMinMax(FatsnowGroundTime)
            end

            if data.LockedIndex then
                REVEL.UnlockGridIndex(data.LockedIndex)
                data.LockedIndex = nil
            end

            sprite:Play("Idle", true)
            npc.Velocity = Vector.Zero
        end
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, fatSnow_NpcUpdate, REVEL.ENT.FATSNOW.id)

REVEL.AddDeathEventsCallback {
    OnDeath = function(npc)
        local data =REVEL.GetData(npc)
        data.Jumping = nil
    end,
    DeathRender = function (npc, triggeredEventThisFrame)
        local sprite, data = npc:GetSprite(), REVEL.GetData(npc)
        if IsAnimOn(sprite, "Death") and not triggeredEventThisFrame then
            local justTriggered
            if sprite:IsEventTriggered("Creep") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_JUMPS, 0.8, 0, false, 1)
                local speed = 7
                -- for i = 0, 2 do
                    -- REVEL.DelayFunction(function()
                        for d = 0, 3 do
                            local dir = REVEL.dirToVel[d]
                            local proj = Isaac.Spawn(9, 0, 0, npc.Position + dir * 8, dir * speed, npc):ToProjectile()
                            proj.FallingSpeed = 2
                            REVEL.GetData(proj).ForceGlacierSkin = true --spawned after death shenanigans
                        end
                    -- end, i * 5)
                -- end
                justTriggered = true
            end

            if sprite:IsFinished("Death") then
                npc:BloodExplode()
                npc:Kill()
                justTriggered = true
            end
            return justTriggered
        end
    end, 
    Type = REVEL.ENT.FATSNOW.id, 
    Variant = REVEL.ENT.FATSNOW.variant,
}

end