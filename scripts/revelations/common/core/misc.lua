local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

-------------------------------
-- TEMPORARY API WORKAROUNDS --
-------------------------------

if not LUA_API_DOCS_PARSING then
    -- Vector multiplication fix for const vectors
    local META_VECTOR = getmetatable(Vector).__class

    local isVec, isVecMeta

    function isVec(a)
        local meta = getmetatable(a)
        return meta and (meta == META_VECTOR or meta.__type == "const Vector")
    end

    if REVEL.DEBUG then
        function isVecMeta(a)
            local meta = getmetatable(a)
            return meta and (meta == META_VECTOR or meta.__type == "const Vector")
        end
    else
        function isVecMeta(a)
            local meta = getmetatable(a)
            if meta and meta.__type == "const Vector" then
                REVEL.DebugLog("WARN: Used multiplication for const vector, more info:", 
                    REVEL.TryGetTraceback(nil, true))
            end
            return meta and (meta == META_VECTOR or meta.__type == "const Vector")
        end
    end

    -- Reimplement repentance main.lua's vector multiplication to work on const vectors too
    rawset(META_VECTOR, "__mul", function(a, b)
        if isVecMeta(a) then
            return isVecMeta(b) and Vector(a.X*b.X, a.Y*b.Y) or Vector(a.X*b,a.Y*b)
        else
            return Vector(a*b.X,a*b.Y)
        end
    end)

    -- Fixed vector multiplication function for Const Vectors,
    -- used as separate function instead of replacing API stuff
    -- to avoid messing with global stuff when not needed,
    -- be Ctrl-shift-F'd later when the API function gets fixed
    function REVEL.VectorMult(a, b)
        if isVec(a) then
            return isVec(b) and Vector(a.X*b.X, a.Y*b.Y) or Vector(a.X*b,a.Y*b)
        else
            return Vector(a*b.X,a*b.Y)
        end
    end

    -- RNG logging for seed 0 crash debugging

    REVEL.ENABLE_RNG_0_LOGGING = true

    if REVEL.DEBUG and REVEL.ENABLE_RNG_0_LOGGING then
        Isaac.DebugString("[REVEL] RNG debug override enabled")

        --[[
        getmetatable(RNG).__class = {
            __const=table: 0E802C98,
            RandomFloat=function: 0E802EC8,
            Next=function: 0E803008,
            __newindex=function: 00EE65B0,
            __index=function: 00EE63C0,
            [userdata]=true,
            __type=RNG,
            SetSeed=function: 0E802F68,
            RandomInt=function: 0E802EA0,
            GetSeed=function: 0E802F40,
            __propset=table: 0E802D38,
            __gc=function: 00F4C520,
            __propget=table: 0E803030
        }
        ]]
        function REVEL.RngDebugCheck(rng, funcName, ...)
            if rng:GetSeed() == 0 then
                error("RNG seed is 0! in " .. funcName .. REVEL.TryGetTraceback(), 4)
            end
        end

        local funcs = {
            -- "GetSeed",
            "Next",
            "RandomFloat",
            "RandomInt",
            "SetSeed",
        }

        REVEL.DebugRngFunctions = {
            Next = function(self)
                REVEL.RngDebugCheck(self, "Next")
            end,
            RandomFloat = function(self)
                REVEL.RngDebugCheck(self, "RandomFloat")
            end,
            RandomInt = function(self)
                REVEL.RngDebugCheck(self, "RandomInt")
            end,
            SetSeed = function(self, seed, off)
                if seed == 0 then
                    error("Setting RNG seed to 0! " .. REVEL.TryGetTraceback())
                end
            end,
        }

        if not REV_REPLACED_RNG then
            _G.REV_PREC_RNG_FUNCS = {}

            for _, f in ipairs(funcs) do
                _G.REV_PREC_RNG_FUNCS[f] = APIOverride.GetCurrentClassFunction(RNG, f)
                --needs to be a global or it gets reset on reload
                APIOverride.OverrideClassFunction(RNG, f, function(self, ...)
                    if REVEL.DebugRngFunctions[f] then
                        REVEL.DebugRngFunctions[f](self, ...)
                    end
                    return _G.REV_PREC_RNG_FUNCS[f](self, ...)
                end)
            end

            REV_REPLACED_RNG = true
        end
    end
end

--------------------------------
-- LUA BETTER DEBUG OVERRIDES --
--------------------------------

