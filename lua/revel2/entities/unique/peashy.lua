local RevRoomType = require "lua.revelcommon.enums.RevRoomType"
local RevCallbacks = require("lua.revelcommon.enums.RevCallbacks")

return function()

-- Peashy

local function isCornered(pos, margin)
    local clamp = REVEL.room:GetClampedPosition(pos, margin)
    return clamp.X ~= pos.X and clamp.Y ~= pos.Y
end

local function shouldThrowDirect(npc, target)
    local nearNailCount = 0
    for _, nail in ipairs(Isaac.FindByType(REVEL.ENT.PEASHY_NAIL.id, REVEL.ENT.PEASHY_NAIL.variant, -1, false, false)) do
        if nail.Position:DistanceSquared(target.Position) < 52 ^ 2 then
            nearNailCount = nearNailCount + 1
        end
    end

    return nearNailCount > 5 or npc.Position:DistanceSquared(target.Position) > 300 ^ 2
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant == REVEL.ENT.PEASHY.variant then
        local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

        if not data.State then
            data.State = "Idle"
            data.AttackCooldown = math.random(15, 35)
        end

        if data.State == "Idle" then
            if not sprite:IsPlaying("Idle") then
                sprite:Play("Idle", true)
            end

            data.AttackCooldown = data.AttackCooldown - 1
            if data.AttackCooldown <= 0 and target.Position:DistanceSquared(npc.Position) < 500 ^ 2 then
                local tooManyNails = (Isaac.CountEntities(nil, REVEL.ENT.PEASHY_NAIL.id, REVEL.ENT.PEASHY_NAIL.variant, -1) or 0) > 8
                if target.Position:DistanceSquared(npc.Position) < 80 ^ 2 or isCornered(npc.Position, 32) 
                or (npc.HitPoints < npc.MaxHitPoints*0.3 and not data.RetalRoll) then
                    sprite:Play("Jump", true)
                    data.State = "Roll"
                    data.RetalRoll = true
                else
                    local hasSight = REVEL.room:CheckLine(npc.Position, target.Position, 3, 0, false, false)
                    if not shouldThrowDirect(npc, target) or hasSight then
                        data.State = "ThrowNail"

                        if tooManyNails then
                            data.ThrowNailDirectly = true
                        end

                        if hasSight and (math.random(1, 5) == 1 or ((Isaac.CountEntities(nil, REVEL.ENT.PEASHY_NAIL.id, REVEL.ENT.PEASHY_NAIL.variant, -1) or 0) > 2 and math.random(1, 2) == 1)) then
                            data.ThrowNailDirectly = true
                        end

                        if data.ThrowNailDirectly then
                            data.AnimSuffix = "_Straight"
                        else
                            data.AnimSuffix = ""
                        end
                        sprite:Play("SpikeStart" .. data.AnimSuffix, true)
                    end
                end

                data.AttackCooldown = math.random(15, 35)
                if tooManyNails then
                    data.AttackCooldown = data.AttackCooldown + 10
                end
            end

            sprite.FlipX = target.Position.X > npc.Position.X
            npc.Velocity = npc.Velocity * 0.7
        elseif data.State == "ThrowNail" then
            if sprite:IsFinished("SpikeStart" .. data.AnimSuffix) or sprite:IsFinished("SpikeHop" .. data.AnimSuffix) then
                if not data.Hopped and target.Position:DistanceSquared(npc.Position) < 120 ^ 2 then
                    data.Hopped = true
                    sprite:Play("SpikeHop" .. data.AnimSuffix, true)
                else
                    sprite:Play("SpikeThrow" .. data.AnimSuffix, true)
                end
            end

            if sprite:IsPlaying("SpikeHop" .. data.AnimSuffix) 
            and sprite:WasEventTriggered("Jump") 
            and not sprite:WasEventTriggered("Land") then
                npc.Velocity = npc.Velocity * 0.7 + (npc.Position - target.Position):Resized(2)
            else
                npc.Velocity = npc.Velocity * 0.7
            end

            if sprite:IsEventTriggered("Shoot") then
                local isDirect = data.ThrowNailDirectly or shouldThrowDirect(npc, target)

                local targetPos = REVEL.room:GetClampedPosition(target.Position + RandomVector() * math.random(0, 39), 8)

                if not isDirect then
                    for _, eff in ipairs(Isaac.FindByType(StageAPI.E.FloorEffect.T, StageAPI.E.FloorEffect.V, -1, false, false)) do
                        if eff:GetData().TrapData then
                            if REVEL.IsTrapTriggerable(eff) and target.Position:DistanceSquared(eff.Position) < 80 ^ 2 and math.random(1, 2) == 1 then
                                targetPos = eff.Position
                            end
                        end
                    end
                end

                local nail = Isaac.Spawn(REVEL.ENT.PEASHY_NAIL.id, REVEL.ENT.PEASHY_NAIL.variant, 0, npc.Position, Vector.Zero, npc)
                nail.SpawnerEntity = npc
                nail:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                nail:AddEntityFlags(EntityFlag.FLAG_HIDE_HP_BAR)
                nail:AddEntityFlags(EntityFlag.FLAG_NO_FLASH_ON_DAMAGE)
                if not isDirect then
                    nail.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                    nail.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                    nail:GetData().StartPos = npc.Position
                    nail:GetData().EndPos = targetPos
                    nail:GetSprite().Rotation = -90
                    nail:GetSprite().Offset = Vector(0, Vector(-50, 0):Rotated(45).Y)
                else
                    nail.Velocity = (targetPos - npc.Position):Resized(14)
                    nail.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
                    nail.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_BULLET
                    nail.SpriteOffset = Vector(0, -15)
                    nail:GetData().Projectile = true
                end
                nail:GetData().Init = true
                nail.SplatColor = REVEL.NO_COLOR

                REVEL.sfx:NpcPlay(npc, REVEL.SFX.SWING, 0.5, 0, false, 0.95 + math.random() * 0.1)
            end

            if sprite:IsFinished("SpikeThrow" .. data.AnimSuffix) then
                data.Hopped = nil
                data.ThrowNailDirectly = nil
                data.State = "Idle"
            end

            sprite.FlipX = target.Position.X > npc.Position.X
        elseif data.State == "Roll" then
            if sprite:IsPlaying("Jump") then
                if sprite:IsEventTriggered("Jump") then
                    data.RollDirection = (target.Position - npc.Position):Resized(1)
                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_JUMP, 0.3, 0, false, 0.9)
                end

                if sprite:IsEventTriggered("Land") then
                    REVEL.sfx:NpcPlay(npc, REVEL.SFX.STONE_ROLL, 0.5, 0, false, 1)
                end

                if sprite:WasEventTriggered("Jump") and not sprite:WasEventTriggered("Land") then
                    npc.Velocity = npc.Velocity * 0.7 + data.RollDirection
                elseif not sprite:WasEventTriggered("Jump") then
                    npc.Velocity = npc.Velocity * 0.7
                end
            end

            if sprite:IsFinished("Jump") then
                sprite:Play("Roll", true)
            end

            if sprite:IsPlaying("Roll") or (sprite:IsPlaying("Jump") and sprite:WasEventTriggered("Land")) or (sprite:IsPlaying("RollEnd") and not sprite:WasEventTriggered("Jump")) then
                npc.Velocity = npc.Velocity * 0.7 + data.RollDirection * 2.5

                for _, nail in ipairs(Isaac.FindByType(REVEL.ENT.PEASHY_NAIL.id, REVEL.ENT.PEASHY_NAIL.variant, -1, false, false)) do
                    if nail.Position:DistanceSquared(npc.Position) < (nail.Size + npc.Size) ^ 2 then
                        nail:GetData().HitLoose = true
                        nail:GetData().Flipped = true
                    end
                end

                if not sprite:IsPlaying("RollEnd") then
                    if (target.Position:DistanceSquared(npc.Position) > 100 ^ 2 and not isCornered(npc.Position, 32)) or (npc.Velocity:LengthSquared() < 2 ^ 2) then
                        sprite:Play("RollEnd", true)
                    end
                end
            elseif sprite:IsPlaying("RollEnd") and not sprite:WasEventTriggered("Land") then
                npc.Velocity = npc.Velocity * 0.9
            elseif not sprite:IsPlaying("Jump") then
                npc.Velocity = npc.Velocity * 0.7
            end

            if sprite:IsFinished("RollEnd") then
                data.State = "Idle"
            end
        end
    elseif npc.Variant == REVEL.ENT.PEASHY_NAIL.variant then
        local data, sprite = npc:GetData(), npc:GetSprite()
        if not data.Init then
            sprite:Play("Idle", true)
            data.CanTriggerTraps = true
            data.HitLoose = true
            data.Flipped = true
        end

        if data.EndPos then
            npc.Velocity = REVEL.Lerp(data.StartPos, data.EndPos, npc.FrameCount / 20) - npc.Position

            if npc.FrameCount >= 17 then
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
            end

            if npc.FrameCount >= 20 then
                if REVEL.room:GetGridCollisionAtPos(npc.Position) ~= 0 then
                    npc:Remove()
                else
                    local rt = StageAPI.GetCurrentRoomType()
                    if rt == RevRoomType.TRAP or rt == RevRoomType.TRAP_BOSS then
                        sprite:Play("Land2", true)
                        data.HitLoose = true
                        data.Flipped = true
                    else
                        npc:Morph(npc.Type, npc.Variant, 1, -1)
                        sprite:Play("Land", true)
                        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_LAND, 0.4, 0, false, 1)
                        npc.CollisionDamage = 0
                    end

                    sprite.Rotation = 0
                    sprite.Offset = Vector.Zero
                    data.EndPos = nil
                    data.CanTriggerTraps = true
                    data.LockPosition = npc.Position
                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
                    npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
                    npc.Velocity = Vector.Zero
                end
            end
        elseif data.Projectile then
            sprite.Rotation = npc.Velocity:GetAngleDegrees()
            if npc:CollidesWithGrid() then
                REVEL.sfx:Play(SoundEffect.SOUND_POT_BREAK, 0.5, 0, false, 1.6)
                for i = 1, math.random(3, 4) do
                    local particleSprite = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.NAIL_PARTICLE, 0, npc.Position, -npc.Velocity:Resized(math.random(0, 2)):Rotated(math.random(-90, 90)), nil):GetSprite()
                    particleSprite:ReplaceSpritesheet(0, "gfx/monsters/revel2/peashy_nail_gibs.png")
                    particleSprite:LoadGraphics()
                end
                npc:Remove()
            end
        else
            if (not data.HitLoose or not data.Flipped) and not data.PlayerLoosenTimer then
                for _, player in ipairs(REVEL.players) do
                    if player.Position:DistanceSquared(npc.Position) < (player.Size + npc.Size) ^ 2 then
                        if not data.HitLoose then
                            data.HitLoose = true
                        else
                            data.Flipped = true
                        end

                        data.PlayerLoosenTimer = 15
                        break
                    end
                end
            end

            if data.PlayerLoosenTimer then
                data.PlayerLoosenTimer = data.PlayerLoosenTimer - 1
                if data.PlayerLoosenTimer <= 0 then
                    data.PlayerLoosenTimer = nil
                end
            end

            if data.HitLoose and sprite:IsFinished("Land") then
                local target = npc:GetPlayerTarget()
                local targetDiff = npc.Position - target.Position
                if math.abs(targetDiff.X) > math.abs(targetDiff.Y) then
                    if targetDiff.X < 0 then
                        sprite:Play("LooseLeft", true)
                    else
                        sprite:Play("LooseRight", true)
                    end
                else
                    if targetDiff.Y < 0 then
                        sprite:Play("LooseUp", true)
                    else
                        sprite:Play("LooseDown", true)
                    end
                end
            end

            if sprite:IsFinished("Flip") or sprite:IsFinished("Land2") then
                data.CanTriggerTraps = true
                sprite:Play("Idle", true)
            end

            if (data.HitLoose or data.Flipped) and npc:HasEntityFlags(EntityFlag.FLAG_NO_FLASH_ON_DAMAGE) then
                npc:ClearEntityFlags(EntityFlag.FLAG_NO_FLASH_ON_DAMAGE)
                npc:ClearEntityFlags(EntityFlag.FLAG_HIDE_HP_BAR)
            end

            if sprite:IsEventTriggered("Land") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_LAND, 0.7, 0, false, 1)
            end

            if data.Flipped and not (sprite:IsPlaying("Flip") or sprite:IsPlaying("Idle") or sprite:IsFinished("Idle")) then
                data.CanTriggerTraps = false
                npc:Morph(npc.Type, npc.Variant, 0, -1)
                npc.CollisionDamage = 0
                sprite:Play("Flip", true)
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SHELLGAME, 0.2, 0, false, 1)
            end

            if sprite:IsPlaying("Flip") and sprite:GetFrame() == 6 then
                npc.CollisionDamage = 1
            end

            if data.Flipped then
                npc.Velocity = npc.Velocity * 0.7
            else
                npc.Velocity = Vector.Zero
                npc.Position = data.LockPosition
            end

            if npc:IsDead() then
                REVEL.sfx:Play(SoundEffect.SOUND_POT_BREAK, 0.5, 0, false, 1.6)
                for i = 1, math.random(3, 4) do
                    local particleSprite = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.NAIL_PARTICLE, 0, npc.Position, RandomVector() * math.random(0, 2), nil):GetSprite()
                    particleSprite:ReplaceSpritesheet(0, "gfx/monsters/revel2/peashy_nail_gibs.png")
                    particleSprite:LoadGraphics()
                end
            end
        end
    end
