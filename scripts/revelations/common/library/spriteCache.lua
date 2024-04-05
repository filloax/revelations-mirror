local RevCallbacks = require "scripts.revelations.common.enums.RevCallbacks"
return function()

-- Since too many mods = memory issues, try to offer tools
-- to make removing unused sprites easier.
-- Following functions access sprite instance that only last
-- for a limited scope, and creates them if not existing, 
-- using statically defined params

---@alias RevSpriteCache.ID any

---@class SpriteProxy : Sprite

local SpriteFunctionNames = {
    "PlayOverlay", "IsPlaying", "GetFilename", "IsOverlayPlaying", 
    "SetAnimation", "WasEventTriggered","SetFrame", "IsEventTriggered", 
    "IsLoaded", "RemoveOverlay", "SetOverlayAnimation", "SetLayerFrame", 
    "ReplaceSpritesheet", "GetDefaultAnimationName", "GetFrame", "Reset", 
    "Render", "SetOverlayFrame", "Play", "SetLastFrame", 
    "GetLayerCount", "GetOverlayAnimation", "SetOverlayRenderPriority", "Update", 
    "Stop", "IsOverlayFinished", "RenderLayer", "GetDefaultAnimation", 
    "Load", "GetTexel", "GetOverlayFrame", "IsFinished", 
    "LoadGraphics", "Reload", "GetAnimation", "PlayRandom",     
}

---@param getSprite fun(params: RevSpriteCache.Params): Sprite
---@param params RevSpriteCache.Params
---@return SpriteProxy
local function MakeSpriteProxy(getSprite, params)
    local proxy = {}
    for _, key in ipairs(SpriteFunctionNames) do
        proxy[key] = function(self, ...)
            local sprite = getSprite(params)
            return sprite[key](sprite, ...)
        end
    end

    setmetatable(proxy, {
        __index = function(self, key)
            return getSprite(params)[key]
        end,
        __newindex = function(self, key, value)
            getSprite(params)[key] = value
        end,
    })

    return proxy
end

---@class RevSpriteCache.Params
---@field ID RevSpriteCache.ID
---@field Anm2 string?
---@field Animation string?
---@field Color Color?
---@field Scale Vector?
---@field Offset Vector?
---@field PlaybackSpeed number?
---@field OnCreate (fun(sprite: Sprite))?

---@param params RevSpriteCache.Params
---@return Sprite
local function CreateSpriteFromParams(params)
    local sprite = Sprite()
    if params.Anm2 then
        sprite:Load(params.Anm2, true)
        if params.Animation then
            sprite:Play(params.Animation, true)
        end
        if params.Color then
            sprite.Color = params.Color
        end
        if params.Scale then
            sprite.Scale = params.Scale
        end
        if params.Offset then
            sprite.Offset = params.Offset
        end
        if params.PlaybackSpeed then
            sprite.PlaybackSpeed = params.PlaybackSpeed
        end
    end
    if params.OnCreate then
        params.OnCreate(sprite)
    end

    return sprite
end

--#region RoomSprite

---@type table<RevSpriteCache.ID, Sprite>
local RoomSprites = {}
local NumRoomSprites = 0

-- handle reload
if REV_RELOAD_PERSIST.RoomSprites and Isaac.GetPlayer(0) then
    RoomSprites = REV_RELOAD_PERSIST.RoomSprites
end
REV_RELOAD_PERSIST.RoomSprites = RoomSprites

---Accesses a sprite instance that only lasts for a room,
-- creating it if it doesn't exist
---@param params RevSpriteCache.Params
---@return Sprite
function REVEL.RoomSprite(params)
    REVEL.Assert(type(params) == "table", "Params need to be in a table", 2)
    REVEL.Assert(params.ID, "Params need an ID", 2)

    local id = params.ID
    if not RoomSprites[id] then
        RoomSprites[id] = CreateSpriteFromParams(params)
        NumRoomSprites = NumRoomSprites + 1

        REVEL.DebugStringMinor("Created room sprite with id", id)
    end

    return RoomSprites[id]
end

---Returns object that acts like sprite and is only actually 
-- instanced when indexed
-- Meaning you can use it as a sprite but the instance lasts only for a room
---@param params RevSpriteCache.Params
function REVEL.LazyLoadRoomSprite(params)
    return MakeSpriteProxy(REVEL.RoomSprite, params)
end

---@param id RevSpriteCache.ID | RevSpriteCache.Params
---@return Sprite?
function REVEL.GetRoomSprite(id)
    if type(id) == "table" then 
        id = id.ID 
    end
    return RoomSprites[id]
end

---@param id RevSpriteCache.ID
---@return boolean had
function REVEL.ClearRoomSprite(id)
    local had = not not RoomSprites[id]
    if had then
        RoomSprites[id] = nil
        NumRoomSprites = NumRoomSprites - 1
    end
    return had
end

local function roomSprite_PostNewRoom()
    RoomSprites = {}
    REV_RELOAD_PERSIST.RoomSprites = RoomSprites

    REVEL.DebugStringMinor("[REVEL] Cleared", NumRoomSprites, "room sprites")
    NumRoomSprites = 0
