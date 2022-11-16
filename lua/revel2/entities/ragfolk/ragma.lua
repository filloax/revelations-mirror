local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local ShrineTypes = require "lua.revelcommon.enums.ShrineTypes"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Ragma

local Anm2GlowNull0
local Anm2GlowNull1

local bal = {
    ragBounce = 6,
    ragWidth = 12,
}

local ragmaBlacklist  = {
    REVEL.ENT.RAGMA,
    REVEL.ENT.ANIMA
}

local ignoreWrapOverlay  = {
    REVEL.ENT.RAG_DRIFTY,
    REVEL.ENT.PSEUDO_RAG_DRIFTY
}

local function snareProcessing(npc, newRoom)
    local data = npc:GetData()

    data.ragSnared = data.ragSnared or {}
    data.ragIndices = data.ragIndices or {}

    data.npcIndex = REVEL.room:GetGridIndex(npc.Position)

    if not newRoom then
        newRoom = StageAPI.GetCurrentRoom()
    end

    if newRoom then
        local groups = newRoom.Metadata:GroupsWithIndex(data.npcIndex)

        if #groups > 0 then
            local indices = newRoom.Metadata:IndicesInGroup(groups[1])
            data.ragIndices = indices
        end
    end

    for _, ent in ipairs(Isaac.FindInRadius(npc.Position, 1000, EntityPartition.ENEMY)) do
        local check
        for _, entCheck in ipairs(ragmaBlacklist) do
            if ent.Type == entCheck.id and ent.Variant == entCheck.variant then
                check = true
                break
            end
        end
        if not check then
            if ent:GetData().ragmaParent then
                if ent:GetData().ragmaIndex == data.npcIndex then
                    table.insert(data.ragSnared, EntityPtr(ent))
                end
            elseif #data.ragIndices > 0 then
                local entIndex = REVEL.room:GetGridIndex(ent.Position)
                for _, index in ipairs(data.ragIndices) do
                    if entIndex == index then
                        table.insert(data.ragSnared, EntityPtr(ent))
                    end
                end
            else
                table.insert(data.ragSnared, EntityPtr(ent))
            end
        end
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.RAGMA.variant then return end

    local data = npc:GetData()
    local sprite = npc:GetSprite()
    --local rng = npc:GetDropRNG()

    local isFriendly = npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)

    if not data.init then
        data.state = "Spawn"
        sprite:Play("Spawn", true)

        if REVEL.room:GetFrameCount() > 10 then
            snareProcessing(npc)
        end

        data.ragSnared = data.ragSnared or {}
        data.ragIndices = data.ragIndices or {}

        data.npcIndex = data.npcIndex or REVEL.room:GetGridIndex(npc.Position)

        npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
        npc.SplatColor = REVEL.PurpleRagSplatColor

        data.ragmaHelper = Isaac.Spawn(1000, REVEL.ENT.RAGMA_HELPER.variant, 0, npc.Position, Vector.Zero, npc)

        data.init = true
    end

    if data.Buffed and not data.BuffedInit then
        for i=0, 5 do
            sprite:ReplaceSpritesheet(i, "gfx/monsters/revel2/ragma_buffed.png")
        end
        sprite:LoadGraphics()
        data.BuffedInit = true

        if data.ragsOut then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_REDLIGHTNING_ZAP)
        end
    end
    
    if data.state == "Spawn" then
        
        if sprite:IsEventTriggered("Sound") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SIREN_MINION_SMOKE)
        end

        if sprite:IsEventTriggered("RagSpawn") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_RAGMAN_2,1,0,false,1.1)

            data.ragsOut = true

            if #data.ragSnared > 0 then
                if not isFriendly then
                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WHIP)
                    if data.Buffed then
                        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_REDLIGHTNING_ZAP)
                    end
                else
                    REVEL.sfx:NpcPlay(npc, REVEL.SFX.LOVERS_LIB)
                end
            end
        end

        if sprite:IsFinished("Spawn") then
            data.state = "Idle"
        end
    elseif data.state == "Idle" then
        if not sprite:IsPlaying("Idle") then
            sprite:Play("Idle", true)
        end

        if isFriendly then
            npc:Kill()
        end
    end

    data.ragNumber = 0

    -- Rag Wall Logic
    if data.ragsOut and #data.ragSnared > 0 then
        for _, entPtr in ipairs(data.ragSnared) do
            local ent = entPtr.Ref

            if ent then
                local entData = ent:GetData()
                if ent:Exists() and ent:IsVisible() and not ent:GetData().ragmaIgnore then 

                    if not isFriendly and not ent:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then

                        data.ragNumber = data.ragNumber + 1

                        -- Rag Wall Collisions
                        local angleToRagma = (npc.Position-ent.Position):GetAngleDegrees()%360
                        local angleToEnt = (ent.Position-npc.Position):GetAngleDegrees()%360

                        for _, player in ipairs(REVEL.players) do

                            local pAngleToRagma = (npc.Position-player.Position):GetAngleDegrees()%360
                            local pAngleToEnt = (ent.Position-player.Position):GetAngleDegrees()%360

                            local ragWidth = bal.ragWidth
                            local npcDist = player.Position:Distance(npc.Position)
                            local entDist = player.Position:Distance(ent.Position)
                            if (npcDist > 120 and entDist > 120) then
                                local aDistance = (npcDist + entDist)*0.5
                                ragWidth = bal.ragWidth / math.max(1,(aDistance)/100)
                            end

                            if (math.abs(pAngleToEnt-angleToEnt) < ragWidth or math.abs(pAngleToEnt-angleToEnt) > 360-ragWidth)
                            and (math.abs(pAngleToRagma-angleToRagma) < ragWidth or math.abs(pAngleToRagma-angleToRagma) > 360-ragWidth) then
                                
                                -- Rag Contact
                                
                                -- touching clockwise
                                if (pAngleToEnt-angleToEnt > 0 and pAngleToEnt-angleToEnt < 300) or pAngleToEnt-angleToEnt < -300 then
                                    player.Velocity = (npc.Position-ent.Position):Rotated(90):Resized(bal.ragBounce)
                                -- touching counter-clockwise
                                else
                                    player.Velocity = (npc.Position-ent.Position):Rotated(-90):Resized(bal.ragBounce)
                                end

                                if data.Buffed then
                                    player:TakeDamage(1, 0, EntityRef(npc), 0)
                                end
                            end
                        end

                        -- Evis cord shenanigans
                        entData.ragmaCord = entData.ragmaCord or {}
                        if not entData.ragmaCord[npc.Index] then
                            entData.ragmaCord[npc.Index] = Isaac.Spawn(EntityType.ENTITY_EVIS, 10, 0, ent.Position, Vector.Zero, ent)
                            entData.ragmaCord[npc.Index].Parent = npc
                            entData.ragmaCord[npc.Index].Target = ent

                            entData.ragmaCord[npc.Index]:GetSprite():Load("gfx/monsters/revel2/ragma_rag.anm2", true)
                            local roomHeight = REVEL.room:GetBottomRightPos().Y - REVEL.room:GetTopLeftPos().Y
                            entData.ragmaCord[npc.Index].DepthOffset = -roomHeight

                            entData.ragmaParent = EntityPtr(npc)
                            entData.ragmaCord[npc.Index]:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)

                            for _, entCheck in ipairs(ignoreWrapOverlay) do
                                if ent.Type == entCheck.id and ent.Variant == entCheck.variant then
                                    entData.ragmaWrapIgnore = true
                                    break
                                end
                            end

                            ent.Velocity = (ent.Position - npc.Position):Resized(6)
                        else
                            if entData.ragmaParent then
                                entData.ragmaIndex = data.npcIndex

                                if data.Buffed then
                                    if not entData.ragmaCord[npc.Index]:GetSprite():IsPlaying("Gut_Buffed") then
                                        entData.ragmaCord[npc.Index]:GetSprite():Play("Gut_Buffed", true)
                                        for i=0, 1 do
                                            entData.ragmaCord[npc.Index]:GetSprite():ReplaceSpritesheet(i, "gfx/monsters/revel2/ragma_rag_buffed.png")
                                        end
                                        entData.ragmaCord[npc.Index]:GetSprite():LoadGraphics()
                                    end

                                    entData.ragmaBuffed = true
                                end
                            end

                            -- ragma dead
                            if npc:IsDead() then
                                entData.ragmaCord[npc.Index]:Kill()
                                entData.ragmaCord[npc.Index] = nil
                            end
                        end
                    else
                        if ent.MaxHitPoints < 100 then
                            ent:AddCharmed(EntityRef(npc), -1)
                        end
                    end

                    if ent.Type == EntityType.ENTITY_FIREPLACE then
                        if entData.ragmaCord and ent:ToNPC().State == 3 then
                            entData.ragmaParent = nil
                            entData.ragmaIgnore = true
                        end
                    end
                else
                    --npc dead
                    if entData.ragmaCord then
                        if entData.ragmaCord[npc.Index] then
                            entData.ragmaCord[npc.Index]:Kill()
                            entData.ragmaCord[npc.Index] = nil
                        end
                    end
                end
            end
        end
    end

    if data.state == "Idle" and npc.SubType == 1 and data.ragNumber <= 0 then
        npc:Kill()
    end

    if npc:IsDead() and (not data.Buffed or (REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) and math.random(1, 5) == 1)) and not data.SpawnedRag then
        REVEL.SpawnRevivalRag(npc)
        data.SpawnedRag = true
    end

    if data.Buffed then
        REVEL.EmitBuffedParticles(npc, Anm2GlowNull0)
        REVEL.EmitBuffedParticles(npc, Anm2GlowNull1)
    end

    npc.Velocity = Vector.Zero