end, REVEL.ENT.PEASHY.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if npc.Variant ~= REVEL.ENT.PEASHY_NAIL.variant or not REVEL.IsRenderPassNormal() then
        return
    end

    local data, sprite = npc:GetData(), npc:GetSprite()
    if data.EndPos then
        if not data.RenderFrame then
            data.RenderFrame = 1
        end

        if data.RenderFrame < npc.FrameCount + 1 then
            data.RenderFrame = data.RenderFrame + 0.5
            sprite.Rotation = sprite.Rotation + 14.25
        end
        sprite.Offset = Vector(0, Vector(-50, 0):Rotated(REVEL.Lerp(45, 180, data.RenderFrame / 19)).Y)
    end
end, REVEL.ENT.PEASHY_NAIL.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, amount, flag, source)
    if e.Type == REVEL.ENT.PEASHY_NAIL.id and e.Variant == REVEL.ENT.PEASHY_NAIL.variant then
        if e:GetSprite():IsFinished("Land") and not e:GetData().HitLoose and amount <= 10 then
            e:GetData().HitLoose = true
            return false
        elseif (e:GetData().HitLoose or amount > 10) and not e:GetData().Flipped and amount < 50 then
            e:GetData().Flipped = true
            return false
        end
    elseif e.Type == EntityType.ENTITY_PLAYER and source and source.Type == REVEL.ENT.PEASHY_NAIL.id and source.Variant == REVEL.ENT.PEASHY_NAIL.variant then
        if source.Entity and source.Entity:Exists() then
            for _, nail in ipairs(Isaac.FindByType(REVEL.ENT.PEASHY_NAIL.id, REVEL.ENT.PEASHY_NAIL.variant, -1, false, false)) do
                if GetPtrHash(nail) == GetPtrHash(source.Entity) then
                    REVEL.sfx:Play(SoundEffect.SOUND_POT_BREAK, 0.5, 0, false, 1.6)
                    for i = 1, math.random(3, 4) do
                        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.NAIL_PARTICLE, 0, nail.Position, RandomVector() * math.random(0, 2), nil)
                    end
                    nail:Remove()
                end
            end
        end

        e:BloodExplode()
        e:GetData().PeashyPunctured = 60
    end
end)

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
    local puncturedTimer = player:GetData().PeashyPunctured
    if puncturedTimer then
        puncturedTimer = puncturedTimer - 1
        if math.random(1, 5) == 1 then
            local splatSprite = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_SPLAT, 0, player.Position, Vector.Zero, nil):GetSprite()
            local frame = math.random(0, 15)
            local anim = "Size1BloodStains"
            if math.random(1, 3) == 1 then
                anim = "Size2BloodStains"
            end

            splatSprite:SetFrame(anim, frame)
        end

        if puncturedTimer <= 0 then
            player:GetData().PeashyPunctured = nil
        else
            player:GetData().PeashyPunctured = puncturedTimer
        end
    end
end)

end