end

--#endregion RoomSprite

--#region LevelSprite

---@type table<RevSpriteCache.ID, Sprite>
local LevelSprites = {}
local NumLevelSprites = 0

-- handle reload
if REV_RELOAD_PERSIST.LevelSprites and Isaac.GetPlayer(0) then
    LevelSprites = REV_RELOAD_PERSIST.LevelSprites
end
REV_RELOAD_PERSIST.LevelSprites = LevelSprites

---Accesses a sprite instance that only lasts for a level,
-- creating it if it doesn't exist
---@param params RevSpriteCache.Params
---@return Sprite
function REVEL.LevelSprite(params)
    REVEL.Assert(type(params) == "table", "Params need to be in a table", 2)
    REVEL.Assert(params.ID, "Params need an ID", 2)

    local id = params.ID
    if not LevelSprites[id] then
        LevelSprites[id] = CreateSpriteFromParams(params)
        NumLevelSprites = NumLevelSprites + 1

        REVEL.DebugStringMinor("Created level sprite with id", id)
    end

    return LevelSprites[id]
end

---Returns object that acts like sprite and is only actually 
-- instanced when indexed
-- Meaning you can use it as a sprite but the instance lasts only for a level
---@param params RevSpriteCache.Params
function REVEL.LazyLoadLevelSprite(params)
    return MakeSpriteProxy(REVEL.LevelSprite, params)
end

---@param id RevSpriteCache.ID | RevSpriteCache.Params
---@return Sprite?
function REVEL.GetLevelSprite(id)
    if type(id) == "table" then 
        id = id.ID 
    end
    return LevelSprites[id]
end

---@param id RevSpriteCache.ID
---@return boolean had
function REVEL.ClearLevelSprite(id)
    local had = not not LevelSprites[id]
    if had then
        NumLevelSprites = NumLevelSprites - 1
        LevelSprites[id] = nil
    end
    return had
end

local LastStageSeed = REV_RELOAD_PERSIST.LevelSpriteLastStage or -1

local function levelSprite_PostNewRoom()
    local stageSeed = REVEL.level:GetDungeonPlacementSeed()
    if stageSeed ~= LastStageSeed then
        LevelSprites = {}
        REV_RELOAD_PERSIST.LevelSprites = LevelSprites
        LastStageSeed = stageSeed
        REV_RELOAD_PERSIST.LevelSpriteLastStage = LastStageSeed

        REVEL.DebugToString("[REVEL] Cleared", NumLevelSprites, "level sprites")
        NumLevelSprites = 0
    end
end

--#endregion LevelSprite

--#region RunSprite

-- Sprites that last for a run, for instance sprites used by items
-- or characters but not otherwise

---@type table<RevSpriteCache.ID, Sprite>
local RunSprites = {}
local NumRunSprites = 0

-- handle reload
if REV_RELOAD_PERSIST.RunSprites and Isaac.GetPlayer(0) then
    RunSprites = REV_RELOAD_PERSIST.RunSprites
end
REV_RELOAD_PERSIST.RunSprites = RunSprites

---Accesses a sprite instance that only lasts for a run,
-- creating it if it doesn't exist
---@param params RevSpriteCache.Params
---@return Sprite
function REVEL.RunSprite(params)
    REVEL.Assert(type(params) == "table", "Params need to be in a table", 2)
    REVEL.Assert(params.ID, "Params need an ID", 2)

    local id = params.ID
    if not RunSprites[id] then
        RunSprites[id] = CreateSpriteFromParams(params)
        NumRunSprites = NumRunSprites + 1

        REVEL.DebugStringMinor("Created level sprite with id", id)
    end

    return RunSprites[id]
end

---Returns object that acts like sprite and is only actually 
-- instanced when indexed
-- Meaning you can use it as a sprite but the instance lasts only for a level
---@param params RevSpriteCache.Params
function REVEL.LazyLoadRunSprite(params)
    return MakeSpriteProxy(REVEL.RunSprite, params)
end

---@param id RevSpriteCache.ID | RevSpriteCache.Params
---@return Sprite?
function REVEL.GetRunSprite(id)
    if type(id) == "table" then 
        id = id.ID 
    end
    return RunSprites[id]
end

---@param id RevSpriteCache.ID
---@return boolean had
function REVEL.ClearRunSprite(id)
    local had = not not RunSprites[id]
    if had then
        NumRunSprites = NumRunSprites - 1
        RunSprites[id] = nil
    end
    return had
end

local function runSprite_PostGameStarted()
    RunSprites = {}
    REV_RELOAD_PERSIST.RunSprites = RunSprites

    REVEL.DebugToString("[REVEL] Cleared", NumRunSprites, "run sprites")
    NumRunSprites = 0
end

--#endregion RunSprite

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 0, levelSprite_PostNewRoom)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 0, roomSprite_PostNewRoom)
revel:AddCallback(ModCallbacks.MC_POST_GAME_END, runSprite_PostGameStarted)

    
end