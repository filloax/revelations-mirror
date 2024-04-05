local RevCallbacks = require "scripts.revelations.common.enums.RevCallbacks"
return function()

--Find entities around pos in radius from partitions (EntityPartitions enum) except ones whose type is in blacklist table
function REVEL.MultiFindInRadius(pos, radius, partitions, blacklist)
    local ret = {}
    blacklist = blacklist or {}
    for _, partition in ipairs(partitions) do
        local ents = Isaac.FindInRadius(pos, radius, partition)
        for _, ent in ipairs(ents) do
            if not REVEL.includes(blacklist, ent.Type) then
              ret[#ret + 1] = ent
            end
        end
    end

    return ret
end

-- primarily made to be used with GetNClosestEntities i.e, (pos, entities, 3, REVEL.IsTargetableEntity, ...)
function REVEL.IsTargetableEntity(ent) 
    return not ent:HasEntityFlags(EntityFlag.FLAG_NO_TARGET)
end

-- primarily made to be used with GetNClosestEntities i.e, (pos, entities, 3, REVEL.IsTargetableEntity, ...)
function REVEL.IsNotFriendlyEntity(ent) 
    return not ent:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
end

-- primarily made to be used with GetNClosestEntities i.e, (pos, entities, 3, REVEL.IsTargetableEntity, ...)
function REVEL.IsVulnerableEnemy(ent) 
    return ent:IsVulnerableEnemy()
end

function REVEL.GetNClosestEntities(position, entities, n, ...)
    local outEnts = {}

    local checks = {...}
    for _, ent in ipairs(entities) do
        local d = ent.Position:Distance(position)
        if #outEnts < n then
            local valid = true
            for _, check in ipairs(checks) do
                if not check(ent) then
                    valid = false
                end
            end

            if valid then
                outEnts[#outEnts + 1] = {
                    E = ent,
                    D = d
                }
            end
        else
            local highestDist, highIndex
            for index, distData in ipairs(outEnts) do
                if not highestDist or distData.D > highestDist then
                    highestDist = distData.D
                    highIndex = index
                end
            end

            if highIndex and highestDist and highestDist > d then
                local valid = true
                for _, check in ipairs(checks) do
                    if not check(ent) then
                        valid = false
                    end
                end

                if valid then
                    outEnts[highIndex] = {
                        E = ent,
                        D = d
                    }
                end
            end
        end
    end

    local outEntities = {}
    for _, distData in ipairs(outEnts) do
        outEntities[#outEntities + 1] = distData.E
    end

    return outEntities
end

function REVEL.getClosestEnemy(from, linecheck, vulnerable, targetable, ignoreFriendly, includeSelf)
    local dist,targ = nil,nil
    for i,e in ipairs(REVEL.roomEnemies) do
        local d = e.Position:Distance(from.Position)
    
        if (not dist or d < dist)
        and (not linecheck or REVEL.room:CheckLine(e.Position, from.Position, 1, 0, false, false))
        and (not vulnerable or e:IsVulnerableEnemy())
        and not (targetable and e:HasEntityFlags(EntityFlag.FLAG_NO_TARGET))
        and not (ignoreFriendly and e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY))
        and (includeSelf or GetPtrHash(from) ~= GetPtrHash(e)) then
            dist = d
            targ = e
        end
    end
  
    return targ
end
  
function REVEL.getRandomEnemy(vulnerable, ignoreFriendly)
    if #REVEL.roomEnemies ~= 0 then
        local targ, i = nil, 0
    
        repeat
            targ = REVEL.randomFrom(REVEL.roomEnemies)
            i = i + 1
        until ( (not vulnerable or targ:IsVulnerableEnemy()) and not (ignoreFriendly and targ:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)) ) or i == 100
    
        return targ
    end
end

--- get closest entity of a table from another entity
---@param table Entity[]
---@param from Entity
---@param ifNotData? any
---@return Entity closest
---@return number distSquared
function REVEL.getClosestInTable(table, from, ifNotData)
    local dist,targ
    for i,e in ipairs(table) do
        if (not ifNotData or not REVEL.GetData(e)[ifNotData]) then
            local d = e.Position:DistanceSquared(from.Position)
            if (not dist or d < dist) 
            and e:Exists() and not e:IsDead() then
                dist = d
                targ = e
            end
        end
    end
  
    return targ, dist
end

