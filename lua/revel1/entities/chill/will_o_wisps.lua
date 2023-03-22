local ShrineTypes = require "lua.revelcommon.enums.ShrineTypes"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

--------------------------
-- CHILL / GRILL O WISP --
--------------------------
local ChillwispVecs = { --optimization
    (Vector.FromAngle(45)),
    (Vector.FromAngle(135)),
    (Vector.FromAngle(225)),
    (Vector.FromAngle(315)),
}

local WISP_SPEED = 4

local DEFAULT_ROOM_WIDTH = 520
local DEFAULT_ROOM_HEIGHT = 280
local ROOM_MARGIN = Vector(180, 120)

local WRAITH_COOLDOWN = 5.5 * 30

local WraithLastRoomIdx = -1
local WraithLastStage = -1

--[[revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, etype, variant, subtype, pos, velocity, spawner, seed)
if etype == REVEL.ENT.CHILL_O_WISP.id then
    if REVEL.chillroom and variant == REVEL.ENT.CHILL_O_WISP.variant then
    return {etype, REVEL.ENT.GRILL_O_WISP.variant, subtype, seed}
    elseif not REVEL.chillroom and variant == REVEL.ENT.GRILL_O_WISP.variant then
    return {etype, REVEL.ENT.CHILL_O_WISP.variant, subtype, seed}
    end
end
end)]]

REVEL.EmberParticle = REVEL.ParticleType.FromTable{
    Name = "Fire Ember",
    Anm2 =  "gfx/1000.066_ember particle.anm2",
    BaseLife = 40,
    Variants = 8,
    -- ScaleRandom = 0.2,
    StartScale = 1,
    EndScale = 1,
    Turbulence = true,
    TurbulenceReangleMinTime = 5,
    TurbulenceReangleMaxTime = 20,
    TurbulenceMaxAngleXYZ = Vec3(45,35,35),
    AnimationName = "Idle",
    OrientToMotion = true,
    Weight = 4.5,
}

REVEL.EmberParticleBlue = REVEL.ParticleType.FromTable{
    Name = "Fire Ember",
    Anm2 =  "gfx/1000.066_ember particle.anm2",
    BaseLife = 40,
    Variants = 8,
    -- ScaleRandom = 0.2,
    StartScale = 1,
    EndScale = 1,
    Turbulence = true,
    TurbulenceReangleMinTime = 5,
    TurbulenceReangleMaxTime = 20,
    TurbulenceMaxAngleXYZ = Vec3(45,35,35),
    AnimationName = "Idle",
    OrientToMotion = true,
    Weight = 4.5,
    Spritesheet = "gfx/effects/revel1/effect_ember_blue.png",
}

local h,s,v = hsvToRgb(0.02, 0.9, 0.6)
local lightColor = Color(h,s,v, 1,conv255ToFloat( 150,150,150))
local chilloColor = Color(0.5,0.5,0.5,1,conv255ToFloat(66,125,245))
local grilloColor = Color(0.5,0.5,0.5,1,conv255ToFloat(255,131,1))

local PARTICLE_EMITTER_ID = "Will o wisp Particle Emitter"

REVEL.Chillo = {}

function REVEL.Chillo.OnFreeze(entity)
    if REVEL.ENT.ICE_WRAITH:isEnt(entity) then
        entity:GetData().ChillCooldown = WRAITH_COOLDOWN
    end
end