-- Various functions just throw a generic error with no
-- line number if they're used incorrectly, let's try and
-- fix that when in debug mode
if REVEL.DEBUG and not REV_DEBUG_REPLACED_LUA_FUNCS and not LUA_API_DOCS_PARSING then
    REVEL.DISABLE_ERROR_TRACEBACK = false
    if not REV_ALREADY_LOGGING_TRACEBACK then
        _G.__oldError = error

        local function traceback(levelOffset)
            levelOffset = levelOffset or 1
            if debug then
                Isaac.DebugString(debug.traceback(nil, 3 + levelOffset - 1))
            end
        end

        function error(message, level)
            level = level or 1
            if not REVEL.DISABLE_ERROR_TRACEBACK then
                traceback(level + 1)
            end
            _G.__oldError(message, level + 1)
        end
    end

    _G.__oldIpairs = ipairs

    function ipairs(t)
        if t == nil then
            error("ipairs: t nil", 2)
        end
        if type(t) ~= "table" and type(t) ~= "userdata" then
            error("ipairs: t not a table, is " .. type(t).. ": " .. tostring(t), 2)
        end

        return _G.__oldIpairs(t)
    end

    _G.__oldPairs = pairs

    function pairs(t)
        if t == nil then
            error("pairs: t nil", 2)
        end
        if type(t) ~= "table" and type(t) ~= "userdata" then
            error("pairs: t not a table, is " .. type(t) .. ": " .. tostring(t), 2)
        end

        return _G.__oldPairs(t)
    end

    _G.__oldMax = math.max

    function math.max(x, ...)
        if x == nil then
            error("max: x nil", 2)
        end
        local args = {...}
        if select('#', ...) ~= #args then
            error("max: args nil", 2)
        end

        return _G.__oldMax(x, ...)
    end

    _G.__oldMin = math.min

    function math.min(x, ...)
        if x == nil then
            error("min: x nil", 2)
        end
        local args = {...}
        if select('#', ...) ~= #args then
            error("min: args nil", 2)
        end

        return _G.__oldMin(x, ...)
    end

    REV_DEBUG_REPLACED_LUA_FUNCS = true
end


-------------------
-- MODDATA STATS --
-------------------
do
--REVEL.DEFAULT_MODDATA in revelN_defaultmoddata

    --[[
        Note to self: 
        when it was TearHeight, default TearHeight was -17.5
        with TearRange it's 260 (with the HUD range being in tiles, so this / 40)
    ]]

    REVEL.FlagStats = {
        [CacheFlag.CACHE_DAMAGE] = "Damage",
        [CacheFlag.CACHE_FIREDELAY] = "MaxFireDelay",
        [CacheFlag.CACHE_SHOTSPEED] = "ShotSpeed",
        [CacheFlag.CACHE_RANGE] = "TearRange",
    --    [CacheFlag.CACHE_RANGE] = "TearFallingSpeed",  this affects range too, but if things are done this way must be manually modified
        [CacheFlag.CACHE_SPEED] = "MoveSpeed",
        [CacheFlag.CACHE_LUCK] = "Luck"
    }

    REVEL.StatFlags = {
        Damage = CacheFlag.CACHE_DAMAGE,
        MaxFireDelay = CacheFlag.CACHE_FIREDELAY,
        ShotSpeed = CacheFlag.CACHE_SHOTSPEED,
        TearRange = CacheFlag.CACHE_RANGE,
        MoveSpeed = CacheFlag.CACHE_SPEED,
        Luck = CacheFlag.CACHE_LUCK,
    }

    REVEL.StatMin = {
        [CacheFlag.CACHE_DAMAGE] = 1,
        [CacheFlag.CACHE_FIREDELAY] = 5,
        [CacheFlag.CACHE_SHOTSPEED] = -999,
        [CacheFlag.CACHE_RANGE] = 0,
        [CacheFlag.CACHE_SPEED] = 0.5,
        [CacheFlag.CACHE_LUCK] = -999
    }

    --apply stat changes
    revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
        local runStats = revel.data.run.stats[REVEL.GetPlayerID(player)]

        if runStats then
            if runStats[REVEL.FlagStats[flag]] then
                local prevStat = player[REVEL.FlagStats[flag]]

                player[REVEL.FlagStats[flag]] = player[REVEL.FlagStats[flag]] + runStats[REVEL.FlagStats[flag]]
                player[REVEL.FlagStats[flag]] = player[REVEL.FlagStats[flag]] * runStats.mult[REVEL.FlagStats[flag]]

                player[REVEL.FlagStats[flag]] = math.max( math.min( REVEL.StatMin[flag] , prevStat ) , player[REVEL.FlagStats[flag]] )
            end

            if flag == CacheFlag.CACHE_RANGE then
                player.TearFallingSpeed = (player.TearFallingSpeed + runStats.TearFallingSpeed) * runStats.mult.TearFallingSpeed
            end
        end
    end)

end