end, REVEL.ENT.RAGMA.id)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, function(newRoom, isFirstVisit, isExtraRoom)
    local ragmas = Isaac.FindByType(REVEL.ENT.RAGMA.id, REVEL.ENT.RAGMA.variant, -1, false, false)

    if #ragmas > 0 then
        for _, npc in ipairs(ragmas) do
            snareProcessing(npc, newRoom)
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if npc:GetData().ragmaCord then
        local data = npc:GetData()
        if data.ragmaParent and data.ragmaParent.Ref and not data.ragmaWrapIgnore then
            if data.ragmaParent.Ref:Exists() then
                if not data.ragmaWrap then
                    data.ragmaWrap = Sprite()
                    data.ragmaWrap:Load("gfx/monsters/revel2/ragma_wrapping.anm2", true)
                else
                    local size = "_Small"
                    local suffix = "_Appear"
                    if data.ragmaWrapInit or data.ragmaWrap:IsFinished("Wrap" .. size .. "_Appear") then
                        suffix = ""
                        data.ragmaWrapInit = true
                    end
                    if data.ragmaBuffed then
                        if not data.ragmaLightning then
                            data.ragmaLightning = Sprite()
                            data.ragmaLightning:Load("gfx/monsters/revel2/ragma_rag.anm2", true)
                            data.ragmaWrap:ReplaceSpritesheet(0, "gfx/monsters/revel2/ragma_wrapping_buffed.png")
                            data.ragmaWrap:LoadGraphics()
                        end
                    end

                    local anim = "Wrap" .. size .. suffix
                    if not data.ragmaWrap:IsPlaying(anim) then
                        data.ragmaWrap:Play(anim, true)
                    end

                    data.ragmaWrap:Update()

                    data.ragmaWrap.Offset = Vector(0,-5)
                    data.ragmaWrap.FlipX = npc:GetSprite().FlipX
                    data.ragmaWrap:Render(Isaac.WorldToRenderPosition(npc.Position) + REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)

                    if data.ragmaLightning then
                        if not data.ragmaLightning:IsPlaying("Lightning") then
                            data.ragmaLightning:Play("Lightning", true)
                        end
                        data.ragmaLightning.PlaybackSpeed = 0.5
                        data.ragmaLightning:Update()

                        data.ragmaLightning.Rotation = (data.ragmaParent.Ref.Position-npc.Position):GetAngleDegrees() + 90
                        local stretch = (npc.Position:Distance(data.ragmaParent.Ref.Position))*0.0026
                        data.ragmaLightning.Scale = Vector(0.7,stretch)
                        data.ragmaLightning.Offset = Vector(0,-8)
                        data.ragmaLightning:Render(Isaac.WorldToRenderPosition(data.ragmaParent.Ref.Position) + REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
                    end
                end
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, eff)
    local npc = eff.SpawnerEntity

    local roomHeight = REVEL.room:GetBottomRightPos().Y - REVEL.room:GetTopLeftPos().Y
    eff.DepthOffset = -roomHeight - 10

    if npc then
        local sprite, data = npc:GetSprite(), npc:GetData()
        if not data.bottomSprite then
            data.bottomSprite = Sprite()
            data.bottomSprite:Load("gfx/monsters/revel2/ragma.anm2", true)
        elseif npc.FrameCount > 0 then
            data.bottomSprite.Color = sprite.Color