local function IceWraithUpdate(npc, data)
    npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

    local baseDir = npc.Velocity:LengthSquared() > 0 and npc.Velocity or Vector(10, 0)

    local body, tail = data.WraithBody and data.WraithBody.Ref, data.WraithTail and data.WraithTail.Ref
    if not body then
        body = REVEL.ENT.ICE_WRAITH_BODY:spawn(npc.Position - baseDir, npc.Velocity, npc)
        body:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        body:GetSprite():Play("Body", true)
        body.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        data.WraithBody = EntityPtr(body)
    end
    if not tail then
        tail = REVEL.ENT.ICE_WRAITH_BODY:spawn(npc.Position - baseDir * 4, npc.Velocity, npc)
        tail:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        tail:GetSprite():Play("Tail", true)
        tail.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        data.WraithTail = EntityPtr(tail)
    end

    local segments = {npc, body, tail}
    local segmentTargetDists = {0, 18, 10}
    local a, f = 3, 0.5

    for i = 2, 3 do
        local dir
        if data.ChillCooldown then
            dir = REVEL.VEC_UP
        elseif math.abs(segments[i-1].Velocity.X) < 0.35 
        and math.abs(segments[i-1].Velocity.Y) < 0.35
        then
            if segments[i-1].Position:DistanceSquared(segments[i].Position) > 0 then
                dir = (segments[i-1].Position - segments[i].Position):Normalized()
            else
                dir = REVEL.VEC_DOWN
            end
        else
            dir = segments[i-1].Velocity:Normalized()
        end
        local targetPos = segments[i-1].Position - dir * segmentTargetDists[i]
        local dist = segments[i].Position:Distance(targetPos)
        segments[i].Velocity = segments[i].Velocity * f + (targetPos - segments[i].Position):Resized(math.min(dist, a))
    end

    for i, segment in ipairs(segments) do
        local t = (npc.FrameCount - (i-1) * 3) / 10
        local off = segment.SpriteOffset
        segment.SpriteOffset = Vector(math.sin(t) * 3, off.Y)
    end
end

