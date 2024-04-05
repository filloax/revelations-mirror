return function()

-- Chicken

local hopUntilFlutter = 19 - 8
local bombUntilFlutter = 21 - 18
local hopJumpTime = 39 - 8
local bombJumpTime = 40 - 18
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.CHICKEN.variant then
        return
    end

    local sprite, data, target = npc:GetSprite(), REVEL.GetData(npc), npc:GetPlayerTarget()

    data.Cooldown = data.Cooldown or 0
    data.Cooldown = data.Cooldown - 1

    if not data.State then
        data.State = "Idle"
        data.Cooldown = math.random(20, 40)
        data.BombLast = true
    end

    if data.State == "Idle" then
        if not sprite:IsPlaying("Peck") and not sprite:IsPlaying("Idle") then
            sprite:Play("Idle", true)
        end

        data.Cooldown = data.Cooldown - 1
        if data.Cooldown <= 0 and not sprite:IsPlaying("Peck") then
            local index = REVEL.room:GetGridIndex(npc.Position)

            local radius = 3

            local validIndices = REVEL.GetNearFreeGridIndexes(index, radius, 32, nil, nil, nil, 2) --find near indexes free from entities
            if #validIndices > 0 then
                local chosen
                if data.BombLast then
                    chosen = REVEL.GetClosestGridIndexToPosition(target.Position, validIndices)
                else
                    chosen = validIndices[math.random(1, #validIndices)]
                end

                local position = REVEL.room:GetGridPosition(chosen)
                data.State = "Jump"
                data.Start = npc.Position
                data.End = position
                data.JumpFrame = 0
                if data.BombLast then
                    data.JumpTime = hopJumpTime
                else
                    data.JumpTime = bombJumpTime
                end

                data.LockedIndex = chosen
                REVEL.LockGridIndex(chosen)
                if data.BombLast then
                    sprite:Play("Hop", true)
                else
                    sprite:Play("Bomb", true)
                end

                data.BombLast = not data.BombLast
            end
        elseif data.Cooldown > 0 and not sprite:IsPlaying("Peck") then
            if math.random(1, 15) == 1 then
                sprite:Play("Peck", true)
            end
        end

        npc.Velocity = npc.Velocity * 0.75
    elseif data.State == "Jump" then
        if sprite:IsEventTriggered("Jump") or sprite:IsEventTriggered("Flutter") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BIRD_FLAP, 0.6, 0, false, 1)
        end

        if sprite:IsEventTriggered("Bomb") or sprite:IsEventTriggered("Jump") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BIRD_FLAP, 0.6, 0, false, 1)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
            if sprite:IsEventTriggered("Bomb") then
                local bomb = Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombVariant.BOMB_TROLL, 0, npc.Position, Vector.Zero, npc):ToBomb()
                bomb:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                bomb:GetSprite():Play("Pulse", true)
                bomb:SetExplosionCountdown(math.random(45, 55))
                REVEL.sfx:Play(SoundEffect.SOUND_PLOP, 0.6, 0, false, 1)
            end
        end

        if sprite:IsEventTriggered("Land") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_LAND, 0.6, 0, false, 1)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
        end

        if (sprite:WasEventTriggered("Jump") or sprite:WasEventTriggered("Bomb")) and not sprite:WasEventTriggered("Land") and data.JumpFrame then
            npc.Velocity = Vector.Zero
            data.JumpFrame = data.JumpFrame + 1
            if data.JumpFrame <= data.JumpTime then
                local pos = REVEL.Lerp(data.Start, data.End, data.JumpFrame / data.JumpTime)
                npc.Velocity = (pos - npc.Position)
                sprite.FlipX = npc.Velocity.X < 0
            else
                data.JumpFrame = nil
                data.JumpTime = nil
                if data.LockedIndex then
                    REVEL.UnlockGridIndex(data.LockedIndex)
                    data.LockedIndex = nil
                end
            end
        else
            npc.Velocity = npc.Velocity * 0.75
        end

        if sprite:IsFinished("Hop") or sprite:IsFinished("Bomb") then
            if data.LockedIndex then
                REVEL.UnlockGridIndex(data.LockedIndex)
                data.LockedIndex = nil
            end

            data.LerpFrames = nil
            data.Cooldown = math.random(20, 40)
            data.State = "Idle"
        end
    end
end, REVEL.ENT.CHICKEN.id)

end