-- get closest entity of a table from a position
function REVEL.getClosestInTableFromPos(table, pos, ifNotData, alsoDead)
    local dist,targ
    for i,e in ipairs(table) do
        if (not ifNotData or not REVEL.GetData(e)[ifNotData]) then
            local d = e.Position:DistanceSquared(pos)
            if (not dist or d < dist) and e:Exists() 
            and (alsoDead or not e:IsDead()) then
                dist = d
                targ = e
            end
        end
    end

    return targ, dist
end

--return t without all the entities that have a balcklisted type + variant
--blacklist: {Type = {Variant1, Variant2}, Type2 = {...
function REVEL.GetFilteredEntityList(t, list, white, vulnerable, targetable, ignoreFriendly)
    if white then
        return REVEL.GetFilteredArray(t, function(ent, list)
            return REVEL.IsTypeVariantInList(ent, list)
            and (not vulnerable or ent:IsVulnerableEnemy())
            and not (targetable and ent:HasEntityFlags(EntityFlag.FLAG_NO_TARGET))
            and not (ignoreFriendly and ent:HasEntityFlags(EntityFlag.FLAG_FRIENDLY))
        end, list)
    else
        return REVEL.GetFilteredArray(t, function(ent, list)
            return not REVEL.IsTypeVariantInList(ent, list)
            and (not vulnerable or ent:IsVulnerableEnemy())
            and not (targetable and ent:HasEntityFlags(EntityFlag.FLAG_NO_TARGET))
            and not (ignoreFriendly and ent:HasEntityFlags(EntityFlag.FLAG_FRIENDLY))
        end, list)
    end
end

---Takes a map of variant lists
---@param ent Entity
---@param blacklist {[EntityType]: integer[] | -1}
---@return boolean
function REVEL.IsTypeVariantInList(ent, blacklist)
    if blacklist[ent.Type] then
        return blacklist[ent.Type] == -1 or REVEL.includes(blacklist[ent.Type], ent.Variant)
    else
        return false
    end
end

---Takes a map of variant sets (more efficient)
---@param ent Entity
---@param blacklist {[EntityType]: {[integer]: true} | boolean}
function REVEL.IsTypeVariantInMap(ent, blacklist)
    if blacklist[ent.Type] then
        return blacklist[ent.Type] == true or blacklist[ent.Type][ent.Variant]
    else
        return false
    end
end

-- doc says Entity:CanShutDoors() is a function, 
-- but some subclasses have it as a boolean for some reason
function REVEL.CanShutDoors(e)
    if type(e.CanShutDoors) == "boolean" then
        return e.CanShutDoors
    elseif type(e.CanShutDoors) == "function" then
        return e:CanShutDoors()
    end
end

function REVEL.GetEntFromConst(constEnt)
    local matching = Isaac.FindByType(constEnt.Type, constEnt.Variant, constEnt.SubType, false, false)

    return REVEL.getClosestInTableFromPos(matching, constEnt.Position, nil, true)
end

---@param entRef EntityRef
---@return Entity?
function REVEL.GetEntFromRef(entRef)
    if entRef.Entity then
        return REVEL.GetEntFromConst(entRef.Entity)
    end
end

function REVEL.IsEntIn(entityDefList, ent)
    return REVEL.some(entityDefList, function(v) return v:isEnt(ent) end)
end

function REVEL.MeltEntity(e)
    REVEL.SpawnIceCreep(e.Position, e)
    local poof = Isaac.Spawn(1000, EffectVariant.POOF01, 0, e.Position, Vector.Zero, e)
    poof.Color = REVEL.CHILL_COLOR
    SFXManager():Play(SoundEffect.SOUND_FIREDEATH_HISS, 0.5, 0, false, 1.1+math.random()*0.3)
    e:Die()
    for i=1, 4 do
        REVEL.SpawnIceRockGib(e.Position, Vector.FromAngle(1*math.random(0, 360)):Resized(math.random(1, 5)), e)
    end
end

-- Assumes NPC doesn't use globin spritesheet by default
-- checks if npc is dark red champion and currently regenerating
function REVEL.IsNpcChampionRegenerating(npc)
    return npc:GetSprite():GetFilename() == "gfx/024.000_Globin.anm2"
end

local TrackedDamageBufferEntities = {}

-- Entity damage isn't immediately applied, but it is applied 
-- the frame after (which is why :HasMortalDamage is a thing). 
-- Use this to get the buffer if needed before it's applied for whatever reason
-- Info: https://wofsauge.github.io/IsaacDocs/rep/Entity.html#hitpoints
---@return number
function REVEL.GetDamageBuffer(entity)
    local eid = GetPtrHash(entity)
    local entry = TrackedDamageBufferEntities[eid]
    return entry and entry.Buffer or 0
end

-- If next frame HasMortalDamage will return true 
-- for this entity and then it will die, 
-- can optionally specify additional damage if used
-- within a damage callback
function REVEL.WillHaveMortalDamage(entity, newDamage)
    return entity.HitPoints - REVEL.GetDamageBuffer(entity) - (newDamage or 0) <= 0
end

local function trackDamageBuffer_Early_EntityTakeDmg(_, entity, damage)
    local eid = GetPtrHash(entity)
    local entry = TrackedDamageBufferEntities[eid]
    if entry and entry.LastFrame ~= entity.FrameCount then
        entry.Buffer = 0
        entry.LastFrame = entity.FrameCount
    end
end

local function trackDamageBuffer_EntityTakeDmg(entity, damage)
    local eid = GetPtrHash(entity)
    local entry = TrackedDamageBufferEntities[eid]
    if not entry then
        entry = {
            Buffer = 0,
            LastFrame = -1,
        }
        TrackedDamageBufferEntities[eid] = entry
    end
    entry.Buffer = entry.Buffer + damage
end

local function trackDamageBuffer_PostNewRoom()
    TrackedDamageBufferEntities = {}
end

---Meant for entities like players where a lot of different things
-- might try to change .Visible near each other, interfering;
-- this will try (at least for rev) to avoid interference in that
---@param entity Entity
---@param lockId any
function REVEL.LockEntityVisibility(entity, lockId)
    local data = REVEL.GetData(entity)
    data.EntityVisibleLock = data.EntityVisibleLock or {}
    if not data.EntityVisibleLock[lockId] then
        data.EntityVisibleLockNum = (data.EntityVisibleLockNum or 0) + 1

        if data.EntityVisibleLockNum == 1 then
            entity.Visible = false
        end
    end
    data.EntityVisibleLock[lockId] = true
end

---See `REVEL.LockEntityVisibility`
---@param entity Entity
---@param lockId any
function REVEL.UnlockEntityVisibility(entity, lockId)
    local data = REVEL.GetData(entity)
    if data.EntityVisibleLock and data.EntityVisibleLock[lockId] then
        data.EntityVisibleLockNum = data.EntityVisibleLockNum - 1
        data.EntityVisibleLock[lockId] = nil
        
        if data.EntityVisibleLockNum == 0 then
            entity.Visible = true
        end
    end
end

---@param entity Entity
function REVEL.DamageFlash(entity)
    local flashRed, flashDuration = Color(1,0.5,0.5,1,150,0,0), 3
    entity:SetColor(flashRed, flashDuration, 1, false, false)
end

-- The following requires Repentogon

---@param entity Entity
---@return table?
function REVEL.GetOverlayFrame(entity)
    return entity:GetSprite():GetNullFrame("OverlayEffect")
end

---@param entity Entity
---@return Vector?
function REVEL.GetOverlayPos(entity)
    local animFrame = REVEL.GetOverlayFrame(entity)
    return animFrame and animFrame:GetPos()
end

if not REPENTOGON then
    local function err() 
        error("Tried using Repentogon feature without Repentogon")
    end

    REVEL.GetOverlayFrame = err
    REVEL.GetOverlayPos = err
end



--Scale entity, since base game doesn't work in single npc updates

local ScaledEnts = {}

---@class CustomScaleData
---@field SpriteScale number | Vector # percent | Vector
---@field SizeScale number # percent
---@field HealthScale number # percent
---@field ScaleChildren boolean

---@param entity any #Entity
---@param customScaleData CustomScaleData
function REVEL.ScaleEntity(entity, customScaleData)
    local data = REVEL.GetData(entity)
    local hash = GetPtrHash(entity)

    if not ScaledEnts[hash] then
        ScaledEnts[hash] = entity
    end

    if type(customScaleData.SpriteScale) == "number" then
        customScaleData.SpriteScale = Vector.One * customScaleData.SpriteScale
    end

    entity.Size = entity.Size * (customScaleData.SizeScale or 1)

    local hp, maxHp = entity.HitPoints, entity.MaxHitPoints
    local minHp = 0
    hp = hp - minHp
    maxHp = maxHp - minHp

    local percentHP = hp / maxHp
    entity.MaxHitPoints = maxHp * (customScaleData.HealthScale or 1)
    entity.HitPoints = minHp + entity.MaxHitPoints * percentHP
    entity.MaxHitPoints = entity.MaxHitPoints + minHp

    data.CustomScaleData = customScaleData
end

function REVEL.ScaleChildEntity(parent, child)
    local data = REVEL.GetData(parent)
    if data.CustomScaleData and data.CustomScaleData.ScaleChildren then
        REVEL.ScaleEntity(child, data.CustomScaleData)
    end
end

local function scaleEntityPostUpdate()
    for hash, ent in pairs(ScaledEnts) do
        if not ent:Exists() then
            ScaledEnts[hash] = nil
        elseif REVEL.GetData(ent).CustomScaleData.SpriteScale then
            local doSetScale = true

            if ent.Type == EntityType.ENTITY_LASER then
                local laser = ent:ToLaser()
                if laser.Timeout < 0 then
                    local dieScaleMult = REVEL.Lerp2Clamp(1, 0, laser.Timeout, 0, -20)
                    ent.SpriteScale = REVEL.GetData(ent).CustomScaleData.SpriteScale * dieScaleMult
                    doSetScale = false
                end
            end

            if doSetScale then
                ent.SpriteScale = REVEL.GetData(ent).CustomScaleData.SpriteScale
            end
        end
    end
end

local function scaleEntityPostNewRoom()
    ScaledEnts = {}
end

local function scaleEntityNpcInit(npc)
    local parent = npc.SpawnerEntity or npc.Parent
    if parent then
        REVEL.ScaleChildEntity(parent, npc)
    end
end

-- Death events

---@alias Rev.OnDeath.Callback fun(npc: EntityNPC): string?
---@alias Rev.OnDeath.Render fun(npc: EntityNPC, triggeredEventThisFrame: boolean): boolean?

---Since during death state updates don't run, and keeping the dying npc in the death state is buggy,
---run updates in death (usually for sound events in sprites) during POST_NPC_RENDER
---@param onDeath Rev.OnDeath.Callback
---@param deathRender Rev.OnDeath.Render triggeredEventThisFrame resets every game framecount change, can be used to avoid playing an event twice due to render being at 60fps set it by returning true to the function
---@param npcId EntityType
---@param npcVariant integer
---@overload fun(handler: {OnDeath: Rev.OnDeath.Callback, DeathRender: Rev.OnDeath.Render, Type: EntityType, Variant: integer})
function REVEL.AddDeathEventsCallback(onDeath, deathRender, npcId, npcVariant)
    if type(onDeath) == "table" then
        local tbl = onDeath
        onDeath = tbl.OnDeath
        deathRender = tbl.DeathRender
        npcId = tbl.Type
        npcVariant = tbl.Variant
    end

    local function triggerDeath(npc, sprite, data)
        local anim = "Death"
        if onDeath then 
            local ret = onDeath(npc) 
            if ret ~= nil then
                anim = ret
            end
        end

        sprite:Play(anim, true)
        npc.Velocity = Vector.Zero
        npc.HitPoints = 0
        npc:RemoveStatusEffects()
        npc:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
        npc.State = NpcState.STATE_UNIQUE_DEATH
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        data.StartedDeath = true
        data.__startedDeath = true
    end

    revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
        if npc.Variant ~= npcVariant or not REVEL.IsRenderPassNormal() then return end

        local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

        if not data.__startedDeath and npc:HasMortalDamage() then
            triggerDeath(npc, sprite, data)
        end

        if data.__startedDeath and deathRender and not REVEL.game:IsPaused() then
            local triggeredEventThisFrame = deathRender(npc, data.__triggeredEventThisFrame)

            if REVEL.game:GetFrameCount() ~= data.__lastDeathRenderFrame then
                data.__lastDeathRenderFrame = REVEL.game:GetFrameCount()
                data.__triggeredEventThisFrame = nil
            end
            data.__triggeredEventThisFrame = data.__triggeredEventThisFrame or triggeredEventThisFrame
        end
    end, npcId)

    revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, entity)
        if entity.Variant ~= npcVariant then return end

        local npc = entity:ToNPC() or entity
        local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

        if not data.__startedDeath then
            triggerDeath(npc, sprite, data)
        end
    end, npcId)