---@param npc EntityNPC
local function chilloWisp_NpcUpdate(_, npc)
    if REVEL.ENT.CHILL_O_WISP:isEnt(npc)
    or REVEL.ENT.GRILL_O_WISP:isEnt(npc, false)
    or REVEL.ENT.ICE_WRAITH:isEnt(npc, true)
    then
        local sprite, data = npc:GetSprite(), npc:GetData()

        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

        --GRILL INIT
        if npc.Variant == REVEL.ENT.GRILL_O_WISP.variant then
            npc.SplatColor = grilloColor
            if not data.Init then
                if not data.SpriteChanged and npc.SubType == 1 then
                    local spritesheet = "gfx/monsters/revel1/chill_o_wisp_hot_small.png"
                    npc:GetSprite():ReplaceSpritesheet(0, spritesheet)
                    npc:GetSprite():ReplaceSpritesheet(1, spritesheet)
                    npc:GetSprite():LoadGraphics()
                end
                data.radius = REVEL.GetChillWarmRadius()
                if npc.SubType == 1 then
                    data.radius = data.radius * 0.6
                end

                REVEL.SpawnLightAtEnt(npc, lightColor, 2.5, Vector(0, -15))
                REVEL.SpawnLightAtEnt(npc, Color.Default, 2.5, Vector(0, -15), false, false, 1000, EffectVariant.RED_CANDLE_FLAME, 0)

                npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)

                data.Init = true
                return
            end

            REVEL.SetWarmAura(npc, data.radius)

        --CHILL INIT
        else
            if not data.Init then
                if not data.SpriteChanged and npc.SubType == 1 then
                    local spritesheet = "gfx/monsters/revel1/chill_o_wisp_small.png"
                    npc:GetSprite():ReplaceSpritesheet(0, spritesheet)
                    npc:GetSprite():ReplaceSpritesheet(1, spritesheet)
                    npc:GetSprite():LoadGraphics()
                end

                data.radius = REVEL.GetChillFreezeRadius()
                if npc.SubType == 1 then
                    data.radius = data.radius * 0.7
                end
                REVEL.SetChillAura(npc, data.radius)
                REVEL.SpawnLightAtEnt(npc, lightColor, 2.5, Vector(0, -15))
                REVEL.SpawnLightAtEnt(npc, Color.Default, 2.5, Vector(0, -15), false, false, 1000, EffectVariant.BLUE_FLAME, 0)

                if REVEL.ENT.ICE_WRAITH:isEnt(npc) then
                    npc:AddEntityFlags(EntityFlag.FLAG_PERSISTENT)

                    local dir = (REVEL.getClosestInTable(REVEL.players, npc).Position - npc.Position):Normalized()

                    local body = REVEL.ENT.ICE_WRAITH_BODY:spawn(npc.Position - dir * 10, npc.Velocity, npc)
                    local tail = REVEL.ENT.ICE_WRAITH_BODY:spawn(npc.Position - dir * 40, npc.Velocity, npc)
                    body:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    tail:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

                    body:GetSprite():Play("Body", true)
                    tail:GetSprite():Play("Tail", true)
                    data.WraithBody = EntityPtr(body)
                    data.WraithTail = EntityPtr(tail)

                    WraithLastRoomIdx = REVEL.level:GetCurrentRoomIndex()
                    npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                    data.DSSMenuSafe = true
                    body:GetData().DSSMenuSafe = true
                    tail:GetData().DSSMenuSafe = true
                end
                
                npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)

                data.Init = true
            end

            npc.SplatColor = chilloColor
        end

        if not REVEL.HasEntityParticleEmitter(npc, PARTICLE_EMITTER_ID) then
            REVEL.AddEntityParticleEmitter(npc, REVEL.Emitter(), PARTICLE_EMITTER_ID)
        end

        local particleEmitter = REVEL.GetEntityParticleEmitter(npc, PARTICLE_EMITTER_ID)

        npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

        if sprite:IsFinished("Appear") then
            npc.State = NpcState.STATE_MOVE
        elseif sprite:IsFinished("Death") then
            npc:Kill()
        end

        --FLY AROUND
        if npc.State == NpcState.STATE_MOVE then
            if not REVEL.MultiPlayingCheck(npc:GetSprite(), "FlickerRed") then
                if REVEL.ENT.ICE_WRAITH:isEnt(npc) then
                    if data.ChillCooldown then
                        if not sprite:GetAnimation():starts("Cooldown") then
                            sprite:Play("Cooldown_start", true)
                        elseif sprite:IsFinished("Cooldown_start") then
                            sprite:Play("Cooldown_loop", true)
                        end
                    elseif not sprite:IsPlaying("Cooldown_end") then
                        REVEL.AnimateWalkFrame(
                            sprite, npc.Velocity, 
                            {Horizontal = "Idle_Left", Down = "Idle", Up = "Idle_Up"}, 
                            true
                        )
                    end
                else
                    REVEL.PlayIfNot(sprite, "Idle", true)
                end
            end

            if npc.Variant == REVEL.ENT.GRILL_O_WISP.variant then
                local vel = npc.Velocity
                if vel.X < 0 then vel.X=vel.X*-1 end
                if vel.Y < 0 then vel.Y=vel.Y*-1 end
                if vel.X+vel.Y <= 1 then
                    if data.ForceDirection then
                        ---@diagnostic disable-next-line
                        npc.Velocity = ChillwispVecs[data.ForceDirection] * WISP_SPEED
                    else
                        npc.Velocity = ChillwispVecs[math.random(1,4)] * WISP_SPEED
                    end
                end
                if not data.StayStill then
                    local angle = npc.Velocity:GetAngleDegrees() % 360
                    local dir = math.floor(angle / 90) + 1
                    npc.Velocity = ChillwispVecs[dir] * WISP_SPEED
                    if REVEL.IsShrineEffectActive(ShrineTypes.FROST) then
                        npc.Velocity = npc.Velocity * 1.5
                    end
                end

                REVEL.SpawnFireParticles(npc, -40, 20)
                particleEmitter:EmitParticlesPerSec(REVEL.EmberParticle, REVEL.FireSystem, Vec3(npc.Position.X + (math.random() * 2 - 1) * 20, npc.Position.Y, -40), -Vec3(0, 0, -5), 5, 0.5, 60)

                --if any grillos overlapping this one (can be caused by draugr), go in a random direction
                if npc.FrameCount % 15 == 0 then
                    local grillos = Isaac.FindByType(npc.Type, npc.Variant, -1, true, false)
                    for i, ent in ipairs(grillos) do
                        if ent.Index ~= npc.Index and ent.Position:DistanceSquared(npc.Position) < 5 and ent.Velocity:DistanceSquared(npc.Velocity) < 5 then
                            npc.Velocity = npc.Velocity:Rotated(90 * math.ceil(math.random(3)))
                        end
                    end
                end
            else
                local target = npc:GetPlayerTarget()
                local speed
                if npc.SubType == 1 then
                    speed = 0.12
                else
                    speed = 0.08
                end
                if REVEL.IsShrineEffectActive(ShrineTypes.FROST) then
                    speed = speed * 1.5
                end
                if REVEL.ENT.ICE_WRAITH:isEnt(npc) and not REVEL.room:IsPositionInRoom(npc.Position, 0) then
                    speed = speed * 1.75
                end

                local friction = 0.975

                if REVEL.ENT.ICE_WRAITH:isEnt(npc) then
                    data.ChillTimer = 0.5 * 30
                    IceWraithUpdate(npc, data)
                end

                local stayStill = data.StayStill or DeadSeaScrollsMenu.IsOpen()

                if not stayStill and not data.ChillCooldown then
                    REVEL.UsePathMap(REVEL.GenericFlyingChaserPathMap, npc)
                    if data.Path then
                        REVEL.FollowPath(npc, speed, data.Path, true, friction, false, true)
                    else
                        npc.Velocity = npc.Velocity * friction + (target.Position - npc.Position):Resized(speed)
                    end

                    local otherChillos = REVEL.filter(REVEL.ENT.CHILL_O_WISP:getInRoom(false, true, false), function(chillo2)
                        return chillo2.Index ~= npc.Index and chillo2:GetData().radius
                    end)

                    for _, chillo2 in ipairs(otherChillos) do
                        if chillo2.Position:DistanceSquared(npc.Position) <= ((data.radius + chillo2:GetData().radius) * 0.65) ^ 2 then
                            npc.Velocity = npc.Velocity + (npc.Position - chillo2.Position):Resized(speed * 0.5)
                        end
                    end
                else
                    npc.Velocity = npc.Velocity * 0.75
                end

                local chillAuraOn = not REVEL.IncludesWarmAura(npc)

                if data.ChillCooldown then
                    chillAuraOn = false
                    data.ChillCooldown = data.ChillCooldown - 1
                    if data.ChillCooldown <= 30 then
                        if math.floor(data.ChillCooldown / 2) % 2 == 0 then
                            npc.Color = Color(1.1,1.1,1.1, 1, 0.1, 0.1, 0.1)
                        else
                            npc.Color = Color.Default
                        end
                    end

                    if data.ChillCooldown <= 0 then
                        npc.Color = Color.Default
                        data.ChillCooldown = nil
                        sprite:Play("Cooldown_end", true)
                    end
                end

                -- REVEL.DebugLog("chill aura on", chillAuraOn, npc, "Includes warm aura", REVEL.IncludesWarmAura(npc))

                if chillAuraOn then
                    -- update timer if set
                    local timer = data.ChillTimer or nil
                    REVEL.SetChillAura(npc, data.radius, nil, timer)

                    REVEL.EnableChillAura(npc)
                else
                    REVEL.DisableChillAura(npc)
                    if data.ChillPlayer then
                        for _, player in ipairs(REVEL.players) do
                            if player.Index == data.ChillPlayer then
                                player:GetData().ChillAuraTimer = nil
                            end
                        end
                        data.ChillPlayer = nil
                        REVEL.sfx:Stop(REVEL.SFX.ICE_BEAM)
                    end
                end

                if not data.ChillCooldown then
                    REVEL.SpawnFireParticles(npc, -40, 20, nil, REVEL.EmberParticleBlue.Spritesheet)
                    particleEmitter:EmitParticlesPerSec(REVEL.EmberParticleBlue, REVEL.FireSystem, Vec3(npc.Position.X + (math.random() * 2 - 1) * 20, npc.Position.Y, -40), -Vec3(0, 0, -5), 5, 0.5, 60)
                end
            end

            if REVEL.room:IsClear() and Isaac.CountEnemies() <= 0 and npc.Variant == REVEL.ENT.CHILL_O_WISP.variant then --only chill o wisps die on room clear
                npc.State = NpcState.STATE_SUICIDE
                npc:GetSprite():Play("Death", true)
            end
        elseif npc.State == NpcState.STATE_SUICIDE then
            npc.Velocity = Vector.Zero
        end

        if data.IsProjectile then
            npc.Velocity = data.ProjectileVelocity
            if data.MaxMarginOutsideRoom and not REVEL.room:IsPositionInRoom(npc.Position, data.MaxMarginOutsideRoom) then
                npc:Remove()
            end
        end
    elseif REVEL.ENT.ICE_WRAITH_BODY:isEnt(npc, true) then
        local data = npc:GetData()
        if not data.Init then
            data.Init = true
            npc:AddEntityFlags(EntityFlag.FLAG_PERSISTENT)
        end
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

        if npc.SpawnerEntity then
            if npc.SpawnerEntity:GetSprite():IsPlaying("Appear") then
                npc.Velocity = npc.Velocity * 0.2
            end
        end
    end
