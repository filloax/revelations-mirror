local ShrineTypes = require "lua.revelcommon.enums.ShrineTypes"
return function()

----------------
-- RAG TRITE --
----------------

REVEL.PushBlacklist[REVEL.ENT.RAG_TRITE.id] = {REVEL.ENT.RAG_TRITE.variant}

local jumpTime = 14
local function ragTrite_NpcUpdate(_, npc)
    if npc.Variant ~= REVEL.ENT.RAG_TRITE.variant then
        return
    end

    npc.SplatColor = REVEL.PurpleRagSplatColor

    local sprite, data, target = npc:GetSprite(), npc:GetData(), npc:GetPlayerTarget()

    data.Cooldown = data.Cooldown or 0
    data.Cooldown = data.Cooldown - 1

    if data.Buffed then
        REVEL.EmitBuffedParticles(npc)
    end

    if (sprite:IsPlaying("Idle") or sprite:IsFinished("Idle") or sprite:IsPlaying("Idle2") or sprite:IsFinished("Idle2")) and target and data.Cooldown <= 0 then
        data.NumJumps = data.NumJumps or 0
        if not data.Buffed or data.NumJumps < 1 or target.Position:DistanceSquared(npc.Position) > 350 ^ 2 then
            data.NumJumps = data.NumJumps + 1
            local index = REVEL.room:GetGridIndex(npc.Position)

            local radius = 2 + math.random(0, 3)

            local validIndices = REVEL.GetNearFreeGridIndexes(index, radius, 32) --find near indexes free from entities
            if #validIndices > 0 then
                local chosen
                if math.random(1, 2) == 1 then
                    chosen = REVEL.GetClosestGridIndexToPosition(target.Position, validIndices)
                else
                    chosen = validIndices[math.random(1, #validIndices)]
                end

                local position = REVEL.room:GetGridPosition(chosen)
                data.Jumping = true
                data.Start = npc.Position
                data.End = position
                data.JumpTime = jumpTime
                data.LockedIndex = chosen
                REVEL.LockGridIndex(chosen)
                if data.Buffed then
                    sprite:Play("Hop2", true)
                else
                    sprite:Play("Hop", true)
                end

                npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
            end
        else
            sprite:Play("HopBig", true)
            data.NumJumps = 0
        end
    end

    if sprite:IsPlaying("HopBig") and (sprite:IsEventTriggered("Jump") or sprite:IsEventTriggered("Jump2")) then
        if data.LockedIndex then
            REVEL.UnlockGridIndex(data.LockedIndex)
        end

        local targDiff = target.Position - npc.Position
        local chosen = REVEL.room:GetGridIndex(target.Position + targDiff:Resized(32))
        if not REVEL.IsGridIndexFree(chosen, 20) then
            local targetIndex = REVEL.room:GetGridIndex(target.Position)
            if REVEL.IsGridIndexFree(targetIndex, 20) then
                chosen = targetIndex
            end
        end

        if chosen then
            local position = REVEL.room:GetGridPosition(chosen)
            if position:DistanceSquared(npc.Position) > 500 ^ 2 then
                position = npc.Position + (position - npc.Position):Resized(500)
            end

            data.Jumping = true
            data.Start = npc.Position
            data.End = position
            data.JumpTime = jumpTime
            data.LockedIndex = chosen
            REVEL.LockGridIndex(chosen)
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
        else
            data.TargetPosition = target.Position
        end
    end

    if sprite:IsEventTriggered("Creep") then
        local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, npc.Position, npc, false)
        creep.Color = REVEL.CustomColor(146, 39, 143)
        REVEL.UpdateCreepSize(creep, creep.Size * 2, true)
    end

    npc.Velocity = Vector.Zero

    if data.Jumping and ((sprite:WasEventTriggered("Jump") and not sprite:WasEventTriggered("Creep")) or sprite:WasEventTriggered("Jump2")) then
        if not REVEL.LerpEntityPosition(npc, data.Start, data.End, data.JumpTime) then
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
            data.Jumping = nil
            if data.LockedIndex then
                REVEL.UnlockGridIndex(data.LockedIndex)
                data.LockedIndex = nil
            end
        end
    elseif data.TargetPosition and ((sprite:WasEventTriggered("Jump2") and not sprite:WasEventTriggered("Land")) or (sprite:WasEventTriggered("Jump") and not sprite:WasEventTriggered("Creep"))) then
        npc.Velocity = (data.TargetPosition - npc.Position):Resized(10)
    end

    if sprite:IsEventTriggered("Land") or sprite:IsEventTriggered("Creep") then
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_IMPACTS, 1, 0, false, 1)
    end

    if sprite:IsFinished("Hop") or sprite:IsFinished("Appear") or sprite:IsFinished("Hop2") or sprite:IsFinished("HopBig") or sprite:IsFinished("Appear2") or sprite:IsFinished("Idle") or sprite:IsFinished("Idle2") then
        if data.LockedIndex then
            REVEL.UnlockGridIndex(data.LockedIndex)
            data.LockedIndex = nil
        end

        local minCooldown, maxCooldown = 10, 20
        data.Cooldown = math.random(minCooldown, maxCooldown)

        if data.Buffed then
            sprite:Play("Idle2", true)
        else
            sprite:Play("Idle", true)
        end
    end

    if npc:IsDead() and (not data.Buffed or (REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) and math.random(1, 5) == 1)) and not data.SpawnedRag then
        REVEL.SpawnRevivalRag(npc)
        data.SpawnedRag = true
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, ragTrite_NpcUpdate, REVEL.ENT.RAG_TRITE.id)


end