-------------------
-- MORE LOG INFO --
-------------------
do
    revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
        if REVEL.DEBUG then
            local stageName
            if StageAPI.GetCurrentStage() then
                stageName = StageAPI.GetCurrentStageDisplayName()
            else
                local stage = REVEL.level:GetStage()
                local stageType = REVEL.level:GetStageType()
                local lstageName = REVEL.getKeyFromValue(LevelStage, stage)
                local stageTypeName = REVEL.getKeyFromValue(StageType, stageType)
                local i = string.find(stageTypeName, "_")
                stageTypeName = string.sub(stageTypeName, i + 1, #stageTypeName)
                stageName = lstageName .. ":" .. stageTypeName
            end
            REVEL.DebugToString("[REVEL] Changed stage! New stage: '" .. stageName .. "'")
        end
    end)

    StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_STAGEAPI_NEW_ROOM, 1, function()
        if REVEL.DEBUG then
            local currentRoom = StageAPI.GetCurrentRoom()
            local desc = REVEL.level:GetCurrentRoomDesc()

            if currentRoom then
                local rtype = StageAPI.GetCurrentRoomType()
                local rtypeName = REVEL.keyOf(RoomType, rtype)
                rtype = rtypeName and (rtypeName .. " [" .. tostring(rtype) .. "]") or rtype

                REVEL.DebugStringMinor(("[REVEL] Loaded StageAPI room '%s', type %s, from list '%s', is visit n° %d"):format(
                    currentRoom.Layout.Name,
                    rtype,
                    currentRoom.RoomsListName,
                    desc.VisitedCount
                ))
            else 
                local name = desc.Data.Name ~= "" and ("%s.%d"):format(desc.Data.Name, desc.Data.Variant) or desc.Data.Variant
                name = tostring(desc.Data.StageID) .. ":" .. name
                REVEL.DebugStringMinor(("[REVEL] Loaded vanilla room '%s', type %s, is visit n° %d"):format(
                    name,
                    REVEL.room:GetType(),
                    desc.VisitedCount
                ))
            end
        end
    end)

    StageAPI.AddCallback("Revelations", StageAPICallbacks.CHALLENGE_WAVE_CHANGED, 1, function()
        if REVEL.DEBUG then
            -- wait for normal enemies to be removed
            REVEL.DelayFunction(1, function()
                local npcs = REVEL.GetRoomNPCs()
                local npcCount = {}
                for _, npc in ipairs(npcs) do
                    npcCount[npc.Type] = npcCount[npc.Type] or {}
                    npcCount[npc.Type][npc.Variant] = npcCount[npc.Type][npc.Variant] or 0
                    npcCount[npc.Type][npc.Variant] = npcCount[npc.Type][npc.Variant] + 1
                end
                local strings = {}
                for type, variantTables in pairs(npcCount) do
                    for variant, count in pairs(variantTables) do
                        local thisStr = type .. "." .. variant .. " x" .. count
                        strings[#strings+1] = thisStr
                    end
                end
                REVEL.DebugToString("StageAPI Challenge wave changed, room enemies: " .. table.concat(strings, ", "))
            end)
        end
    end)
end

------------------------------
-- ASSOCIATE PLAYER WEAPONS --
------------------------------

do
StageAPI.AddCallback("Revelations", RevCallbacks.BOMB_UPDATE_INIT, 1, function(bomb)
    if bomb.SpawnerType == 1 then
        if not bomb.Parent then --applies to normally dropped bomb, not dr fetus for instance
            REVEL.GetData(bomb).__player = REVEL.getClosestInTable(REVEL.players, bomb)
        else
            local data = REVEL.GetData(bomb)
            data.__player = bomb.Parent:ToPlayer()

            -- TEMP: Incubus workaround for bombs
            local incubi = Isaac.FindByType(3, FamiliarVariant.INCUBUS)
            if #incubi > 0 then
                local closestIncubus, distSquared = REVEL.getClosestInTable(incubi, bomb)

                if distSquared < bomb.Position:DistanceSquared(data.__player.Position) then
                    data.Incubus = closestIncubus
                    bomb.Parent = closestIncubus
                end 
            end   
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, eff)
    if eff.Variant == EffectVariant.TARGET then --epic fetus target
        REVEL.GetData(eff).__player = REVEL.getClosestInTable(REVEL.players, eff)
    elseif eff.Variant == EffectVariant.ROCKET then --epic fetus missile
        local target = REVEL.getClosestInTable(Isaac.FindByType(1000, 30, -1, false, true), eff)
        if target then
            REVEL.GetData(eff).__player = REVEL.GetData(target).__player
        end
    end
end)

local HDTearSprites = {
    ["gfx/002.005_Fire Tear.anm2"] = true,
    ["gfx/002.007_Mysterious Tear.anm2"] = true,
    ["gfx/002.020_Coin Tear.anm2"] = true
}

function REVEL.IsHDTearSprite(e) --some tear flags have higher def sprites, with smaller scales to make them have the same size, making replacing their sprites with normal res ones makes the tear small
    local file = e:GetSprite():GetFilename()
    return HDTearSprites[file]
end

function REVEL.GetLudoTear()
    for i,e in ipairs(REVEL.roomTears) do
        if e:HasTearFlags(TearFlags.TEAR_LUDOVICO) then
            return e
        end
    end