;
            local anim = "Bottom" .. sprite:GetAnimation()
            if not data.bottomSprite:IsPlaying(anim) then
                data.bottomSprite:Play(anim, true)
            end
            data.bottomSprite.PlaybackSpeed = 0.5
            data.bottomSprite:Update()

            if data.Buffed and not eff:GetData().BuffedInit and npc:GetData().BuffedInit then
                for i=0, 5 do
                    data.bottomSprite:ReplaceSpritesheet(i, "gfx/monsters/revel2/ragma_buffed.png")
                end
                data.bottomSprite:LoadGraphics()
                eff:GetData().BuffedInit = true
            end

            data.bottomSprite:Render(Isaac.WorldToRenderPosition(npc.Position) + REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
        end

        if not data.ragTransition then
            data.ragTransition = Sprite()
            data.ragTransition:Load("gfx/monsters/revel2/ragma_rag.anm2", true)
        elseif sprite:IsEventTriggered("Shoot") then
            if #data.ragSnared > 0 then
                for _, entPtr in ipairs(data.ragSnared) do
                    local ent = entPtr.Ref
        
                    if ent then
                        if ent:Exists() then 
                            if not data.ragTransition:IsPlaying("JustARag") then
                                data.ragTransition:Play("JustARag", true)
                            end
                    
                            data.ragTransition.Rotation = (npc.Position-ent.Position):GetAngleDegrees() + 90
                            local stretch = (ent.Position:Distance(npc.Position))*0.0025
                            data.ragTransition.Scale = Vector(1,stretch*0.5)
                            data.ragTransition.Offset = Vector(0,-7)
                            data.ragTransition:Render(Isaac.WorldToRenderPosition(npc.Position) + REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
                        end
                    end
                end
            end
        end

        if not npc:Exists() then
            eff:Remove()
        end
    end
end, REVEL.ENT.RAGMA_HELPER.variant)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, dmg, flag, src, invuln)
    if e.Variant ~= REVEL.ENT.RAGMA.variant then return end

    local data = e:GetData()
    if not e:GetSprite():IsPlaying("Idle")
    and flag ~= flag | DamageFlag.DAMAGE_CLONES then
        e:TakeDamage(dmg * 0.2, DamageFlag.DAMAGE_CLONES, src, invuln)
        return false
    
    elseif e:GetData().ragNumber <= 0
    and flag ~= flag | DamageFlag.DAMAGE_CLONES then
        e:TakeDamage(dmg * 2, DamageFlag.DAMAGE_CLONES, src, invuln)
        return false
    end

