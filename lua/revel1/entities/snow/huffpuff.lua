local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()

-- Huffpuff
local bal = {
    GrabbableEntites = {REVEL.ENT.SNOWBALL, REVEL.ENT.YELLOW_SNOWBALL, REVEL.ENT.STRAWBERRY_SNOWBALL},
    EntityAnims = {[REVEL.ENT.SNOWBALL] = "Idle", [REVEL.ENT.YELLOW_SNOWBALL] = "Idle", [REVEL.ENT.STRAWBERRY_SNOWBALL] = "Idle"},

    Friction = 0.95,
    TargetMoveAccel = 0.4,
    MaxHeldNum = 3,
    CooldownAfterGulp = {Min = 35, Max = 55},
    CooldownAfterGrab = {Min = 10, Max = 30},
    CooldownAfterGrabAll = {Min = 15, Max = 40},
    ShootSpeed = 15,
    MinDistToShoot = 480,
    DistToForceShoot = 120,
}

local AnimData = {
    Grab_Holding = {
        LerpStart = 20,
        LerpEnd = 27,
        LerpToStackOffset = true,
    },
    Gulp = {
        LerpFromStackOffset = true,
        LerpStart = 10,
        LerpEnd = 15,
    }
}

local NullNames = {
    HELD0 = "held0",
    HELD1 = "held1",
    HELD2 = "held2",
}

--enemy offsets stack with the ones below (useful in case they need different offsets for each enemy)
local SnowballOffsets = {Vector(-2, 0), Vector(0, -8), Vector(0, -8)}
local SnowballOffsetXWaveLen = {0, 1, 1}
local SnowballOffsetXWaveDel = {0, 0, 0.5}

local function getAllGrabbables(npc)
    local out = {}
    for _, entityDef in ipairs(bal.GrabbableEntites) do
        out = REVEL.ConcatTables(out, entityDef:getInRoom())
    end
    return out
end