end

end


------------------------------
-- BETTER COLLECTIBLEEFFECT --
------------------------------
do
local CollectibleEffects = {{}, {}, {}, {}}

--add an item for the room, to be used when AddCollectibleEffect doesn't work/only adds the costume
--~~items added like this WILL count towards transformations~~ rep added transformation counter removal so not anymore
function REVEL.AddCollectibleEffect(id, player, amount)
    player = player or REVEL.player
    amount = amount or 1
    for i = 1, amount do
        player:AddCollectible(id, 6, false)
        table.insert(CollectibleEffects[REVEL.GetPlayerID(player)], id)
    end
end

function REVEL.RemoveCollectibleEffects(player)
    for _,v in ipairs(CollectibleEffects[REVEL.GetPlayerID(player)]) do
        player:RemoveCollectible(v)
    end
    CollectibleEffects[REVEL.GetPlayerID(player)] = {}
end

function REVEL.RemoveAllCollectibleEffects()
	for i, p in ipairs(REVEL.players) do
		REVEL.RemoveCollectibleEffects(p)
	end
end

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, REVEL.RemoveAllCollectibleEffects)
revel:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, REVEL.RemoveAllCollectibleEffects)
end

---------------------
-- UPDATE ENTITIES --
---------------------
do

-- if true: only load specific entity lists when requested,
-- keep them in cache for UPDATE_ALL_ENTS_FREQ frames, 
-- and add/remove entities as they are spawned/removed
-- if false: do Isaac.GetRoomEntities each frame and that's it
-- Caching might have issues
REVEL.CACHE_ENTITY_LISTS = false
REVEL.UPDATE_ALL_ENTS_FREQ = 30 --in frames

local globalTable = {
    Entities = {},
    Updated = -1,
}

---@generic T : Entity
---@class Rev.EntityTable
---@field Entities table
---@field Updated integer
---@field CheckBelongs fun(entity: Entity): boolean
---@field GetOnlyThis fun(): Entity[] is actually instances of the specific entity subclass returned from Convert
---@field Convert fun(entity: Entity): Entity
---@field InitCallback ModCallbacks

