local ShrineTypes = require "lua.revelcommon.enums.ShrineTypes"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-------------
-- RAG TAG --
-------------

local Anm2GlowNullVariants0
local Anm2GlowNullVariants1

local SLAP_NEW_ROOM_COOLDOWN = {Min = 80, Max = 110}
local SLAP_COOLDOWN = {Min = 55, Max = 80}
local TIME_TO_SWIPE = 5

function REVEL.SetPlayingFrame(sprite, anim, frame)
    sprite:Play(anim, true)
    for i = 1, frame do
        sprite:Update()
    end
end

function REVEL.LoopAnimFrames(sprite, data, anim, frames)
    local frame = sprite:GetFrame()
    data.AnimFrameIndex = data.AnimFrameIndex or 1
    local foundFrame
    for i, f in ipairs(frames) do
        if f + 1 == frame then
            foundFrame = i
        end
    end

    if not foundFrame then
        data.AnimFrameIndex = 1
    end

    REVEL.SetPlayingFrame(sprite, anim, frames[data.AnimFrameIndex])
    data.AnimFrameIndex = data.AnimFrameIndex + 1
    if data.AnimFrameIndex > #frames then
        data.AnimFrameIndex = 1
    end
end

---@param npc EntityNPC
local function ragTag_NpcUpdate(_, npc)
    if npc.Variant == REVEL.ENT.RAG_TAG.variant then
        npc.SplatColor = REVEL.PurpleRagSplatColor
        local data, sprite = npc:GetData(), npc:GetSprite()
        if data.Skin == nil then data.Skin = 0 end

        local target = npc:GetPlayerTarget()
        local targetDistSq = target.Position:DistanceSquared(npc.Position)
        -- target stabstack pieces
        local stabstackPieces = REVEL.ENT.STABSTACK_ROLLING:getInRoom()
        if not data.TargetStabstackCooldown then
            for _, piece in ipairs(stabstackPieces) do
                local distSq = piece.Position:DistanceSquared(npc.Position)
                if distSq < targetDistSq and distSq < 120^2 then
                    target = piece
                    targetDistSq = distSq
                end
            end
        else
            data.TargetStabstackCooldown = data.TargetStabstackCooldown - 1
            if data.TargetStabstackCooldown <= 0 then
                data.TargetStabstackCooldown = nil
            end
        end

        -- see pathfinding.lua / function REVEL.GetMinimumTargetSets(entities)
        data.TargetIndex = REVEL.room:GetGridIndex(target.Position)

        local animAppend = ""
        local speedmult = 1
        if data.Buffed then
            animAppend = "Buffed"
            speedmult = 2
        end
        if npc:IsDead() and (not data.Buffed or (REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) and math.random(1, 5) == 1)) then
            REVEL.SpawnRevivalRag(npc)
        end

        if not data.Init or sprite:IsFinished("Attack" .. animAppend) or sprite:IsFinished("Flurry") then
            if not data.Init then
                data.Skin = math.random(1, 3)
                for i = 0, 3 do
                    sprite:ReplaceSpritesheet(i, "gfx/monsters/revel2/rag_tag_" .. tostring(data.Skin) .. ".png")
                end

                if REVEL.room:GetFrameCount() < 5 then
                    data.AttackCooldown = REVEL.GetFromMinMax(SLAP_NEW_ROOM_COOLDOWN)
                end
                data.SlapTimer = 0
                sprite:LoadGraphics()
                data.Init = true
            end

            data.Slapped = {}
            if data.NumExtraDashes then
                data.State = "Attack"
                data.NumExtraDashes = data.NumExtraDashes - 1
                if data.NumExtraDashes <= 0 then
                    data.NumExtraDashes = nil
                end
            else
                data.State = "Moving"
                if not data.AttackCooldown then
                    if not data.NoDash then
                        data.AttackCooldown = REVEL.GetFromMinMax(SLAP_COOLDOWN)
                    end
                elseif data.NoDash then
                    data.AttackCooldown = data.AttackCooldown - 15
                end
            end
        end

        if data.State == "Moving" then
            if not sprite:IsPlaying("Head" .. animAppend) then
                sprite:Play("Head" .. animAppend, true)
            end

            REVEL.UsePathMap(REVEL.GenericFlyingChaserPathMap, npc)
            
            if data.Path then
                REVEL.FollowPath(npc, 0.2 * speedmult, data.Path, true, 0.9, false, true)
            end

            local targetDist = npc.Position:DistanceSquared(target.Position)
            local shouldAttack

            if data.AttackCooldown then
                data.AttackCooldown = data.AttackCooldown - 1
                if data.AttackCooldown <= 0 then
                    data.AttackCooldown = nil
                end
            end

            if not data.AttackCooldown then
                if targetDist < 150 ^ 2 then
                    shouldAttack = true
                elseif targetDist > 250 ^ 2 then
                    shouldAttack = true
                end
            end

            if shouldAttack then
                data.State = "Attack"
                data.NoDash = nil
                if data.Buffed then
                    data.NumExtraDashes = 1
                end
            else
                local tearWillHit = 0
                for _, tear in ipairs(REVEL.roomTears) do
                    if (tear.Position + (tear.Velocity * TIME_TO_SWIPE * 2)):DistanceSquared(npc.Position + npc.Velocity * TIME_TO_SWIPE * 2) < (20 + tear.Size + npc.Size) ^ 2 then
                        tearWillHit = tearWillHit + 1
                    end
                end

                if tearWillHit > 0 then
                    if data.AttackCooldown then
                        data.NoDash = true
                    end
                    if (tearWillHit > 1 or math.random(1, 3) == 1) and data.Buffed then
                        data.State = "Flurry"
                        sprite:Play("Flurry", true)
                    else
                        data.State = "Attack"
                        sprite:Play("Attack" .. animAppend, true)
                    end
                end
            end
        elseif data.State == "Attack" then
            if not sprite:IsPlaying("Attack" .. animAppend) then
                sprite:Play("Attack" .. animAppend, true)
            end
            if not sprite:WasEventTriggered("Dash") or sprite:WasEventTriggered("Slap") or data.NoDash then
                npc.Velocity = npc.Velocity * 0.9
            end
        elseif data.State == "Flurry" then
            npc.Velocity = npc.Velocity * 0.9
        end

        if not sprite:WasEventTriggered("StorePos") or sprite:IsEventTriggered("StorePos") then
            sprite.FlipX = npc.Position.X > target.Position.X
        end

        if sprite:IsEventTriggered("StorePos") and not data.NoDash then
            data.AddVelocity = (target.Position - npc.Position):Resized(26)
        end

        if sprite:IsEventTriggered("Dash") and not data.NoDash then
            npc.Velocity = data.AddVelocity
        end

        if sprite:IsEventTriggered("Dash") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SHELLGAME, 1, 0, false, 1)
        end

        if sprite:IsEventTriggered("Slap") then
            if data.NoDash then
                data.SlapTimer = 3
            else
                data.SlapTimer = 6
            end
        end

        if data.SlapTimer > 0 then
            local didImpact
            for _, p in ipairs(REVEL.players) do
                if not data.Slapped[GetPtrHash(p)]
                and p.Position:DistanceSquared(npc.Position) <= (npc.Size + p.Size + 20) ^ 2 
                then
                    p.Velocity = p.Velocity + (p.Position - npc.Position):Resized(20)
                    didImpact = true
                    data.Slapped[GetPtrHash(p)] = true
                end
            end

            for _, stabstack in ipairs(REVEL.ENT.STABSTACK:getInRoom()) do
                if not data.Slapped[GetPtrHash(stabstack)]
                and stabstack.Position:DistanceSquared(npc.Position) <= (npc.Size + stabstack.Size + 32) ^ 2 
                then
                    REVEL.ShootStabstackSegment(stabstack, (stabstack.Position - npc.Position):Normalized())
                    didImpact = true
                    data.Slapped[GetPtrHash(stabstack)] = true
                end
            end

            for _, piece in ipairs(stabstackPieces) do
                if not data.Slapped[GetPtrHash(piece)]
                and piece.Position:DistanceSquared(npc.Position) <= (npc.Size + piece.Size + 32) ^ 2 
                then
                    piece.Velocity = piece.Velocity + (piece.Position - npc.Position):Resized(18)
                    didImpact = true
                    data.Slapped[GetPtrHash(piece)] = true
                    data.TargetStabstackCooldown = math.random(30, 90)
                end
            end
            for i, v in ipairs(REVEL.roomTears) do
                if v.Position:DistanceSquared(npc.Position) <= (20 + v.Size + npc.Size) ^ 2 then
                REVEL.AuraReflectTear(v, target, npc)
                end
            end
            data.SlapTimer = data.SlapTimer - 1

            if didImpact then
                npc.Velocity = Vector.Zero
            end
        end

        --[[if sprite:IsPlaying("Flurry") and sprite:WasEventTriggered("Slap") and sprite:GetFrame() < 22 then
            for i, v in ipairs(REVEL.roomTears) do
            if v.Position:DistanceSquared(npc.Position) <= (20 + v.Size + npc.Size) ^ 2 then
            REVEL.AuraReflectTear(v, target, npc)
            end
        end]]

        if data.Buffed then
            REVEL.EmitBuffedParticles(npc, Anm2GlowNullVariants0[data.Skin])
            REVEL.EmitBuffedParticles(npc, Anm2GlowNullVariants1[data.Skin])
        end
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, ragTag_NpcUpdate, REVEL.ENT.RAG_TAG.id)

