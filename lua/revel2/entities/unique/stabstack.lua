local RevCallbacks = require "lua.revelcommon.enums.RevCallbacks"
local ProjectilesMode = require "lua.revelcommon.enums.ProjectilesMode"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

--[[
-A tall segmented cactus that slowly moves around. The amount of 
segments it has is defined by the room editor.
    - Filloax's note: amount of segments = subtype - 1, so that
    subtype 0 is used as default for `spawn` command etc

-After taking a certain amount of damage, the segment at the very 
bottom will get shot backwards and will start quickly rolling and 
bouncing around, eventually losing momentum.
Once detached, a segment basically works like a Singe ball, and 
can pushed around by enemies and Isaac's body/tears, but deals 
contact damage. Segments can't be killed in that state.
The more the stack is damaged, the more of its segments will get 
shot out, until only the head remains.

-When detached, the head will bounce around, trying to avoid Isaac. 
It will occasionally stop and shoot out a bunch of needle projectiles
that travels quickly and has medium range.
Once the head is killed, all of its other segments will disappear.
]]

--[[
    Anims:
    Head_Idle
    Body_[1-3]_Idle
    Body_Roll
    Head_Fall
    Head_Hop
    Head_Shoot

    Events:
    Hop
    Shoot
    Land
]]

local PART_OFFSET = 20
local FALL_DURATION = 10
local MOVE_ACCEL = 0.5
local MOVE_FRICTION = 0.65
local HEAD_HOP_SPEED = 5
local SHOOT_TIME = {Min = 30, Max = 90}
local PROJ_NUM = 5
local ROLLING_ANIM_LEN = 8

---@param npc EntityNPC
local function stabstack_Init(_, npc)
    if not REVEL.ENT.STABSTACK:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), npc:GetData()

    -- Doesn't include head
    local partNum = 3
    -- subtype 0: manually spawned
    if npc.SubType > 0 then 
        partNum = npc.SubType - 1
    end

    local offset = -PART_OFFSET * npc.SpriteScale.Y

    data.PartNum = partNum    
    data.Parts = {}
    for i = 1, partNum do
        local part = REVEL.ENT.STABSTACK_PIECE:spawn(npc.Position, Vector.Zero, npc)
        if npc:IsChampion() then
            part:ToNPC():MakeChampion(npc.InitSeed, npc:GetChampionColorIdx())
        end
        part:ToNPC().Scale = npc.Scale
        part:GetData().StabstackParent = EntityPtr(npc)
        part:GetData().StabstackIdx = i
        part:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        part.DepthOffset = - data.PartNum - 5 + i

        part:GetSprite():Play("Body_" .. math.random(1, 3) .. "_Idle", true)
        REVEL.SkipAnimFrames(part:GetSprite(), math.random(6)) --desync parts

        if i > 1 then
            part.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            part.SpriteOffset = Vector(0, offset * (i - 1))
        end

        data.Parts[i] = EntityPtr(part)
    end

    -- One for each segment killed at the same time, in case it managed to somehow
    data.FallCounters = {}

    if data.PartNum > 0 then
        sprite:Play("Head_Idle", true)
        npc.SpriteOffset = Vector(0, offset * partNum)
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    else
        sprite:Play("Head_Fall", true)
        data.ShootCounter = math.floor(REVEL.GetFromMinMax(SHOOT_TIME)/2)
    end

    npc.Mass = 50
end

---@param npc Entity # Stabstack segment, or head to shoot lowest segment
---@param dir Vector
---@param parent? Entity
---@param remove? boolean
function REVEL.ShootStabstackSegment(npc, dir, parent, remove)
    if remove == nil then remove = true end -- only not to be used here in take damage

    local data = npc:GetData()

    if REVEL.ENT.STABSTACK:isEnt(npc) then
        if data.PartNum == 0 then
            return
        end

        local part = data.Parts[1] and data.Parts[1].Ref
        if not part then
            REVEL.DebugToString("Warning: no first stabstack segment when shooting one away from the head")
            return
        end
        parent = npc
        npc = part
        data = part:GetData()
    end

    if not parent then
        parent = data.StabstackParent and data.StabstackParent.Ref
        if not parent then 
            REVEL.DebugStringMinor("Warning: stabstack part shot with no parent")
            return
        end
        if parent:ToNPC().State == NpcState.STATE_APPEAR then
            return false
        end
    end

    data.SpawnedRolling = true

    local offset = -PART_OFFSET * parent.SpriteScale.Y * (data.StabstackIdx - 1)
    local horiSpeed = 10
    local zSpeed = 8
    local rollingPart = REVEL.ENT.STABSTACK_ROLLING:spawn(npc.Position, dir * horiSpeed, parent)
    rollingPart:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    REVEL.ZPos.SetData(rollingPart, {
        ZPosition = -offset,
        ZVelocity = zSpeed,
        Bounce = 0.75,
        BounceFromGrid = true,
    })
    rollingPart:GetSprite():SetFrame("Body_Roll", math.random(ROLLING_ANIM_LEN - 1))
    npc.Visible = false

    -- Ragma interaction
    if data.ragmaParent and data.ragmaParent.Ref then
        table.insert(data.ragmaParent.Ref:GetData().ragSnared, EntityPtr(rollingPart))
    end

    -- When called from other places, like ragtags
    if remove then
        npc:Remove()
    end