---@type table<string, Rev.EntityTable>
local entityTables = {
    roomTears = {
        Entities = {},
        Updated = -1,
        CheckBelongs = function(entity)
            return entity.Type == EntityType.ENTITY_TEAR
        end,
        GetOnlyThis = function()
            return Isaac.FindByType(EntityType.ENTITY_TEAR)
        end,
        Convert = function(e) return e:ToTear() end,
        InitCallback = ModCallbacks.MC_POST_TEAR_INIT,
    },
    roomFamiliars = {
        Entities = {},
        Updated = -1,
        CheckBelongs = function(entity)
            return entity.Type == EntityType.ENTITY_FAMILIAR
        end,
        GetOnlyThis = function()
            return Isaac.FindByType(EntityType.ENTITY_FAMILIAR)
        end,
        Convert = function(e) return e:ToFamiliar() end,
        InitCallback = ModCallbacks.MC_POST_FAMILIAR_INIT,
    },
    roomPickups = {
        Entities = {},
        Updated = -1,
        CheckBelongs = function(entity)
            return entity.Type == EntityType.ENTITY_PICKUP
        end,
        GetOnlyThis = function()
            return Isaac.FindByType(EntityType.ENTITY_PICKUP)
        end,
        Convert = function(e) return e:ToPickup() end,
        InitCallback = ModCallbacks.MC_POST_PICKUP_INIT,
    },
    roomBombdrops = {
        Entities = {},
        Updated = -1,
        CheckBelongs = function(entity)
            return entity.Type == EntityType.ENTITY_BOMBDROP
        end,
        GetOnlyThis = function()
            return Isaac.FindByType(EntityType.ENTITY_BOMBDROP)
        end,
        Convert = function(e) return e:ToBomb() end,
        InitCallback = ModCallbacks.MC_POST_BOMB_INIT,
    },
    roomSlots = {
        Entities = {},
        Updated = -1,
        CheckBelongs = function(entity)
            return entity.Type == EntityType.ENTITY_SLOT
        end,
        GetOnlyThis = function()
            return Isaac.FindByType(EntityType.ENTITY_SLOT)
        end,
        -- InitCallback = ModCallbacks.MC_POST_BOMB_INIT, --not yet added in API
    },
    roomLasers = {
        Entities = {},
        Updated = -1,
        CheckBelongs = function(entity)
            return entity.Type == EntityType.ENTITY_LASER
        end,
        GetOnlyThis = function()
            return Isaac.FindByType(EntityType.ENTITY_LASER)
        end,
        Convert = function(e) return e:ToLaser() end,
        InitCallback = ModCallbacks.MC_POST_LASER_INIT,
    },
    roomKnives = {
        Entities = {},
        Updated = -1,
        CheckBelongs = function(entity)
            return entity.Type == EntityType.ENTITY_KNIFE
        end,
        GetOnlyThis = function()
            return Isaac.FindByType(EntityType.ENTITY_KNIFE)
        end,
        Convert = function(e) return e:ToKnife() end,
        InitCallback = ModCallbacks.MC_POST_KNIFE_INIT,
    },
    roomProjectiles = {
        Entities = {},
        Updated = -1,
        CheckBelongs = function(entity)
            return entity.Type == EntityType.ENTITY_PROJECTILE
        end,
        GetOnlyThis = function()
            return Isaac.FindByType(EntityType.ENTITY_PROJECTILE)
        end,
        Convert = function(e) return e:ToProjectile() end,
        InitCallback = ModCallbacks.MC_POST_PROJECTILE_INIT,
    },
    roomEnemies = {
        Entities = {},
        Updated = -1,
        CheckBelongs = function(entity)
            if entity:IsActiveEnemy(false) 
            and not (
                REVEL.GetData(entity).__friendly 
                or entity:HasEntityFlags(EntityFlag.FLAG_NO_TARGET)
            ) then
                return entity
            end
        end,
        Convert = function(e) return e:ToNPC() end,
        InitCallback = ModCallbacks.MC_POST_NPC_INIT,
    },
    roomNPCs = {
        Entities = {},
        Updated = -1,
        CheckBelongs = function(entity)
            return entity:ToNPC()
        end,
        Convert = function(e) return e:ToNPC() end,
        InitCallback = ModCallbacks.MC_POST_NPC_INIT,
    },
    roomFires = {
        Entities = {},
        Updated = -1,
        PreUpdate = function()
            REVEL.roomFireGrids = {}
        end,
        CheckBelongs = function(entity)
            return entity.Type == EntityType.ENTITY_FIREPLACE
        end,
        GetOnlyThis = function()
            return Isaac.FindByType(EntityType.ENTITY_FIREPLACE)
        end,
        OnAdd = function(entity)
            REVEL.roomFireGrids[REVEL.room:GetGridIndex(entity.Position)] = true
        end,
        OnRemove = function(entity)
            REVEL.roomFireGrids[REVEL.room:GetGridIndex(entity.Position)] = nil
        end,
        Convert = function(e) return e:ToNPC() end,
        InitCallback = ModCallbacks.MC_POST_NPC_INIT,
    },
    roomEffects = {
        Entities = {},
        Updated = -1,
        CheckBelongs = function(entity)
            return entity.Type == 1000
        end,
        GetOnlyThis = function()
            return Isaac.FindByType(1000)
        end,
        Convert = function(e) return e:ToEffect() end,
        InitCallback = ModCallbacks.MC_POST_EFFECT_INIT,
    },
}

local function IsEntTableFresh(entTable)
    return entTable.Updated >= 0 
        and REVEL.game:GetFrameCount() - entTable.Updated < REVEL.UPDATE_ALL_ENTS_FREQ
end