local function getSpitAnimFromVec(vec, isEnd)
    local midfix = isEnd and "End_" or ""

    if math.abs(vec.Y) > math.abs(vec.X) then
        if vec.Y > 0 then
            return "Spit_" .. midfix .. "Down", false
        else
            return "Spit_" .. midfix .. "Up", false
        end
    else
        if vec.X > 0 then
            return "Spit_" .. midfix .. "Side", false
        else
            return "Spit_" .. midfix .. "Side", true
        end
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if not REVEL.ENT.HUFFPUFF:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), npc:GetData()

    npc.SplatColor = REVEL.SnowSplatColor

    if npc.FrameCount == 0 then
        -- npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        sprite:Play("Appear", true)
        npc:AddEntityFlags(EntityFlag.FLAG_NO_SPIKE_DAMAGE)
    end

    if sprite:IsFinished("Appear") or (not IsAnimOn(sprite, "Appear") and not data.State) then
        sprite:Play("Idle", true)
        data.IdleAnim = "Idle"
        data.State = "Moving"
        data.HeldSprites = {Sprite(), Sprite(), Sprite()}
        data.HeldSpritesAnims = {"", "", ""}
        data.HeldEntities = {}
        data.ShouldRender = {false, false, false}
        data.IdleCount = math.random(bal.CooldownAfterGrab.Min, bal.CooldownAfterGrab.Max)
    end
    if not data.State then
        return
    end

    for i = 1, #data.HeldEntities do
        REVEL.PlayIfNot(data.HeldSprites[i], data.HeldSpritesAnims[i])
        data.HeldSprites[i]:Update()
    end

    if npc:IsDead() then
        if data.HeldEntities then
            for _, e in ipairs(data.HeldEntities) do
                local vel = RandomVector() * 3

                local ent = Isaac.Spawn(e.Type, e.Variant, e.SubType, npc.Position, vel, npc)
                ent.HitPoints = e.HitPoints
                ent:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            end
            data.HeldEntities = nil
        end
        return
    end

    if data.State == "Moving" then
        if not data.Target then
            local grabbables = getAllGrabbables(npc)
            local playerTarget = npc:GetPlayerTarget()
            local shouldShoot = playerTarget and (#data.HeldEntities >= bal.MaxHeldNum or (#data.HeldEntities > 0 and #grabbables == 0))
            local forceShoot = false

            data.AvgDmgTaken = ((data.PrevHP or npc.MaxHitPoints) - npc.HitPoints + (data.AvgDmgTaken or 0)) / 2 --not really 'average' but works
            data.PrevHP = npc.HitPoints

            if not shouldShoot and #data.HeldEntities > 0 and data.AvgDmgTaken > 1.5 then
                shouldShoot = true
                forceShoot = true
            end

            if playerTarget and not shouldShoot then
                if #data.HeldEntities >= 2 and playerTarget.Position:DistanceSquared(npc.Position) < bal.DistToForceShoot^2 then
                    shouldShoot = true
                    forceShoot = true
                end
            end

            shouldShoot = shouldShoot and playerTarget.Position:DistanceSquared(npc.Position) < bal.MinDistToShoot^2
                and REVEL.room:CheckLine(npc.Position, playerTarget.Position, 0, 0, false, false)
            forceShoot = forceShoot and shouldShoot

            if data.IdleCount and not forceShoot then
                REVEL.MoveRandomly(npc, 60, 9, 19, 0.5, 0.95)
                data.IdleCount = data.IdleCount - 1
                if data.IdleCount <= 0 then
                    data.IdleCount = nil
                end
            else
                if shouldShoot then
                    sprite:Play("Gulp", true)
                    data.State = "Shoot"
                else
                    if #grabbables > 0 and #data.HeldEntities < bal.MaxHeldNum then
                        data.Target = REVEL.getClosestInTable(grabbables, npc)
                    elseif #grabbables == 0 and #data.HeldEntities == 0 then
                        sprite:Play("HatTrick", true)
                        data.State = "HatTrick"
                    else
                        data.IdleCount = 5
                    end
                end
            end
        elseif data.Target and data.Target:Exists() then
            if data.Target.Position:DistanceSquared(npc.Position) < (npc.Size + data.Target.Size + 5) ^ 2 then
                npc.Velocity = data.Target.Velocity
                data.State = "Grab"
                sprite:Play((#data.HeldEntities == 0) and "Grab" or "Grab_Holding", true)
                data.GrabbingNum = #data.HeldEntities + 1

                data.HeldSprites[#data.HeldEntities + 1]:Load(data.Target:GetSprite():GetFilename(), true)
                local anim = data.Target:GetSprite():GetDefaultAnimationName()
                for entDef, animName in pairs(bal.EntityAnims) do
                    if entDef:isEnt(data.Target) then
                        anim = animName
                    end
                end

                data.HeldSprites[#data.HeldEntities + 1]:Play(anim, true)
                REVEL.SkipAnimFrames(data.HeldSprites[#data.HeldEntities + 1], data.Target:GetSprite():GetFrame())
                data.HeldSpritesAnims[#data.HeldEntities + 1] = anim
            else
                npc.Velocity = npc.Velocity * bal.Friction + (data.Target.Position - npc.Position):Resized(bal.TargetMoveAccel)
            end
        else
            data.Target = nil
        end
    elseif data.State == "Grab" then
        if data.Target and not data.Target:Exists() then
            data.Target = nil
            data.State = "Moving"
            sprite:Play(data.IdleAnim, true)
        else
            if data.Target then
                npc.Velocity = data.Target.Velocity
            else
                npc.Velocity = npc.Velocity * 0.8
            end

            if sprite:IsEventTriggered("Throw") then
                data.HeldEntities[#data.HeldEntities + 1] = {Type = data.Target.Type, Variant = data.Target.Variant, SubType = data.Target.SubType, HitPoints = data.Target.HitPoints}
                data.ShouldRender[#data.HeldEntities] = true
                data.Target:Remove()
                data.IdleAnim = "Idle_Holding"
                data.Target = nil
                REVEL.sfx:Play(REVEL.SFX.WHOOSH, 0.6, 0, false, 1.05 + math.random() * 0.1)
            elseif sprite:IsEventTriggered("Land") then
                REVEL.sfx:Play(SoundEffect.SOUND_FETUS_LAND, 0.7, 0, false, 1)
            end

            if sprite:IsFinished("Grab") or sprite:IsFinished("Grab_Holding") then
                data.Target = nil
                data.State = "Moving"
                sprite:Play(data.IdleAnim, true)
                if #data.HeldEntities == bal.MaxHeldNum then
                    data.IdleCount = math.random(bal.CooldownAfterGrabAll.Min, bal.CooldownAfterGrabAll.Max)
                end
            end
        end

    elseif data.State == "Shoot" then
        local target = npc:GetPlayerTarget()

        if sprite:IsPlaying("Gulp") then
            for i = 1, bal.MaxHeldNum do
                if sprite:IsEventTriggered("Eat" .. i) and data.HeldEntities[i] then
                    data.ShouldRender[i] = false
                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_VAMP_GULP, 0.9, 0, false, 1)
                end
            end
        elseif sprite:IsFinished("Gulp") then
            local anim, flip = getSpitAnimFromVec(target.Position - npc.Position)
            data.SpitStartVel = target.Position - npc.Position
            data.SpitDir = REVEL.GetDirectionFromVelocity(target.Position - npc.Position)
            data.SpitAnim = anim
            sprite:Play(anim, true)
            sprite.FlipX = flip
        elseif REVEL.MultiFinishCheck(sprite, "Spit_Down", "Spit_Side", "Spit_Up") then
            if #data.HeldEntities == 0 then
                local anim = getSpitAnimFromVec(data.SpitStartVel, true)
                sprite:Play(anim, true)
            else
                sprite:Play(data.SpitAnim, true)
            end
        elseif REVEL.MultiFinishCheck(sprite, "Spit_End_Down", "Spit_End_Side", "Spit_End_Up") then
            sprite.FlipX = false
            data.IdleAnim = "Idle"
            data.IdleCount = nil
            sprite:Play("Idle", true)
            data.State = "Moving"
        end

        if sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_LITTLE_SPIT, 1, 0, false, 1)
            local offset = REVEL.dirToVel[data.SpitDir] * 20
            local vel = REVEL.dirToVel[data.SpitDir] * bal.ShootSpeed

            local ent = Isaac.Spawn(data.HeldEntities[1].Type, data.HeldEntities[1].Variant, data.HeldEntities[1].SubType, npc.Position + offset, vel, npc)
            ent.HitPoints = REVEL.Lerp(data.HeldEntities[1].HitPoints, ent.MaxHitPoints, 0.25)
            ent:GetData().ShotByHuffpuff = true
            ent:GetData().ShotByHuffpuffVel = vel
            ent:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            ent:GetSprite():Play(ent:GetSprite():GetDefaultAnimationName(), true)
            REVEL.ZPos.SetData(ent, {
                ZPosition = 15, 
                ZVelocity = 0, 
                Gravity = 0.005, 
                FloatOnPits = true
            })
            REVEL.ZPos.UpdateEntity(ent)
            ent:GetSprite().Rotation = REVEL.dirToAngle[data.SpitDir] + 90

            table.remove(data.HeldEntities, 1)
        end

        if not REVEL.MultiPlayingCheck(sprite, "Spit_End_Down", "Spit_End_Side", "Spit_End_Up") then
            local diff = target.Position + target.Velocity - npc.Position
            if data.SpitDir == Direction.UP or data.SpitDir == Direction.DOWN then
                npc.Velocity = Vector(npc.Velocity.X * bal.Friction + sign(diff.X) * bal.TargetMoveAccel, 0)
            else
                npc.Velocity = Vector(0, npc.Velocity.Y * bal.Friction + sign(diff.Y) * bal.TargetMoveAccel)
            end
        else
            npc.Velocity = npc.Velocity * 0.85
        end
    elseif data.State == "HatTrick" then
        npc.Velocity = npc.Velocity * 0.85
        local target = npc:GetPlayerTarget()

        if sprite:IsEventTriggered("Shoot") then
            local offset = Vector(9 * REVEL.SCREEN_TO_WORLD_RATIO, 0)
            local vel = (target.Position - npc.Position - offset):Resized(4)
            local ent = REVEL.ENT.SNOWBALL:spawn(npc.Position + offset, vel, npc)
            ent:GetData().ShotByHuffpuff = true
            ent:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            ent:GetSprite():Play(ent:GetSprite():GetDefaultAnimationName(), true)
            REVEL.ZPos.SetData(ent, {
                ZPosition = 20 * REVEL.SCREEN_TO_WORLD_RATIO, 
                ZVelocity = 3, 
                Gravity = 0.25
            })
            REVEL.ZPos.UpdateEntity(ent)
        end

        if sprite:IsFinished("HatTrick") then
            data.IdleCount = math.random(bal.CooldownAfterGulp.Min, bal.CooldownAfterGulp.Max)
            sprite:Play("Idle", true)
            data.State = "Moving"
        end
    end
end, REVEL.ENT.HUFFPUFF.id)

local function huffpuff_Snowball_NpcUpdate(_, npc)
    if not (
        REVEL.ENT.SNOWBALL:isEnt(npc) 
        or REVEL.ENT.YELLOW_SNOWBALL:isEnt(npc) 
        or REVEL.ENT.STRAWBERRY_SNOWBALL:isEnt(npc)
    ) 
    or not npc:GetData().ShotByHuffpuff 
    then 
        return 
    end

    if npc:GetData().ShotByHuffpuffVel then
        npc.Velocity = npc:GetData().ShotByHuffpuffVel
    end

    if REVEL.ENT.YELLOW_SNOWBALL:isEnt(npc) and npc.FrameCount % 5 == 0 then
        REVEL.SpawnCreep(EffectVariant.CREEP_YELLOW, 0, npc.Position, npc, false)
    end
    npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
    npc:AddEntityFlags(EntityFlag.FLAG_NO_SPIKE_DAMAGE)

    if npc:CollidesWithGrid() then
        REVEL.ZPos.SetData(npc, {Gravity = 0.3})
        npc:GetData().ShotByHuffpuff = nil
        npc:GetSprite().Rotation = 0
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
        npc:ClearEntityFlags(EntityFlag.FLAG_NO_SPIKE_DAMAGE)

        REVEL.sfx:Play(SoundEffect.SOUND_MEAT_IMPACTS, 0.8, 0, false, 1)

        for i = 1, math.random(1, 4) do
            local eff = Isaac.Spawn(1000, EffectVariant.POOP_PARTICLE, 0, npc.Position + Vector(0, REVEL.ZPos.GetPosition(npc)), RandomVector() * math.random(1,5), npc)
            eff:GetData().NoGibOverride = true
            if REVEL.ENT.YELLOW_SNOWBALL:isEnt(npc) then
                eff.Color = Color(1, 1, 0, 1,conv255ToFloat( 0, 0, 0))
            elseif REVEL.ENT.STRAWBERRY_SNOWBALL:isEnt(npc) then
                eff.Color = Color(1, 0.75, 1, 1,conv255ToFloat( 85, 0, 0))
            else
                eff.Color = Color.Default
            end
            eff:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel1/snow_gibs.png")
            eff:GetSprite():LoadGraphics()
        end

        if REVEL.ENT.STRAWBERRY_SNOWBALL:isEnt(npc) then
            for i = 1, 4 do
                local p = REVEL.SpawnNPCProjectile(npc, Vector.FromAngle(45 + 90 * i) * 11)
                p:GetData().NoFrostyProjectile = true
                p.Color = REVEL.StrawberryCreepColor
            end
        end
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, huffpuff_Snowball_NpcUpdate, REVEL.ENT.SNOWBALL.id)
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, huffpuff_Snowball_NpcUpdate, REVEL.ENT.YELLOW_SNOWBALL.id)

local function huffpuff_Snowball_PostEntityAirMovementLand(npc, airMovementData, fromPit)
    if REVEL.ENT.SNOWBALL:isEnt(npc) or REVEL.ENT.YELLOW_SNOWBALL:isEnt(npc) or REVEL.ENT.STRAWBERRY_SNOWBALL:isEnt(npc) then
        npc:GetData().ShotByHuffpuff = nil
        npc:GetSprite().Rotation = 0

        REVEL.sfx:Play(SoundEffect.SOUND_MEAT_IMPACTS, 0.8, 0, false, 1)

        for i = 1, math.random(3, 5) do
            local eff = Isaac.Spawn(1000, EffectVariant.POOP_PARTICLE, 0, npc.Position, RandomVector() * math.random(1,5), npc)
            eff:GetData().NoGibOverride = true
            if REVEL.ENT.YELLOW_SNOWBALL:isEnt(npc) then
                eff.Color = Color(1, 1, 0, 1,conv255ToFloat( 0, 0, 0))
            elseif REVEL.ENT.STRAWBERRY_SNOWBALL:isEnt(npc) then
                eff.Color = Color(1, 0.75, 1, 1,conv255ToFloat( 85, 0, 0))
            else
                eff.Color = Color.Default
            end
            eff:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel1/snow_gibs.png")
            eff:GetSprite():LoadGraphics()
        end
    end
end

revel:AddCallback(RevCallbacks.POST_ENTITY_ZPOS_LAND, huffpuff_Snowball_PostEntityAirMovementLand, REVEL.ENT.SNOWBALL.id)
revel:AddCallback(RevCallbacks.POST_ENTITY_ZPOS_LAND, huffpuff_Snowball_PostEntityAirMovementLand, REVEL.ENT.YELLOW_SNOWBALL.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc, renderOffset)
    if not REVEL.ENT.HUFFPUFF:isEnt(npc) or npc:IsDead() then return end

    local sprite, data = npc:GetSprite(), npc:GetData()

    if REVEL.IsNpcChampionRegenerating(npc) then
        data.State = nil
    end

    if not data.State then return end

    local anim = sprite:GetAnimation()
    local heldNum = #data.HeldEntities

    local nullFrames = {}
    nullFrames[1] = sprite:GetNullFrame(NullNames.HELD0)
    nullFrames[2] = sprite:GetNullFrame(NullNames.HELD1)
    nullFrames[3] = sprite:GetNullFrame(NullNames.HELD2)

    if (nullFrames[1] or nullFrames[2]) and heldNum > 0 then
        if not nullFrames[3] then --grab/holding handling
            local spriteScaleCopy = REVEL.CloneVec(npc.SpriteScale)
            local offset = nullFrames[1] and nullFrames[1]:GetPos() * spriteScaleCopy or Vector.Zero
            local scale = nullFrames[1] and nullFrames[1]:GetScale() or Vector.One

            for i = 1, heldNum do
                offset = offset + SnowballOffsets[i] 
                    + Vector(SnowballOffsetXWaveLen[i] 
                        * math.sin(npc.FrameCount * 0.15 + SnowballOffsetXWaveDel[i]), 0)
                    
                if data.ShouldRender[i] then
                    local thisOffset = offset
                    local thisScale = scale
                    if i == data.GrabbingNum then
                        if nullFrames[2] then
                            local grabOffset, grabScale = nullFrames[2]:GetPos(), nullFrames[2]:GetScale()
                            thisScale = thisScale * grabScale
                            thisOffset = grabOffset
                        end
                        if AnimData[anim] and AnimData[anim].LerpToStackOffset then
                            thisOffset = REVEL.Lerp2Clamp(thisOffset, offset, sprite:GetFrame(), AnimData[anim].LerpStart, AnimData[anim].LerpEnd)
                        end
                    end
                    data.HeldSprites[i].Scale = thisScale
                    data.HeldSprites[i]:Render(Isaac.WorldToScreen(npc.Position) + thisOffset + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
                end
            end
        else
            local stackOffset = Vector.Zero
            for i = 1, heldNum do
                stackOffset = stackOffset + SnowballOffsets[i]
                if data.ShouldRender[i] then
                    local offset = nullFrames[i]:GetPos()
                    if AnimData[anim] and AnimData[anim].LerpFromStackOffset then
                        offset = offset + REVEL.Lerp2Clamp(stackOffset, Vector.Zero, sprite:GetFrame(), AnimData[anim].LerpStart, AnimData[anim].LerpEnd)
                    end

                    data.HeldSprites[i].Scale = nullFrames[i]:GetScale()
                    data.HeldSprites[i]:Render(Isaac.WorldToScreen(npc.Position) + offset + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
                end
            end
        end
    end
end, REVEL.ENT.HUFFPUFF.id)

end