-- Anm2 glow nulls
Anm2GlowNullVariants0 = {
    {
        HeadBuffed = {
            Offset = {Vector(-6, -28), Vector(-6, -28), Vector(-6, -28), Vector(-6, -29), Vector(-6, -29), Vector(-6, -30), Vector(-6, -30), Vector(-6, -30), Vector(-6, -30), Vector(-6, -30), Vector(-6, -30), Vector(-6, -29), Vector(-6, -29), Vector(-6, -29), Vector(-6, -29), Vector(-6, -29), Vector(-6, -28), Vector(-6, -28), Vector(-6, -28), Vector(-6, -28)},
            Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
            Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
            Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        },
        AttackBuffed = {
            Offset = {Vector(-6, -28), Vector(-6, -28), Vector(-6, -29), Vector(-6, -30), Vector(-6, -31), Vector(-6, -31), Vector(-6, -31), Vector(-6, -31), Vector(-6, -21), Vector(-6, -21), Vector(-6, -21), Vector(-6, -21), Vector(-6, -21), Vector(-6, -21), Vector(-5, -23), Vector(-5, -24), Vector(-5, -24), Vector(-5, -25), Vector(-6, -29), Vector(-6, -29), Vector(-6, -28), Vector(-6, -28), Vector(-6, -28), Vector(-6, -28)},
            Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
            Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
            Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        },
        Flurry = {
            Offset = {Vector(-6, -28), Vector(-6, -28), Vector(-6, -29), Vector(-6, -30), Vector(-6, -31), Vector(-6, -31), Vector(-6, -31), Vector(-6, -31), Vector(-6, -22), Vector(-6, -23), Vector(-5, -24), Vector(-5, -23), Vector(-6, -22), Vector(-6, -23), Vector(-5, -24), Vector(-6, -23), Vector(-6, -22), Vector(-6, -23), Vector(-5, -25), Vector(-5, -25), Vector(-5, -25), Vector(-5, -26), Vector(-7, -27), Vector(-7, -27), Vector(-6, -28), Vector(-6, -28), Vector(-6, -28), Vector(-6, -28)},
            Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
            Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
            Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        },        
    },
    {
        HeadBuffed = {
            Offset = {Vector(-1, -24), Vector(-1, -24), Vector(-1, -24), Vector(-1, -25), Vector(-1, -25), Vector(-1, -26), Vector(-1, -26), Vector(-1, -26), Vector(-1, -26), Vector(-1, -26), Vector(-1, -26), Vector(-1, -25), Vector(-1, -25), Vector(-1, -25), Vector(-1, -25), Vector(-1, -25), Vector(-1, -24), Vector(-1, -24), Vector(-1, -24), Vector(-1, -24)},
            Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
            Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
            Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        },
        AttackBuffed = {
            Offset = {Vector(-1, -24), Vector(-1, -24), Vector(-1, -25), Vector(-1, -26), Vector(-1, -27), Vector(-1, -27), Vector(-1, -27), Vector(-1, -27), Vector(-1, -18), Vector(-1, -18), Vector(-1, -18), Vector(-1, -18), Vector(-1, -18), Vector(-1, -18), Vector(-1, -19), Vector(-1, -20), Vector(-1, -20), Vector(-1, -21), Vector(-1, -24), Vector(-1, -24), Vector(-1, -24), Vector(-1, -24), Vector(-1, -24), Vector(-1, -24)},
            Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
            Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
            Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        },
        Flurry = {
            Offset = {Vector(-1, -24), Vector(-1, -24), Vector(-1, -25), Vector(-1, -26), Vector(-1, -27), Vector(-1, -27), Vector(-1, -27), Vector(-1, -27), Vector(-3, -20), Vector(-2, -20), Vector(-2, -20), Vector(-2, -20), Vector(-2, -19), Vector(-2, -20), Vector(-2, -20), Vector(-2, -20), Vector(-2, -20), Vector(-2, -20), Vector(-2, -21), Vector(-2, -21), Vector(-2, -21), Vector(-2, -22), Vector(-2, -23), Vector(-1, -24), Vector(-1, -24), Vector(-1, -24), Vector(-1, -24), Vector(-1, -24)},
            Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
            Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
            Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        },        
    },
    {
        HeadBuffed = {
            Offset = {Vector(-7, -30), Vector(-7, -30), Vector(-7, -30), Vector(-7, -31), Vector(-7, -31), Vector(-7, -32), Vector(-7, -32), Vector(-7, -32), Vector(-7, -32), Vector(-7, -32), Vector(-7, -32), Vector(-7, -31), Vector(-7, -31), Vector(-7, -31), Vector(-7, -31), Vector(-7, -31), Vector(-7, -30), Vector(-7, -30), Vector(-7, -30), Vector(-7, -30)},
            Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
            Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
            Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        },
        AttackBuffed = {
            Offset = {Vector(-7, -30), Vector(-7, -30), Vector(-6, -31), Vector(-6, -33), Vector(-6, -34), Vector(-6, -34), Vector(-6, -34), Vector(-6, -34), Vector(-8, -22), Vector(-7, -23), Vector(-7, -24), Vector(-7, -24), Vector(-7, -24), Vector(-7, -24), Vector(-7, -25), Vector(-7, -26), Vector(-7, -26), Vector(-7, -27), Vector(-6, -32), Vector(-6, -32), Vector(-7, -30), Vector(-7, -30), Vector(-7, -30), Vector(-7, -30)},
            Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
            Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
            Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        },
        Flurry = {
            Offset = {Vector(-7, -30), Vector(-7, -30), Vector(-7, -31), Vector(-7, -32), Vector(-7, -34), Vector(-7, -34), Vector(-7, -34), Vector(-7, -34), Vector(-8, -24), Vector(-7, -25), Vector(-6, -27), Vector(-7, -25), Vector(-8, -24), Vector(-7, -25), Vector(-6, -27), Vector(-7, -25), Vector(-8, -24), Vector(-7, -26), Vector(-6, -27), Vector(-6, -27), Vector(-6, -27), Vector(-6, -28), Vector(-8, -29), Vector(-7, -30), Vector(-6, -31), Vector(-7, -31), Vector(-7, -30), Vector(-7, -30)},
            Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
            Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
            Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        },        
    },
}