end, REVEL.ENT.RAGMA.id)

Anm2GlowNull0 = {
    Idle = {
        Offset = {Vector(-8, -34), Vector(-8, -34), Vector(-8, -34), Vector(-8, -34), Vector(-8, -33), Vector(-8, -33), Vector(-8, -33), Vector(-8, -33), Vector(-8, -32), Vector(-8, -32), Vector(-8, -32), Vector(-8, -32), Vector(-8, -32), Vector(-8, -32), Vector(-8, -32), Vector(-8, -32), Vector(-8, -33), Vector(-8, -33), Vector(-8, -34), Vector(-8, -35), Vector(-8, -34), Vector(-8, -34), Vector(-8, -34), Vector(-8, -34), Vector(-8, -34), Vector(-8, -34)},
        Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
    Spawn = {
        Offset = {Vector(-8, -34), Vector(-8, -34), Vector(-8, -34), Vector(-8, -34), Vector(-8, -34), Vector(-8, -34), Vector(-8, -34), Vector(-8, -34), Vector(-8, -34), Vector(-8, -34), Vector(-7, -48), Vector(-7, -47), Vector(-8, -45), Vector(-8, -44), Vector(-8, -44), Vector(-8, -44), Vector(-8, -43), Vector(-8, -43), Vector(-8, -44), Vector(-8, -45), Vector(-8, -45), Vector(-7, -35), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-7, -33), Vector(-9, -32), Vector(-8, -33), Vector(-8, -35), Vector(-8, -34), Vector(-8, -34), Vector(-8, -34)},
        Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, true}
    },    
}

Anm2GlowNull1 = {
    Idle = {
        Offset = {Vector(8, -36), Vector(8, -36), Vector(8, -36), Vector(8, -36), Vector(8, -35), Vector(8, -35), Vector(8, -35), Vector(8, -35), Vector(8, -34), Vector(8, -34), Vector(8, -34), Vector(8, -34), Vector(8, -34), Vector(8, -34), Vector(8, -34), Vector(8, -34), Vector(8, -35), Vector(8, -35), Vector(8, -36), Vector(8, -37), Vector(8, -36), Vector(8, -36), Vector(8, -36), Vector(8, -36), Vector(8, -36), Vector(8, -36)},
        Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
    Spawn = {
        Offset = {Vector(8, -36), Vector(8, -36), Vector(8, -36), Vector(8, -36), Vector(8, -36), Vector(8, -36), Vector(8, -36), Vector(8, -36), Vector(8, -36), Vector(8, -36), Vector(6, -53), Vector(6, -51), Vector(7, -49), Vector(7, -48), Vector(7, -48), Vector(7, -48), Vector(7, -47), Vector(7, -47), Vector(7, -48), Vector(7, -49), Vector(7, -50), Vector(7, -37), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(7, -35), Vector(9, -34), Vector(8, -35), Vector(8, -37), Vector(8, -36), Vector(8, -36), Vector(8, -36)},
        Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, true}
    },    
}

end