end

local function LoseSegment(npc, sprite, data, partIdx)
    data.FallCounters[partIdx] = FALL_DURATION
    if data.PartNum == 1 then
        sprite:Play("Head_Fall", true)
        data.ShootCounter = REVEL.GetFromMinMax(SHOOT_TIME)
    end
end

local function derefEntity(ePtr) return ePtr.Ref end

local function tableRemoveWithNils(tbl, idx, size)
    for i = idx, size - 1 do
        tbl[i]= tbl[i + 1]
    end
end

---@param npc EntityNPC
local function StabstackUpdate(npc)
    local sprite, data = npc:GetSprite(), npc:GetData()

    ---@type table<integer, Entity>
    local parts = REVEL.map(data.Parts, derefEntity)

    -- timer used to decrease spriteoffset to next step
    -- if present, currently falling to next segment
    if data.PartNum > 0 and not data.FallCounters[1] then
        -- get any movement obtained on the first part,
        -- and check for segment death
        local firstPart = parts[1]
        local segmentDied = not firstPart or firstPart:IsDead()
        if not segmentDied then
            if data.LastFirstPartVel then
                npc.Velocity = npc.Velocity + (firstPart.Velocity - data.LastFirstPartVel) * 0.5
            end
            data.LastFirstPartVel = firstPart.Velocity
        else
            LoseSegment(npc, sprite, data, 1)
        end
    end
    
    for i = 2, data.PartNum do
        local part = parts[i]
        if not data.FallCounters[i]
        and (not part or part:IsDead())
        then
            LoseSegment(npc, sprite, data, i) 
        end
    end

    local changedStack = false

    local offset = -PART_OFFSET * npc.SpriteScale.Y
    local fallOffset = 0

    for partIdx, _ in pairs(data.FallCounters) do
        data.FallCounters[partIdx] = data.FallCounters[partIdx] - 1

        if data.FallCounters[partIdx] <= 0 then
            data.FallCounters[partIdx] = nil
            tableRemoveWithNils(parts, partIdx, data.PartNum)
            changedStack = true
            data.LastFirstPartVel = nil
            data.PartNum = data.PartNum - 1

            if data.PartNum > 0 then
                parts[1].EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            else
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                npc.SpriteOffset = Vector.Zero
            end
        else
            local t = 1 - data.FallCounters[partIdx] / FALL_DURATION
            local pct = 1- (-1.9 * t^2 + 0.9 * t + 1)
            fallOffset = fallOffset - offset * pct
        end
    end

    if changedStack then
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_LAND)
        for i = 1, data.PartNum do
            parts[i]:GetData().StabstackIdx = i
            data.Parts[i] = EntityPtr(parts[i])
            parts[i].DepthOffset = - data.PartNum - 5 + i
        end
    end

    -- Actual AI

    if data.PartNum > 0 then
        if not sprite:IsPlaying("Head_Fall") then
            REVEL.MoveRandomlyAxisAligned(npc, 15, 60, MOVE_ACCEL, MOVE_FRICTION, true)
            local grid = REVEL.room:GetGridEntityFromPos(npc.Position + REVEL.dirToVel[data.MoveRandomlyDirection] * 40)
            if grid 
            and (
                grid:GetType() == GridEntityType.GRID_SPIKES
                or grid:GetType() == GridEntityType.GRID_SPIKES_ONOFF
            )
            then
                data.ReangleTime = 0
            end
        elseif sprite:IsEventTriggered("Land") then
            npc.Velocity = Vector.Zero
        else
            npc.Velocity = npc.Velocity * 0.95
        end
    else
        if sprite:IsFinished("Head_Fall") then
            sprite:Play("Head_Hop", true)
        end

        if sprite:IsPlaying("Head_Hop") then
            data.ShootCounter = data.ShootCounter - 1
            if data.ShootCounter <= 0 and sprite:GetFrame() == 0 then
                data.ShootCounter = REVEL.GetFromMinMax(SHOOT_TIME)
                sprite:Play("Head_Shoot", true)
            end
        end

        if sprite:IsPlaying("Head_Shoot") then
            npc.Velocity = npc.Velocity * 0.65

            if sprite:IsEventTriggered("Shoot") then
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.SPIKE_SHOT, 1, 0, false, 1.1)

                local params = ProjectileParams()
                params.FallingAccelModifier = 0.4
                local projSpeed = 15
                -- velocity explained in doc for ProjectilesMode.CIRCLE
                npc:FireProjectiles(npc.Position, Vector(projSpeed, PROJ_NUM), ProjectilesMode.CIRCLE, params)

                -- Reskin projectiles as they are not returned by FireProjectiles
                local pos = npc.Position
                REVEL.DelayFunction(function()
                    ---@type table<any, Entity>
                    local nearProjs = Isaac.FindInRadius(pos, projSpeed * 1.5, EntityPartition.BULLET)
                    for _, projectile in ipairs(nearProjs) do
                        if projectile.FrameCount == 0 
                        and projectile.SpawnerType == REVEL.ENT.STABSTACK.id
                        and projectile.SpawnerVariant == REVEL.ENT.STABSTACK.variant
                        then
                            local psprite = projectile:GetSprite()
                            psprite:Load("gfx/monsters/revel2/stabstack_needle.anm2", true)
                            psprite:Play(projectile:GetSprite():GetDefaultAnimation())
                            psprite.Rotation = projectile.Velocity:GetAngleDegrees()
                            projectile:GetData().Stabstack = true
                        end
                    end
                end, 0)
            end

        elseif sprite:IsFinished("Head_Shoot") then
            sprite:Play("Head_Hop", true)
        else -- anims with hop events
            if sprite:IsEventTriggered("Hop") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_JUMP)

                local fromIdx = REVEL.room:GetGridIndex(npc.Position)
                local target = npc:GetPlayerTarget()
                local targPos = target.Position
                local targIdx = REVEL.room:GetGridIndex(targPos)
                local path = REVEL.GeneratePathAStar(fromIdx, targIdx)
                if path and path[1] then
                    REVEL.FollowPath(
                        npc, 
                        HEAD_HOP_SPEED, 
                        path, 
                        true, 
                        1,
                        nil, nil, nil, nil,
                        true
                    )
                else
                    npc.Velocity = (targPos - npc.Position):Resized(HEAD_HOP_SPEED)
                end
            end
            if sprite:IsEventTriggered("Land") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_LAND)
            end

            if sprite:WasEventTriggered("Hop")
            and not sprite:WasEventTriggered("Land") 
            then 
                npc.Velocity = npc.Velocity * 0.95
            elseif sprite:IsPlaying("Head_Fall")
            and not sprite:WasEventTriggered("Hop")
            then
                npc.Velocity = npc.Velocity * 0.99
            else
                npc.Velocity = npc.Velocity * 0.65
            end
        end
    end

    -- Update segments, and sprite offset

    for i = 1, data.PartNum do
        local part = parts[i]
        if part and not part:IsDead() then
            local waveOffset = math.cos(npc.FrameCount * 0.09 + i * 5) * 3
            part.Position = npc.Position
            part.Velocity = npc.Velocity
            part.SpriteOffset = Vector(waveOffset, offset * (i - 1) + fallOffset)
            part:ToNPC().Scale = npc.Scale
        end
    end
    if data.PartNum > 0 then
        local waveOffset = math.cos(npc.FrameCount * 0.09) * 3
        npc.SpriteOffset = Vector(waveOffset, offset * data.PartNum + fallOffset)
    end