Anm2GlowNullVariants1 = {
    {
        HeadBuffed = {
            Offset = {Vector(5, -30), Vector(5, -30), Vector(5, -30), Vector(5, -30), Vector(5, -30), Vector(5, -31), Vector(5, -31), Vector(5, -31), Vector(5, -31), Vector(5, -31), Vector(5, -31), Vector(5, -30), Vector(5, -30), Vector(5, -30), Vector(5, -30), Vector(5, -30), Vector(5, -30), Vector(5, -30), Vector(5, -30), Vector(5, -30)},
            Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
            Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
            Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        },
        AttackBuffed = {
            Offset = {Vector(5, -30), Vector(5, -30), Vector(5, -31), Vector(5, -32), Vector(5, -33), Vector(5, -33), Vector(5, -33), Vector(5, -33), Vector(6, -21), Vector(5, -21), Vector(5, -22), Vector(5, -22), Vector(5, -22), Vector(5, -22), Vector(5, -23), Vector(5, -24), Vector(5, -24), Vector(5, -26), Vector(5, -31), Vector(5, -31), Vector(5, -29), Vector(5, -30), Vector(5, -30), Vector(5, -30)},
            Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
            Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
            Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        },
        Flurry = {
            Offset = {Vector(5, -30), Vector(5, -30), Vector(5, -31), Vector(5, -32), Vector(5, -33), Vector(5, -33), Vector(5, -33), Vector(5, -33), Vector(5, -23), Vector(5, -24), Vector(4, -25), Vector(4, -24), Vector(5, -23), Vector(5, -24), Vector(4, -25), Vector(4, -24), Vector(5, -23), Vector(5, -24), Vector(4, -26), Vector(4, -26), Vector(4, -26), Vector(4, -27), Vector(5, -29), Vector(5, -29), Vector(5, -30), Vector(5, -30), Vector(5, -30), Vector(5, -30)},
            Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
            Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
            Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        },        
    },
    {

    },
    {
        HeadBuffed = {
            Offset = {Vector(5, -33), Vector(5, -33), Vector(5, -33), Vector(5, -34), Vector(5, -34), Vector(5, -34), Vector(5, -34), Vector(5, -34), Vector(5, -34), Vector(5, -34), Vector(5, -34), Vector(5, -34), Vector(5, -34), Vector(5, -34), Vector(5, -34), Vector(5, -34), Vector(5, -33), Vector(5, -33), Vector(5, -33), Vector(5, -33)},
            Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
            Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
            Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        },
        AttackBuffed = {
            Offset = {Vector(5, -33), Vector(5, -33), Vector(5, -34), Vector(5, -35), Vector(5, -36), Vector(5, -36), Vector(5, -36), Vector(5, -36), Vector(6, -23), Vector(6, -24), Vector(5, -25), Vector(5, -25), Vector(5, -25), Vector(5, -25), Vector(5, -26), Vector(5, -27), Vector(5, -27), Vector(5, -29), Vector(4, -35), Vector(4, -35), Vector(5, -32), Vector(5, -32), Vector(5, -33), Vector(5, -33)},
            Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
            Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
            Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        },
        Flurry = {
            Offset = {Vector(5, -33), Vector(5, -33), Vector(5, -34), Vector(5, -35), Vector(5, -36), Vector(5, -36), Vector(5, -36), Vector(5, -36), Vector(5, -26), Vector(5, -27), Vector(4, -30), Vector(5, -28), Vector(5, -26), Vector(5, -27), Vector(4, -29), Vector(5, -28), Vector(5, -26), Vector(5, -28), Vector(4, -30), Vector(4, -30), Vector(4, -31), Vector(4, -31), Vector(5, -31), Vector(5, -32), Vector(5, -33), Vector(5, -33), Vector(5, -33), Vector(5, -33)},
            Scale = {Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20), Vector(20, 20)},
            Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
            Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        },        
    },
}

end