end


--#region Fade Entities

local FadingSprites = {} --for sprite vars
local SpriteFadeDone = {} --used to detect if fade is done for that certain sprite
local FadedSpriteOrigColor = {}
local FadingEntities = {}

function REVEL.FadeEntity(e, time, fullOpacityTime)
fullOpacityTime = fullOpacityTime or 0
FadingEntities[e] = {timer = time+fullOpacityTime, fadeTime = time, initialColor = e.Color}
end

--for vars directly assigned to sprites that can be made nil, not entity sprites etc
function REVEL.FadeSprite(spr, time, fullOpacityTime)
fullOpacityTime = fullOpacityTime or 0
FadingSprites[spr] = {timer = time+fullOpacityTime, fadeTime = time}
FadedSpriteOrigColor[spr] = Color(spr.Color.R,spr.Color.G,spr.Color.B,spr.Color.A, spr.Color.RO, spr.Color.GO, spr.Color.BO)
end


revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
for e, t in pairs(FadingEntities) do
    t.timer = t.timer-1

    if t.timer == 0 or not e:Exists() then
        if e:Exists() then e:Remove() end

        FadingEntities[e] = nil
    else
        local spr = e:GetSprite()

        spr.Color = t.initialColor * Color(1, 1, 1, math.min(1, t.timer/t.fadeTime))
    end