local function UpdateAllEntityTables()
    local frame = REVEL.game:GetFrameCount()
    local ents = Isaac.GetRoomEntities()

    globalTable.Entities = ents
    globalTable.Updated = frame

    for k, entTable in pairs(entityTables) do
        entTable.Entities = {}
        entTable.Updated = frame

        if entTable.PreUpdate then
            entTable.PreUpdate()
        end
    end

    for _, entity in ipairs(ents) do
        for k, entTable in pairs(entityTables) do
            if entTable.CheckBelongs(entity) then
                entTable.Entities[#entTable.Entities+1] = entTable.Convert and entTable.Convert(entity) or entity
                if entTable.OnAdd then
                    entTable.OnAdd(entity)
                end
            end
        end
    end
end

local function UpdateSingleEntityTable(entTable)
    if entTable.GetOnlyThis then
        local frame = REVEL.game:GetFrameCount()
        local ents = entTable.GetOnlyThis()

        if entTable.PreUpdate then
            entTable.PreUpdate()
        end

        for _, entity in ipairs(ents) do
            entTable.Entities[#entTable.Entities + 1] = entTable.Convert and entTable.Convert(entity) or entity
            if entTable.OnAdd then
                entTable.OnAdd(entity)
            end
        end

        entTable.Updated = frame
    else
        UpdateAllEntityTables()
    end
end

local calls = {}

local indexFunctions = {
    roomEntities = function()
        -- if not REVEL.game:IsPaused() then
        --     calls.roomEntities = (calls.roomEntities or 0) + 1
        -- end
        if not IsEntTableFresh(globalTable) then
            UpdateAllEntityTables()
        end
        return globalTable.Entities
    end,
}

for k, entTable in pairs(entityTables) do
    indexFunctions[k] = function()
        -- if not REVEL.game:IsPaused() then
        --     calls[k] = (calls[k] or 0) + 1
        -- end
        if not IsEntTableFresh(entTable) then
            if entTable.PreUpdate then
                entTable.PreUpdate()
            end
            UpdateSingleEntityTable(entTable)
        end
        return entTable.Entities
    end
end

REVEL.mixin(REVEL.IndexFunctions, indexFunctions)


-- revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
--     if REVEL.game:GetFrameCount() % 30 == 0 then
--         local total = 0
--         for k, v in pairs(calls) do
--             total = total + v
--         end

--         for k, v in pairs(calls) do
--             REVEL.DebugLog("Calls to " .. k .. ": " .. math.floor(v * 100 / total) .. "% " .. v)
--         end

--         calls = {}
--     end
-- end)

local function enttablesPostEntityRemove(_, entity)
    for _, entTable in pairs(entityTables) do
        if IsEntTableFresh(entTable) then --no point in updating else
            if entTable.CheckBelongs(entity) then
                for i, entity2 in ripairs(entTable.Entities) do
                    if GetPtrHash(entity) == GetPtrHash(entity2) then
                        table.remove(entTable.Entities, i)
                        if entTable.OnRemove then
                            entTable.OnRemove(entity)
                        end
                        break
                    end
                end
            end
        end
    end
    if IsEntTableFresh(globalTable) then
        for i, entity2 in ripairs(globalTable.Entities) do
            if GetPtrHash(entity) == GetPtrHash(entity2) then
                table.remove(globalTable.Entities, i)
                break
            end
        end
    end
end

local function enttablesReset()
    globalTable.Updated = -1
    globalTable.Entities = {}
    for _, entTable in pairs(entityTables) do
        entTable.Updated = -1
        entTable.Entities = {}
    end
end

REVEL.InvalidateEntityCache = enttablesReset

-- No cache version, set roomEntities and continually update it 
local function enttablesNoCacheUpdateLists()
    UpdateAllEntityTables()

    REVEL.roomEntities = globalTable.Entities

    for k, entTable in pairs(entityTables) do
        REVEL[k] = entTable.Entities
    end
end

local DeepDebug = false

if REVEL.CACHE_ENTITY_LISTS then
    revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, enttablesPostEntityRemove)
    revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, enttablesReset)
    revel:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, enttablesReset)
    StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, -50, enttablesReset)

    for k, entTable in pairs(entityTables) do
        if entTable.InitCallback then
            revel:AddCallback(entTable.InitCallback, function(_, entity)
                if IsEntTableFresh(entTable) then
                    if entTable.CheckBelongs(entity) then
                        entTable.Entities[#entTable.Entities+1] = entTable.Convert and entTable.Convert(entity) or entity
                        if DeepDebug then
                            REVEL.DebugToString("Added " .. entity.Type .. "." .. entity.Variant .. " to " .. k)
                        end
                        if entTable.OnAdd then
                            entTable.OnAdd(entity)
                        end
                    end
                end
                -- Handle things like fires with more than 1 entity table with same init callback
                if IsEntTableFresh(globalTable) 
                and GetPtrHash(globalTable.Entities[#globalTable.Entities]) ~= GetPtrHash(entity) then
                    if DeepDebug then
                        REVEL.DebugToString("Added " .. entity.Type .. "." .. entity.Variant .. " to globalTable")
                    end
                    globalTable.Entities[#globalTable.Entities+1] = entity
                end
            end)
        end
    end
else
    StageAPI.AddCallback("Revelations", "POST_STAGEAPI_NEW_ROOM", -50, enttablesNoCacheUpdateLists)
    revel:AddCallback(ModCallbacks.MC_POST_UPDATE, enttablesNoCacheUpdateLists)
end


function REVEL.TestGetEntsPerformance()
    local t1 = Isaac.GetTime()
    for i = 1, 1000 do
        UpdateAllEntityTables()
    end
    local t2 = Isaac.GetTime()
    REVEL.DebugLog("Took " .. ((t2-t1) / 1000) .. "ms")
end

end


do -- Disabled items
	local function removeDisabledItems()
		for _, item in pairs(REVEL.ITEM) do
			if item.disabled then
				for _,p in ipairs(REVEL.roomPickups) do
				  if p.Variant == PickupVariant.PICKUP_COLLECTIBLE and p.SubType == item.id then
					  p:Morph(p.Type, p.Variant, 0, true)
				  end
				end

				for _, player in ipairs(REVEL.players) do
					local numItem = player:GetCollectibleNum(item.id, true)
					if numItem > 0 then
						for i = 1, numItem do
							player:RemoveCollectible(item.id)
						end
					end
				end
			end
		end
	end

	revel:AddCallback(ModCallbacks.MC_POST_UPDATE, removeDisabledItems)
	StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, removeDisabledItems)
end


--------------------------
-- SELF REMOVING ENTITY --
--------------------------
do
  revel:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, eff)
  	if eff.Variant == REVEL.ENT.SELF_REMOVING_ENTITY.variant then
  		eff:Remove()
  	end
  end)
end

-- Items originally in / taken from room (used in hyper dice)
do

-- All collectibles and all other pickups with a price in the room (i'm using "Notable" as "things that shouldn't be given to you for free by hyper dice or other similar things")
function REVEL.GetRoomNotablePickups()
    local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP, -1, -1, false, false)
    local notablePickups = {}
    for _, pickup in ipairs(pickups) do
        if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
            if pickup.SubType ~= 0 then
                notablePickups[#notablePickups + 1] = pickup
            end
        else
            if pickup:ToPickup().Price ~= 0 then
                notablePickups[#notablePickups + 1] = pickup
            end
        end
    end

    return notablePickups
end

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    if REVEL.room:IsFirstVisit() then
        local roomID = StageAPI.GetCurrentRoomID()
        revel.data.run.level.notablePickupsInRoom[roomID] = #REVEL.GetRoomNotablePickups()
        revel.data.run.level.notablePickupsTakenFromRoom[roomID] = 0
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    local roomID = StageAPI.GetCurrentRoomID()
    if revel.data.run.level.notablePickupsInRoom[roomID] then
        local numItems = #REVEL.GetRoomNotablePickups()
        if numItems > revel.data.run.level.notablePickupsInRoom[roomID] then
            revel.data.run.level.notablePickupsInRoom[roomID] = numItems
        elseif numItems < revel.data.run.level.notablePickupsInRoom[roomID] then
            revel.data.run.level.notablePickupsTakenFromRoom[roomID] = revel.data.run.level.notablePickupsTakenFromRoom[roomID] + (revel.data.run.level.notablePickupsInRoom[roomID] - numItems)
            revel.data.run.level.notablePickupsInRoom[roomID] = numItems
        end
    end
end)

end


-- Remove curse of the maze
do

    function REVEL.CurseOfMazeDenied(stage)
        if REVEL.StageIsRevelStage(stage or StageAPI.GetCurrentStage()) then
            return true
        end
        if REVEL.IsDanteCharon(REVEL.player) and not REVEL.game:IsGreedMode() then
            return true
        end
        return false
    end

    revel:AddCallback(ModCallbacks.MC_POST_CURSE_EVAL, function(_, curses)
        if HasBit(curses, LevelCurse.CURSE_OF_MAZE) and REVEL.CurseOfMazeDenied(StageAPI.GetNextStage()) then
            return curses & (~LevelCurse.CURSE_OF_MAZE)
        end
    end)

    local function removeMazeCurse()
        if HasBit(REVEL.level:GetCurses(), LevelCurse.CURSE_OF_MAZE) and REVEL.CurseOfMazeDenied() then
            REVEL.level:RemoveCurses(LevelCurse.CURSE_OF_MAZE)
        end
    end
    revel:AddCallback(ModCallbacks.MC_POST_UPDATE, removeMazeCurse)
    StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, removeMazeCurse)
    revel:AddCallback(ModCallbacks.MC_USE_PILL, removeMazeCurse, PillEffect.PILLEFFECT_QUESTIONMARK)

    revel:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function(_, pickup)
        if pickup.SubType > 0 and REVEL.pool:GetPillEffect(pickup.SubType) == PillEffect.PILLEFFECT_QUESTIONMARK and REVEL.CurseOfMazeDenied() then
            pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, 0, true)
        end
    end, PickupVariant.PICKUP_PILL)

