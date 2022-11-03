REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

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
        if (not ifNotData or not e:GetData()[ifNotData]) then
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
        if (not ifNotData or not e:GetData()[ifNotData]) then
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

local function trackDamageBuffer_EntityTakeDmg(_, entity, damage)
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

-- Add at low priority
REVEL.EarlyCallbacks.trackDamageBuffer_Early_EntityTakeDmg = trackDamageBuffer_Early_EntityTakeDmg
REVEL.AddLowPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, trackDamageBuffer_EntityTakeDmg)
revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, trackDamageBuffer_PostNewRoom)

end

REVEL.PcallWorkaroundBreakFunction()