end

---@param npc EntityNPC
local function StabstackPartUpdate(npc)
    local sprite, data = npc:GetSprite(), npc:GetData()
    local parent = data.StabstackParent and data.StabstackParent.Ref
    if not parent
    or parent:IsDead() then
        npc:Die()
    elseif parent:ToNPC().State == NpcState.STATE_APPEAR then
        npc.Velocity = Vector.Zero
    end
end

---@param npc EntityNPC
local function StabstackRollingUpdate(npc)
    local parent = npc.SpawnerEntity
    if not parent
    or parent:IsDead() then
        npc:Die()
    else
        local sprite, data = npc:GetSprite(), npc:GetData()

        if REVEL.ZPos.GetPosition(npc) <= 0 then
            npc.Velocity = npc.Velocity * 0.98
        end

        local speed = npc.Velocity:Length()

        local playbackSpeed = 0 --emulate as works weird with negative speed
        if speed > 0.5 then
            playbackSpeed = REVEL.SmoothLerp2(0.3, 1, speed, 0, 12)
        else
            npc.Velocity = Vector.Zero
        end
        if npc.Velocity.Y < 0 then
            playbackSpeed = -playbackSpeed
        end

        data.Frame = ((data.Frame or 0) + playbackSpeed) % ROLLING_ANIM_LEN
        sprite:SetFrame(REVEL.Round(data.Frame))
    end