end

--Item spawn helper (uses softid, intended for BR rooms)
do

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.ITEM_SPAWN_HELPER.variant then return end
    if not npc:Exists() then return end

    local id = npc.SubType
    if id == 0 then
        local ids = REVEL.keys(REVEL.ITEMS_MAP)
        id = ids[math.random(#ids)]
    end

    local item = REVEL.getItemBySoftId(id)
    if item then
        local i = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, item.id, npc.Position, Vector.Zero, nil)
        REVEL.GetData(i).DisableReroll = StageAPI.InTestMode
        i:Update()
    else
        REVEL.DebugLog("Tried to spawn invalid soft item id:", id)
    end

    npc:Remove()
end, REVEL.ENT.ITEM_SPAWN_HELPER.id)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE , function(_, npc)
    if npc.Variant ~= REVEL.ENT.TRINKET_SPAWN_HELPER.variant then return end
    if not npc:Exists() then return end

    local id = npc.SubType
    if id == 0 then
        local ids = REVEL.keys(REVEL.TRINKETS_MAP)
        id = ids[math.random(#ids)]
    end

    local item = REVEL.getTrinketBySoftId(id)
    if item then
        local t = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, item.id, npc.Position, Vector.Zero, nil)
        REVEL.GetData(t).DisableReroll = StageAPI.InTestMode
        t:Update()
    else
        REVEL.DebugLog("Tried to spawn invalid soft trinket id:", id)
    end

    npc:Remove()
end, REVEL.ENT.TRINKET_SPAWN_HELPER.id)

