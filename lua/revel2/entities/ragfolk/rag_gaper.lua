local ShrineTypes = require "lua.revelcommon.enums.ShrineTypes"
return function()

---------------
-- RAG GAPER --
---------------

local gaperMoanFrames = 50

local function ragGaperUpdate(_, npc)
    if npc.Variant ~= REVEL.ENT.RAG_GAPER.variant then
        return
    end

    npc.SplatColor = REVEL.PurpleRagSplatColor
    local data, sprite, player = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

    if not data.State then
        data.RearedHead = false
        sprite.PlaybackSpeed = 1
        if not data.Buffed then
            sprite:SetOverlayFrame("Head", 0)
        else
            sprite:SetOverlayFrame("Head2", 0)
        end

        data.State = "Moving"
    end

    if data.Buffed and not data.BuffedInit then
        sprite:ReplaceSpritesheet(1, "gfx/monsters/revel2/rag_gaper_body_buffed.png")
        sprite:ReplaceSpritesheet(2, "gfx/monsters/revel2/rag_gusher_buffed.png")
        sprite:ReplaceSpritesheet(3, "gfx/monsters/revel2/rag_gusher_buffed.png")
        sprite:LoadGraphics()
        data.BuffedInit = true
    end

    if data.Buffed then
        REVEL.EmitBuffedParticles(npc)
    end

    if sprite:IsFinished("TripHori") or sprite:IsFinished("TripVert") then
        npc:Morph(REVEL.ENT.RAG_GUSHER.id, REVEL.ENT.RAG_GUSHER.variant, 0, -1)
        return
    end

    if sprite:IsEventTriggered("Collapse") then
        if not data.NoRags then
            REVEL.SpawnRevivalRag(npc)
        end
        npc:Kill()
        return
    end

    REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)

    if data.State == "Moving" then
        if not data.RearedHead and data.Path then
            data.RearedHead = true
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_ZOMBIE_WALKER_KID, 1, 10, false, 1)
            if not data.Buffed then
                sprite:PlayOverlay("Head", true)
            else
                sprite:PlayOverlay("Head2", true)
            end
        end

        if data.RearedHead then
            REVEL.AnimateWalkFrameSpeed(sprite, npc.Velocity, {Horizontal = "WalkHori", Vertical = "WalkVert"})

            if data.Buffed then
                if not REVEL.IsOverlayOn(sprite, "Head2") then
                    sprite:SetOverlayFrame("Head2", 19)
                end
            end

            if npc.FrameCount > 30 and player.Position:Distance(npc.Position) <= 90 then
                sprite:RemoveOverlay()
                local diff = player.Position - npc.Position

                if data.Buffed then
                    if math.abs(diff.Y) > math.abs(diff.X) then
                        sprite:Play("TripVert", true)
                    else
                        sprite:Play("TripHori", true)
                    end
                else
                    if math.abs(diff.Y) > math.abs(diff.X) then
                        sprite:Play("TripVertNormal", true)
                    else
                        sprite:Play("TripHoriNormal", true)
                    end
                end

                npc.Velocity = Vector.Zero
                data.State = "Gaper Trip"
                sprite.PlaybackSpeed = 1
                data.TripDirection = diff:Normalized()
            end
        end

        if data.Path and data.RearedHead then
            local speed = 0.55
            if data.Buffed then
                speed = 0.75
            end

            REVEL.FollowPath(npc, speed, data.Path, true, 0.85)

            if npc.FrameCount % gaperMoanFrames == 0 then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_ZOMBIE_WALKER_KID, 1, 0, false, 1)
            end
        else
            npc.Velocity = npc.Velocity * 0.9
        end
    elseif data.State == "Gaper Trip" then
        npc.Velocity = Vector.Zero
        if sprite:IsEventTriggered("Spawn") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_GOOATTACH0, 1, 0, false, 1)
            local head = Isaac.Spawn(REVEL.ENT.RAG_GAPER_HEAD.id, REVEL.ENT.RAG_GAPER_HEAD.variant, 0, npc.Position + data.TripDirection * 5, data.TripDirection * 7.5, npc)
            head:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            head.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            head:GetData().Buffed = data.Buffed
        end
    elseif data.State == "Regen" then
        npc.Velocity = Vector.Zero
        if sprite:IsFinished("Regen") then
            sprite:SetOverlayFrame("Head2", 19)
            data.State = "Moving"
        end
    end

    if npc:IsDead() and (not data.Buffed or (REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) and math.random(1, 5) == 1)) and not data.NoRags then
        REVEL.SpawnRevivalRag(npc)
    end
end

local function ragGaperHeadUpdate(_, npc)
    if npc.Variant ~= REVEL.ENT.RAG_GAPER_HEAD.variant then
        return
    end

    local data, sprite, player = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()
    if not data.Init then
        npc.SplatColor = REVEL.PurpleRagSplatColor
        data.Init = true
        data.Speed = 7.5
        data.Reduce = 0.99
        if data.Buffed then
            data.Speed = 10.5
            data.Reduce = 0.995
        end
    end

    data.Speed = data.Speed * data.Reduce

    npc.Velocity = npc.Velocity * 0.9 + (player.Position - npc.Position):Resized(data.Speed / 10)

    if npc.FrameCount == 4 then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
    end

    if data.Speed <= 2 then
        npc:BloodExplode()
        --Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position + Vector(0,3), Vector.Zero, npc)
        --REVEL.SpawnRevivalRag(npc, REVEL.ENT.RAG_TRITE.id, REVEL.ENT.RAG_TRITE.variant, 231)
        npc:Remove()
    end

    if data.Buffed then
        REVEL.AnimateWalkFrame(sprite, npc.Velocity, {
            Right = "RollRight",
            Down = "RollDown",
            Left = "RollLeft",
            Up = "RollUp"
        })
    
        REVEL.EmitBuffedParticles(npc)
    else
        REVEL.AnimateWalkFrame(sprite, npc.Velocity, {
            Right = "RollRightNormal",
            Down = "RollDownNormal",
            Left = "RollLeftNormal",
            Up = "RollUpNormal"
        })
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, ragGaperUpdate, REVEL.ENT.RAG_GAPER.id)
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, ragGaperHeadUpdate, REVEL.ENT.RAG_GAPER_HEAD.id)


end