end

local function stabstack_NpcUpdate(_, npc)
    if REVEL.ENT.STABSTACK:isEnt(npc) then 
        StabstackUpdate(npc)
    elseif REVEL.ENT.STABSTACK_PIECE:isEnt(npc) then
        StabstackPartUpdate(npc)
    elseif REVEL.ENT.STABSTACK_ROLLING:isEnt(npc) then
        StabstackRollingUpdate(npc)
    end
end

---@param entity Entity
---@param airMovementData AirMovementData
---@param landFromGrid boolean
local function StabstackRolling_EntityAirMovementLand(entity, airMovementData, landFromGrid)
    if math.abs(airMovementData.ZVelocity) > 0.85 then
        REVEL.sfx:Play(SoundEffect.SOUND_ANIMAL_SQUISH, 0.85, 0, false, 0.9)
    end
end

local function stabstack_EntityAirMovementLand(entity, airMovementData, landFromGrid)
    if REVEL.ENT.STABSTACK_ROLLING:isEnt(entity) then
        return StabstackRolling_EntityAirMovementLand(entity, airMovementData, landFromGrid)
    end
end

---@param entity Entity
---@param dmg number
---@param flag integer
---@param source EntityRef
---@param invuln integer
local function StabstackPiece_EntityTakeDmg(entity, dmg, flag, source, invuln)
    local data = entity:GetData()

    local parent = data.StabstackParent and data.StabstackParent.Ref
    if not parent then 
        REVEL.DebugStringMinor("Warning: stabstack part damaged with no parent")
        return
    end
    if parent:ToNPC().State == NpcState.STATE_APPEAR then
        return false
    end

    if entity.HitPoints - dmg - REVEL.GetDamageBuffer(entity) <= 0
    and not data.SpawnedRolling then
        local dir
        if source.Position then
            dir = (entity.Position - source.Position):Normalized()
        else
            dir = RandomVector()
        end
        dir = dir:Rotated(math.random(-15, 15))

        REVEL.ShootStabstackSegment(entity, dir, parent, false)
    end
end

---@param entity Entity
---@param dmg number
---@param flag integer
---@param source EntityRef
---@param invuln integer
local function Stabstack_EntityTakeDmg(entity, dmg, flag, source, invuln)
    if HasBit(flag, DamageFlag.DAMAGE_SPIKES) then
        return false
    end
end

local function stabstack_EntityTakeDmg(_, entity, dmg, flag, source, invuln)
    if REVEL.ENT.STABSTACK_PIECE:isEnt(entity) then 
        return StabstackPiece_EntityTakeDmg(entity, dmg, flag, source, invuln)
    elseif REVEL.ENT.STABSTACK:isEnt(entity) then
        return Stabstack_EntityTakeDmg(entity, dmg, flag, source, invuln)
    end
end

---@param poof Entity
---@param data table
---@param sprite Sprite
---@param parent Entity
---@param grandparent Entity
local function stabstack_BulletPoof(poof, data, sprite, parent, grandparent)
    if REVEL.ENT.STABSTACK:isEnt(grandparent) then
        for i = 1, math.random(5, 9) do
            local dir = RandomVector()
            REVEL.SpawnParticleGibs(
                "gfx/monsters/revel2/stabstack_needle_gibs_035_tooth.anm2", 
                poof.Position + dir * 1, 
                dir * 3,
                EffectVariant.TOOTH_PARTICLE
            )
        end
        REVEL.sfx:Play(SoundEffect.SOUND_SCYTHE_BREAK)
        poof:Remove()
    end
end

-- This all assumes they all have the same type
revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, stabstack_Init, REVEL.ENT.STABSTACK.id)
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, stabstack_NpcUpdate, REVEL.ENT.STABSTACK.id)
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, stabstack_EntityTakeDmg, REVEL.ENT.STABSTACK.id)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_PROJ_POOF_INIT, 1, stabstack_BulletPoof)
revel:AddCallback(RevCallbacks.POST_ENTITY_ZPOS_LAND, stabstack_EntityAirMovementLand)

end