end

-----------------------------------------
-- JACOB AND ESAU SHARING POSITION FIX --
-----------------------------------------

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    for i,player in ipairs(REVEL.players) do
        if player:GetPlayerType() == PlayerType.PLAYER_JACOB then
            -- if player is Jacob, next player must be Esau
            local esau = REVEL.players[i + 1]
            
            if player.Position.X == esau.Position.X and player.Position.Y == esau.Position.Y then
                player.Position = player.Position + Vector(-20,0)
                esau.Position = esau.Position + Vector(20,0)
            end
        end
    end
end)


------------------------
-- LABYRINTH OVERRIDE --
------------------------

do
    local NoLabyrinthStages = {

    }
    local AddLabyrinthStages = {

    }

    ---@param customStage CustomStage
    function REVEL.StageDisableLabyrinth(customStage)
        NoLabyrinthStages[customStage.Name] = true
    end

    -- Make a stage able to have labyrinth even if it normally couldn't
    -- have it
    ---@param customStage CustomStage
    function REVEL.StageAddLabyrinthChance(customStage)
        AddLabyrinthStages[customStage.Name] = true
    end

    -- https://bindingofisaacrebirth.fandom.com/wiki/Curses#Chance
    local function GetLabyrinthChance(curses)
        if curses > 0 then
            return 0
        end

        -- Use base curse chance, increase
        -- it as the "roll" already happened by base game and this
        -- would lead to a lower chance (ie it would need
        -- to pick the correct number twice)

        -- Also, no way to check game progress, so just pick an average of 
        -- likely chances (check Wiki page) until it is possible,
        -- assuming most players that play this mod have at least
        -- killed mom 5 times

        local avgChance
        if REVEL.game.Difficulty == Difficulty.DIFFICULTY_HARD then
            avgChance = (1/5 + 1/3 + 1/3) / 3
        else
            avgChance = (1/30 + 1/10 + 1/5) / 3
        end

        -- Increase it, as above
        local curseChance = avgChance * 2

        local labyrinthChance = curseChance / 6

        return labyrinthChance
    end

    -- For stages with unconventional level gen basics
    -- (example: glacier using 1_2 and 2_1), override
    -- labyrinth as it would be in invalid stage otherwise

    -- Important for logging: callbacks called by something in a command
    -- (for example: this and `stage`) do not print anything to console
    -- when the command is called via `Isaac.ExecuteCommand`
    revel:AddCallback(ModCallbacks.MC_POST_CURSE_EVAL, function(_, curses)
        if StageAPI.NextStage then
            if NoLabyrinthStages[StageAPI.NextStage.Name] then
                REVEL.DebugStringMinor("[REVEL] Curse eval: no labyrinth stage", StageAPI.NextStage.Name)
                if HasBit(curses, LevelCurse.CURSE_OF_LABYRINTH) then
                    REVEL.DebugToString("[REVEL] Curse eval: remove labyrinth from no labyrinth stage", StageAPI.NextStage.Name)
                    return ClearBit(curses, LevelCurse.CURSE_OF_LABYRINTH)
                end
            elseif AddLabyrinthStages[StageAPI.NextStage.Name] then
                REVEL.DebugStringMinor("[REVEL] Curse eval: add labyrinth stage", StageAPI.NextStage.Name)
                local labyrinthChance = GetLabyrinthChance(curses)
                local rng = REVEL.RNG()
                rng:SetSeed(REVEL.level:GetDungeonPlacementSeed(), 40)
                if rng:RandomFloat() < labyrinthChance then
                    REVEL.DebugToString("[REVEL] Curse eval: add labyrinth to no labyrinth stage", StageAPI.NextStage.Name, "chance was", labyrinthChance)
                    return SetBit(curses, LevelCurse.CURSE_OF_LABYRINTH)
                end
            end
        end
    end)
end


------------------------
-- DICE ROOM OVERRIDE --
------------------------

do
    local SUBTYPE_5_PIP = 4

    revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, etype, variant, subtype, pos, vel, spawner, seed)
        if variant == EffectVariant.DICE_FLOOR and etype == 1000
        and StageAPI.InNewStage() 
        and subtype == SUBTYPE_5_PIP
        then
            local rng = REVEL.RNG()
            rng:SetSeed(seed, 38)
            local newSubtype = rng:RandomInt(5)
            if newSubtype == SUBTYPE_5_PIP then
                newSubtype = 5
            end
            REVEL.DebugToString("[REVEL] Replacing 5-pip dice room with", newSubtype + 1, "pip dice room")
            return {
                etype,
                variant,
                newSubtype,
                seed
            }
        end
    end)
end

end