end

for spr, t in pairs(FadingSprites) do
    t.timer = t.timer-1

    if t.timer == 0 then
        FadingSprites[spr] = nil
    else
        spr.Color= Color(spr.Color.R,spr.Color.G,spr.Color.B,
            math.min(1, spr.Color.A*t.timer/t.fadeTime), spr.Color.RO, spr.Color.GO, spr.Color.BO)
    end
end
end)
    
--#endregion


--#region Pushing Entities
--Due to how AIs work, pushing entities is kinda wonky, this here keeps adding velocity but reduced
local ents = {}
local entSeeds = {}
REVEL.PushBlacklist = {
    [REVEL.ENT.FATSNOW.id] = {REVEL.ENT.FATSNOW.variant},
    [EntityType.ENTITY_HOPPER] = {-1},
    [EntityType.ENTITY_PORTAL] = {-1},
    [EntityType.ENTITY_SHOPKEEPER] = {-1},
    [EntityType.ENTITY_BIG_HORN] = {-1}
}

function REVEL.PushEnt(e, force, dir, time, player, update, ignoreAlreadyPushed)
    local data = REVEL.GetData(e)

    local blacklisted = REVEL.PushBlacklist[e.Type] and (REVEL.PushBlacklist[e.Type][1] == -1 or REVEL.includes(REVEL.PushBlacklist[e.Type], e.Variant))

    if not entSeeds[e.InitSeed] and not blacklisted and e.Friction > 0
    and (data.RevPushingStillWorks or not (e:HasEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK) or e:HasEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)))
    and not (ignoreAlreadyPushed and entSeeds[e.InitSeed]) then
            if data.PushData then
            force = data.PushData.ForceMult and (force * data.PushData.ForceMult) or force
            time = data.PushData.TimeMult and math.floor(time * data.PushData.TimeMult) or time
        end

        e.Velocity = e.Velocity*0.3 + dir:Resized(force)

        ents[e] = force
        entSeeds[e.InitSeed] = true
        data.entPushCount = time
        data.entPushTime = time
        data.entPushUpdate = update
        data.pushDir = dir
        e:AddEntityFlags(EntityFlag.FLAG_SLIPPERY_PHYSICS)
        e.Target = nil
    end