end

local function chilloWisp_Fireplace_NpcUpdate(_, npc)
    if REVEL.IsChilly() then
        if npc.HitPoints <= 1 
        and not npc:GetData().SpawnedGrillo 
        and npc.SpawnerType ~= EntityType.ENTITY_BOMB
        then
            local grillo = Isaac.Spawn(REVEL.ENT.GRILL_O_WISP.id, REVEL.ENT.GRILL_O_WISP.variant, 1, npc.Position, Vector.Zero, nil)
            npc:GetData().SpawnedGrillo = true
        end
    end
end

local function iceWraith_PostNewRoom()
    local wraithNum = REVEL.ENT.ICE_WRAITH:countInRoom(true)
    if REVEL.IsShrineEffectActive(ShrineTypes.ICE_WRAITH) 
    and REVEL.Glacier.RoomGoodForIceWraith() then
        local currentIdx = REVEL.level:GetCurrentRoomIndex()
        if wraithNum > 0 then
            local wraiths = REVEL.ENT.ICE_WRAITH:getInRoom(true)
            for i = 2, wraithNum do
                wraiths[i]:Remove()
            end

            local wraith = wraiths[1]
            local prevPos = wraith.Position

            if currentIdx >= 0 and WraithLastRoomIdx >= 0 and WraithLastStage == REVEL.level:GetStage() then
                local prevRoomX, prevRoomY = StageAPI.GridToVector(WraithLastRoomIdx, 13)
                local curRoomX,  curRoomY  = StageAPI.GridToVector(currentIdx, 13)
                -- above previous room, move down
                if curRoomY < prevRoomY then
                    wraith.Position = wraith.Position + REVEL.VEC_DOWN * (DEFAULT_ROOM_HEIGHT + ROOM_MARGIN.Y)
                -- below previous room, move up
                elseif curRoomY > prevRoomY then
                    wraith.Position = wraith.Position + REVEL.VEC_UP * (DEFAULT_ROOM_HEIGHT + ROOM_MARGIN.Y)
                end
                -- left of previous room, move right
                if curRoomX < prevRoomX then
                    wraith.Position = wraith.Position + REVEL.VEC_RIGHT * (DEFAULT_ROOM_HEIGHT + ROOM_MARGIN.X)
                -- right of previous room, move left
                elseif curRoomX > prevRoomX then
                    wraith.Position = wraith.Position + REVEL.VEC_LEFT * (DEFAULT_ROOM_HEIGHT + ROOM_MARGIN.X)
                end
            else
                local dir = REVEL.dirToVel[math.random(0, 3)]
                wraith.Position = wraith.Position + dir * DEFAULT_ROOM_WIDTH * 0.65
            end
            WraithLastStage = REVEL.level:GetStage()

            local body, tail = wraith:GetData().WraithBody and wraith:GetData().WraithBody.Ref, wraith:GetData().WraithTail and wraith:GetData().WraithTail.Ref
            if body then
                body.Position = body.Position + wraith.Position - prevPos
            end
            if tail then
                tail.Position = tail.Position + wraith.Position - prevPos
            end

            if wraith:GetData().ChillCooldown then
                wraith:GetData().ChillCooldown = 0
            end
        else
            REVEL.DebugStringMinor("Pact of the Ice Wraith | No wraiths, spawning...")

            local c, tl = REVEL.room:GetCenterPos(), REVEL.room:GetTopLeftPos()
            local pos = Vector(tl.X - 200, c.Y)
            REVEL.ENT.ICE_WRAITH:spawn(pos, Vector(10, 0), nil)
        end
        WraithLastRoomIdx = currentIdx
    elseif wraithNum > 0 then
        REVEL.DebugStringMinor("Pact of the Ice Wraith | Wraiths with pact not active, removing...")
        for _, npc in ipairs(REVEL.ENT.ICE_WRAITH:getInRoom()) do
            REVEL.RemoveChillAura(npc)
            npc:Remove()
        end
    end
end

local function iceWraith_PostNewLevel()
    WraithLastRoomIdx = -1
    
    -- do check again, as stageapi level checks are done after new room
    iceWraith_PostNewRoom()
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, chilloWisp_NpcUpdate, REVEL.ENT.CHILL_O_WISP.id)
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, chilloWisp_Fireplace_NpcUpdate, EntityType.ENTITY_FIREPLACE)
revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, iceWraith_PostNewRoom)
revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, iceWraith_PostNewLevel)

end