end

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    for e, force in pairs(ents) do
        local data = REVEL.GetData(e)
        if e:Exists() and data and data.entPushCount then
            data.entPushCount = data.entPushCount - 1
            if data.entPushUpdate then
                data.entPushUpdate(e, data, force)
            end

            if data.entPushCount <= 0 then
                ents[e] = nil
                entSeeds[e.InitSeed] = nil
                e:ClearEntityFlags(EntityFlag.FLAG_SLIPPERY_PHYSICS)
            else
                e.Target = nil
        --        e:MultiplyFriction(1.3)
                e.Velocity = e.Velocity * 0.5 + data.pushDir:Resized( REVEL.Lerp(0, force, data.entPushCount / data.entPushTime) )
            end
        else
            ents[e] = nil
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    ents = {}
end)
--#endregion

    


-- Add at low priority
revel:AddPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CallbackPriority.IMPORTANT, trackDamageBuffer_Early_EntityTakeDmg)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 0, trackDamageBuffer_EntityTakeDmg)
revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, trackDamageBuffer_PostNewRoom)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, scaleEntityPostUpdate)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, scaleEntityPostNewRoom)
StageAPI.AddCallback("Revelations", RevCallbacks.NPC_UPDATE_INIT, 1, scaleEntityNpcInit)

end